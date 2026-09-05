//
//  ContactsListView.swift
//  ContactsExplorer
//
//  Created by Shai Balassiano on 17/08/2026.
//

import SwiftUI

struct ContactsListView: View {
    @State private var store: ContactsStore
    @State private var path: [Contact] = []
    @State private var searchText = ""

    private let favorites: FavoritesManager
    private let service: ContactsService

    init(favorites: FavoritesManager, service: ContactsService) {
        self.favorites = favorites
        self.service = service
        _store = State(wrappedValue: ContactsStore(service: service))
    }

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationTitle("Contacts")
                .navigationDestination(for: Contact.self) { contact in
                    ContactDetailView(contact: contact, favorites: favorites, service: service)
                }
        }
        .task {
            guard store.state == .idle else { return }
            await store.load()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.state {
        case .idle, .loading:
            ProgressView("Loading Contacts…")
        case .permissionDenied:
            PermissionDeniedView()
        case .failed:
            FailedView { await store.load() }
        case .loaded:
            contactsList
        }
    }

    private var contactsList: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Name or phone number", text: $searchText)
            }
            .padding(8)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)
            List(filteredContacts) { contact in
                Button {
                    path.append(contact)
                } label: {
                    Row(
                        contact: contact,
                        isFavorite: favorites.contains(contact.id),
                        onToggleFavorite: { favorites.toggle(contact.id) }
                    )
                }
                .buttonStyle(.plain)
            }
            .overlay {
                if hasNoSearchResults {
                    ContentUnavailableView.search(text: searchText)
                }
            }
            .refreshable {
                await store.load()
            }
        }
    }

    // MARK: - Search Logic

    private var filteredContacts: [Contact] {
        let query = trimmedSearchText
        guard !query.isEmpty else { return store.contacts }
        return store.contacts.filter { matches(contact: $0, query: query) }
    }

    private var hasNoSearchResults: Bool {
        !trimmedSearchText.isEmpty && filteredContacts.isEmpty
    }

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespaces)
    }

    private func matches(contact: Contact, query: String) -> Bool {
        print("DEBUG: checking if '\(contact.displayName)' matches query '\(query)'")
        if contact.displayName.localizedCaseInsensitiveContains(query) {
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

