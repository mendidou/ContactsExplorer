//
//  ContactDetailView.swift
//  ContactsExplorer
//
//  Created by Shai Balassiano on 17/08/2026.
//

import Contacts
import SwiftUI
import os

private let logger = Logger(subsystem: "com.shaibalassiano.ContactsExplorer", category: "ContactDetailView")

struct ContactDetailView: View {
    let contact: Contact
    let favorites: FavoritesManager
    @State private var fullImageData: Data?

    var body: some View {
        List {
            HeaderSection(contact: contact, imageData: fullImageData)
            DetailsSection(contact: contact)
            InfoSection(contact: contact)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                FavoriteToolbarButton(contactID: contact.id, favorites: favorites)
            }
        }
        .task {
            await loadFullImage()
        }
    }

    // TODO: consider moving this into a manager
    private func loadFullImage() async {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        guard status == .authorized || status == .limited else { return }
        do {
            let keysToFetch = [CNContactImageDataKey as CNKeyDescriptor]
            let cnContact = try CNContactStore().unifiedContact(withIdentifier: contact.id, keysToFetch: keysToFetch)
            fullImageData = cnContact.imageData
        } catch {
            logger.error("Loading contact image failed: \(String(describing: error))")
        }
    }
}
