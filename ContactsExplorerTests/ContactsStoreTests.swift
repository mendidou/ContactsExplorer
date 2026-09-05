//
//  ContactsStoreTests.swift
//  ContactsExplorerTests
//

import Foundation
import Testing
@testable import ContactsExplorer

private extension ContactsService {
    static func returning(_ contacts: [Contact]) -> ContactsService {
        ContactsService(fetchContacts: { contacts }, fullImageData: { _ in nil })
    }

    static func failing(with error: Error) -> ContactsService {
        ContactsService(fetchContacts: { throw error }, fullImageData: { _ in nil })
    }
}

@Suite("Loading contacts")
struct ContactsStoreLoadingTests {
    @Test("Starts idle and ends loaded")
    func loadsContacts() async {
        let store = ContactsStore(service: .returning(MockGenerator.contacts()))
        #expect(store.loadState == .idle)

        await store.load()

        #expect(store.loadState == .loaded)
        #expect(store.contacts.count == MockGenerator.contacts().count)
    }

    @Test("A denied authorization is not a failure")
    func deniedAccess() async {
        let store = ContactsStore(service: .failing(with: ContactsAccessError.denied))

        await store.load()

        #expect(store.loadState == .permissionDenied)
        #expect(store.contacts.isEmpty)
    }

    @Test("Any other error fails the screen")
    func otherErrorFails() async {
        struct Boom: Error {}
        let store = ContactsStore(service: .failing(with: Boom()))

        await store.load()

        #expect(store.loadState == .failed)
    }

    @Test("A failed reload surfaces the error even with contacts already on screen")
    func failedReloadSurfaces() async {
        struct Boom: Error {}
        let store = ContactsStore(
            service: .failing(with: Boom()),
            contacts: MockGenerator.contacts(),
            loadState: .loaded
        )

        await store.load()

        #expect(store.loadState == .failed, "a list that silently stops refreshing is worse")
        #expect(store.contacts.isEmpty == false, "the fetched value is only assigned on success")
    }
}

@Suite("Searching contacts")
struct ContactsStoreSearchTests {
    private func loadedStore() -> ContactsStore {
        ContactsStore(
            service: .returning([]),
            contacts: MockGenerator.contacts(),
            loadState: .loaded
        )
    }

    @Test("An empty query returns everything")
    func emptyQuery() {
        let store = loadedStore()
        #expect(store.filteredContacts.count == MockGenerator.contacts().count)
        #expect(store.isSearchActive == false)
    }

    @Test("Whitespace only is not a search")
    func whitespaceOnly() {
        let store = loadedStore()
        store.searchText = "   "
        #expect(store.filteredContacts.count == MockGenerator.contacts().count)
        #expect(store.isSearchActive == false)
    }

    @Test("Matches a name whatever the case")
    func matchesName() {
        let store = loadedStore()
        store.searchText = "emma"
        #expect(store.filteredContacts.map(\.displayName) == ["Emma Stone"])
    }

    @Test("Matches an organization when the contact has no name")
    func matchesOrganization() {
        let store = loadedStore()
        store.searchText = "pizza"
        #expect(store.filteredContacts.map(\.displayName) == ["Pizza Palace"])
    }

    @Test("Matches a phone number typed without its separators")
    func matchesPhoneNumber() {
        let store = loadedStore()
        store.searchText = "541234567"
        #expect(store.filteredContacts.map(\.displayName) == ["Emma Stone"])
    }

    @Test("Matches a phone number typed with spaces")
    func matchesPhoneNumberWithSpaces() {
        let store = loadedStore()
        store.searchText = "212 555 0187"
        #expect(store.filteredContacts.map(\.displayName) == ["James Chen"])
    }

    @Test("A query with no match returns nothing, and says a search is running")
    func noMatch() {
        let store = loadedStore()
        store.searchText = "zzz"
        #expect(store.filteredContacts.isEmpty)
        #expect(store.isSearchActive)
    }
}
