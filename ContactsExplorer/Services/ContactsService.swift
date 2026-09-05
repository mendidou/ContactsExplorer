//
//  ContactsService.swift
//  ContactsExplorer
//

import Contacts
import Foundation

enum ContactsAccessError: Error {
    case denied
}

struct ContactsService: Sendable {
    var fetchContacts: @Sendable () async throws -> [Contact]
    var fullImageData: @Sendable (_ contactID: String) async throws -> Data?
}

extension ContactsService {
    static let live = ContactsService(
        fetchContacts: { @concurrent in
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
        },
        fullImageData: { @concurrent contactID in
            guard try await requestAccessIfNeeded() else {
                throw ContactsAccessError.denied
            }
            let keysToFetch = [CNContactImageDataKey as CNKeyDescriptor]
            return try CNContactStore()
                .unifiedContact(withIdentifier: contactID, keysToFetch: keysToFetch)
                .imageData
        }
    )
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
