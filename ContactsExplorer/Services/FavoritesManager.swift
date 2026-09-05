//
//  FavoritesManager.swift
//  ContactsExplorer
//
//  Created by Shai Balassiano on 17/08/2026.
//

import Foundation

/// Where the favorites are read from and written to. Injected so the store can be
/// exercised without touching `UserDefaults`.
struct FavoritesStorage: Sendable {
    var load: @Sendable () -> Set<String>
    var save: @Sendable (Set<String>) -> Void
}

extension FavoritesStorage {
    private nonisolated static let key = "favoriteContactIDs"

    static let userDefaults = FavoritesStorage(
        load: { Set(UserDefaults.standard.stringArray(forKey: key) ?? []) },
        save: { UserDefaults.standard.set(Array($0), forKey: key) }
    )
}

/// Stays a class: it holds state the screens observe, and both of them must see the
/// same instance for the star to stay in sync.
@Observable
final class FavoritesManager {
    private var ids: Set<String>

    private let storage: FavoritesStorage

    init(storage: FavoritesStorage = .userDefaults) {
        self.storage = storage
        ids = storage.load()
    }

    func toggle(_ contactID: String) {
        if ids.contains(contactID) {
            ids.remove(contactID)
        } else {
            ids.insert(contactID)
        }
        storage.save(ids)
    }

    func contains(_ contactID: String) -> Bool {
        ids.contains(contactID)
    }
}
