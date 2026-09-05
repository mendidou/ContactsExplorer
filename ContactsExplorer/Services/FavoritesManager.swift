//
//  FavoritesManager.swift
//  ContactsExplorer
//
//  Created by Shai Balassiano on 17/08/2026.
//

import Foundation

@Observable
final class FavoritesManager {
    private enum Key: String {
        case favoriteContactIDs
    }

    private(set) var ids: Set<String>

    init() {
        ids = Set(UserDefaults.standard.stringArray(forKey: Key.favoriteContactIDs.rawValue) ?? [])
    }

    func toggle(_ contactID: String) {
        if ids.contains(contactID) {
            ids.remove(contactID)
        } else {
            ids.insert(contactID)
        }
        persist()
    }

    func contains(_ contactID: String) -> Bool {
        ids.contains(contactID)
    }

    private func persist() {
        UserDefaults.standard.set(Array(ids), forKey: Key.favoriteContactIDs.rawValue)
    }
}
