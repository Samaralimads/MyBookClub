//
//  AppTextFieldStyle.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import SwiftUI

struct AppTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.appBody)
            .foregroundStyle(.inkPrimary)
            .padding(Spacing.md)
            .background(Color.cardBackground)
            .clipShape(.rect(cornerRadius: CornerRadius.button))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.button)
                    .stroke(Color.border, lineWidth: 1)
            )
    }
}
