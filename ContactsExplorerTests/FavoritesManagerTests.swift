//
//  FavoritesManagerTests.swift
//  ContactsExplorerTests
//

import Foundation
import Testing
@testable import ContactsExplorer

/// Stands in for UserDefaults. `saved` records what was written, so the tests can check
/// that a change is persisted rather than only held in memory.
private nonisolated final class StorageSpy: @unchecked Sendable {
    private(set) var saved: [Set<String>] = []
    private var current: Set<String>

    init(initial: Set<String> = []) {
        current = initial
    }

    var storage: FavoritesStorage {
        FavoritesStorage(
            load: { [self] in current },
            save: { [self] ids in
                current = ids
                saved.append(ids)
            }
        )
    }
}

@Suite("Favorites")
struct FavoritesManagerTests {
    @Test("Reads what was already stored")
    func loadsExistingIDs() {
        let spy = StorageSpy(initial: ["contact-emma"])
        let favorites = FavoritesManager(storage: spy.storage)

        #expect(favorites.contains("contact-emma"))
        #expect(favorites.contains("contact-james") == false)
    }

    @Test("Toggling adds, then removes")
    func toggleAddsThenRemoves() {
        let favorites = FavoritesManager(storage: StorageSpy().storage)

        favorites.toggle("contact-emma")
        #expect(favorites.contains("contact-emma"))

        favorites.toggle("contact-emma")
        #expect(favorites.contains("contact-emma") == false)
    }

    @Test("Every toggle is written out, so nothing is lost on relaunch")
    func everyToggleIsPersisted() {
        let spy = StorageSpy()
        let favorites = FavoritesManager(storage: spy.storage)

        favorites.toggle("contact-emma")
        favorites.toggle("contact-james")
        favorites.toggle("contact-emma")

        #expect(spy.saved.count == 3)
        #expect(spy.saved.last == ["contact-james"])
    }

    @Test("A second instance sees what the first one saved")
    func survivesANewInstance() {
        let spy = StorageSpy()
        FavoritesManager(storage: spy.storage).toggle("contact-emma")

        let reopened = FavoritesManager(storage: spy.storage)

        #expect(reopened.contains("contact-emma"))
    }
}
