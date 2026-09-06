//
//  ContactDetailView.swift
//  ContactsExplorer
//
//  Created by Shai Balassiano on 17/08/2026.
//

import SwiftUI
import os

struct ContactDetailView: View {
    let contact: Contact
    let favoritesManager: FavoritesManager
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
                FavoriteToolbarButton(contactID: contact.id, favoritesManager: favoritesManager)
            }
        }
        .task {
            await loadFullImage()
        }
    }

    private func loadFullImage() async {
        do {
            fullImageData = try await service.fullImageData(contact.id)
        } catch {
            Logger.contacts.error("Loading contact image failed: \(String(describing: error))")
        }
    }
}
