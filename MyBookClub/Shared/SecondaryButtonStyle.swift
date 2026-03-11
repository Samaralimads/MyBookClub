//
//  SecondaryButtonStyle.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 11/03/2026.
//

import SwiftUI

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appBody.weight(.semibold))
            .foregroundStyle(.accent)
            .padding(.vertical, Spacing.md)
            .padding(.horizontal, Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.button)
                    .stroke(Color.accent, lineWidth: 1.5)
            )
            .opacity(configuration.isPressed ? 0.7 : isEnabled ? 1.0 : 0.4)
            .animation(Animations.fade, value: configuration.isPressed)
            .animation(Animations.fade, value: isEnabled)
    }
}


