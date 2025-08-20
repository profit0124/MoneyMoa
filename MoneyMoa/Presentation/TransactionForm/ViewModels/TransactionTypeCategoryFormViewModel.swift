//
//  TransactionTypeCategoryFormViewModel.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/18/25.
//

import Foundation
import Observation
import Combine

/// 거래 유형 및 카테고리 선택을 관리하는 ViewModel
/// 
/// 주요 기능:
/// - 거래 유형별 카테고리 동적 로딩
/// - 서브카테고리 선택 및 관리  
/// - 카테고리/서브카테고리 동적 생성
/// - 폼 간 데이터 연동
@Observable
final class TransactionTypeCategoryFormViewModel: Identifiable {

    // MARK: - Properties
    
    /// 고유 식별자
    let id = UUID()
    
    /// 거래 유형별 카테고리 조회 UseCase
    private var getCategoriesByTypeUseCase: GetCategoriesByTypeUseCase
    
    /// 카테고리 생성 UseCase
    private var createCategoryUseCase: CreateCategoryUseCase
    
    /// 서브카테고리 생성 UseCase
    private var createSubCategoryUseCase: CreateSubCategoryUseCase

    /// 거래 유형별 카테고리 목록
    var categories: [CategoryDTO] = []
    
    /// 선택된 서브카테고리 (유효성 검증 기준)
    var selectedSubCategory: SubCategoryDTO?
    
    /// 현재 선택된 거래 유형 (기본: 변동비)
    var selectedTransactionType: TransactionType = .variableExpense

    /// 카테고리 생성 폼 ViewModel (모달 표시용)
    var categoryFormViewModel: CategoryFormViewModel?

    /// Combine 구독 관리
    var cancellables: Set<AnyCancellable> = []

    // MARK: - Computed Properties
    
    /// 카드 요약 정보 생성 (거래 유형, 선택된 서브카테고리)
    var summary: String {
        var result: [String] = []

        result.append(selectedTransactionType.displayName)

        if let subCategory = selectedSubCategory {
            result.append("📂 \(subCategory.name)")
        }

        return result.isEmpty ? "정보 없음" : result.joined(separator: " • ")
    }

    /// 폼 유효성 검증 (서브카테고리 선택 필수)
    var isValid: Bool {
        selectedSubCategory != nil
    }

    public init(getCategoriesByTypeUseCase: GetCategoriesByTypeUseCase,
                createCategoryUseCase: CreateCategoryUseCase,
                createSubCategoryUseCase: CreateSubCategoryUseCase,
                categories: [CategoryDTO] = [],
                selectedTransactionType: TransactionType = .variableExpense
    ) {
        self.getCategoriesByTypeUseCase = getCategoriesByTypeUseCase
        self.createCategoryUseCase = createCategoryUseCase
        self.createSubCategoryUseCase = createSubCategoryUseCase
        self.categories = categories
        self.selectedTransactionType = selectedTransactionType
    }

    // MARK: - Action Handling
    
    /// 사용자 액션 정의
    enum Action {
        case onAppear                                          // 뷰 나타남
        case fetchCategories                                   // 카테고리 목록 조회
        case setTransactionType(TransactionType)               // 거래 유형 변경
        case setSubCategory(SubCategoryDTO?)                   // 서브카테고리 선택
        case presentCategoryForm(CategoryDTO?)                 // 카테고리 생성 폼 표시
        case setSelectedSubCategoryFromCategoryForm(SubCategoryDTO) // 생성된 서브카테고리 선택
        case subscribeCategoryForm                             // 카테고리 폼 결과 구독
        case dismissCategoryForm                               // 카테고리 폼 닫기
        case unsubscribe                                      // 구독 해제
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:
            onAppear()

        case .setTransactionType(let transactionType):
            if setSelectedTransactionType(transactionType) {
                send(.fetchCategories)
                send(.setSubCategory(nil))
            }

        case .fetchCategories:
            Task {
                await fetchCategories()
            }
        case .setSubCategory(let subCategory):
            setSelectedSubCategory(subCategory)

        case .presentCategoryForm(let categoryDTO):
            presentCategoryForm(categoryDTO)

        case .setSelectedSubCategoryFromCategoryForm(let subCategory):
            send(.fetchCategories)
            send(.setSubCategory(subCategory))

        case .subscribeCategoryForm:
            subscribeCategoryForm()

        case .dismissCategoryForm:
            dismissCategoryForm()
            send(.unsubscribe)

        case .unsubscribe:
            cancellables.removeAll()
        }
    }

    // MARK: - Private Methods
    
    private func onAppear() {
        if categories.isEmpty {
            Task {
                await fetchCategories()
            }
        }
    }

    /// 거래 유형 변경 시 카테고리 재로딩
    /// - Returns: 변경되었으면 true, 동일하면 false
    private func setSelectedTransactionType(_ type: TransactionType) -> Bool {
        if selectedTransactionType == type {
            return false
        } else {
            selectedTransactionType = type
            return true
        }
    }

    /// 선택된 거래 유형에 맞는 카테고리 목록 조회
    private func fetchCategories() async {
        do {
            categories = try await getCategoriesByTypeUseCase.execute(selectedTransactionType)
        } catch {
            handleError(error)
        }
    }

    private func setSelectedSubCategory(_ subCategory: SubCategoryDTO?) {
        self.selectedSubCategory = subCategory
    }

    /// 카테고리 생성 폼을 표시하고 결과를 구독
    /// - Parameter category: 기존 카테고리 (서브카테고리 추가용) 또는 nil (새 카테고리)
    private func presentCategoryForm(_ category: CategoryDTO?) {
        self.categoryFormViewModel = .init(
            createCategoryUseCase: createCategoryUseCase,
            createSubCategoryUseCase: createSubCategoryUseCase,
            transactionType: selectedTransactionType,
            category: category
        )

        subscribeCategoryForm()
    }

    private func subscribeCategoryForm() {
        self.categoryFormViewModel?.createPublisher
            .sink(receiveValue: { [weak self] subCategory in
                self?.send(.setSelectedSubCategoryFromCategoryForm(subCategory))
                self?.send(.dismissCategoryForm)
            })
            .store(in: &cancellables)
    }

    private func dismissCategoryForm() {
        self.categoryFormViewModel = nil
    }

    /// 에러 처리 및 사용자 피드백
    private func handleError(_ error: Error) {
        // 현재는 단순 로깅만 처리
        print(error)
    }
}
