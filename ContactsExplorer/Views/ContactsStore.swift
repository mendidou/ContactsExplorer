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
            Logger.contacts.error("Loading contacts failed: \(String(describing: error))")
            if contacts.isEmpty {
                loadState = .failed
            }
        }
    }
}
