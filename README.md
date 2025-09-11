  # MoneyMoa 💰

  Clean Architecture + SwiftUI Coordinator Pattern 기반 개인 가계부 iOS 앱SwiftUI, SwiftData, Modern iOS Development 실전 프로젝트

  MoneyMoa는 Clean Architecture와 현대적 iOS 개발 기법을 실무에 적용한 개인 가계부 앱입니다. 복잡한 기존 가계부 앱들의 문제를 해결하고자 간단함과 직관성에 집중하여 개발된
  실용적인 학습 프로젝트입니다.

  ## 🚀 핵심 특징

  ### 💡 실용적 학습 프로젝트

  - 실제 개인 니즈에서 출발한 문제 해결 및 사용자 경험 중심 개발
  - 최신 iOS 기술 스택 실무 적용 (iOS 17+, SwiftUI, SwiftData)

  ### 🏗️  엔터프라이즈급 아키텍처

  - Clean Architecture + MVVM 패턴으로 계층 분리
  - SwiftUI Coordinator Pattern 확장 가능한 네비게이션
  - 의존성 주입 컨테이너 기반 모듈화
  - UseCase 패턴으로 비즈니스 로직 캡슐화

  ### ⚡ 현대적 iOS 개발

  - @Observable (iOS 17+) 상태 관리
  - Swift Concurrency 기반 비동기 처리
  - Combine 반응형 이벤트 시스템
  - SwiftData 현대적 데이터 영속성

  ## 📱 주요 기능

  ### ✅ 구현 완료

  - 메인 대시보드: 월별 거래 내역, 캘린더 뷰, 예산 대비 지출 현황
  - 3단계 거래 등록: 위자드 형태의 직관적 입력 플로우
  - 거래 관리: CRUD 완전 지원 (조회, 수정, 삭제)
  - 실시간 동기화: 이벤트 기반 데이터 업데이트 (Combine 활용)
  - 통계 및 차트: 소비 패턴 시각화

  ### 🚧 개발 예정
  
  - 다국적 시간대 지원: TransactionTimeContext로 정확한 시간 처리
  - 에러 처리: 포괄적 예외 상황 관리
  - 고급 설정: 사용자 맞춤 설정 (거래내역 템플릿(자동생성), 예산 템플릿/월별 예산, 통화 단위)

  ### 🛠 기술 스택

  Core Technologies
```
  // iOS 17+ Modern Features
  @Observable class ViewModel  // 새로운 상태 관리
  actor DatabaseActor         // 안전한 데이터 접근
  async/await                 // Swift Concurrency
```
  Architecture Stack

  - SwiftUI - 선언적 UI 프레임워크
  - SwiftData - Core Data의 현대적 대안
  - Combine - 반응형 프로그래밍
  - Swift Concurrency - 비동기 프로그래밍

  Development Tools

  - Xcode 16.1 - 최신 개발 환경
  - SwiftLint - 코드 품질 관리
  - GitHub Actions - CI/CD 파이프라인

  ### 🏗 아키텍처 설계

  Clean Architecture 계층 구조
```
  ┌─────────────────────────────────────────┐
  │           Presentation Layer            │
  │  SwiftUI Views + @Observable ViewModels │
  │        + Coordinator Pattern            │
  └─────────────────┬───────────────────────┘
                    │
  ┌─────────────────┴───────────────────────┐
  │            Domain Layer                 │
  │   UseCases + DTOs + Repository Protocol │
  └─────────────────┬───────────────────────┘
                    │
  ┌─────────────────┴───────────────────────┐
  │             Data Layer                  │
  │  SwiftData Models + Repository Impl     │
  └─────────────────────────────────────────┘
```
  핵심 패턴 구현

  1. SwiftUI Coordinator Pattern

  타입 안전한 라우팅 시스템:
  ```
  // AppRoute.swift - 기능별 라우트 분리
  enum MainRoute: Hashable {
      case home
  }

  enum SettingsRoute: Hashable {
      case root
      case budget(YearMonth)
      case category
      case categorySelector(CategoryDTO)
      case categoryForm(CategoryListMode, CategoryDTO?, TransactionType?)
  }

  enum TransactionsRoute: Hashable {
      case add
      case detail(TransactionDTO)
      case update(TransactionDTO)
  }

  // Union 타입으로 전체 라우트 관리
  enum AppRoute: Hashable {
      case main(MainRoute)
      case settings(SettingsRoute)
      case transactions(TransactionsRoute)
      case statistics(StatisticsRoute)
  }

  // 편의 확장
  extension AppRoute {
      static let mainHome = AppRoute.main(.home)
      static let transactionsAdd = AppRoute.transactions(.add)
      static func transactionDetail(_ transaction: TransactionDTO) -> AppRoute {
          return .transactions(.detail(transaction))
      }
  }
```
  계층적 라우터 관리:
  ```
  // AppRouter.swift - @Observable 기반 상태 관리
  @MainActor
  @Observable
  final class AppRouter {
      var path: [AppRoute] = []
      var sheet: ModalItem?
      var fullScreen: ModalItem?

      // 계층적 구조 지원
      weak var parent: AppRouter?

      func push(_ route: AppRoute) {
          path.append(route)
      }

      func present(_ route: AppRoute, as style: ModalStyle) {
          let modalItem = ModalItem(root: route, style: style)
          switch style {
          case .sheet: sheet = modalItem
          case .fullScreen: fullScreen = modalItem
          }
      }

      func dismissModal() {
          parent?.sheet = nil
          parent?.fullScreen = nil
      }
  }
```

  호스트 기반 네비게이션 관리:
  ```
  // CoordinatorHost.swift - 재귀적 네비게이션 지원
  struct CoordinatorHost: View {
      @State private var router: AppRouter
      let container: DIContainer
      let start: AppRoute

      var body: some View {
          let factory = ViewFactory(container: container)

          NavigationStack(path: $router.path) {
              factory.makeView(for: start)
                  .navigationDestination(for: AppRoute.self) { route in
                      factory.makeView(for: route)
                  }
          }
          .environment(router)
          .sheet(item: $router.sheet) { item in
              // 재귀적 CoordinatorHost로 모달 지원
              CoordinatorHost(container: container, start: item.root, parent: router)
          }
          .fullScreenCover(item: $router.fullScreen) { item in
              CoordinatorHost(container: container, start: item.root, parent: router)
          }
      }
  }
```
  Coordinator Pattern의 장점:
  - 타입 안전성: 컴파일 타임 라우팅 검증
  - 확장성: 새로운 기능 추가 시 간단한 case 추가
  - 재사용성: 모달, 네비게이션 일관된 처리
  - 테스트 용이성: 네비게이션 로직 격리 테스트
  - 계층적 구조: 복잡한 모달 플로우 우아한 처리

  2. 다목적 Mock 시스템
```
  Preview + 테스트 통합 지원:
  #if DEBUG
  final class MockTransactionRepository: TransactionRepository {
      // 테스트 시나리오
      var shouldFailOnCreate = false
      var shouldReturnEmpty = false

      // Preview 시나리오
      var previewScenario: PreviewScenario = .normal

      enum PreviewScenario {
          case normal        // 일반적인 데이터
          case empty         // 빈 상태
          case heavyData     // 대량 데이터
          case errorState    // 에러 상황
          case budgetOver    // 예산 초과
      }

      func fetchMonthlyTransactions(yearMonth: YearMonth) async throws -> [TransactionDTO] {
          switch previewScenario {
          case .empty:
              return []
          case .heavyData:
              return Array(repeating: TransactionDTO.mockLunch, count: 100)
          case .errorState:
              throw RepositoryError.databaseError(NSError(domain: "Mock", code: 1))
          default:
              return TransactionFactory.mockMonthlyTransactions
          }
      }
  }

  // Preview용 편의 팩토리
  extension MockDIContainer {
      static func normal() -> DIContainer {
          let container = MockDIContainer()
          return container
      }

      static func empty() -> DIContainer {
          let container = MockDIContainer()
          container.transactionRepository.previewScenario = .empty
          return container
      }

      static func heavyData() -> DIContainer {
          let container = MockDIContainer()
          container.transactionRepository.previewScenario = .heavyData
          return container
      }
  }
  #endif

  SwiftUI Preview 활용:
  // 다양한 상태의 Preview 생성
  struct TransactionListView_Previews: PreviewProvider {
      static var previews: some View {
          Group {
              TransactionListView()
                  .previewDisplayName("일반 상태")
                  .environment(MockDIContainer.normal())

              TransactionListView()
                  .previewDisplayName("빈 상태")
                  .environment(MockDIContainer.empty())

              TransactionListView()
                  .previewDisplayName("대량 데이터")
                  .environment(MockDIContainer.heavyData())
          }
      }
  }
```
  Mock 시스템의 활용 범위:
  - 단위 테스트: 격리된 테스트 환경
  - SwiftUI Preview: 모든 UI 상태 즉시 확인
  - 시나리오 테스트: 엣지 케이스 시각적 검증
  - 디버깅: 특정 상태 재현 및 문제 분석
  - 디자인 검증: 다양한 데이터 시나리오 시각적 테스트

  3. 의존성 주입 시스템
```
  protocol DIContainer {
      func makeMainViewModel() -> MainViewModel
      func makeTransactionRepository() -> TransactionRepository
      func makeCreateTransactionUseCase() -> CreateTransactionUseCase
  }

  // 실제 구현
  class AppDIContainer: DIContainer {
      private let database: Database

      func makeTransactionRepository() -> TransactionRepository {
          TransactionRepositoryImpl(database: database)
      }
  }

  // Mock 구현 (테스트 및 Preview용)
  #if DEBUG
  class MockDIContainer: DIContainer {
      let transactionRepository = MockTransactionRepository()

      func makeTransactionRepository() -> TransactionRepository {
          transactionRepository
      }
  }
  #endif
```
  4. UseCase 패턴
```
  protocol CreateTransactionUseCase {
      func execute(_ transaction: TransactionDTO) async throws
  }

  class CreateTransactionUseCaseImpl: CreateTransactionUseCase {
      private let transactionRepository: TransactionRepository

      func execute(_ transaction: TransactionDTO) async throws {
          // 비즈니스 로직 및 검증
          guard transaction.amount > 0 else {
              throw RepositoryError.custom("금액은 0보다 커야 합니다")
          }
          try await transactionRepository.insertTransaction(transaction)
      }
  }
```

  ### 🧪 테스트 전략

  포괄적 테스트 환경
  
  - 계층별 테스트 분리: ViewModel, UseCase, Repository
  - Mock 기반 단위 테스트: 격리된 테스트 환경

  테스트 아키텍처 예제
```
  @MainActor
  final class AddTransactionViewModelTests: XCTestCase {
      private var viewModel: AddTransactionViewModel!
      private var mockCreateUseCase: MockCreateTransactionUseCase!

      override func setUp() {
          super.setUp()
          mockCreateUseCase = MockCreateTransactionUseCase()
          viewModel = AddTransactionViewModel(createUseCase: mockCreateUseCase)
      }

      func test_거래_생성_성공() async {
          // Given
          let transaction = TransactionDTO.mockLunch

          // When
          await viewModel.createTransaction(transaction)

          // Then
          XCTAssertTrue(mockCreateUseCase.createdTransactions.contains(transaction))
      }
  }
```
  🚀 CI/CD 파이프라인

  GitHub Actions 기반 자동화
```
  # .github/workflows/ci.yml
  name: iOS CI
  jobs:
    build-and-test:
      runs-on: macos-14
      steps:
        - name: SwiftLint 코드 품질 검사
        - name: 자동 시뮬레이터 선택 및 부팅
        - name: 단위 테스트 실행 (xcodebuild test)
        - name: 코드 커버리지 측정 (xccov)
        - name: 아티팩트 업로드 및 리포트 생성

  주요 특징:
  - 동적 시뮬레이터 선택: iPhone 16 → iPhone 15 → 첫 번째 사용 가능한 iPhone
  - 캐시 최적화: SPM 의존성 및 DerivedData 캐싱
  - 포괄적 검증: SwiftLint + 테스트 + 커버리지
  - 아티팩트 관리: 테스트 결과 및 커버리지 리포트 보관
```
  📁 프로젝트 구조
```
  MoneyMoa/
  ├── App/                          # 앱 진입점 & DI 설정
  │   ├── MoneyMoaApp.swift
  │   └── DI/DIContainerFactory.swift
  ├── Core/                         # 공통 유틸리티 & 디자인시스템
  │   ├── DesignSystem/            # 재사용 UI 컴포넌트
  │   ├── Extensions/              # Swift 확장
  │   ├── Services/                # 공통 서비스
  │   └── Types.swift              # 전역 타입 정의
  ├── Data/                         # 데이터 계층
  │   ├── SwiftDataModel/          # SwiftData 모델
  │   └── Repository/              # Repository 구현
  ├── Domain/                       # 도메인 계층
  │   ├── DTOs/                    # 데이터 전송 객체
  │   ├── Repository/              # Repository 인터페이스
  │   ├── UseCases/                # 비즈니스 로직
  │   │   ├── Transaction/         # 거래 관련 UseCase
  │   │   ├── Category/           # 카테고리 관련 UseCase
  │   │   └── Budget/             # 예산 관련 UseCase
  │   └── Services/                # 도메인 서비스
  └── Presentation/                 # 프레젠테이션 계층
      ├── Navigation/              # Coordinator Pattern
      │   ├── CoordinatorHost.swift
      │   ├── AppRoute.swift
      │   ├── AppRouter.swift
      │   └── ViewFactory.swift
      ├── Main/                    # 메인 화면
      ├── Transaction/             # 거래 관련 화면
      ├── TransactionForm/         # 재사용 가능한 폼 컴포넌트
      ├── Category/               # 카테고리 관리
      └── Settings/               # 설정 화면
```

  ## 🎯 기술적 성과 및 학습

  ### 실무 역량 향상

  - Clean Architecture 대규모 프로젝트 적용
  - SwiftUI Coordinator Pattern 확장 가능한 네비게이션
  - 현대적 iOS 개발 (iOS 17+, @Observable)
  - 포괄적 테스트 문화 정착
  - CI/CD 파이프라인 구축 및 운영

  ### 프로덕션 준비도

  - 메모리 관리: Actor 기반 안전한 데이터 접근
  - 성능 최적화: 효율적인 데이터 패칭 및 캐싱
  - 코드 품질: SwiftLint 기반 일관된 코드 스타일
  - 네비게이션: 타입 안전하고 확장 가능한 라우팅


  ## 🔍 설계 철학

  ### 문제 중심 개발

  기존 가계부 앱들의 복잡성과 사용성 문제를 해결하기 위해:
  - 3초 규칙: 거래 기록을 3초 이내에 완료
  - 인지 부하 최소화: 단계별 위자드 인터페이스
  - 일관성: 예측 가능한 사용자 경험

  ### 사용자 중심 개발

  - 앱 초기 시작시 추천 카테고리 자동 생성
  - 다양한 차트로 소비 패턴 시각화 제공
  - 카테고리 사용자 화
  - 유저 경험 시간 바탕 UI 제공 (예정)
  - 가계부 고유 기능에만 집중하여 직관적인 사용성 제공 (광고 없이 무료 배포 예정)

  ### 기술적 결정

  - SwiftUI Coordinator Pattern: 확장 가능하고 타입 안전한 네비게이션
  - Multi-purpose Mock: Preview와 테스트 통합 지원
  - SwiftData 선택: Core Data의 복잡성 해소
  - @Observable 도입: 보일러플레이트 코드 제거, View Rendering 최소화
  - Actor, DTO 활용: 데이터 레이스 조건 원천 차단
  - UseCase 패턴: 테스트 가능한 비즈니스 로직

  ---
  개발 기간: 2025년 7월 ~ 현재 진행플랫폼: iOS 17.0+언어: Swift 5.9+라이센스: MIT
