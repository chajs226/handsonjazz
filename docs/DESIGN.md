# 🎹 handsOnJazz - 기술 설계서

## 📋 프로젝트 개요

**프로젝트명**: handsOnJazz  
**패키지명**: com.monk.handsonjazz  
**개발 기간**: 2025년 7월 12일 시작  
**플랫폼**: Flutter (iOS/Android)  

## 🎯 MVP 개발 목표

재즈 피아노 학습자를 위한 인터랙티브 연습 앱으로, 실제 프로 연주자의 음원과 동기화된 코드 진행 및 보이싱 시각화를 제공합니다.

## 🏗️ 아키텍처 설계

### 1. 전체 아키텍처

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Presentation  │    │    Business      │    │      Data       │
│     Layer       │◄──►│     Layer        │◄──►│     Layer       │
│   (UI/Widgets)  │    │  (BLoC/Cubit)    │    │ (Repository)    │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
                                               ┌─────────────────┐
                                               │   Data Sources  │
                                               │ • Local JSON    │
                                               │ • Audio Files   │
                                               │ • Firebase      │
                                               └─────────────────┘
```

### 2. 폴더 구조

```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   └── theme/
├── core/
│   ├── constants/
│   ├── utils/
│   └── errors/
├── data/
│   ├── models/
│   ├── repositories/
│   └── datasources/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── pages/
    ├── widgets/
    └── blocs/
```

## 📊 데이터 모델 설계

### 1. Song Model
```dart
class Song {
  final String id;
  final String title;
  final String artist;
  final String audioUrl;
  final Map<String, String> chordProgression;
  final Map<String, VoicingData> voicings;
  final int duration; // seconds
}
```

### 2. VoicingData Model
```dart
class VoicingData {
  final List<int> leftHand;  // MIDI note numbers
  final List<int> rightHand; // MIDI note numbers
  final String chordSymbol;
  final String analysis;     // 보이싱 분석 정보
}
```

### 3. AudioState Model
```dart
class AudioState {
  final bool isPlaying;
  final Duration currentPosition;
  final Duration totalDuration;
  final double playbackSpeed;
  final LoopData? loop;
}
```

## 🎨 UI/UX 설계

### 1. 홈 화면 (HomeScreen)
- **기능**: 곡 목록, 즐겨찾기, 연습 기록
- **위젯**: 
  - `SongListWidget`
  - `FavoriteWidget`
  - `PracticeStatsWidget`

### 2. 연습 화면 (PracticeScreen)
- **상단**: 코드 타임라인 (`ChordTimelineWidget`)
- **중앙**: 피아노 롤 (`PianoRollWidget`)
- **하단**: 오디오 플레이어 (`AudioPlayerWidget`)
- **사이드**: 보이싱 분석 (`VoicingAnalysisWidget`)

### 3. 설정 화면 (SettingsScreen)
- **기능**: 템포 설정, 루프 설정, 키 전조
- **위젯**: 
  - `TempoControlWidget`
  - `LoopControlWidget`

## 🔧 핵심 기술 구현

### 1. 오디오 처리
- **라이브러리**: `just_audio`
- **기능**: 재생, 정지, 속도 조절, 루프
- **구현**: `AudioService` 클래스

### 2. 시간 동기화
- **방식**: JSON 타이밍 데이터와 오디오 위치 매핑
- **구현**: `TimingService` 클래스
- **데이터 구조**:
```json
{
  "timing": {
    "00:00": "Cmaj7",
    "00:03": "Am7",
    "00:06": "Dm7",
    "00:09": "G7"
  }
}
```

### 3. 피아노 롤 시각화
- **위젯**: `PianoRollWidget`
- **기능**: MIDI 노트 시각화, 양손 구분 표시
- **상태 관리**: `PianoRollCubit`

### 4. 상태 관리
- **라이브러리**: `flutter_bloc`
- **패턴**: BLoC/Cubit 패턴
- **주요 BLoC**:
  - `AudioPlayerBloc`
  - `ChordProgressionCubit`
  - `PianoRollCubit`

## 📦 의존성 목록

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # 상태 관리
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  
  # 오디오
  just_audio: ^0.9.35
  audio_session: ^0.1.16
  
  # UI
  flutter_piano: ^0.1.0  # 피아노 키보드 위젯
  
  # 유틸리티
  get_it: ^7.6.4
  json_annotation: ^4.8.1
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  json_serializable: ^6.7.1
  build_runner: ^2.4.7
```

## 🗂️ 샘플 데이터 구조

### There Will Never Be Another You - 데이터 예시

```json
{
  "id": "there_will_never_be_another_you",
  "title": "There Will Never Be Another You",
  "artist": "Sample Artist",
  "audioUrl": "assets/audio/there_will_never_be_another_you.mp3",
  "duration": 180,
  "chordProgression": {
    "00:00": "EbMaj7",
    "00:04": "Dm7b5",
    "00:06": "G7",
    "00:08": "Cm7",
    "00:12": "F7",
    "00:16": "BbMaj7"
  },
  "voicings": {
    "00:00": {
      "leftHand": [39, 46],
      "rightHand": [58, 62, 65, 69],
      "chordSymbol": "EbMaj7",
      "analysis": "Root position, 3rd-7th-9th-5th voicing"
    }
  }
}
```

## 🚀 개발 단계별 계획

### Phase 1: 기본 구조 (1주차) ✅ 완료
- [x] Flutter 프로젝트 생성
- [x] 기본 아키텍처 설정
- [x] 데이터 모델 구현
- [x] 샘플 JSON 데이터 준비
- [x] 폴더 구조 및 DI 설정

### Phase 2: 오디오 기능 (2주차) ✅ 완료
- [x] 오디오 플레이어 구현
- [x] 속도 조절 기능
- [x] 루프 기능
- [x] 시간 동기화 로직

### Phase 3: UI 구현 (3주차) ✅ 완료
- [x] 홈 화면 구현
- [x] 연습 화면 레이아웃
- [x] 코드 타임라인 위젯
- [x] 피아노 롤 위젯
- [x] 오디오 플레이어 위젯
- [x] 보이싱 분석 위젯

### Phase 4: 통합 및 테스트 (4주차) 🔄 진행중
- [x] 전체 기능 통합
- [x] BLoC 상태 관리 구현
- [ ] 성능 최적화
- [ ] 실제 오디오 파일 테스트
- [ ] 사용자 테스트
- [ ] 버그 수정

## ✅ 완성된 주요 구현사항

### 1. 아키텍처
- Clean Architecture 패턴 적용
- BLoC/Cubit을 이용한 상태 관리
- Dependency Injection (GetIt) 구현
- Repository 패턴으로 데이터 추상화

### 2. 핵심 기능
- **AudioService**: just_audio를 이용한 오디오 재생, 속도 조절, 루프 기능
- **TimingService**: 음원과 코드 진행의 시간 동기화
- **PianoRoll**: 88건반 피아노 시각화 및 보이싱 표시
- **ChordTimeline**: 대화형 타임라인과 코드 진행 표시

### 3. UI/UX
- 다크 테마 기반의 현대적인 디자인
- 반응형 레이아웃 (데스크톱/모바일 대응)
- 직관적인 컨트롤 인터페이스
- 실시간 시각적 피드백

### 4. 데이터 구조
- JSON 기반 곡 정보 관리
- MIDI 노트 번호를 이용한 보이싱 데이터
- 시간 기반 코드 진행 매핑

## 🔧 추가 구현된 기술적 특징

### 1. 커스텀 페인터
- **PianoRollPainter**: 피아노 건반과 활성 노트 시각화
- **ChordTimelinePainter**: 코드 진행과 재생 위치 표시

### 2. 스트림 기반 상태 관리
- 오디오 상태 실시간 업데이트
- 코드 변경 자동 감지
- 보이싱 데이터 동기화

### 3. 반응형 디자인
- 화면 크기에 따른 레이아웃 변경
- 태블릿/데스크톱에서 사이드 패널 표시
- 모바일에서 수직 스택 레이아웃

## 📱 앱 화면 구성

### 홈 화면
- 환영 메시지 및 통계 정보
- 재즈 스탠다드 곡 목록
- 각 곡의 기본 정보 (아티스트, 길이, 보이싱 수)

### 연습 화면
- **상단**: 코드 타임라인 (클릭 가능한 시간 탐색)
- **중앙**: 피아노 롤 (양손 보이싱 구분 표시)
- **하단**: 오디오 컨트롤 (재생/정지, 속도 조절, 루프)
- **사이드**: 보이싱 분석 (토글 가능)

## 🎨 디자인 시스템

### 색상 팔레트
- Primary: `#1E1E2E` (다크 블루)
- Secondary: `#89B4FA` (라이트 블루)
- Accent: `#F9E2AF` (옐로우)
- Background: `#181825` (다크 그레이)
- Surface: `#313244` (미디엄 그레이)

### 양손 구분 색상
- Left Hand: `#94E2D5` (민트)
- Right Hand: `#F9E2AF` (옐로우)

---

**업데이트 일자**: 2025년 7월 12일  
**현재 상태**: MVP 기능 구현 완료, 테스트 단계  
**다음 단계**: 실제 오디오 파일 테스트 및 성능 최적화
