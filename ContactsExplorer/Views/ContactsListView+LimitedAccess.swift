//
//  ContactsListView+LimitedAccess.swift
//  ContactsExplorer
//

import Contacts
import ContactsUI
import SwiftUI

extension ContactsListView {
    /// Shown only when the user shared a subset of their address book.
    ///
    /// Without it the app presents a partial list as if it were the whole thing: someone who
    /// shared two contacts searches for a third, finds nothing, and has no way to tell an
    /// empty result from a contact they never shared.
    ///
    /// `contactAccessPicker` is the system sheet for widening that selection, so the user
    /// never has to leave the app for Settings. It reports the identifiers it added, which
    /// is the signal to reload — the fetch itself still returns whatever the system decides
    /// we may see.
    ///
    /// Measured on iOS 26.5 in the simulator: confirming a new selection terminates the app
    /// (no crash report, same behaviour as any other TCC change), so `onSelectionChanged`
    /// never runs there — the next launch picks up the wider selection instead. The reload
    /// is kept because it is the documented contract of the completion handler and the
    /// termination was not verified on a device; if it holds there too, this is dead code.
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
