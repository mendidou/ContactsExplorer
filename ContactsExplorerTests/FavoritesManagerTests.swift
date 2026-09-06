//
//  FavoritesManagerTests.swift
//  ContactsExplorerTests
//

import Foundation
import Testing
@testable import ContactsExplorer

/// Stands in for UserDefaults. `saved` keeps every write, so a test can tell a change that
/// was persisted from one that was only held in memory — which is the whole point of the
/// favorites surviving a relaunch.
private nonisolated final class TestStorage: @unchecked Sendable {
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
        let testStorage = TestStorage(initial: ["contact-emma"])
        let favoritesManager = FavoritesManager(storage: testStorage.storage)

        #expect(favoritesManager.contains("contact-emma"))
        #expect(favoritesManager.contains("contact-james") == false)
    }

    @Test("Toggling adds, then removes")
    func toggleAddsThenRemoves() {
        let favoritesManager = FavoritesManager(storage: TestStorage().storage)

        favoritesManager.toggle("contact-emma")
        #expect(favoritesManager.contains("contact-emma"))

        favoritesManager.toggle("contact-emma")
        #expect(favoritesManager.contains("contact-emma") == false)
    }

    @Test("Every toggle is written out, so nothing is lost on relaunch")
    func everyToggleIsPersisted() {
        let testStorage = TestStorage()
        let favoritesManager = FavoritesManager(storage: testStorage.storage)

        favoritesManager.toggle("contact-emma")
        favoritesManager.toggle("contact-james")
        favoritesManager.toggle("contact-emma")

        #expect(testStorage.saved.count == 3)
        #expect(testStorage.saved.last == ["contact-james"])
    }

    @Test("A second instance sees what the first one saved")
    func survivesANewInstance() {
        let testStorage = TestStorage()
        FavoritesManager(storage: testStorage.storage).toggle("contact-emma")

        let reopened = FavoritesManager(storage: testStorage.storage)

        #expect(reopened.contains("contact-emma"))
    }
}
