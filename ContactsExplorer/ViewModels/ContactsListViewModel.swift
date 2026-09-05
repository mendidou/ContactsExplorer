//
//  ContactsListViewModel.swift
//  ContactsExplorer
//
//  Created by Shai Balassiano on 17/08/2026.
//

import Foundation
import os

@Observable
final class ContactsListViewModel {
    enum LoadState {
        case idle
        case loading
        case loaded
        case permissionDenied
        case failed
    }

    private(set) var contacts: [Contact]
    private(set) var loadState: LoadState

    var searchText = ""

    /// Read by the detail screen rather than copied into it: the debug menu swaps this at
    /// runtime, and a copy would go on querying the real address book after the swap.
    private(set) var contactsService: ContactsService

    init(
        service: ContactsService,
        contacts: [Contact] = [],
        loadState: LoadState = .idle
    ) {
        self.contactsService = service
        self.contacts = contacts
        self.loadState = loadState
    }

    func load() async {
        if contacts.isEmpty {
            loadState = .loading
        }
        do {
            contacts = try await contactsService.fetchContacts()
            loadState = .loaded
        } catch ContactsAccessError.denied {
            loadState = .permissionDenied
        } catch {
            Logger.contacts.error("Loading contacts failed: \(String(describing: error))")
            loadState = .failed
        }
    }

    // MARK: - Search

    var filteredContacts: [Contact] {
        let query = trimmedSearchText
        guard !query.isEmpty else { return contacts }
        return contacts.filter { matches(contact: $0, query: query) }
    }

    var isSearchActive: Bool {
        !trimmedSearchText.isEmpty
    }

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespaces)
    }

    private func matches(contact: Contact, query: String) -> Bool {
        if contact.displayName.localizedStandardContains(query) {
            return true
        }
        guard isPhoneNumber(query: query) else {
            return false
        }
        let queryDigits = query.filter(\.isWholeNumber)
        return contact.phoneNumbers.contains { $0.value.filter(\.isWholeNumber).contains(queryDigits) }
    }

    private func isPhoneNumber(query: String) -> Bool {
        query.contains(where: \.isWholeNumber) &&
            query.allSatisfy { $0.isWholeNumber || "+-(). ".contains($0) }
    }
}

#if DEBUG
/// Kept in the same file because `contactsService` is `private(set)`: only this file may write it.
extension ContactsListViewModel {
    func useService(_ service: ContactsService) async {
        contactsService = service
        contacts = []
        await load()
    }
}
#endif
