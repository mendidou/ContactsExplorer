//
//  View+DebugMenu.swift
//  ContactsExplorer
//

import SwiftUI

extension View {
    /// The one place that knows the debug menu exists only in debug builds. Callers read as a
    /// plain modifier; in a release build this resolves to the view itself.
    func debugMenu(for viewModel: ContactsListViewModel) -> some View {
        #if DEBUG
        toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                DebugMenu(viewModel: viewModel)
            }
        }
        #else
        self
        #endif
    }
}
