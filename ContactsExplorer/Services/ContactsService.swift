//
//  ContactsService.swift
//  ContactsExplorer
//

import Contacts
import Foundation

enum ContactsAccessError: Error {
    case denied
}

/// The only type in the project allowed to reach for `CNContactStore`.
final class ContactsService {
    @concurrent
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
        // CNContactStore and CNContactFetchRequest are not Sendable. They are legal inside a
        // @concurrent function only because they never leave it: region isolation sees them as
        // local. Promoting either to a stored property of this service breaks that.
        let request = CNContactFetchRequest(keysToFetch: keysToFetch)
        request.sortOrder = .userDefault
        var fetchedContacts: [Contact] = []
        try CNContactStore().enumerateContacts(with: request) { cnContact, _ in
            fetchedContacts.append(Contact(cnContact))
        }
        return fetchedContacts
    }

    /// Full-size photo, fetched on demand. `Contact.thumbnailData` already carries the small
    /// one, so this is only worth asking for on the detail screen.
    @concurrent
    func fullImageData(for contactID: String) async throws -> Data? {
        guard try await requestAccessIfNeeded() else {
            throw ContactsAccessError.denied
        }
        let keysToFetch = [CNContactImageDataKey as CNKeyDescriptor]
        return try CNContactStore()
            .unifiedContact(withIdentifier: contactID, keysToFetch: keysToFetch)
            .imageData
    }

    @concurrent
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
