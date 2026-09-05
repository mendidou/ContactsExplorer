//
//  DebugMenu.swift
//  ContactsExplorer
//

#if DEBUG
import SwiftUI

struct DebugMenu: View {
    let viewModel: ContactsListViewModel

    @State private var servedBatch: MockContacts.Batch?

    var body: some View {
        Menu {
            Button {
                var batch = servedBatch ?? MockContacts.Batch()
                batch.append(MockContacts.random(count: 100))
                serve(batch)
            } label: {
                Label("Add 100 mock contacts", systemImage: "person.badge.plus")
            }

            Button(role: .destructive) {
                serve(MockContacts.Batch())
            } label: {
                Label("Delete all", systemImage: "trash")
            }

            if servedBatch != nil {
                Divider()
                Button {
                    servedBatch = nil
                    // Restores `.live` rather than whatever was injected: this menu is the only
                    // thing that ever swaps the service, so the two are the same in practice.
                    Task { await viewModel.useService(.live) }
                } label: {
                    Label("Back to real contacts", systemImage: "arrow.uturn.backward")
                }
            }
        } label: {
            Image(systemName: "ladybug")
        }
    }

    private func serve(_ batch: MockContacts.Batch) {
        servedBatch = batch
        Task { await viewModel.useService(.serving(batch)) }
    }
}
#endif
