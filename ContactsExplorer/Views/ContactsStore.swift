//
//  ContactsStore.swift
//  ContactsExplorer
//
//  Created by Shai Balassiano on 17/08/2026.
//

import Foundation
import os

@Observable
final class ContactsStore {
    enum LoadState {
        case idle
        case loading
        case loaded
        case permissionDenied
        case failed
    }

    private(set) var contacts: [Contact]
    private(set) var loadState: LoadState

    /// The only property the view is allowed to write: `.searchable` binds to it.
    var searchText = ""

    private let service: ContactsService

    init(
        service: ContactsService,
        contacts: [Contact] = [],
        loadState: LoadState = .idle
    ) {
        self.service = service
        self.contacts = contacts
        self.loadState = loadState
    }

    func load() async {
        if contacts.isEmpty {
            loadState = .loading
        }
        do {
            contacts = try await service.fetchContacts()
            loadState = .loaded
        } catch ContactsAccessError.denied {
            loadState = .permissionDenied
        } catch {
            // A failed refresh surfaces even when contacts are already on screen. Guarding
            // this on `contacts.isEmpty` left the user with a list that silently stopped
            // refreshing, and it made this catch disagree with the `.denied` one above,
            // which never guarded. Losing the displayed list on a transient error is the
            // cost; the address book is local, so failures here are not transient, and
            // `FailedView` offers a retry.
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

    /// Lets the view tell "no results for a search" from "the address book is empty",
    /// without trimming again or evaluating `filteredContacts` a second time.
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
