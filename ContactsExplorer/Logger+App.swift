//
//  Logger+App.swift
//  ContactsExplorer
//

import Foundation
import os

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "ContactsExplorer"

    static let contacts = Logger(subsystem: subsystem, category: "Contacts")
}
