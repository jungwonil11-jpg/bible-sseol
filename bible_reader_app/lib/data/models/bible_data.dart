import 'dart:convert';

class BibleData {
  const BibleData({
    required this.schemaVersion,
    required this.generatedFrom,
    required this.canonInfo,
    required this.deutMeta,
    required this.books,
  });

  factory BibleData.fromJson(Map<String, dynamic> json) {
    return BibleData(
      schemaVersion: json['schemaVersion'] as int,
      generatedFrom: json['generatedFrom'] as String,
      canonInfo: (json['canonInfo'] as Map<String, dynamic>).map(
        (key, value) =>
            MapEntry(key, CanonInfo.fromJson(value as Map<String, dynamic>)),
      ),
      deutMeta: (json['deutMeta'] as List<dynamic>)
          .map((value) => DeutMeta.fromJson(value as Map<String, dynamic>))
          .toList(growable: false),
      books: (json['books'] as List<dynamic>)
          .map((value) => BibleBook.fromJson(value as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  factory BibleData.fromJsonString(String source) {
    return BibleData.fromJson(jsonDecode(source) as Map<String, dynamic>);
  }

  final int schemaVersion;
  final String generatedFrom;
  final Map<String, CanonInfo> canonInfo;
  final List<DeutMeta> deutMeta;
  final List<BibleBook> books;
}

class CanonInfo {
  const CanonInfo({
    required this.name,
    required this.denominations,
    required this.oldCount,
    required this.newCount,
    required this.total,
    required this.desc,
    required this.extra,
  });

  factory CanonInfo.fromJson(Map<String, dynamic> json) {
    return CanonInfo(
      name: json['name'] as String,
      denominations: json['denominations'] as String,
      oldCount: json['oldCount'] as int,
      newCount: json['newCount'] as int,
      total: json['total'] as int,
      desc: json['desc'] as String,
      extra: (json['extra'] as List<dynamic>).cast<String>(),
    );
  }

  final String name;
  final String denominations;
  final int oldCount;
  final int newCount;
  final int total;
  final String desc;
  final List<String> extra;
}

class DeutMeta {
  const DeutMeta({
    required this.id,
    required this.title,
    required this.ref,
    required this.order,
    required this.canon,
  });

  factory DeutMeta.fromJson(Map<String, dynamic> json) {
    return DeutMeta(
      id: json['id'] as String,
      title: json['title'] as String,
      ref: json['ref'] as String,
      order: (json['order'] as num).toDouble(),
      canon: (json['canon'] as List<dynamic>).cast<String>(),
    );
  }

  final String id;
  final String title;
  final String ref;
  final double order;
  final List<String> canon;
}

class BibleBook {
  const BibleBook({
    required this.id,
    required this.title,
    required this.testament,
    required this.order,
    required this.sortOrder,
    required this.canon,
    required this.ref,
    required this.chapters,
  });

  factory BibleBook.fromJson(Map<String, dynamic> json) {
    return BibleBook(
      id: json['id'] as String,
      title: json['title'] as String,
      testament: json['testament'] as String,
      order: (json['order'] as num).toDouble(),
      sortOrder: (json['sortOrder'] as num).toDouble(),
      canon: (json['canon'] as List<dynamic>).cast<String>(),
      ref: json['ref'] as String,
      chapters: (json['chapters'] as List<dynamic>)
          .map((value) => BibleChapter.fromJson(value as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final String id;
  final String title;
  final String testament;
  final double order;
  final double sortOrder;
  final List<String> canon;
  final String ref;
  final List<BibleChapter> chapters;
}

class BibleChapter {
  const BibleChapter({
    required this.id,
    required this.num,
    required this.title,
    required this.ref,
    required this.blocks,
  });

  factory BibleChapter.fromJson(Map<String, dynamic> json) {
    return BibleChapter(
      id: json['id'] as String,
      num: json['num'] as int,
      title: json['title'] as String,
      ref: json['ref'] as String,
      blocks: (json['blocks'] as List<dynamic>)
          .map((value) => ContentBlock.fromJson(value as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final String id;
  final int num;
  final String title;
  final String ref;
  final List<ContentBlock> blocks;
}

enum ContentBlockType { p, quote, ul, ol, hr }

class ContentBlock {
  const ContentBlock({
    required this.type,
    this.text,
    this.items = const [],
    this.marks = const [],
    this.canon = const [],
    this.canonExtra = false,
    this.canonExtraLabel,
  });

  factory ContentBlock.fromJson(Map<String, dynamic> json) {
    return ContentBlock(
      type: ContentBlockType.values.byName(json['type'] as String),
      text: json['text'] as String?,
      items: ((json['items'] as List<dynamic>?) ?? const [])
          .map((value) => ListBlockItem.fromJson(value as Map<String, dynamic>))
          .toList(growable: false),
      marks: ((json['marks'] as List<dynamic>?) ?? const [])
          .map((value) => TextMark.fromJson(value as Map<String, dynamic>))
          .toList(growable: false),
      canon: ((json['canon'] as List<dynamic>?) ?? const []).cast<String>(),
      canonExtra: (json['canonExtra'] as bool?) ?? false,
      canonExtraLabel: json['canonExtraLabel'] as String?,
    );
  }

  final ContentBlockType type;
  final String? text;
  final List<ListBlockItem> items;
  final List<TextMark> marks;
  final List<String> canon;
  final bool canonExtra;
  final String? canonExtraLabel;
}

class ListBlockItem {
  const ListBlockItem({required this.text, this.marks = const []});

  factory ListBlockItem.fromJson(Map<String, dynamic> json) {
    return ListBlockItem(
      text: json['text'] as String,
      marks: ((json['marks'] as List<dynamic>?) ?? const [])
          .map((value) => TextMark.fromJson(value as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final String text;
  final List<TextMark> marks;
}

class TextMark {
  const TextMark({required this.type, required this.start, required this.end});

  factory TextMark.fromJson(Map<String, dynamic> json) {
    return TextMark(
      type: json['type'] as String,
      start: json['s'] as int,
      end: json['e'] as int,
    );
  }

  final String type;
  final int start;
  final int end;
}
