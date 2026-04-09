//
//  PendingMembersRow.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/04/2026.
//

import SwiftUI

struct PendingMembersRow: View {
    let user: AppUser
    let onApprove: () -> Void
    let onReject: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            AvatarView(user: user, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(.appBody.weight(.semibold))
                    .foregroundStyle(.inkPrimary)
                if let city = user.city, !city.isEmpty {
                    Text(city)
                        .font(.appCaption)
                        .foregroundStyle(.inkTertiary)
                }
            }

            Spacer()

            HStack(spacing: Spacing.sm) {
                Button(action: onReject) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.inkSecondary)
                        .frame(width: 36, height: 36)
                        .background(Color.border.opacity(0.4))
                        .clipShape(.circle)
                }

                Button(action: onApprove) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.accent)
                        .clipShape(.circle)
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.cardBackground)
        .clipShape(.rect(cornerRadius: CornerRadius.card))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .stroke(Color.accent.opacity(0.3), lineWidth: 1)
        }
    }
}
