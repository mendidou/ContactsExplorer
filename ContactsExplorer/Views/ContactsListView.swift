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
            guard store.loadState == .idle else { return }
            await store.load()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.loadState {
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
        let results = store.filteredContacts
        return List(results) { contact in
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
        .searchable(text: $store.searchText, prompt: "Name or phone number")
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .overlay {
            if results.isEmpty && store.isSearchActive {
                ContentUnavailableView.search(text: store.searchText)
            }
        }
        .refreshable {
            await store.load()
        }
    }

}

