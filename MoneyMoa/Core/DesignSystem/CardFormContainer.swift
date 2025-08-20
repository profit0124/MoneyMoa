//
//  CardFormContainer.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/19/25.
//
import SwiftUI

// MARK: State about card
enum FormType {
    case create
    case update
}

struct CardHeaderData {
    let title: String
    let subtitle: String
    let stepNumber: Int
    let summary: String?
    let isCompleted: Bool
}

// MARK: - CardFormCoordinator

protocol CardFormCoordinatorProtocol {
    var expandedCards: Set<String> { get set }
    func expandCard(_ id: String)
    func collapseCard(_ id: String)
}

@Observable
class BasicCardFormCoordinator: CardFormCoordinatorProtocol {
    var expandedCards: Set<String>

    init(expandedCards: Set<String> = []) {
        self.expandedCards = expandedCards
    }

    func expandCard(_ id: String) {}
    func collapseCard(_ id: String) {}
}

final class CreateTransactionFormCoordinator: BasicCardFormCoordinator {
    init(_ id: String) {
        super.init()
        self.expandedCards = Set<String>([id])
    }

    override func expandCard(_ id: String) {
        self.expandedCards.removeAll()
        expandedCards.insert(id)
    }

    override func collapseCard(_ id: String) {
        expandedCards.remove(id)
    }
}

// MARK: - CardFormContainer

struct CardFormContainer: ViewModifier {
    let cardId: String
    let formType: FormType
    let title: String
    let subtitle: String
    let stepNumber: Int
    let summary: String?
    let isCompleted: Bool
    @Environment(BasicCardFormCoordinator.self) private var coordinator

    private var isExpanded: Bool {
        coordinator.expandedCards.contains(cardId)
    }

    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            if !isExpanded || formType != .create {
                cardHeader
            }

            if isExpanded {
                if formType == .update {
                    Divider()
                        .padding(.horizontal, 16)
                }

                content
                    .padding(16)
                    .background(Color(.systemBackground))
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        .id(cardId)
    }

    @ViewBuilder
    private var cardHeader: some View {
        Button(action: {
            if isExpanded {
                coordinator.collapseCard(cardId)
            } else {
                coordinator.expandCard(cardId)
            }
        }, label: {
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    headerIcon
                    headerText
                    Spacer()
                    chevronIcon
                }

                if !isExpanded, let summary = summary {
                    HStack {
                        Text(summary)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    .padding(.horizontal, 56)
                }
            }
            .padding(16)
        })
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private var headerIcon: some View {
        ZStack {
            Circle()
                .fill(isCompleted ? Color.green : Color.blue.opacity(0.2))
                .frame(width: 40, height: 40)

            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            } else {
                Text("\(stepNumber)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
        }
    }

    @ViewBuilder
    private var headerText: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            if isCompleted {
                Text("완료됨")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
            } else {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private var chevronIcon: some View {
        VStack(spacing: 4) {
            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            if !isCompleted {
                ProgressIndicator(currentStep: stepNumber, totalSteps: TransactionStep.allCases.count)
            }
        }
    }
}

struct ProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 2) {
                ForEach(1...totalSteps, id: \.self) { step in
                    Rectangle()
                        .fill(step <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 4)
                        .cornerRadius(2)
                }
            }

            Text("\(currentStep)/\(totalSteps)")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }
}
