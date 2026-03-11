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
            Color.background.ignoresSafeArea()
            VStack {
                Image("logo")
                    .resizable()
                    .scaledToFit()
                ProgressView()
                    .tint(.accent)
            }
        }
    }
}

#Preview {
    SplashView()
}
