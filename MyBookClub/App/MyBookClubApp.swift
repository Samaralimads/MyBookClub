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
                .task {
                    await authVM.startListening()
                }
        }
    }
}
