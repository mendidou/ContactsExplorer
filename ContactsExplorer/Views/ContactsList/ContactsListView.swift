//
//  ContactsListView.swift
//  ContactsExplorer
//
//  Created by Shai Balassiano on 17/08/2026.
//

import SwiftUI

struct ContactsListView: View {
    @State private var viewModel: ContactsListViewModel
    @State private var path: [Contact] = []

    private let favoritesManager: FavoritesManager

    init(favoritesManager: FavoritesManager, service: ContactsService) {
        self.favoritesManager = favoritesManager
        _viewModel = State(wrappedValue: ContactsListViewModel(service: service))
    }

    var body: some View {
        NavigationStack(path: $path) {
            content
                .safeAreaInset(edge: .top, spacing: 0) {
                    LimitedAccessBanner { await viewModel.load() }
                }
                .navigationTitle("Contacts")
                .navigationDestination(for: Contact.self) { contact in
                    ContactDetailView(contact: contact, favoritesManager: favoritesManager, service: viewModel.contactsService)
                }
                .debugMenu(for: viewModel)
        }
        .task {
            guard viewModel.loadState == .idle else { return }
            await viewModel.load()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            ProgressView("Loading Contacts…")
        case .permissionDenied:
            PermissionDeniedView()
        case .failed:
            FailedView { await viewModel.load() }
        case .loaded where viewModel.contacts.isEmpty:
            EmptyAddressBookView()
        case .loaded:
            contactsList
        }
    }

    private var contactsList: some View {
        let results = viewModel.filteredContacts
        return List(results) { contact in
            Button {
                path.append(contact)
            } label: {
                Row(
                    contact: contact,
                    isFavorite: favoritesManager.contains(contact.id),
                    onToggleFavorite: { favoritesManager.toggle(contact.id) }
                )
            }
            .buttonStyle(.plain)
        }
        .searchable(text: $viewModel.searchText, prompt: "Name or phone number")
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .overlay {
            if results.isEmpty && viewModel.isSearchActive {
                ContentUnavailableView.search(text: viewModel.searchText)
            }
        }
        .refreshable {
            await viewModel.load()
        }
    }

}

