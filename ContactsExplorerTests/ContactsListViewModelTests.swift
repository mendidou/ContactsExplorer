//
//  ContactsListViewModelTests.swift
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
struct ContactsListViewModelLoadingTests {
    @Test("Starts idle and ends loaded")
    func loadsContacts() async {
        let viewModel = ContactsListViewModel(service: .returning(MockContacts.fixtures()))
        #expect(viewModel.loadState == .idle)

        await viewModel.load()

        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.contacts.count == MockContacts.fixtures().count)
    }

    @Test("A denied authorization is not a failure")
    func deniedAccess() async {
        let viewModel = ContactsListViewModel(service: .failing(with: ContactsAccessError.denied))

        await viewModel.load()

        #expect(viewModel.loadState == .permissionDenied)
        #expect(viewModel.contacts.isEmpty)
    }

    @Test("Any other error fails the screen")
    func otherErrorFails() async {
        struct Boom: Error {}
        let viewModel = ContactsListViewModel(service: .failing(with: Boom()))

        await viewModel.load()

        #expect(viewModel.loadState == .failed)
    }

    @Test("A failed reload surfaces the error even with contacts already on screen")
    func failedReloadSurfaces() async {
        struct Boom: Error {}
        let viewModel = ContactsListViewModel(
            service: .failing(with: Boom()),
            contacts: MockContacts.fixtures(),
            loadState: .loaded
        )

        await viewModel.load()

        #expect(viewModel.loadState == .failed, "a list that silently stops refreshing is worse")
        #expect(viewModel.contacts.isEmpty == false, "the fetched value is only assigned on success")
    }
}

@Suite("Searching contacts")
struct ContactsListViewModelSearchTests {
    private func loadedViewModel() -> ContactsListViewModel {
        ContactsListViewModel(
            service: .returning([]),
            contacts: MockContacts.fixtures(),
            loadState: .loaded
        )
    }

    @Test("An empty query returns everything")
    func emptyQuery() {
        let viewModel = loadedViewModel()
        #expect(viewModel.filteredContacts.count == MockContacts.fixtures().count)
        #expect(viewModel.isSearchActive == false)
    }

    @Test("Whitespace only is not a search")
    func whitespaceOnly() {
        let viewModel = loadedViewModel()
        viewModel.searchText = "   "
        #expect(viewModel.filteredContacts.count == MockContacts.fixtures().count)
        #expect(viewModel.isSearchActive == false)
    }

    @Test("Matches a name whatever the case")
    func matchesName() {
        let viewModel = loadedViewModel()
        viewModel.searchText = "emma"
        #expect(viewModel.filteredContacts.map(\.displayName) == ["Emma Stone"])
    }

    @Test("Matches a name typed without its diacritics")
    func matchesIgnoringDiacritics() {
        let viewModel = loadedViewModel()
        viewModel.searchText = "jerome mul"
        #expect(viewModel.filteredContacts.map(\.displayName) == ["Jérôme Müller"])
    }

    /// The name test is a substring search, so it holds the word order. Pinned here because
    /// the fix for it is a product decision, not an oversight.
    @Test("Does not match a name whose words are reversed")
    func doesNotMatchReversedWords() {
        let viewModel = loadedViewModel()
        viewModel.searchText = "muller jerome"
        #expect(viewModel.filteredContacts.isEmpty)
    }

    @Test("Matches an organization when the contact has no name")
    func matchesOrganization() {
        let viewModel = loadedViewModel()
        viewModel.searchText = "pizza"
        #expect(viewModel.filteredContacts.map(\.displayName) == ["Pizza Palace"])
    }

    @Test("Matches a phone number typed without its separators")
    func matchesPhoneNumber() {
        let viewModel = loadedViewModel()
        viewModel.searchText = "541234567"
        #expect(viewModel.filteredContacts.map(\.displayName) == ["Emma Stone"])
    }

    @Test("Matches a phone number typed with spaces")
    func matchesPhoneNumberWithSpaces() {
        let viewModel = loadedViewModel()
        viewModel.searchText = "212 555 0187"
        #expect(viewModel.filteredContacts.map(\.displayName) == ["James Chen"])
    }

    @Test("A query with no match returns nothing, and says a search is running")
    func noMatch() {
        let viewModel = loadedViewModel()
        viewModel.searchText = "zzz"
        #expect(viewModel.filteredContacts.isEmpty)
        #expect(viewModel.isSearchActive)
    }
}
