//
//  ContactsListView+LimitedAccess.swift
//  ContactsExplorer
//

import Contacts
import ContactsUI
import SwiftUI

extension ContactsListView {

    struct LimitedAccessBanner: View {
        let onSelectionChanged: () async -> Void

        @State private var isPresentingPicker = false

        var body: some View {
            if CNContactStore.authorizationStatus(for: .contacts) == .limited {
                banner
            }
        }

        private var banner: some View {
            HStack(spacing: 12) {
                Image(systemName: "person.2.badge.gearshape")
                    .foregroundStyle(.secondary)

                Text("You're sharing only some of your contacts.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 8)

                Button("Manage") { isPresentingPicker = true }
                    .font(.footnote.weight(.semibold))
                    .buttonStyle(.borderless)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.thinMaterial)
            .contactAccessPicker(isPresented: $isPresentingPicker) { addedIdentifiers in
                guard !addedIdentifiers.isEmpty else { return }
                Task { await onSelectionChanged() }
            }
        }
    }
}
