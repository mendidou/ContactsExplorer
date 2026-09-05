//
//  ContactsStore.swift
//  ContactsExplorer
//
//  Created by Shai Balassiano on 17/08/2026.
//

import Foundation
import os

private let logger = Logger(subsystem: "com.shaibalassiano.ContactsExplorer", category: "ContactsStore")

// CHANGELOG:
// 2026-08-17: initial implementation
// 2026-08-18: added @concurrent so fetching doesn't block the main thread
// 2026-08-19: fixed missing formatter keys crash (code review feedback)
// 2026-08-20: refactored per developer request
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
        // Step 1: show the loading spinner
        if contacts.isEmpty {
            state = .loading
            //TODO Mendy : show a message if empty
        }
        do {
            // Step 2: fetch the contacts from the device (permission included)
            contacts = try await service.fetchContacts()
            // Step 3: update the UI state
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
