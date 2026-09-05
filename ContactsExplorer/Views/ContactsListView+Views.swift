//
//  ContactsListView+Views.swift
//  ContactsExplorer
//

import SwiftUI
import UIKit


extension ContactsListView {
    struct Row: View {
        let contact: Contact
        let isFavorite: Bool
        let onToggleFavorite: () -> Void

        var body: some View {
            HStack(spacing: 12) {
                ContactAvatarView(contact: contact, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(contact.displayName)
                    if let phoneNumber = contact.phoneNumbers.first {
                        Text(phoneNumber.value)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                FavoriteButton(isFavorite: isFavorite, action: onToggleFavorite)
                    .buttonStyle(.borderless)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(.rect)
        }
    }

    struct PermissionDeniedView: View {
        @Environment(\.openURL) private var openURL

        var body: some View {
            ContentUnavailableView {
                Label("No Access to Contacts", systemImage: "lock")
            } description: {
                Text("Allow access to your contacts in Settings to see them here.")
            } actions: {
                Button("Open Settings") {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    openURL(url)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    struct FailedView: View {
        let onRetry: () async -> Void

        var body: some View {
            ContentUnavailableView {
                Label("Something Went Wrong", systemImage: "exclamationmark.triangle")
            } description: {
                Text("Your contacts could not be loaded. Please try again.")
            } actions: {
                Button("Try Again") {
                    Task { await onRetry() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
