//
//  IconSelectionView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/23/25.
//

import SwiftUI

struct IconSelectionView: View {

    private let icons: [String] = [
        "house.fill", "building.2.fill", "bolt.fill",
        "drop.fill", "flame.fill", "wifi.circle.fill",
        "phone.fill", "fork.knife.circle.fill", "cup.and.saucer.fill",
        "cart.fill", "bag.fill", "tshirt.fill",
        "gift.fill", "car.fill", "bus.fill",
        "tram.fill", "bicycle.circle.fill", "fuelpump.fill",
        "person.2.circle.fill", "heart.text.square.fill", "graduationcap.fill",
        "book.closed.fill", "cross.case.fill", "bandage.fill",
        "airplane.circle.fill", "bed.double.fill", "gamecontroller.fill",
        "film.fill", "ticket.fill", "wineglass.fill",
        "briefcase.fill", "chart.line.uptrend.xyaxis",
        "plus.circle.fill", "repeat.circle.fill",
        "antenna.radiowaves.left.and.right", "medal.fill"
    ]
    private let title: String = "아이콘 선택"
    let color: Color
    @Binding var selectedIcon: String?

    init(color: Color, selectedIcon: Binding<String?>) {
        self.color = color
        self._selectedIcon = selectedIcon
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                ForEach(icons, id: \.self) { iconName in
                    iconButton(iconName)
                }
            }
        }
    }

    @ViewBuilder
    private func iconButton(_ iconName: String) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.2)) {
                selectedIcon = iconName
            }
        }, label: {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundStyle(
                    selectedIcon == iconName ? Color.white : color
                )
                .frame(width: 44, height: 44)
                .background(
                    selectedIcon == iconName
                    ? color
                    : color.opacity(0.1))
                .cornerRadius(8)
                .overlay {
                    if selectedIcon == iconName {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(color, lineWidth: 2)
                    }
                }
        })
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    IconSelectionView(
        color: TransactionType.fixedExpense.color,
        selectedIcon: .constant("")
    )
}
