import SwiftUI
import ContactsUI

/// UIViewControllerRepresentable wrapper for CNContactPickerViewController.
/// Returns (displayName, CNContact.identifier) — no raw contact data stored.
struct ContactPicker: UIViewControllerRepresentable {
    /// Called when the user picks a contact. Receives display name and opaque identifier.
    var onSelect: (_ displayName: String, _ identifier: String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelect)
    }

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    // MARK: - Coordinator

    class Coordinator: NSObject, CNContactPickerDelegate {
        let onSelect: (String, String) -> Void

        init(onSelect: @escaping (String, String) -> Void) {
            self.onSelect = onSelect
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            let name = CNContactFormatter.string(from: contact, style: .fullName)
                ?? contact.givenName
            onSelect(name, contact.identifier)
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {}
    }
}
