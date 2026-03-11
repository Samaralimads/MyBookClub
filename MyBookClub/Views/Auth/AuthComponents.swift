//
//  AuthComponents.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 10/03/2026.
//

import SwiftUI

// MARK: - Input Field with icon, label, error

struct AuthInputField: View {
    let label: String
    let icon: String
    let placeholder: String
    @Binding var text: String
    var error: String?
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    var showSecure: Binding<Bool>? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {

            // Label
            Text(label)
                .font(.appCaption.weight(.medium))
                .foregroundColor(.inkPrimary)

            // Field row
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(.inkTertiary)
                    .frame(width: 18)

                if isSecure, let showBinding = showSecure {
                    Group {
                        if showBinding.wrappedValue {
                            TextField(placeholder, text: $text)
                        } else {
                            SecureField(placeholder, text: $text)
                        }
                    }
                    .font(.appBody)
                    .foregroundColor(.inkPrimary)
                    .autocorrectionDisabled()
                    .autocapitalization(.none)

                    Button {
                        showBinding.wrappedValue.toggle()
                    } label: {
                        Image(systemName: showBinding.wrappedValue ? "eye.slash" : "eye")
                            .font(.system(size: 15))
                            .foregroundColor(.inkTertiary)
                    }
                } else {
                    TextField(placeholder, text: $text)
                        .font(.appBody)
                        .foregroundColor(.inkPrimary)
                        .keyboardType(keyboardType)
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                }
            }
            .padding(.vertical, Spacing.md)
            .padding(.horizontal, Spacing.md)
            .background(Color.cardBackground)
            .cornerRadius(CornerRadius.button)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.button)
                    .stroke(
                        error != nil ? Color.red.opacity(0.7) : Color.border,
                        lineWidth: 1
                    )
            )

            // Inline error
            if let error {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 11))
                    Text(error)
                        .font(.appCaption)
                }
                .foregroundColor(.red)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(Animations.standard, value: error)
    }
}

// MARK: - Password strength bar

struct PasswordStrengthView: View {
    let strength: Int   // 0–5
    let label: String

    private var color: Color {
        switch strength {
        case 0, 1: return .red
        case 2, 3: return .orange
        case 4:    return .green
        default:   return Color(red: 0, green: 0.75, blue: 0.35)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                ForEach(0..<5, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i < strength ? color : Color.border)
                        .frame(height: 4)
                }
            }
            Text(label)
                .font(.appCaption)
                .foregroundColor(color)
        }
        .animation(Animations.standard, value: strength)
    }
}

// MARK: - "or" Divider

struct AuthDivider: View {
    var body: some View {
        HStack(spacing: Spacing.md) {
            Rectangle().fill(Color.border).frame(height: 1)
            Text("or")
                .font(.appCaption)
                .foregroundColor(.inkTertiary)
            Rectangle().fill(Color.border).frame(height: 1)
        }
    }
}
