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
            Tab("Discover", systemImage: "map.fill", value: AppTab.discover) {
                NavigationStack {
                    DiscoverView()
                }
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
    }
}

enum AppTab: Hashable {
    case discover, myClubs, meetings, profile
}

#Preview {
    MainTabView()
}
