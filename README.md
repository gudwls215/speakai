# SpeakAI

**SpeakAI**는 커뮤니티 기반 영어 프리토킹 프리톡 공유 및 AI 대화 기능을 제공하는 Flutter 앱입니다.

## 주요 기능

- **프리토킹 프리톡 목록**  
  - 트렌딩, 신규, 탑 차트 등 다양한 카테고리별 프리톡 조회
  - 각 프리톡별 상세 정보 및 대화 시작

- **AI와의 대화**  
  - 선택한 프리톡에 맞춰 AI와 실시간 채팅
  - 음성 인식 및 TTS(텍스트 음성 변환) 지원

- **프리톡 생성 및 수정**  
  - 사용자가 직접 프리톡를 작성, 수정, 저장 가능

- **관심 등록(즐겨찾기)**  
  - 프리톡를 관심 등록/해제하여 즐겨찾기 목록 관리

- **관심 등록 목록**  
  - 관심 등록한 프리톡만 모아보기

## 주요 기술 스택

- **Flutter** (Dart)
- **Dio**: REST API 통신
- **SharedPreferences**: 로컬 저장소
- **Provider**: 상태 관리
- **PostgreSQL**: 백엔드 DB (관심 등록 등)
- **Speech to Text / TTS**: 음성 인식 및 합성

## 폴더 구조

```
lib/
 ├── tabs/
 │    └── free_talk_tab.dart      # 메인 프리토킹 탭 및 프리톡 목록
 ├── widgets/
 │    └── page/
 │         └── free_talk_page.dart # AI와의 대화 화면
 ├── config.dart                  # 환경설정 및 API base URL 등
```

## DB 설계 예시

관심 등록 테이블:
```sql
CREATE TABLE development.tutor_user_favorite_talk (
    id SERIAL PRIMARY KEY,
    member_id INTEGER NOT NULL REFERENCES members(id) ON DELETE CASCADE,
    talk_id INTEGER NOT NULL REFERENCES tutor_free_talk(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE (member_id, talk_id)
);
```

## 실행 방법

1. Flutter 환경을 준비합니다.
2. `config.dart`에 API 서버 주소 등 환경설정을 맞춥니다.
3. `flutter pub get`으로 의존성 설치 후 실행합니다.

## 기타

- 코드 및 기능 개선 제안은 언제든 환영합니다!