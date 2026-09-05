//
//  ContactDetailView.swift
//  ContactsExplorer
//
//  Created by Shai Balassiano on 17/08/2026.
//

import SwiftUI
import os

private let logger = Logger(subsystem: "com.shaibalassiano.ContactsExplorer", category: "ContactDetailView")

struct ContactDetailView: View {
    let contact: Contact
    let favorites: FavoritesManager
    let service: ContactsService
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

    private func loadFullImage() async {
        do {
            fullImageData = try await service.fullImageData(for: contact.id)
        } catch {
            logger.error("Loading contact image failed: \(String(describing: error))")
        }
    }
}
