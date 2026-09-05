//
//  ContactMappingTests.swift
//  ContactsExplorerTests
//

import Contacts
import Foundation
import Testing
@testable import ContactsExplorer

/// `Contact.init(_ cnContact:)` is the only place the app translates the system's model into
/// its own, and it is where the known birthday defect lives. A `CNMutableContact` is enough to
/// exercise it — nothing here reaches `CNContactStore`, so no device and no permission.
@Suite("Mapping a CNContact")
struct ContactMappingTests {

    @Test("Carries every field across, and builds the full name from the parts")
    func mapsEveryField() {
        let cnContact = CNMutableContact()
        cnContact.givenName = "Jérôme"
        cnContact.familyName = "Müller"
        cnContact.organizationName = "Willow Studio"
        cnContact.phoneNumbers = [
            CNLabeledValue(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: "+972 54-123-4567"))
        ]
        cnContact.emailAddresses = [
            CNLabeledValue(label: CNLabelWork, value: "jerome.muller@example.com")
        ]

        let contact = Contact(cnContact)

        #expect(contact.givenName == "Jérôme")
        #expect(contact.familyName == "Müller")
        #expect(contact.fullName == "Jérôme Müller")
        #expect(contact.organizationName == "Willow Studio")
        #expect(contact.phoneNumbers.map(\.value) == ["+972 54-123-4567"])
        #expect(contact.emails.map(\.value) == ["jerome.muller@example.com"])
    }

    @Test("Turns the raw label constants into something displayable")
    func localisesLabels() {
        let cnContact = CNMutableContact()
        cnContact.phoneNumbers = [
            CNLabeledValue(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: "0612345678"))
        ]

        let label = Contact(cnContact).phoneNumbers.first?.label

        // CNLabelPhoneNumberMobile is the literal "_$!<Mobile>!$_", which must never reach a
        // screen. The localised form depends on the test machine's language, so the assertion
        // is on the shape rather than on the word.
        #expect(label?.isEmpty == false)
        #expect(label?.hasPrefix("_$") == false)
    }

    @Test("Falls back to a generic label when the system supplies none")
    func fallsBackWhenUnlabelled() {
        let cnContact = CNMutableContact()
        cnContact.phoneNumbers = [
            CNLabeledValue(label: nil, value: CNPhoneNumber(stringValue: "0612345678"))
        ]
        cnContact.emailAddresses = [CNLabeledValue(label: nil, value: "someone@example.com")]

        let contact = Contact(cnContact)

        #expect(contact.phoneNumbers.first?.label == "phone")
        #expect(contact.emails.first?.label == "email")
    }

    @Test("A birthday with a year survives the round trip")
    func mapsBirthdayWithYear() {
        let cnContact = CNMutableContact()
        cnContact.birthday = DateComponents(year: 1979, month: 7, day: 22)

        let birthday = Contact(cnContact).birthday
        let parts = birthday.map { Calendar.current.dateComponents([.year, .month, .day], from: $0) }

        #expect(parts?.year == 1979)
        #expect(parts?.month == 7)
        #expect(parts?.day == 22)
    }

    /// Pins a known defect rather than a wanted behaviour. `CNContact.birthday` legitimately
    /// omits the year, and `Calendar.date(from:)` fills the hole with year 1, which the detail
    /// screen then renders. This test is meant to fail the day that is fixed.
    @Test("A birthday with no year becomes year 1 — the defect, pinned")
    func yearlessBirthdayBecomesYearOne() {
        let cnContact = CNMutableContact()
        cnContact.birthday = DateComponents(month: 7, day: 22)

        let birthday = Contact(cnContact).birthday
        let year = birthday.map { Calendar.current.component(.year, from: $0) }

        #expect(year == 1)
    }

    @Test("No birthday stays no birthday")
    func mapsMissingBirthday() {
        #expect(Contact(CNMutableContact()).birthday == nil)
    }
}
