//
//  MainTabView.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: AppTab = .discover
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Discover", systemImage: "map.fill", value: AppTab.discover) {
                DiscoverView()
            }
            
            Tab("My Clubs", systemImage: "books.vertical.fill", value: AppTab.myClubs) {
                NavigationStack {
                    MyClubsView()
                }
            }
            
            Tab("Meetings", systemImage: "calendar", value: AppTab.meetings) {
                NavigationStack {
                    MeetingsView()
                }
            }
            
            Tab("Profile", systemImage: "person.fill", value: AppTab.profile) {
                NavigationStack {
                    ProfileView()
                }
            }
        }
        .tint(.accent)
        .toolbarBackground(Color.cardBackground, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .task {
            await NotificationService.shared.requestPermission()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                selectedTab = .discover
            }
        }
    }
}

enum AppTab: Hashable {
    case discover, myClubs, meetings, profile
}

#Preview {
    MainTabView().environment(AuthViewModel())
}
