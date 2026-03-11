//
//  PrimaryButtonStyle.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 11/03/2026.
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    var isFullWidth: Bool = true
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appBody.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: isFullWidth ? .infinity : nil, minHeight: 50, maxHeight: 50)
            .padding(.horizontal, Spacing.xl)
            .background(Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 50))
            .opacity(configuration.isPressed ? 0.75 : isEnabled ? 1.0 : 0.7)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(Animations.fade, value: configuration.isPressed)
            .animation(Animations.fade, value: isEnabled)
    }
}


#Preview {
    Button("Primary Button") {}
        .buttonStyle(PrimaryButtonStyle(isFullWidth: true))
}
