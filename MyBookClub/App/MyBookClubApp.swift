//
//  MyBookClubApp.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import SwiftUI

@main
struct MyBookClubApp: App {
    @State private var authVM = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authVM)
                .preferredColorScheme(.dark)  // Dark mode first by design
                .task {
                    await authVM.startListening()
                }
        }
    }
}
