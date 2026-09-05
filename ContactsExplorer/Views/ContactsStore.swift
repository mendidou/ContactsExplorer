//
//  ContactsStore.swift
//  ContactsExplorer
//
//  Created by Shai Balassiano on 17/08/2026.
//

import Foundation
import os

private let logger = Logger(subsystem: "com.shaibalassiano.ContactsExplorer", category: "ContactsStore")

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

    private let service = ContactsService()

    init(
        contacts: [Contact] = [],
        state: LoadState = .idle
    ) {
        self.contacts = contacts
        self.state = state
    }

    func load() async {
        if contacts.isEmpty {
            state = .loading
            //TODO Mendy : show a message if empty
        }
        do {
            contacts = try await service.fetchContacts()
            state = .loaded
        } catch ContactsAccessError.denied {
            state = .permissionDenied
        } catch {
            logger.error("Loading contacts failed: \(String(describing: error))")
            if contacts.isEmpty {
                state = .failed
            }
        }
    }
}
