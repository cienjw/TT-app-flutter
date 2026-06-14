// lib/features/auth/data/survey_data.dart

enum InterestField { tech, content, art, social, sport, making }
enum CollabStyle { lead, follow }
enum MeetPurpose { growth, vibe }

extension InterestFieldLabel on InterestField {
  String get label => switch (this) {
    InterestField.tech    => '테크',
    InterestField.content => '콘텐츠·인문',
    InterestField.art     => '디자인·예술',
    InterestField.social  => '소셜·문화',
    InterestField.sport   => '운동·액티비티',
    InterestField.making  => '메이킹·창작',
  };
}

/// 선택지 하나가 부여하는 값들 (해당 없는 건 비움)
class SurveyOption {
  final String label;
  final String emoji;
  final InterestField? field;
  final int depth;
  final int virtuality;
  final CollabStyle? collab;
  final MeetPurpose? purpose;
  const SurveyOption(this.label,
      {this.emoji = '', this.field, this.depth = 0, this.virtuality = 0,
        this.collab, this.purpose});
}

class SurveyQuestion {
  final String question;
  final List<SurveyOption> options;
  const SurveyQuestion(this.question, this.options);
}

const surveyQuestions = <SurveyQuestion>[
  SurveyQuestion('완벽한 반나절의 자유 시간, 나의 선택은?', [
    SurveyOption('다큐·영화 시리즈 몰아보기', emoji: '🎬', field: InterestField.content),
    SurveyOption('레고·코딩·공예 등 나만의 무언가 만들기', emoji: '🧱', field: InterestField.making),
    SurveyOption('예쁜 카페·전시회 핫플 탐방', emoji: '☕', field: InterestField.social),
    SurveyOption('헬스장·야외 액티비티로 땀 흘리기', emoji: '🏋️', field: InterestField.sport),
  ]),
  SurveyQuestion('음악을 즐기는 나만의 방식은?', [
    SurveyOption('세계관·숨은 트랙까지 파고드는 디깅', emoji: '💿', depth: 1),
    SurveyOption('분위기를 띄워주는 가벼운 배경음악', emoji: '🎧', depth: 0),
  ]),
  SurveyQuestion('조금 더 흥미를 느끼는 세계는?', [
    SurveyOption('VR·3D·새 기술이 만드는 미지의 영역', emoji: '🥽', virtuality: 1),
    SurveyOption('재테크·운동·인테리어 등 현실을 가꾸는 영역', emoji: '🪴', virtuality: 0),
  ]),
  SurveyQuestion('결이 맞는 사람들과 모이고 싶은 아지트는?', [
    SurveyOption('언제든 접속하는 디스코드·가상 공간', emoji: '💬', virtuality: 1),
    SurveyOption('얼굴 보고 커피 한잔하는 오프라인 공간', emoji: '🤝', virtuality: 0),
  ]),
  SurveyQuestion('에너지를 발산하는 취미를 고른다면?', [
    SurveyOption('러닝·클라이밍·웨이트 등 몸 쓰는 활동', emoji: '👟', field: InterestField.sport),
    SurveyOption('새 언어·시스템 원리를 파는 지적 활동', emoji: '💻', field: InterestField.tech),
  ]),
  SurveyQuestion('자유 주제 영상 과제, 다루고 싶은 건?', [
    SurveyOption('기술과 인간을 깊게 파는 다큐·철학', emoji: '🎥', depth: 1),
    SurveyOption('요즘 밈·숏폼·캠퍼스 브이로그', emoji: '😂', depth: 0),
  ]),
  SurveyQuestion('마음 맞는 사람들과 함께할 때 나는?', [
    SurveyOption('앞에서 판을 까는 리더형', emoji: '🚩', collab: CollabStyle.lead),
    SurveyOption('분위기에 맞춰가는 서포터형', emoji: '🙌', collab: CollabStyle.follow),
  ]),
  SurveyQuestion('무언가에 꽂혔을 때 나의 스타일은?', [
    SurveyOption('얕고 넓게! 여러 트렌드 맛보기', emoji: '🔍', depth: 0),
    SurveyOption('하나를 파면 끝장! 원리까지', emoji: '🎯', depth: 1),
  ]),
  SurveyQuestion('지금 내 알고리즘을 지배하는 키워드는?', [
    SurveyOption('IT 트렌드·개발·테크 기기', emoji: '💻', field: InterestField.tech),
    SurveyOption('영화·스토리텔링·인문·사회', emoji: '📖', field: InterestField.content),
    SurveyOption('디자인·아트워크·시각예술·건축', emoji: '🎨', field: InterestField.art),
    SurveyOption('일상 브이로그·밈·예능·여행', emoji: '📸', field: InterestField.social),
  ]),
  SurveyQuestion('이 앱에서 가장 만나고 싶은 사람은?', [
    SurveyOption('목표에 자극과 동기를 주는 사람', emoji: '📈', purpose: MeetPurpose.growth),
    SurveyOption('취향으로 밤새 떠들 영혼의 단짝', emoji: '💞', purpose: MeetPurpose.vibe),
  ]),
];

/// 채점 결과
class SurveyResult {
  final Set<InterestField> fields;
  final double depth;       // 0~1
  final double virtuality;  // 0~1
  final CollabStyle collab;
  final MeetPurpose purpose;
  final String? mbti;
  const SurveyResult({
    required this.fields, required this.depth, required this.virtuality,
    required this.collab, required this.purpose, this.mbti,
  });
}

/// answers는 문항 순서대로 고른 선택지 리스트 (length 10)
SurveyResult scoreSurvey(List<SurveyOption> answers, {String? mbti}) {
  final fields = <InterestField>{};
  for (final o in answers) {
    if (o.field != null) fields.add(o.field!);
  }
  // 깊이 측정: Q2·Q6·Q8 (index 1,5,7) / 가상성: Q3·Q4 (index 2,3)
  final depth = (answers[1].depth + answers[5].depth + answers[7].depth) / 3.0;
  final virt  = (answers[2].virtuality + answers[3].virtuality) / 2.0;
  return SurveyResult(
    fields: fields,
    depth: depth,
    virtuality: virt,
    collab: answers[6].collab!,
    purpose: answers[9].purpose!,
    mbti: mbti,
  );
}

/// 결과 화면용 유형 이름 자동 생성
String surveyTypeName(SurveyResult r) {
  final d = r.depth >= 0.6 ? '깊이 파고드는'
      : r.depth <= 0.34 ? '폭넓게 즐기는' : '균형 잡힌';
  final v = r.virtuality >= 0.6 ? '디지털' : r.virtuality <= 0.4 ? '아날로그' : '';
  final field = r.fields.isNotEmpty ? r.fields.first.label : '취향';
  return [d, v, '$field 탐험가'].where((e) => e.isNotEmpty).join(' ');
}