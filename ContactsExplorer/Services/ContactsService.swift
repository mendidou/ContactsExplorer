//
//  ContactsService.swift
//  ContactsExplorer
//

import Contacts
import Foundation

/// Separate from a read failure so callers can map it to its own screen state.
enum ContactsAccessError: Error {
    case denied
}

/// The only type in the project allowed to reach for `CNContactStore`.
final class ContactsService {
    func fetchContacts() async throws -> [Contact] {
        guard try await requestAccessIfNeeded() else {
            throw ContactsAccessError.denied
        }
        // A CNContact is only partially loaded: reading a key that is not listed here
        // raises CNContactPropertyNotFetchedException, which `try` does not catch.
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
        return fetchedContacts
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
