//
//  SettingView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/10/25.
//

import SwiftUI

// MARK: - Settings Data Model

enum SettingsSection: CaseIterable, Hashable {
    case budget
    case category
    case about
    
    var title: String {
        switch self {
        case .budget: return "예산 관리"
        case .category: return "카테고리 설정"
        case .about: return "앱 정보"
        }
    }
    
    var icon: String {
        switch self {
        case .budget: return "chart.pie.fill"
        case .category: return "folder.fill"
        case .about: return "info.circle.fill"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .budget: return .green
        case .category: return .orange
        case .about: return .blue
        }
    }
    
    var items: [SettingsItem] {
        switch self {
        case .budget: return [.monthlyBudget, .transactionTemplate]
        case .category: return [.categoryManagement]
        case .about: return [.versionInfo, .developerInfo]
        }
    }
}

enum SettingsItem: Hashable {
    case monthlyBudget
    case transactionTemplate
    case categoryManagement
    case versionInfo
    case developerInfo
    
    var title: String {
        switch self {
        case .monthlyBudget: return "월별 예산"
        case .transactionTemplate: return "반복 거래 템플릿"
        case .categoryManagement: return "카테고리 관리"
        case .versionInfo: return "버전 정보"
        case .developerInfo: return "개발자"
        }
    }
    
    var subtitle: String {
        switch self {
        case .monthlyBudget: return "월별 예산을 설정하고 관리하세요"
        case .transactionTemplate: return "정기적으로 발생하는 거래를 관리하세요"
        case .categoryManagement: return "수입과 지출 카테고리를 관리하세요"
        case .versionInfo: return "MoneyMoa v1.0.0"
        case .developerInfo: return "Profit"
        }
    }
    
    var icon: String {
        switch self {
        case .monthlyBudget: return "dollarsign.circle.fill"
        case .transactionTemplate: return "repeat.circle.fill"
        case .categoryManagement: return "tag.fill"
        case .versionInfo: return "app.badge.fill"
        case .developerInfo: return "person.fill"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .monthlyBudget: return .green
        case .transactionTemplate: return .indigo
        case .categoryManagement: return .orange
        case .versionInfo: return .blue
        case .developerInfo: return .purple
        }
    }
    
    var showArrow: Bool {
        switch self {
        case .monthlyBudget, .transactionTemplate, .categoryManagement: return true
        case .versionInfo, .developerInfo: return false
        }
    }
    
    @MainActor
    func action(router: AppRouter) {
        switch self {
        case .monthlyBudget:
            router.push(.settingsBudget(YearMonth.current))
        case .transactionTemplate:
            router.push(.settingTransactionTemplate)
        case .categoryManagement:
            router.push(.categorySetup)
        case .versionInfo, .developerInfo:
            break // No action for info items
        }
    }
}

struct SettingsView: View {
    @Environment(AppRouter.self) private var router
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                headerSection
                
                VStack(spacing: 20) {
                    ForEach(SettingsSection.allCases, id: \.self) { section in
                        settingsSection(for: section)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("설정")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 48, weight: .medium))
                .foregroundStyle(.blue.gradient)
            
            Text("MoneyMoa 설정")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Settings Section Builder
    
    private func settingsSection(for section: SettingsSection) -> some View {
        SettingsSectionView(
            title: section.title,
            icon: section.icon,
            iconColor: section.iconColor
        ) {
            VStack(spacing: 12) {
                ForEach(section.items, id: \.self) { item in
                    SettingsRowView(
                        title: item.title,
                        subtitle: item.subtitle,
                        icon: item.icon,
                        iconColor: item.iconColor,
                        showArrow: item.showArrow,
                        action: item.showArrow ? { item.action(router: router) } : nil
                    )
                }
            }
        }
    }
}

// MARK: - Settings Section View

private struct SettingsSectionView<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            content
                .padding(.horizontal, 4)
                .padding(.bottom, 16)
        }
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
}

// MARK: - Settings Row View

private struct SettingsRowView: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let showArrow: Bool
    let action: (() -> Void)?
    
    init(
        title: String,
        subtitle: String,
        icon: String,
        iconColor: Color,
        showArrow: Bool = true,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self.showArrow = showArrow
        self.action = action
    }
    
    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: 16) {
                iconView
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if showArrow {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.separator), lineWidth: 0.5)
                    }
            }
        }
        .buttonStyle(SettingsRowButtonStyle())
        .disabled(action == nil)
    }
    
    private var iconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(iconColor.opacity(0.15))
                .frame(width: 40, height: 40)
            
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(iconColor)
        }
    }
}

// MARK: - Settings Row Button Style

private struct SettingsRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    CoordinatorHost(container: MockDIContainer(), start: .settingsRoot)
}
