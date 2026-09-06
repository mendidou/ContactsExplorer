//
//  MockContacts.swift
//  ContactsExplorer
//

#if DEBUG
import SwiftUI

/// Contacts that never came from the address book. Two jobs, deliberately kept in one place
/// because they share the same building blocks: named fixtures the tests compare against, and
/// throwaway volume for exercising the list at a realistic size.
enum MockContacts {

    // MARK: - Fixtures

    private static func complete() -> Contact {
        Contact(
            id: "contact-emma",
            givenName: "Emma",
            familyName: "Stone",
            fullName: "Emma Stone",
            organizationName: "",
            phoneNumbers: [
                Contact.LabeledValue(label: "mobile", value: "+972 54-123-4567"),
                Contact.LabeledValue(label: "work", value: "03-612-3456")
            ],
            emails: [
                Contact.LabeledValue(label: "home", value: "emma@example.com"),
                Contact.LabeledValue(label: "work", value: "emma.stone@example.com")
            ],
            birthday: date(year: 1988, month: 11, day: 6),
            thumbnailData: image(color: .systemIndigo)
        )
    }

    /// A name and nothing else: no phone, no email, no birthday, no photo.
    private static func minimal() -> Contact {
        Contact(
            id: "contact-maya",
            givenName: "Maya",
            familyName: "Levi",
            fullName: "Maya Levi",
            organizationName: "",
            phoneNumbers: [],
            emails: [],
            birthday: nil,
            thumbnailData: nil
        )
    }


    static func fixtures() -> [Contact] {
        [
            complete(),
            Contact(
                id: "contact-james",
                givenName: "James",
                familyName: "Chen",
                fullName: "James Chen",
                organizationName: "",
                phoneNumbers: [Contact.LabeledValue(label: "mobile", value: "(212) 555-0187")],
                emails: [Contact.LabeledValue(label: "work", value: "james.chen@example.com")],
                birthday: date(year: 1990, month: 3, day: 14),
                thumbnailData: nil
            ),
            // Diacritics on both names: the search must find this one from plain ASCII.
            Contact(
                id: "contact-jerome",
                givenName: "Jérôme",
                familyName: "Müller",
                fullName: "Jérôme Müller",
                organizationName: "",
                phoneNumbers: [Contact.LabeledValue(label: "mobile", value: "04-987-6543")],
                emails: [Contact.LabeledValue(label: "work", value: "jerome.muller@example.com")],
                birthday: date(year: 1979, month: 7, day: 22),
                thumbnailData: nil
            ),
            minimal(),
            Contact(
                id: "contact-noah",
                givenName: "Noah",
                familyName: "Davis",
                fullName: "Noah Davis",
                organizationName: "",
                phoneNumbers: [],
                emails: [Contact.LabeledValue(label: "home", value: "noah.davis@example.com")],
                birthday: nil,
                thumbnailData: nil
            ),
            Contact(
                id: "contact-olivia",
                givenName: "Olivia",
                familyName: "",
                fullName: "Olivia",
                organizationName: "",
                phoneNumbers: [Contact.LabeledValue(label: "mobile", value: "052-876-5432")],
                emails: [],
                birthday: nil,
                thumbnailData: image(color: .systemTeal)
            ),
            Contact(
                id: "contact-pizza",
                givenName: "",
                familyName: "",
                fullName: "",
                organizationName: "Pizza Palace",
                phoneNumbers: [Contact.LabeledValue(label: "main", value: "09-765-4321")],
                emails: [],
                birthday: nil,
                thumbnailData: nil
            ),
            Contact(
                id: "contact-unknown",
                givenName: "",
                familyName: "",
                fullName: "",
                organizationName: "",
                phoneNumbers: [Contact.LabeledValue(label: "mobile", value: "058-112-2334")],
                emails: [],
                birthday: nil,
                thumbnailData: nil
            )
        ]
    }

    // MARK: - Volume
    struct Batch: Sendable {
        var contacts: [Contact] = []
        var fullImages: [String: Data] = [:]

        mutating func append(_ other: Batch) {
            contacts += other.contacts
            fullImages.merge(other.fullImages) { _, new in new }
        }
    }

    static func random(count: Int) -> Batch {
        let photos = photoPalette()
        var batch = Batch()
        for _ in 0..<count {
            let photo = roll(percent: 60) ? photos[Int.random(in: 0..<photos.count)] : nil
            let contact = randomContact(thumbnailData: photo?.thumbnail)
            batch.contacts.append(contact)
            if let photo {
                batch.fullImages[contact.id] = photo.full
            }
        }
        return batch
    }

    private static func randomContact(thumbnailData: Data?) -> Contact {
        let givenName: String
        let familyName: String
        let organizationName: String
        if roll(percent: 10) {
            givenName = ""
            familyName = ""
            organizationName = pick(organizations)
        } else {
            givenName = pick(givenNames)
            familyName = pick(familyNames)
            organizationName = ""
        }
        let fullName = "\(givenName) \(familyName)".trimmingCharacters(in: .whitespaces)

        return Contact(
            id: UUID().uuidString,
            givenName: givenName,
            familyName: familyName,
            fullName: fullName,
            organizationName: organizationName,
            phoneNumbers: randomPhoneNumbers(),
            emails: randomEmails(for: fullName.isEmpty ? organizationName : fullName),
            birthday: randomBirthday(),
            thumbnailData: thumbnailData
        )
    }

    private static func randomPhoneNumbers() -> [Contact.LabeledValue] {
        let labels = ["mobile", "work", "home"].shuffled()
        return (0..<Int.random(in: 1...2)).map { index in
            Contact.LabeledValue(label: labels[index], value: randomPhoneNumber())
        }
    }

    private static func randomPhoneNumber() -> String {
        let format = pick(["+972 5#-###-####", "0#-###-####", "(###) ###-####", "05########"])
        return String(format.map { $0 == "#" ? Character(String(Int.random(in: 0...9))) : $0 })
    }

    private static func randomEmails(for name: String) -> [Contact.LabeledValue] {
        guard roll(percent: 70) else { return [] }
        let handle = name
            .folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(of: " ", with: ".")
            .lowercased()
        return [Contact.LabeledValue(label: "home", value: "\(handle)@example.com")]
    }

    /// A birthday without a year is legal in Contacts, and it is the case the detail screen
    /// gets wrong today, so the generated set deliberately contains some.
    private static func randomBirthday() -> Date? {
        guard roll(percent: 60) else { return nil }
        var components = DateComponents()
        components.month = Int.random(in: 1...12)
        components.day = Int.random(in: 1...28)
        if roll(percent: 60) {
            components.year = Int.random(in: 1950...2005)
        }
        return Calendar.current.date(from: components)
    }

    // MARK: - Building blocks

    private typealias Photo = (thumbnail: Data, full: Data)

    /// Rendered once per batch and shared by every contact that gets a photo: a
    /// `UIGraphicsImageRenderer` pass per generated contact would stall the main actor.
    private static func photoPalette() -> [Photo] {
        [UIColor.systemIndigo, .systemTeal, .systemPink, .systemOrange].compactMap { color in
            guard let thumbnail = image(color: color),
                  let full = image(color: color, side: 800) else {
                return nil
            }
            return (thumbnail, full)
        }
    }

    private static func image(color: UIColor, side: CGFloat = 240) -> Data? {
        let size = CGSize(width: side, height: side)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }.pngData()
    }

    private static func date(year: Int, month: Int, day: Int) -> Date? {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day))
    }

    private static func roll(percent: Int) -> Bool {
        Int.random(in: 0..<100) < percent
    }

    private static func pick(_ values: [String]) -> String {
        values[Int.random(in: 0..<values.count)]
    }

    private static let givenNames = [
        "Emma", "James", "Maya", "Noah", "Olivia", "Liam", "Ava", "Ethan",
        "José", "Zoë", "Émile", "Chloé", "Björn", "Anaïs", "Søren", "Renée",
        "Yosef", "Tamar", "Amir", "Noa"
    ]

    private static let familyNames = [
        "Stone", "Chen", "Levi", "Davis", "Cohen", "García", "Müller", "O'Neill",
        "Dubois", "Rossi", "Nakamura", "Abadi", "Mizrahi", "Fitzgerald", "Ben-David"
    ]

    private static let organizations = [
        "Pizza Palace", "Café Central", "Blue Ridge Dental", "Hôtel du Parc",
        "Northwind Logistics", "Studio Nine", "Le Petit Marché"
    ]
}

extension ContactsService {
    static func serving(_ batch: MockContacts.Batch) -> ContactsService {
        ContactsService(
            fetchContacts: { batch.contacts },
            fullImageData: { batch.fullImages[$0] }
        )
    }
}
#endif
