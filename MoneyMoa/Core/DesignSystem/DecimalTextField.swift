//
//  DecimalTextField.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/22/25.
//

import SwiftUI

struct DecimalTextField: View {

    let placeHolder: String
    @Binding var decimal: Decimal?
    private var decimalText: String {
        guard let decimal else { return "" }
        let result = decimal.formattedAmountWithoutWon
        return result
    }

    init(_ placeHolder: String, decimal: Binding<Decimal?>) {
        self.placeHolder = placeHolder
        self._decimal = decimal
    }

    var body: some View {
        TextField(placeHolder, text: Binding(get: {
            decimalText
        }, set: {
            setDecimal($0)
        }))
    }

    func setDecimal(_ text: String) {
        let digits = text.filter(\.isNumber)
        let dropped = digits.drop(while: { $0 == "0" })
        let normalized = dropped.isEmpty ? "" : String(dropped)

        self.decimal = normalized.isEmpty ? nil : Decimal(string: normalized)
    }
}

#Preview {
    DecimalTextField("", decimal: .constant(1000))
}
