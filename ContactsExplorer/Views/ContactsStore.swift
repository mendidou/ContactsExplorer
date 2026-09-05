//
//  ContactsStore.swift
//  ContactsExplorer
//
//  Created by Shai Balassiano on 17/08/2026.
//

import Contacts
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
            // Step 2: request permission from the user
            guard try await requestAccessIfNeeded() else {
                state = .permissionDenied
                return
            }
            // Step 3: fetch the contacts from the device
            let keysToFetch: [CNKeyDescriptor] = [
                CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactOrganizationNameKey as CNKeyDescriptor,
                CNContactPhoneNumbersKey as CNKeyDescriptor,
                CNContactEmailAddressesKey as CNKeyDescriptor,
                CNContactBirthdayKey as CNKeyDescriptor,
                CNContactThumbnailImageDataKey as CNKeyDescriptor
            ]
            let request = CNContactFetchRequest(keysToFetch: keysToFetch)
            request.sortOrder = .userDefault
            var fetchedContacts: [Contact] = []
            try CNContactStore().enumerateContacts(with: request) { cnContact, _ in
                fetchedContacts.append(Contact(cnContact))
            }
            contacts = fetchedContacts
            // Step 4: update the UI state
            state = .loaded
        } catch {
            logger.error("Loading contacts failed: \(String(describing: error))")
            if contacts.isEmpty {
                state = .failed
            }
        }
    }

    private func requestAccessIfNeeded() async throws -> Bool {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized, .limited:
            true
        case .notDetermined:
            try await CNContactStore().requestAccess(for: .contacts)
        case .denied, .restricted:
            false
        @unknown default:
            false
        }
    }
}
