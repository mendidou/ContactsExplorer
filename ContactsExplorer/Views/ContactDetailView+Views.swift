//
//  ContactDetailView+Views.swift
//  ContactsExplorer
//

import SwiftUI


extension ContactDetailView {

    struct HeaderSection: View {
        let contact: Contact
        let imageData: Data?

        var body: some View {
            Section {
                VStack(spacing: 12) {
                    ContactAvatarView(contact: contact, imageData: imageData, size: 120)
                    Text(contact.displayName)
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
            .listRowBackground(Color.clear)
        }
    }

    struct DetailsSection: View {
        let contact: Contact

        var body: some View {
            if contact.phoneNumbers.isEmpty && contact.emails.isEmpty {
                Section {
                    Text("This contact has no phone numbers or emails.")
                        .foregroundStyle(.secondary)
                }
            } else {
                if !contact.phoneNumbers.isEmpty {
                    Section("Phone Numbers") {
                        ForEach(contact.phoneNumbers) { phoneNumber in
                            LabeledContent(phoneNumber.label, value: phoneNumber.value)
                        }
                    }
                }
                if !contact.emails.isEmpty {
                    Section("Emails") {
                        ForEach(contact.emails) { email in
                            LabeledContent(email.label, value: email.value)
                        }
                    }
                }
            }
        }
    }

    struct InfoSection: View {
        let contact: Contact

        var body: some View {
            if !contact.organizationName.isEmpty || contact.birthday != nil {
                Section {
                    if !contact.organizationName.isEmpty {
                        row(label: "Organization", value: contact.organizationName)
                    }
                    if let birthday = contact.birthday {
                        row(label: "Birthday", value: birthday.formatted(date: .long, time: .omitted))
                    }
                } header: {
                    Text("Info")
                        .font(.subheadline)
                }
            }
        }

        private func row(label: String, value: String) -> some View {
            HStack {
                Text(label)
                Spacer()
                Text(value)
                    .foregroundStyle(.secondary)
            }
            .font(.callout)
        }
    }

    struct FavoriteToolbarButton: View {
        let contactID: String
        let favorites: FavoritesManager

        var body: some View {
            FavoriteButton(
                isFavorite: favorites.contains(contactID),
                action: { favorites.toggle(contactID) }
            )
        }
    }
}
