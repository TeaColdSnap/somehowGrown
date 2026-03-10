import SwiftUI

struct AddFriendSheet: View {
    @ObservedObject var store: FriendStore
    var editingFriend: Friend?

    @Environment(\.dismiss) private var dismiss

    @State private var friendName = ""
    @State private var contactIdentifier: String?
    @State private var kids: [KidDraft] = []
    @State private var showContactPicker = false

    private var canSave: Bool {
        !friendName.trimmingCharacters(in: .whitespaces).isEmpty
            && kids.allSatisfy { $0.gender != nil }
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Friend name + contact picker
                Section("友人") {
                    HStack {
                        TextField("名前", text: $friendName)
                            .autocorrectionDisabled()
                        Spacer()
                        Button {
                            showContactPicker = true
                        } label: {
                            Image(systemName: contactIdentifier != nil
                                  ? "person.crop.circle.fill.badge.checkmark"
                                  : "person.crop.circle")
                                .foregroundStyle(contactIdentifier != nil ? .green : .secondary)
                        }
                        .buttonStyle(.borderless)
                    }
                    if contactIdentifier != nil {
                        Label("連絡先とリンク済み", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }

                // MARK: Kid forms
                ForEach($kids) { $kid in
                    KidFormSection(
                        kid: $kid,
                        onRemove: kids.count > 1 ? { kids.removeAll { $0.id == kid.id } } : nil
                    )
                }

                // MARK: Add kid button
                Section {
                    Button {
                        kids.append(KidDraft())
                    } label: {
                        Label("子供を追加", systemImage: "plus.circle")
                    }
                }
            }
            .navigationTitle(editingFriend != nil ? "友人を編集" : "友人を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存", action: save)
                        .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showContactPicker) {
                ContactPicker { name, identifier in
                    friendName = name
                    contactIdentifier = identifier
                }
                .ignoresSafeArea()
            }
            .onAppear(perform: populate)
        }
    }

    // MARK: - Populate from existing friend

    private func populate() {
        guard let f = editingFriend else {
            kids = [KidDraft()]
            return
        }
        friendName         = f.name
        contactIdentifier  = f.contactIdentifier
        kids               = f.kids.map { KidDraft(from: $0) }
    }

    // MARK: - Save

    private func save() {
        guard canSave else { return }
        let now = Date()

        let friend = Friend(
            id:                editingFriend?.id ?? UUID().uuidString,
            name:              friendName.trimmingCharacters(in: .whitespaces),
            contactIdentifier: contactIdentifier,
            kids: kids.compactMap { draft -> Kid? in
                guard let gender = draft.gender else { return nil }
                // Preserve original gradeWhenAdded / ageWhenAdded / dateRecorded on edit
                let existing = editingFriend?.kids.first { $0.id == draft.id }
                return Kid(
                    id:             draft.id,
                    name:           draft.name.trimmingCharacters(in: .whitespaces),
                    gender:         gender,
                    gradeWhenAdded: existing?.gradeWhenAdded ?? draft.grade,
                    ageWhenAdded:   existing?.ageWhenAdded   ?? draft.age,
                    dateRecorded:   existing?.dateRecorded   ?? now,
                    cutoff:         draft.cutoff,
                    birthdayMonth:  draft.birthdayMonth,
                    birthdayDay:    draft.birthdayDay
                )
            },
            createdAt: editingFriend?.createdAt ?? now
        )

        store.addOrUpdate(friend)
        dismiss()
    }
}
