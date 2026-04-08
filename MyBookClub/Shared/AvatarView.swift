//
//  AvatarView.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 07/04/2026.
//

import SwiftUI

struct AvatarView: View {
    let url: URL?
    let size: CGFloat
    var strokeColor: Color = .clear
    var strokeWidth: CGFloat = 0

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    placeholder
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(.circle)
        .overlay { Circle().stroke(strokeColor, lineWidth: strokeWidth) }
    }

    private var placeholder: some View {
        Circle()
            .fill(Color.purpleTint)
            .overlay {
                Image(systemName: "person.fill")
                    .foregroundStyle(.accent)
                    .font(.system(size: size * 0.4))
            }
    }
}

// MARK: - Convenience initialisers

extension AvatarView {
    /// Init from an AppUser
    init(user: AppUser?, size: CGFloat, strokeColor: Color = .clear, strokeWidth: CGFloat = 0) {
        self.url = user?.avatarURL.flatMap { URL(string: $0) }
        self.size = size
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
    }

    /// Init from a URL string
    init(urlString: String?, size: CGFloat, strokeColor: Color = .clear, strokeWidth: CGFloat = 0) {
        self.url = urlString.flatMap { URL(string: $0) }
        self.size = size
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
    }
}
