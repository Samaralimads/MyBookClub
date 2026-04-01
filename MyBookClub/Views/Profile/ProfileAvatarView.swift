//
//  ProfileAvatarView.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 01/04/2026.
//

import SwiftUI

struct ProfileAvatarView: View {
    let avatarURL: String?
    let initials: String
    let onEditTap: () -> Void

    private let size: CGFloat = 88

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            avatarRing
            editBadge
        }
    }

    // MARK: - Subviews

    private var avatarRing: some View {
        Circle()
            .stroke(Color.accent, lineWidth: 2.5)
            .frame(width: size, height: size)
            .overlay {
                avatarContent
                    .clipShape(.circle)
                    .padding(3)
            }
    }

    @ViewBuilder
    private var avatarContent: some View {
        if let urlString = avatarURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    initialsPlaceholder
                }
            }
        } else {
            initialsPlaceholder
        }
    }

    private var initialsPlaceholder: some View {
        Color.accentSubtle
            .overlay {
                Text(initials)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.inkPrimary)
            }
    }

    private var editBadge: some View {
        Button(action: onEditTap) {
            Image(systemName: "pencil")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.accent)
                .clipShape(.circle)
                .overlay {
                    Circle().stroke(Color.background, lineWidth: 2)
                }
        }
        .accessibilityLabel("Edit profile photo")
    }
}

#Preview {
    ProfileAvatarView(avatarURL: nil, initials: "SL") {}
        .padding()
        .background(Color.background)
}
