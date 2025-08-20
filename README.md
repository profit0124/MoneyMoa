# MoneyMoa 💰

> **개인 가계부 관리 iOS 앱** - SwiftUI, SwiftData, Clean Architecture 학습 프로젝트

MoneyMoa는 개인 학습 목적으로 개발한 가계부 관리 iOS 앱입니다. 현대적인 iOS 개발 기술과 아키텍처 패턴을 학습하고 실제 필요에 의해 만들어진 실용적인 개인 프로젝트입니다.

## 📱 주요 기능

### ✅ 완료된 기능
- [x] **메인 화면 (MainView)**
  - [x] 월별 거래 내역 목록 조회
  - [x] 캘린더 기반 날짜별 거래 표시
  - [x] 월별 지출/수입 요약 정보
  - [x] 전월 대비 지출 증감률 표시
  - [x] 예산 대비 지출 현황
  - [x] 월 단위 네비게이션

- [x] **거래 등록 (AddTransaction)**
  - [x] 3단계 위자드 형태의 거래 등록 플로우
  - [x] 금액, 장소, 결제수단 입력
  - [x] 거래 유형 및 카테고리 선택
  - [x] 날짜, 메모, 즐겨찾기 설정
  - [x] 실시간 유효성 검증
  - [x] 단계별 진행률 표시

- [x] **거래 상세 조회 (TransactionDetail)**
  - [x] 거래 내역 상세 정보 표시
  - [x] 삭제 기능 및 확인 다이얼로그
  - [x] 수정 모드 전환
  - [x] 이벤트 기반 실시간 데이터 동기화

- [x] **거래 수정 (UpdateTransaction)**
  - [x] 기존 거래 데이터로 폼 초기화
  - [x] TransactionForm 컴포넌트 재사용
  - [x] 수정 완료 후 자동 새로고침
  - [x] 취소 및 저장 플로우

- [x] **데이터 관리**
  - [x] SwiftData 기반 로컬 데이터베이스
  - [x] 거래, 카테고리, 결제수단, 예산 관리
  - [x] Mock 데이터를 통한 테스트 지원

### 🚧 진행 예정인 기능
- [ ] **차트 및 통계 (Chart)**
- [ ] **설정 관리 (Settings)**
- [ ] **에러 처리 (ErrorHandling)**

## 🏗 아키텍처

### Clean Architecture + MVVM 패턴
프로젝트는 **Clean Architecture** 원칙을 따라 계층별로 명확히 분리되어 있습니다:

```
┌─────────────────────────────────────────┐
│              Presentation               │
│  ┌─────────────┐ ┌─────────────────────┐│
│  │    View     │ │     ViewModel       ││
│  │  (SwiftUI)  │ │   (@Observable)     ││
│  └─────────────┘ └─────────────────────┘│
└─────────────────────────────────────────┘
               │
┌─────────────────────────────────────────┐
│               Domain                    │
│  ┌─────────────┐ ┌─────────────────────┐│
│  │   UseCase   │ │        DTO          ││
│  │ (Business)  │ │   (Data Model)      ││
│  └─────────────┘ └─────────────────────┘│
└─────────────────────────────────────────┘
               │
┌─────────────────────────────────────────┐
│                Data                     │
│  ┌─────────────┐ ┌─────────────────────┐│
│  │ Repository  │ │    SwiftData        ││
│  │    (Impl)   │ │     (Model)         ││
│  └─────────────┘ └─────────────────────┘│
└─────────────────────────────────────────┘
```

### 핵심 아키텍처 특징

#### 1. 의존성 주입 (Dependency Injection)
```swift
// Protocol 기반 DI Container
protocol DIContainer {
    func makeMainViewModel() -> MainViewModel
    func makeAddTransactionViewModel() -> AddTransactionViewModel
    func makeTransactionDetailViewModel(transaction: TransactionDTO) -> TransactionDetailViewModel
    func makeUpdateTransactionViewModel(transaction: TransactionDTO) -> UpdateTransactionViewModel
    func makeUpdateTransactionUseCase() -> UpdateTransactionUseCase
    func makeGetTransactionByIdUseCase() -> GetTransactionByIdUseCase
    // ...
}

// 실제 구현과 Mock 구현 분리
class AppDIContainer: DIContainer { /* 실제 구현 */ }
class MockDIContainer: DIContainer { /* 테스트용 */ }
```

#### 2. UseCase 패턴
```swift
// 비즈니스 로직을 UseCase로 캡슐화
protocol CreateTransactionUseCase {
    func execute(_ transaction: TransactionDTO) async throws
}

protocol UpdateTransactionUseCase {
    func execute(_ transaction: TransactionDTO) async throws
}

protocol GetTransactionByIdUseCase {
    func execute(id: UUID) async throws -> TransactionDTO?
}

class CreateTransactionUseCaseImpl: CreateTransactionUseCase {
    private let transactionRepository: TransactionRepository
    
    func execute(_ transaction: TransactionDTO) async throws {
        // 비즈니스 로직 및 검증
        guard transaction.amount > 0 else {
            throw TransactionCreationError.invalidAmount
        }
        try await transactionRepository.insertTransaction(transaction)
    }
}
```

#### 3. Repository 패턴
```swift
// 데이터 접근 추상화
protocol TransactionRepository {
    func insertTransaction(_ transaction: TransactionDTO) async throws
    func updateTransaction(_ transaction: TransactionDTO) async throws
    func fetchTransaction(id: UUID) async throws -> TransactionDTO?
    func fetchMonthlyTransactions(yearMonth: YearMonth) async throws -> [TransactionDTO]
    func deleteTransaction(id: UUID) async throws
}

// SwiftData 구현
class TransactionRepositoryImpl: TransactionRepository {
    private let database: Database
    // SwiftData 모델과 DTO 변환 로직
}
```

#### 4. 이벤트 기반 아키텍처
```swift
// Combine Publisher를 활용한 이벤트 시스템
protocol TransactionEventPublisher {
    var transactionEvents: AnyPublisher<TransactionEvent, Never> { get }
    func publish(_ event: TransactionEvent)
}

// 거래 변경 시 자동으로 MainView 업데이트
```

## 🛠 기술 스택

### Core Technologies
- **SwiftUI** - 선언적 UI 프레임워크
- **SwiftData** - Core Data의 현대적 대안
- **Combine** - 반응형 프로그래밍 및 이벤트 처리
- **Concurrency** - 비동기 프로그래밍
- **@Observable** - iOS 17+ 새로운 상태 관리 패턴

### Architecture & Patterns
- **Clean Architecture** - 계층별 책임 분리
- **MVVM** - 뷰와 비즈니스 로직 분리
- **UseCase Pattern** - 비즈니스 로직 캡슐화
- **Repository Pattern** - 데이터 접근 추상화
- **Dependency Injection** - 의존성 관리

### Development Tools
- **Xcode 16.1** - 주 개발 환경
- **SwiftLint** - 코드 품질 관리
- **XCTest** - 단위 테스트 프레임워크

## 🧪 테스트 전략

### 포괄적인 테스트 커버리지
**총 35개의 테스트 파일, 2,500+ 줄의 테스트 코드**

#### 1. 단위 테스트 (Unit Tests)
```swift
// ViewModel 테스트
@MainActor
final class AddTransactionViewModelTests: XCTestCase {
    // Given-When-Then 패턴
    // Mock 객체를 통한 격리된 테스트
}

// UseCase 테스트
final class CreateTransactionUseCaseTests: XCTestCase {
    // 비즈니스 로직 검증
    // Mock Repository 활용
}

final class UpdateTransactionUseCaseTests: XCTestCase {
    // 거래 수정 로직 테스트
    // 금액 유효성 검증 및 에러 케이스
}

final class GetTransactionByIdUseCaseTests: XCTestCase {
    // ID로 거래 조회 테스트
    // 존재하지 않는 거래 처리
}
```

#### 2. Repository 테스트
```swift
// SwiftData 통합 테스트
final class TransactionRepositoryTests: XCTestCase {
    // 인메모리 데이터베이스
    // 실제 데이터 CRUD 테스트
}
```

#### 3. Mock 패턴
```swift
// #if DEBUG 블록 활용
#if DEBUG
final class MockCreateTransactionUseCase: CreateTransactionUseCase {
    var shouldFail = false
    var createdTransactions: [TransactionDTO] = []
    // Mock 구현
}
#endif
```

#### 4. 테스트 데이터 관리
```swift
// Mock Sample 데이터 패턴
extension TransactionDTO {
    #if DEBUG
    static let mockLunch = TransactionDTO(
        amount: 15000,
        place: "맥도날드",
        // ...
    )
    #endif
}
```

## 🚀 CI/CD

### GitHub Actions 기반 자동화
```yaml
name: iOS CI
on: [push, pull_request]

jobs:
  build-and-test:
    runs-on: macos-14
    steps:
      - name: SwiftLint 검사
      - name: 단위 테스트 실행
      - name: 코드 커버리지 생성
      - name: 테스트 결과 업로드
```

### 특징
- **SwiftLint** 코드 품질 검사
- **XCTest** 자동 테스트 실행
- **Code Coverage** 측정 및 리포트
- **시뮬레이터 호환성** 자동 처리
- **아티팩트 업로드** 테스트 결과 보관

## 📁 프로젝트 구조

```
MoneyMoa/
├── App/                          # 앱 진입점
│   ├── MoneyMoaApp.swift
│   └── DI/                       # 의존성 주입 설정
├── Core/                         # 공통 유틸리티
│   ├── DesignSystem/            # UI 컴포넌트
│   ├── Extensions/              # Swift 확장
│   ├── Services/                # 공통 서비스
│   └── FormatterManager.swift   # 포맷터 관리
├── Data/                         # 데이터 계층
│   ├── SwiftDataModel/          # SwiftData 모델
│   └── Repository/              # Repository 구현
├── Domain/                       # 도메인 계층
│   ├── DTOs/                    # 데이터 전송 객체
│   ├── Repository/              # Repository 인터페이스
│   ├── UseCases/                # 비즈니스 로직
│   │   ├── Transaction/         # 거래 관련 UseCase
│   │   │   ├── CreateTransactionUseCase/
│   │   │   ├── UpdateTransactionUseCase/
│   │   │   ├── GetTransactionByIdUseCase/
│   │   │   └── DeleteTransactionUseCase/
│   │   ├── Category/           # 카테고리 관련 UseCase
│   │   └── Budget/             # 예산 관련 UseCase
│   └── DI/                      # DI Container
└── Presentation/                 # 프레젠테이션 계층
    ├── Main/                    # 메인 화면
    ├── Transaction/             # 거래 관련
    │   ├── Views/              # TransactionDetailView, UpdateTransactionView
    │   └── ViewModels/         # TransactionDetailViewModel, UpdateTransactionViewModel
    ├── TransactionForm/         # 거래 폼 컴포넌트
    │   ├── Views/              # 재사용 가능한 폼 컴포넌트
    │   └── ViewModels/         # 폼별 ViewModel
    ├── Navigation/              # 네비게이션
    └── ...
```

## 📊 프로젝트 현황

### 개발 진행률
```
📱 UI 화면: 70% (4/5 완료)
🏗 아키텍처: 95% (거의 완성)
🧪 테스트: 51% (주요 기능 커버)
📚 문서화: 75% (README, 코드 주석)
```

### 통계
- **Swift 파일**: 108개
- **테스트 파일**: 35개
- **커밋 수**: 72개
- **테스트 코드**: 2,500+ 줄

## 🎯 학습 목표 및 성과

### 기술적 학습
- [x] **Clean Architecture** 실제 프로젝트 적용
- [x] **SwiftUI + @Observable** 현대적 상태 관리
- [x] **SwiftData** 를 활용한 데이터 영속성
- [x] **Combine** 기반 반응형 프로그래밍
- [x] **의존성 주입** 패턴 구현
- [x] **포괄적인 테스트** 작성 방법론

### 개발 프로세스 학습
- [x] **Git Flow** 브랜치 전략
- [x] **CI/CD** 파이프라인 구축
- [x] **코드 품질 관리** (SwiftLint)
- [x] **문서화** 습관

## 🔄 향후 계획

### 단기 목표 (1-2개월)
1. ✅ **거래 상세 조회** 화면 구현 (완료)
2. ✅ **거래 수정** 기능 추가 (완료)
3. **차트 및 통계** 화면 개발
4. **설정 화면** 기본
5. **에러 처리** 체계 구축

### 장기 목표 (3-6개월)
1. **설정 화면** 고도화
2. **데이터 백업/복원** 기능
3. **위젯** 지원
4. **App Store 배포** 고려

## 👨‍💻 개발자 노트

이 프로젝트는 **실제 개인적 필요**에서 시작된 학습 프로젝트입니다. 기존 가계부 앱들의 복잡성에 불만을 느껴 간단하고 직관적인 인터페이스를 목표로 개발했습니다.

특히 **아키텍처 설계**에 많은 고민과 시간을 투자했으며, 확장 가능하고 테스트하기 쉬운 구조를 만들기 위해 노력했습니다. Clean Architecture의 핵심 원칙들을 지키면서도 iOS 생태계에 맞는 실용적인 구현을 추구했습니다.

## 🔍 사전 조사 및 설계

### 📊 사용자 니즈 분석

| 니즈 | 설명 | 기능 설계 방향 |

|------|------|----------------|

| ****소비 통제**** | 충동구매와 불필요한 지출 감소 | 예산 설정 + 초과 시 즉시 알림 |

| ****간편한 기록**** | 복잡한 기능 없이 쉬운 반복 기록 | 자동완성 + 빈도별 카테고리 추천 |

| ****직관적 분석**** | 소비 패턴을 한눈에 파악 | 시각적 차트 + 카테고리별 비중 분석 |

| ****개인화**** | 본인만의 기록 방식 선택 | 커스텀 카테고리 + 다양한 입력 방법 |

### 💡 핵심 설계 원칙

- ***사용자 니즈 → 가계부 성공 방법 → 앱 기능 매핑***

| 사용자 니즈 | 가계부 잘 쓰는 방법 | MoneyMoa 솔루션 |

|-------------|-------------------|-----------------|

| 소비 통제 | 예산 먼저 세우고 그 안에서 소비 | 월/카테고리별 예산 설정 + 실시간 진행률 |

| 기록 피로감 해소 | 완벽함보다 꾸준함 우선 | 최근 항목 자동완성 + 3초 입력 |

| 패턴 파악 | 월말 결산 & 항목별 분석 | 직관적 차트 + 요약 카드 |

| 개인화 | 스트레스 없는 도구 선택 | 커스텀 카테고리 + 유연한 구조 |

---

**개발 기간**: 2025년 7월 ~ 현재 진행중  
**플랫폼**: iOS 17.0+  
**언어**: Swift 5.9+  
**라이센스**: MIT
