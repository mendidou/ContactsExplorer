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
    private(set) var state: LoadState

    private let service: ContactsService

    init(
        service: ContactsService,
        contacts: [Contact] = [],
        state: LoadState = .idle
    ) {
        self.service = service
        self.contacts = contacts
        self.state = state
    }

    func load() async {
        if contacts.isEmpty {
            state = .loading
        }
        do {
            contacts = try await service.fetchContacts()
            state = .loaded
        } catch ContactsAccessError.denied {
            state = .permissionDenied
        } catch {
            Logger.contacts.error("Loading contacts failed: \(String(describing: error))")
            if contacts.isEmpty {
                state = .failed
            }
        }
    }
}
