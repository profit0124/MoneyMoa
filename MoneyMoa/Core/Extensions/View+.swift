//
//  View+.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/19/25.
//

import SwiftUI

extension View {
    func cardFormContainer(
        cardId: String,
        formType: FormType,
        title: String,
        subtitle: String = "",
        stepNumber: Int,
        summary: String? = nil,
        isCompleted: Bool = false
    ) -> some View {
        modifier(
            CardFormContainer(
                cardId: cardId,
                formType: formType,
                title: title,
                subtitle: subtitle,
                stepNumber: stepNumber,
                summary: summary,
                isCompleted: isCompleted
            )
        )
    }
}
