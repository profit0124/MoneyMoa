//
//  TransactionDetailView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/10/25.
//

import SwiftUI

struct TransactionDetailView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: TransactionDetailViewModel

    public init(viewModel: TransactionDetailViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // MARK: - 메인 정보 (가장 강조)
                    mainInfoSection
                    
                    // MARK: - 부가 정보 (두 번째 우선순위)
                    additionalInfoSection
                    
                    // MARK: - 메모 및 기타 정보
                    if (viewModel.transaction.memo != nil && !viewModel.transaction.memo!.isEmpty) || viewModel.transaction.isFavorite {
                        memoAndExtraSection
                    }
                    
                    Spacer(minLength: 100) // 버튼 영역 확보
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .navigationTitle("거래 상세")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("수정", systemImage: "pencil") {
                            viewModel.send(.changeViewMode)
                        }
                        
                        Divider()
                        
                        Button("삭제", systemImage: "trash", role: .destructive) {
                            viewModel.send(.showDeleteConfirmation)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                actionButtons
            }
        }
        .confirmationDialog(
            "거래를 삭제하시겠습니까?",
            isPresented: $viewModel.isPresentedDeleteConfirmation,
            titleVisibility: .visible,
            actions: {
                Button("삭제", role: .destructive) {
                    viewModel.send(.deleteTransaction(router.dismissModal))
                }
                Button("취소", role: .cancel) { }
            },
            message: {
                Text("삭제된 거래는 복구할 수 없습니다.")
            }
        )
    }
}

// MARK: - Main Info Section (가장 강조되는 정보)
private extension TransactionDetailView {
    var mainInfoSection: some View {
        VStack(spacing: 16) {
            // 금액 - 가장 크게 강조
            amountDisplay
            
            // 카테고리 정보
            categoryDisplay
            
            // 날짜 정보
            dateDisplay
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    var amountDisplay: some View {
        VStack(spacing: 8) {
            let transaction = viewModel.transaction
            HStack {
                Image(systemName: transaction.transactionType.icon)
                    .font(.title2)
                    .foregroundColor(transaction.transactionType.color)
                
                Text(transaction.transactionType.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(transaction.transactionType.color)
            }
            
            Text(FormatterManager.shared.formatCurrency(transaction.amount))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(transaction.transactionType.color)
        }
    }
    
    var categoryDisplay: some View {
        HStack(spacing: 16) {
            // 카테고리 아이콘
            Image(systemName: "folder.fill")
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)
                .background(Circle().fill(.blue.opacity(0.1)))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.transaction.subCategory.transactionType.displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                HStack {
                    Image(systemName: viewModel.transaction.subCategory.categoryIconName)

                    Text("\(viewModel.transaction.subCategory.categoryName) - \(viewModel.transaction.subCategory.name)")
                }
                .font(.headline)
                .fontWeight(.semibold)
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    var dateDisplay: some View {
        HStack(spacing: 16) {
            // 날짜 아이콘
            Image(systemName: "calendar")
                .font(.title3)
                .foregroundColor(.green)
                .frame(width: 32, height: 32)
                .background(Circle().fill(.green.opacity(0.1)))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("거래 일시")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(FormatterManager.shared.formatDate(viewModel.transaction.date, format: .dateOnly))
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(FormatterManager.shared.formatDate(viewModel.transaction.date, format: .timeOnly))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Additional Info Section (두 번째 우선순위)
private extension TransactionDetailView {
    var additionalInfoSection: some View {
        VStack(spacing: 12) {
            // 결제수단
            paymentMethodDisplay
            
            // 장소
            if let place = viewModel.transaction.place, !place.isEmpty {
                placeDisplay
            }
        }
    }
    
    var paymentMethodDisplay: some View {
        HStack(spacing: 16) {
            // 결제수단 아이콘
            Image(systemName: viewModel.transaction.paymentMethod.kind.iconName)
                .font(.title3)
                .foregroundColor(.orange)
                .frame(width: 32, height: 32)
                .background(Circle().fill(.orange.opacity(0.1)))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("결제수단")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.transaction.paymentMethod.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(viewModel.transaction.paymentMethod.kind.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    var placeDisplay: some View {
        HStack(spacing: 16) {
            // 장소 아이콘
            Image(systemName: "location.fill")
                .font(.title3)
                .foregroundColor(.purple)
                .frame(width: 32, height: 32)
                .background(Circle().fill(.purple.opacity(0.1)))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("거래 장소")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(viewModel.transaction.place ?? "")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Memo and Extra Section
private extension TransactionDetailView {
    var memoAndExtraSection: some View {
        VStack(spacing: 12) {
            // 메모
            if let memo = viewModel.transaction.memo, !memo.isEmpty {
                memoDisplay
            }
            
            // 즐겨찾기
            if viewModel.transaction.isFavorite {
                favoriteDisplay
            }
        }
    }
    
    var memoDisplay: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "note.text")
                    .font(.title3)
                    .foregroundColor(.gray)
                
                Text("메모")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            Text(viewModel.transaction.memo ?? "")
                .font(.body)
                .foregroundColor(.primary)
                .padding(.leading, 32)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    var favoriteDisplay: some View {
        HStack(spacing: 16) {
            Image(systemName: "star.fill")
                .font(.title3)
                .foregroundColor(.yellow)
                .frame(width: 32, height: 32)
                .background(Circle().fill(.yellow.opacity(0.1)))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("즐겨찾기")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("자주 사용하는 거래")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Action Buttons
private extension TransactionDetailView {
    var actionButtons: some View {
        Button {
            router.dismissModal()
        } label: {
            Text("확 인")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.blue)
                )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
        )
    }
}

#Preview {
    let viewModel = TransactionDetailViewModel(transaction: .mockLunch)
    TransactionDetailView(viewModel: viewModel)
        .environment(AppRouter())
}
