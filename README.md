# 🎹 handsOnJazz

재즈 피아노 학습자를 위한 인터랙티브 연습 앱

## 📱 앱 소개

handsOnJazz는 재즈 피아노 학습자들이 프로 연주자의 보이싱과 코드 진행을 시각적으로 학습할 수 있도록 도와주는 Flutter 기반 모바일 앱입니다.

### 🎯 주요 특징

- **실시간 보이싱 시각화**: 88건반 피아노 롤에서 양손 보이싱을 실시간으로 표시
- **대화형 코드 타임라인**: 곡의 코드 진행을 시간축으로 표시하고 클릭으로 탐색 가능
- **스마트 오디오 플레이어**: 속도 조절(50%, 75%, 100%), 구간 반복, 동기화된 재생
- **보이싱 분석**: 각 코드의 구성음과 보이싱 해석 정보 제공
- **반응형 디자인**: 모바일과 태블릿에 최적화된 레이아웃

## 🚀 시작하기

### 필요 조건

- Flutter SDK 3.8.1 이상
- Dart 3.0 이상
- iOS 12.0+ / Android API 21+

### 설치 및 실행

1. 프로젝트 클론
```bash
git clone https://github.com/your-username/handsOnJazz.git
cd handsOnJazz/handsonjazz
```

2. 의존성 설치
```bash
flutter pub get
```

3. 코드 생성 (JSON 시리얼라이제이션)
```bash
flutter packages pub run build_runner build
```

4. 앱 실행
```bash
flutter run
```

## 🏗️ 아키텍처

### Clean Architecture + BLoC 패턴

```
📁 lib/
├── 📁 app/                    # 앱 설정 및 테마
├── 📁 core/                   # 핵심 유틸리티
│   ├── 📁 di/                 # Dependency Injection
│   ├── 📁 services/           # 도메인 서비스
│   └── 📁 utils/              # 유틸리티 함수
├── 📁 data/                   # 데이터 계층
│   ├── 📁 models/             # 데이터 모델
│   ├── 📁 repositories/       # Repository 구현
│   └── 📁 datasources/        # 데이터 소스
├── 📁 domain/                 # 도메인 계층
│   ├── 📁 entities/           # 엔티티
│   ├── 📁 repositories/       # Repository 인터페이스
│   └── 📁 usecases/           # 유스케이스
└── 📁 presentation/           # 프레젠테이션 계층
    ├── 📁 pages/              # 화면
    ├── 📁 widgets/            # 재사용 위젯
    └── 📁 blocs/              # BLoC/Cubit
```

## 🎵 데이터 구조

### 곡 정보 (JSON)
```json
{
  "id": "song_id",
  "title": "Song Title",
  "artist": "Artist Name",
  "audioUrl": "assets/audio/song.mp3",
  "duration": 180,
  "chordProgression": {
    "0": "Cmaj7",
    "4": "Am7",
    "8": "Dm7",
    "12": "G7"
  },
  "voicings": {
    "0": {
      "leftHand": [36, 43],
      "rightHand": [60, 64, 67, 71],
      "chordSymbol": "Cmaj7",
      "analysis": "Root position, 3rd-7th-9th-5th voicing"
    }
  }
}
```

## 🎨 UI 컴포넌트

### 핵심 위젯

- **PianoRollWidget**: 88건반 피아노 시각화 및 보이싱 표시
- **ChordTimelineWidget**: 대화형 코드 진행 타임라인
- **AudioPlayerWidget**: 오디오 재생 컨트롤러
- **VoicingAnalysisWidget**: 보이싱 분석 정보 패널

### 색상 시스템

- **Primary**: #1E1E2E (다크 블루)
- **Secondary**: #89B4FA (라이트 블루)  
- **Accent**: #F9E2AF (옐로우)
- **Left Hand**: #94E2D5 (민트)
- **Right Hand**: #F9E2AF (옐로우)

## 📦 주요 의존성

```yaml
dependencies:
  flutter_bloc: ^8.1.3        # 상태 관리
  just_audio: ^0.9.35         # 오디오 재생
  equatable: ^2.0.5           # 값 객체 비교
  get_it: ^7.6.4              # 의존성 주입
  json_annotation: ^4.8.1     # JSON 시리얼라이제이션
```

## 🔧 개발 도구

```yaml
dev_dependencies:
  json_serializable: ^6.7.1   # JSON 코드 생성
  build_runner: ^2.4.7        # 코드 생성 러너
  flutter_lints: ^5.0.0       # 린팅 규칙
```

## 📊 현재 구현 상태

### ✅ 완료된 기능
- [x] 기본 프로젝트 구조 및 아키텍처
- [x] 오디오 재생 및 컨트롤 (속도, 루프)
- [x] 피아노 롤 시각화
- [x] 코드 타임라인 및 동기화
- [x] 보이싱 분석 패널
- [x] 홈 화면 및 곡 목록
- [x] 반응형 레이아웃

### 🔄 진행 중
- [ ] 실제 오디오 파일 통합
- [ ] 성능 최적화
- [ ] 추가 곡 데이터

### 📋 향후 계획
- [ ] 멜로디 라인 시각화
- [ ] 사용자 연습 기록
- [ ] 소셜 기능 (연주 공유)
- [ ] 오프라인 모드

## 🤝 기여하기

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 라이센스

이 프로젝트는 MIT 라이센스 하에 배포됩니다. 자세한 내용은 `LICENSE` 파일을 참조하세요.

## 📞 문의

프로젝트 관련 문의사항이나 버그 리포트는 [GitHub Issues](https://github.com/your-username/handsOnJazz/issues)를 통해 제보해주세요.

---

**Made with ❤️ for Jazz Piano learners**
