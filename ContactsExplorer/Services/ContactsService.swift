//
//  ContactsService.swift
//  ContactsExplorer
//

import Contacts
import Foundation

enum ContactsAccessError: Error {
    case denied
}

final class ContactsService {
    
    @concurrent
    func fetchContacts() async throws -> [Contact] {
        guard try await requestAccessIfNeeded() else {
            throw ContactsAccessError.denied
        }

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
