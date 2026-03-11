//
//  MainTabView.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: AppTab = .discover

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DiscoverView()
            }
            .tabItem {
                Label("Discover", systemImage: "map.fill")
            }
            .tag(AppTab.discover)

            NavigationStack {
                MyClubsView()
            }
            .tabItem {
                Label("My Clubs", systemImage: "books.vertical.fill")
            }
            .tag(AppTab.myClubs)

            NavigationStack {
                MeetingsView()
            }
            .tabItem {
                Label("Meetings", systemImage: "calendar")
            }
            .tag(AppTab.meetings)

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
            .tag(AppTab.profile)
        }
        .tint(.accent)
        .toolbarBackground(Color.cardBackground, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

enum AppTab: Hashable {
    case discover, myClubs, meetings, profile
}

#Preview {
    MainTabView().environment(AuthViewModel())
}
