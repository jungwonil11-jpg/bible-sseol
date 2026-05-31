#!/usr/bin/env python3
import json
import os
import re
import sys
from html.parser import HTMLParser

from canon_meta import CANON_INFO, DEUT_META

BASE = os.path.dirname(os.path.abspath(__file__))
ALL_CANONS = ["protestant", "catholic", "orthodox"]
EXTRA_CANONS = ["catholic", "orthodox"]
KNOWN_TAGS = {"p", "ul", "ol", "li", "strong", "div", "span", "br", "hr"}


def js_unescape(value):
    return json.loads(f'"{value}"')


def find_matching(text, start, open_ch, close_ch):
    depth = 0
    quote = None
    escape = False
    for i in range(start, len(text)):
        ch = text[i]
        if quote:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == quote:
                quote = None
            continue
        if ch in ('"', "'", "`"):
            quote = ch
        elif ch == open_ch:
            depth += 1
        elif ch == close_ch:
            depth -= 1
            if depth == 0:
                return i
    raise ValueError(f"matching {close_ch} not found")


def extract_array(text, name):
    match = re.search(rf"\b{name}\s*:\s*\[", text)
    if not match:
        raise ValueError(f"{name} array not found")
    start = match.end() - 1
    end = find_matching(text, start, "[", "]")
    return text[start + 1:end]


def split_objects(array_text):
    objects = []
    depth = 0
    start = None
    quote = None
    escape = False
    for i, ch in enumerate(array_text):
        if quote:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == quote:
                quote = None
            continue
        if ch in ('"', "'", "`"):
            quote = ch
        elif ch == "{":
            if depth == 0:
                start = i
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0 and start is not None:
                objects.append(array_text[start:i + 1])
                start = None
    return objects


def extract_string(obj, field, default=""):
    match = re.search(rf"\b{field}\s*:\s*\"((?:\\.|[^\"\\])*)\"", obj, re.S)
    if not match:
        return default
    return js_unescape(match.group(1))


def extract_number(obj, field, default=0):
    match = re.search(rf"\b{field}\s*:\s*([0-9]+(?:\.[0-9]+)?)", obj)
    if not match:
        return default
    value = match.group(1)
    return float(value) if "." in value else int(value)


def extract_string_array(obj, field):
    match = re.search(rf"\b{field}\s*:\s*\[([^\]]*)\]", obj, re.S)
    if not match:
        return None
    return re.findall(r"\"([^\"]+)\"", match.group(1))


def extract_backtick(obj, field):
    match = re.search(rf"\b{field}\s*:\s*`", obj)
    if not match:
        return ""
    start = match.end()
    i = start
    escape = False
    while i < len(obj):
        ch = obj[i]
        if escape:
            escape = False
        elif ch == "\\":
            escape = True
        elif ch == "`":
            return obj[start:i]
        i += 1
    raise ValueError(f"{field} template literal not closed")


def trim_text_and_marks(text, marks):
    leading = len(text) - len(text.lstrip())
    trailing_text = text.rstrip()
    end_limit = len(trailing_text)
    trimmed = text[leading:end_limit]
    adjusted = []
    for mark in marks:
        s = max(0, mark["s"] - leading)
        e = min(len(trimmed), mark["e"] - leading)
        if s < e:
            adjusted.append({"type": mark["type"], "s": s, "e": e})
    return trimmed, adjusted


class BlockHTMLParser(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.blocks = []
        self.unknown_tags = set()
        self.canon_extra = False
        self.canon_extra_label = None
        self.capture_label = False
        self.label_parts = []
        self.current_block = None
        self.current_ul = None
        self.current_item = None
        self.strong_stack = []

    def current_text_target(self):
        if self.current_item is not None:
            return self.current_item
        return self.current_block

    def text_len(self):
        target = self.current_text_target()
        return len(target["text"]) if target else 0

    def append_text(self, data):
        if self.capture_label:
            self.label_parts.append(data)
            return
        target = self.current_text_target()
        if target is not None:
            target["text"] += data

    def decorate_extra(self, block):
        if self.canon_extra:
            block["canon"] = EXTRA_CANONS
            block["canonExtra"] = True
            if self.canon_extra_label:
                block["canonExtraLabel"] = self.canon_extra_label

    def close_text_target(self, target):
        text, marks = trim_text_and_marks(target["text"], target["marks"])
        target["text"] = text
        if marks:
            target["marks"] = marks
        else:
            target.pop("marks", None)

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag not in KNOWN_TAGS:
            self.unknown_tags.add(tag)
            return
        if tag == "div":
            if attrs.get("class") == "canon-extra":
                self.canon_extra = True
                self.canon_extra_label = None
            else:
                self.unknown_tags.add("div")
        elif tag == "span":
            if attrs.get("class") == "ce-label" and self.canon_extra:
                self.capture_label = True
                self.label_parts = []
            else:
                self.unknown_tags.add("span")
        elif tag == "p":
            block_type = "quote" if attrs.get("class") == "quote" else "p"
            if attrs.get("class") not in (None, "quote"):
                self.unknown_tags.add(f"p.{attrs.get('class')}")
            self.current_block = {"type": block_type, "text": "", "marks": []}
        elif tag in ("ul", "ol"):
            self.current_ul = {"type": tag, "items": []}
            self.decorate_extra(self.current_ul)
        elif tag == "li":
            self.current_item = {"text": "", "marks": []}
        elif tag == "strong":
            self.strong_stack.append(self.text_len())
        elif tag == "br":
            self.append_text("\n")
        elif tag == "hr":
            block = {"type": "hr"}
            self.decorate_extra(block)
            self.blocks.append(block)

    def handle_endtag(self, tag):
        if tag == "strong":
            if self.strong_stack:
                start = self.strong_stack.pop()
                target = self.current_text_target()
                if target is not None and start < len(target["text"]):
                    target["marks"].append({"type": "strong", "s": start, "e": len(target["text"])})
        elif tag == "span" and self.capture_label:
            self.canon_extra_label = "".join(self.label_parts).strip()
            self.capture_label = False
            self.label_parts = []
        elif tag == "p" and self.current_block is not None:
            self.close_text_target(self.current_block)
            if self.current_block["text"]:
                self.decorate_extra(self.current_block)
                self.blocks.append(self.current_block)
            self.current_block = None
        elif tag == "li" and self.current_item is not None:
            self.close_text_target(self.current_item)
            if self.current_item["text"] and self.current_ul is not None:
                self.current_ul["items"].append(self.current_item)
            self.current_item = None
        elif tag in ("ul", "ol") and self.current_ul is not None:
            if self.current_ul["items"]:
                self.blocks.append(self.current_ul)
            self.current_ul = None
        elif tag == "div" and self.canon_extra:
            self.canon_extra = False
            self.canon_extra_label = None

    def handle_data(self, data):
        self.append_text(data)


def html_to_blocks(html):
    parser = BlockHTMLParser()
    parser.feed(html)
    parser.close()
    return parser.blocks, parser.unknown_tags


def parse_chapters(book_obj, book_id):
    match = re.search(r"\bchapters\s*:\s*\[", book_obj)
    if not match:
        return [], set()
    start = match.end() - 1
    end = find_matching(book_obj, start, "[", "]")
    chapter_objects = split_objects(book_obj[start + 1:end])
    chapters = []
    unknown_tags = set()
    for chapter_obj in chapter_objects:
        num = extract_number(chapter_obj, "num")
        html = extract_backtick(chapter_obj, "html")
        blocks, tags = html_to_blocks(html)
        unknown_tags.update(tags)
        chapters.append({
            "id": f"{book_id}:{num}",
            "num": num,
            "title": extract_string(chapter_obj, "title"),
            "ref": extract_string(chapter_obj, "ref"),
            "blocks": blocks,
        })
    return chapters, unknown_tags


def parse_books(source):
    books = []
    unknown_tags = set()
    deut_order = {item["id"]: item["order"] for item in DEUT_META}
    for testament in ("old", "new", "deut"):
        for book_obj in split_objects(extract_array(source, testament)):
            book_id = extract_string(book_obj, "id")
            canon = extract_string_array(book_obj, "canon")
            if canon is None:
                canon = ALL_CANONS[:]
            chapters, tags = parse_chapters(book_obj, book_id)
            unknown_tags.update(tags)
            order = extract_number(book_obj, "order")
            books.append({
                "id": book_id,
                "title": extract_string(book_obj, "title"),
                "testament": testament,
                "order": order,
                "sortOrder": deut_order.get(book_id, order),
                "canon": canon,
                "ref": extract_string(book_obj, "ref"),
                "cover": extract_string(book_obj, "cover"),
                "chapters": chapters,
            })
    return books, unknown_tags


def find_sample_canon_extra(data):
    for book in data["books"]:
        if book["id"] != "esther":
            continue
        for chapter in book["chapters"]:
            for block in chapter["blocks"]:
                if block.get("canonExtra"):
                    return {"book": book["id"], "chapter": chapter["num"], "block": block}
    return None


def find_sample_ul(data):
    for book in data["books"]:
        for chapter in book["chapters"]:
            for block in chapter["blocks"]:
                if block["type"] == "ul":
                    return {"book": book["id"], "chapter": chapter["num"], "block": block}
    return None


def main():
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    with open(os.path.join(BASE, "books.js"), "r", encoding="utf-8") as f:
        source = f.read()
    books, unknown_tags = parse_books(source)
    data = {
        "schemaVersion": 1,
        "generatedFrom": "books.js",
        "canonInfo": CANON_INFO,
        "deutMeta": DEUT_META,
        "books": books,
    }
    # 루트 assets(중간 산출물)와 Flutter 앱 assets(실사용) 양쪽에 동시 기록.
    # 앱 경로를 빼먹으면 코드/데이터를 고쳐도 앱엔 반영 안 됨 → 둘 다 쓴다.
    output_paths = [
        os.path.join(BASE, "assets", "books.json"),
        os.path.join(BASE, "bible_reader_app", "assets", "books.json"),
    ]
    for output_path in output_paths:
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        with open(output_path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, separators=(",", ":"))
    chapter_count = sum(len(book["chapters"]) for book in books)
    block_count = sum(len(ch["blocks"]) for book in books for ch in book["chapters"])
    rels = ", ".join(os.path.relpath(p, BASE).replace("\\", "/") for p in output_paths)
    print(f"변환 완료: {rels}")
    print(f"책 {len(books)}권, 편 {chapter_count}개, 블록 {block_count}개")
    print("알 수 없는 태그:", ", ".join(sorted(unknown_tags)) if unknown_tags else "없음")
    print("\n[샘플 canon-extra]")
    print(json.dumps(find_sample_canon_extra(data), ensure_ascii=False, indent=2)[:4000])
    print("\n[샘플 ul]")
    print(json.dumps(find_sample_ul(data), ensure_ascii=False, indent=2)[:4000])


if __name__ == "__main__":
    main()
