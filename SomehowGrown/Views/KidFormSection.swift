import SwiftUI

// MARK: - KidDraft (mutable form state, not persisted directly)

struct KidDraft: Identifiable {
    let id: String
    var name: String
    var gender: Gender?      // nil = not selected yet (required field)
    var grade: Int
    var age: Int
    var cutoff: CutoffType
    var birthdayMonth: Int?
    var birthdayDay: Int?

    init() {
        id            = UUID().uuidString
        name          = ""
        gender        = nil
        grade         = 1
        age           = 6
        cutoff        = .jp
    }

    init(from kid: Kid) {
        id            = kid.id
        name          = kid.name
        gender        = kid.gender
        grade         = kid.gradeWhenAdded
        age           = kid.ageWhenAdded
        cutoff        = kid.cutoff
        birthdayMonth = kid.birthdayMonth
        birthdayDay   = kid.birthdayDay
    }
}

// MARK: - KidFormSection

struct KidFormSection: View {
    @Binding var kid: KidDraft
    /// Pass a closure to show the remove button; nil = only child, hide button
    var onRemove: (() -> Void)?

    var body: some View {
        Section {
            // MARK: Name
            HStack {
                TextField("名前（任意）", text: $kid.name)
                if let remove = onRemove {
                    Button(role: .destructive, action: remove) {
                        Image(systemName: "minus.circle.fill")
                    }
                    .buttonStyle(.borderless)
                }
            }

            // MARK: Gender (required)
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Text("性別")
                        .foregroundStyle(.secondary)
                    if kid.gender == nil {
                        Text("（必須）")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .font(.subheadline)

                HStack(spacing: 12) {
                    ForEach(Gender.allCases, id: \.self) { g in
                        Button {
                            kid.gender = g
                        } label: {
                            HStack(spacing: 4) {
                                Text(g.emoji)
                                Text(g.label)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                kid.gender == g
                                    ? (g == .male ? Color.blue.opacity(0.15) : Color.pink.opacity(0.15))
                                    : Color(.systemGray6),
                                in: RoundedRectangle(cornerRadius: 8)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        kid.gender == g
                                            ? (g == .male ? Color.blue : Color.pink)
                                            : Color.clear,
                                        lineWidth: 1.5
                                    )
                            )
                            .foregroundStyle(
                                kid.gender == g
                                    ? (g == .male ? Color.blue : Color.pink)
                                    : Color.secondary
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // MARK: Grade (Stepper with label)
            VStack(alignment: .leading, spacing: 4) {
                Text("学年（必須）")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Stepper(
                    GradeSystem.label(grade: kid.grade, cutoff: kid.cutoff),
                    value: $kid.grade,
                    in: -3...16
                )
                .onChange(of: kid.grade) { _, newGrade in
                    kid.age = GradeSystem.suggestAge(fromGrade: newGrade, cutoff: kid.cutoff)
                }
            }

            // MARK: Age
            HStack {
                Text("年齢")
                    .foregroundStyle(.secondary)
                Spacer()
                Stepper("\(kid.age)歳", value: $kid.age, in: 0...30)
                    .onChange(of: kid.age) { _, newAge in
                        kid.grade = GradeSystem.suggestGrade(fromAge: newAge, cutoff: kid.cutoff)
                    }
            }
            .font(.subheadline)

            // MARK: School system
            Picker("制度", selection: $kid.cutoff) {
                ForEach(CutoffType.allCases, id: \.self) { c in
                    Text(c.label).tag(c)
                }
            }
            .onChange(of: kid.cutoff) { _, newCutoff in
                kid.age = GradeSystem.suggestAge(fromGrade: kid.grade, cutoff: newCutoff)
            }

            // MARK: Birthday (optional, collapsible)
            DisclosureGroup("誕生月日（任意）") {
                Picker("月", selection: $kid.birthdayMonth) {
                    Text("未設定").tag(Int?.none)
                    ForEach(1...12, id: \.self) { m in
                        Text("\(m)月").tag(Int?.some(m))
                    }
                }
                if kid.birthdayMonth != nil {
                    Picker("日", selection: $kid.birthdayDay) {
                        Text("未設定").tag(Int?.none)
                        ForEach(1...31, id: \.self) { d in
                            Text("\(d)日").tag(Int?.some(d))
                        }
                    }
                }
            }
        }
    }
}
