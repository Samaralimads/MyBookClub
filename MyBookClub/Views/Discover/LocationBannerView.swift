//
//  LocationBannerView.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 15/06/2026.
//

import SwiftUI

struct LocationBannerView: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                Image(systemName: "location.circle")
                    .font(.system(size: 22))
                    .foregroundStyle(.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Set your location")
                        .font(.appCaptionBold)
                        .foregroundStyle(.inkPrimary)
                    Text("Enable GPS or enter your city to see clubs near you.")
                        .font(.appCaption)
                        .foregroundStyle(.inkSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.inkTertiary)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(Color.accentSubtle)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .stroke(Color.accent.opacity(0.3), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.lg)
    }
}
