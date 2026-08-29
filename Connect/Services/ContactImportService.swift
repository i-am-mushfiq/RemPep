@preconcurrency import Contacts
import Foundation

struct ImportedContact: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let phone: String?
    let email: String?
    let photoData: Data?
}

enum ContactImportError: LocalizedError {
    case denied
    var errorDescription: String? { "Contacts access is needed only to choose people to add." }
}

actor ContactImportService {
    private let store = CNContactStore()

    func fetchContacts() async throws -> [ImportedContact] {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        if status == .notDetermined {
            let granted = try await store.requestAccess(for: .contacts)
            guard granted else { throw ContactImportError.denied }
        } else if status != .authorized && status != .limited {
            throw ContactImportError.denied
        }
        let keys: [CNKeyDescriptor] = [CNContactIdentifierKey as CNKeyDescriptor, CNContactFormatter.descriptorForRequiredKeys(for: .fullName), CNContactPhoneNumbersKey as CNKeyDescriptor, CNContactEmailAddressesKey as CNKeyDescriptor, CNContactThumbnailImageDataKey as CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)
        request.sortOrder = .userDefault
        var result: [ImportedContact] = []
        try store.enumerateContacts(with: request) { contact, _ in
            let name = CNContactFormatter.string(from: contact, style: .fullName) ?? ""
            guard !name.isEmpty else { return }
            result.append(ImportedContact(id: contact.identifier, name: name, phone: contact.phoneNumbers.first?.value.stringValue, email: contact.emailAddresses.first.map { String($0.value) }, photoData: contact.thumbnailImageData))
        }
        return result
    }
}
