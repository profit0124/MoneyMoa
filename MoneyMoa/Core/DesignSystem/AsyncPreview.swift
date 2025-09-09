//
//  AsyncPreview.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/9/25.
//

import SwiftUI

#if DEBUG
struct AsyncPreview<Content: View>: View {
    let content: () async throws -> Content
    @State private var loadedContent: Content?
    @State private var isLoading = true
    @State private var error: Error?

    var body: some View {
        Group {
            if let content = loadedContent {
                content
            } else if isLoading {
                ProgressView("Loading Preview...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text("Preview Error")
                    .foregroundColor(.red)
            }
        }
        .task {
            do {
                let result = try await content()
                loadedContent = result
                isLoading = false
            } catch {
                self.error = error
                isLoading = false
            }
        }
    }
}

public struct StatisticsPreviewHelper {
    @ViewBuilder
    public static func preview<T: View>(
        range: DateRangePreset = .threeMonths,
        @ViewBuilder content: @escaping (StatisticsDashboardDTO) async throws -> T
    ) -> some View {
        AsyncPreview {
            let container = MockDIContainer()
            let useCase = container.makeGetStatisticsDashboardUseCase()
            let dashboard = try await useCase.execute(range: range.resolve())
            return try await content(dashboard)
        }
    }
}

#else
public struct StatisticsPreviewHelper {
    @ViewBuilder
    public static func preview<T: View>(
        range: DateRangePreset = .threeMonths,
        @ViewBuilder content: @escaping (StatisticsDashboardDTO) async throws -> T
    ) -> some View {
        Text("Preview only available in DEBUG")
            .foregroundStyle(.secondary)
    }
}
#endif
