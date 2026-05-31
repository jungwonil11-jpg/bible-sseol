DEUT_META = [
    {"id": "manasseh", "title": "므낫세의 기도", "ref": "정교회", "order": 14.5, "canon": ["orthodox"]},
    {"id": "esdras1", "title": "에스드라스 1서", "ref": "정교회", "order": 14.8, "canon": ["orthodox"]},
    {"id": "tobit", "title": "토비트", "ref": "천주교 · 정교회", "order": 16.1, "canon": ["catholic", "orthodox"]},
    {"id": "judith", "title": "유딧", "ref": "천주교 · 정교회", "order": 16.5, "canon": ["catholic", "orthodox"]},
    {"id": "maccabees1", "title": "마카베오상", "ref": "천주교 · 정교회", "order": 17.1, "canon": ["catholic", "orthodox"]},
    {"id": "maccabees2", "title": "마카베오하", "ref": "천주교 · 정교회", "order": 17.2, "canon": ["catholic", "orthodox"]},
    {"id": "maccabees3", "title": "마카베오 3서", "ref": "정교회", "order": 17.3, "canon": ["orthodox"]},
    {"id": "psalm151", "title": "시편 151편", "ref": "정교회", "order": 19.5, "canon": ["orthodox"]},
    {"id": "wisdom", "title": "지혜서", "ref": "천주교 · 정교회", "order": 22.1, "canon": ["catholic", "orthodox"]},
    {"id": "sirach", "title": "집회서", "ref": "천주교 · 정교회", "order": 22.2, "canon": ["catholic", "orthodox"]},
    {"id": "baruch", "title": "바룩", "ref": "천주교 · 정교회", "order": 25.1, "canon": ["catholic", "orthodox"]},
]

CANON_INFO = {
    "protestant": {
        "name": "개신교",
        "denominations": "장로교 · 감리교 · 침례교 · 루터교",
        "oldCount": 39,
        "newCount": 27,
        "total": 66,
        "desc": "히브리 성경(유대교 정경)과 같은 범위의 구약. 종교개혁(1517년) 이후 개신교 표준으로 자리잡음.",
        "extra": [],
    },
    "catholic": {
        "name": "천주교",
        "denominations": "로마 가톨릭",
        "oldCount": 46,
        "newCount": 27,
        "total": 73,
        "desc": "구약을 더 넓게 잡아, 초대교회가 그리스어 성경으로 함께 읽어온 책들까지 정경에 포함. 트리엔트 공의회(1546년)가 이 오랜 전통을 교의로 확정.",
        "extra": ["토비트", "유딧", "지혜서", "집회서", "바룩", "마카베오상", "마카베오하"],
    },
    "orthodox": {
        "name": "정교회",
        "denominations": "그리스 · 러시아 · 세르비아 정교회",
        "oldCount": 49,
        "newCount": 27,
        "total": 76,
        "desc": "그리스어 성경(칠십인역) 전통을 가장 폭넓게 이어받은 구약. 대체로 천주교보다 넓지만, 단일하게 확정된 목록은 없어 전통마다 범위가 조금씩 다름.",
        "extra": ["에스드라스 1서", "마카베오 3서", "므낫세의 기도", "시편 151편"],
    },
}

CANON_META_JS = '''  // 제2경전 메타데이터 — books.js와 독립적으로 관리
  // books.js BIBLE.deut에 실제 본문이 있으면 우선 사용, 없으면 coming_soon 플레이스홀더로 표시
  // order = 구약 정경 순서 기준 소수점 sortKey (B안: 제2경전을 구약 시퀀스에 끼움).
  // 에스더/다니엘 그리스어 추가본은 본편(17·27)에 흡수됨 → 여기 없음.
  var DEUT_META = [
    { id: "manasseh",    title: "므낫세의 기도", ref: "정교회",                 order: 14.5, canon: ["orthodox"] },
    { id: "esdras1",     title: "에스드라스 1서", ref: "정교회",                 order: 14.8, canon: ["orthodox"] },
    { id: "tobit",       title: "토비트",       ref: "천주교 · 정교회",         order: 16.1, canon: ["catholic", "orthodox"] },
    { id: "judith",      title: "유딧",         ref: "천주교 · 정교회",         order: 16.5, canon: ["catholic", "orthodox"] },
    { id: "maccabees1",  title: "마카베오상",   ref: "천주교 · 정교회",         order: 17.1, canon: ["catholic", "orthodox"] },
    { id: "maccabees2",  title: "마카베오하",   ref: "천주교 · 정교회",         order: 17.2, canon: ["catholic", "orthodox"] },
    { id: "maccabees3",  title: "마카베오 3서",  ref: "정교회",                 order: 17.3, canon: ["orthodox"] },
    { id: "psalm151",    title: "시편 151편",   ref: "정교회",                 order: 19.5, canon: ["orthodox"] },
    { id: "wisdom",      title: "지혜서",       ref: "천주교 · 정교회",         order: 22.1, canon: ["catholic", "orthodox"] },
    { id: "sirach",      title: "집회서",       ref: "천주교 · 정교회",         order: 22.2, canon: ["catholic", "orthodox"] },
    { id: "baruch",      title: "바룩",         ref: "천주교 · 정교회",         order: 25.1, canon: ["catholic", "orthodox"] }
  ];

  var CANON_INFO = {
    protestant: {
      name: '개신교', denominations: '장로교 · 감리교 · 침례교 · 루터교',
      oldCount: 39, newCount: 27, total: 66,
      desc: '히브리 성경(유대교 정경)과 같은 범위의 구약. 종교개혁(1517년) 이후 개신교 표준으로 자리잡음.',
      extra: []
    },
    catholic: {
      name: '천주교', denominations: '로마 가톨릭',
      oldCount: 46, newCount: 27, total: 73,
      desc: '구약을 더 넓게 잡아, 초대교회가 그리스어 성경으로 함께 읽어온 책들까지 정경에 포함. 트리엔트 공의회(1546년)가 이 오랜 전통을 교의로 확정.',
      extra: ['토비트', '유딧', '지혜서', '집회서', '바룩', '마카베오상', '마카베오하']
    },
    orthodox: {
      name: '정교회', denominations: '그리스 · 러시아 · 세르비아 정교회',
      oldCount: 49, newCount: 27, total: 76,
      desc: '그리스어 성경(칠십인역) 전통을 가장 폭넓게 이어받은 구약. 대체로 천주교보다 넓지만, 단일하게 확정된 목록은 없어 전통마다 범위가 조금씩 다름.',
      extra: ['에스드라스 1서', '마카베오 3서', '므낫세의 기도', '시편 151편']
    }
  };'''
