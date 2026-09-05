//
//  ContactsExplorerApp.swift
//  ContactsExplorer
//
//  Created by Shai Balassiano on 17/08/2026.
//

import SwiftUI

@main
struct ContactsExplorerApp: App {
    @State private var favorites = FavoritesManager()

    var body: some Scene {
        WindowGroup {
            ContactsListView(favorites: favorites)
        }
    }
}
