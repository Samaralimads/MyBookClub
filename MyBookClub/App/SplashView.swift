//
//  SplashView.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: Spacing.lg) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.accent)
                Text("MyBookClub")
                    .font(.appTitle)
                    .foregroundColor(.inkPrimary)
                ProgressView()
                    .tint(.accent)
            }
        }
    }
}

#Preview {
    SplashView()
}
