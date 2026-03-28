import SwiftUI

// MARK: - KidDraft (mutable form state, not persisted directly)

struct KidDraft: Identifiable {
    let id: String
    var name: String
    var gender: Gender?      // nil = not selected yet (required field)
    var grade: Int
    var age: Int
    var cutoff: CutoffType
    var birthdayYear: Int?
    var birthdayMonth: Int?
    var birthdayDay: Int?
    /// nil = standard grade; non-nil = 社会人 or free-text label
    var customGradeLabel: String?
    /// false = new draft (flow not yet completed); true = loaded from existing or flow done
    var ageGradeConfirmed: Bool

    init() {
        id                = UUID().uuidString
        name              = ""
        gender            = nil
        grade             = 1
        age               = 6
        cutoff            = .us
        birthdayYear      = Calendar.current.component(.year, from: Date())
                            - GradeSystem.suggestAge(fromGrade: 1, cutoff: .us)
        customGradeLabel  = nil
        ageGradeConfirmed = false
    }

    init(from kid: Kid) {
        id                = kid.id
        name              = kid.name
        gender            = kid.gender
        grade             = kid.gradeWhenAdded
        age               = kid.ageWhenAdded
        cutoff            = kid.cutoff
        birthdayYear      = kid.birthdayYear
        birthdayMonth     = kid.birthdayMonth
        birthdayDay       = kid.birthdayDay
        customGradeLabel  = kid.customGradeLabel
        ageGradeConfirmed = true
    }
}

// MARK: - KidFormSection

struct KidFormSection: View {
    @Binding var kid: KidDraft
    var onRemove: (() -> Void)?

    private var birthdayYearRange: ClosedRange<Int> {
        let y = Calendar.current.component(.year, from: Date())
        return (y - 20)...y
    }

    var body: some View {
        Section {
            // MARK: Name + school system
            HStack {
                TextField("名前（任意）", text: $kid.name)
                Picker("", selection: $kid.cutoff) {
                    ForEach(CutoffType.allCases, id: \.self) { c in
                        Text(c.label).tag(c)
                    }
                }
                .labelsHidden()
                .fixedSize()
                .onChange(of: kid.cutoff) { _, newCutoff in
                    kid.age = GradeSystem.suggestAge(fromGrade: kid.grade, cutoff: newCutoff)
                    let y = Calendar.current.component(.year, from: Date())
                    kid.birthdayYear = y - GradeSystem.suggestAge(fromGrade: kid.grade, cutoff: newCutoff)
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

            // MARK: Age → Grade 4-step flow
            AgeGradeFlowView(kid: $kid)
                .padding(.vertical, 4)

            // MARK: Birthday (optional, collapsible)
            DisclosureGroup("誕生日（任意）") {
                Picker("年", selection: $kid.birthdayYear) {
                    Text("未設定").tag(Int?.none)
                    ForEach((birthdayYearRange).reversed(), id: \.self) { y in
                        Text(verbatim: String(format: NSLocalizedString("year_picker_format", comment: ""), y)).tag(Int?.some(y))
                    }
                }
                Picker("月", selection: $kid.birthdayMonth) {
                    Text("未設定").tag(Int?.none)
                    ForEach(1...12, id: \.self) { m in
                        Text(verbatim: String(format: NSLocalizedString("month_picker_format", comment: ""), m)).tag(Int?.some(m))
                    }
                }
                if kid.birthdayMonth != nil {
                    Picker("日", selection: $kid.birthdayDay) {
                        Text("未設定").tag(Int?.none)
                        ForEach(1...31, id: \.self) { d in
                            Text(verbatim: String(format: NSLocalizedString("day_picker_format", comment: ""), d)).tag(Int?.some(d))
                        }
                    }
                }
            }

            // MARK: Delete child (bottom of section)
            if let remove = onRemove {
                Button(role: .destructive, action: remove) {
                    Text("このお子さんの情報を削除")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }
}

// MARK: - AgeGradeFlowView

private struct AgeGradeFlowView: View {
    @Binding var kid: KidDraft

    private enum Step { case ageEntry, gradeConfirm, customEntry, done }

    @State private var step: Step
    @State private var ageText: String
    @State private var customText: String = ""
    @FocusState private var ageFieldFocused: Bool

    init(kid: Binding<KidDraft>) {
        _kid = kid
        let confirmed = kid.wrappedValue.ageGradeConfirmed
        _step    = State(initialValue: confirmed ? .done : .ageEntry)
        _ageText = State(initialValue: confirmed ? String(kid.wrappedValue.age) : "")
    }

    private var enteredAge: Int? {
        guard let n = Int(ageText.trimmingCharacters(in: .whitespaces)),
              n >= 0, n <= 50 else { return nil }
        return n
    }

    private var estimatedGrade: Int {
        GradeSystem.suggestGrade(fromAge: enteredAge ?? kid.age, cutoff: kid.cutoff)
    }

    private struct GradeCandidate: Identifiable {
        let id: Int        // grade value
        let label: String
        let isEstimate: Bool
    }

    private var gradeCandidates: [GradeCandidate] {
        let g = estimatedGrade
        return [
            GradeCandidate(id: g - 1, label: GradeSystem.label(grade: g - 1, cutoff: kid.cutoff), isEstimate: false),
            GradeCandidate(id: g,     label: GradeSystem.label(grade: g,     cutoff: kid.cutoff), isEstimate: true),
            GradeCandidate(id: g + 1, label: GradeSystem.label(grade: g + 1, cutoff: kid.cutoff), isEstimate: false),
        ]
    }

    var body: some View {
        Group {
            switch step {
            case .ageEntry:     ageEntryView
            case .gradeConfirm: gradeConfirmView
            case .customEntry:  customEntryView
            case .done:         doneView
            }
        }
    }

    // MARK: Step 1 — 年齢入力

    private var ageEntryView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("年齢を入力")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                TextField("例: 15", text: $ageText)
                    .keyboardType(.numberPad)
                    .font(.title3.weight(.medium))
                    .frame(width: 72)
                    .focused($ageFieldFocused)
                Text("歳")
                    .foregroundStyle(.secondary)
                Spacer()
                Button("次へ") {
                    guard let age = enteredAge else { return }
                    kid.age = age
                    kid.grade = GradeSystem.suggestGrade(fromAge: age, cutoff: kid.cutoff)
                    ageFieldFocused = false
                    step = .gradeConfirm
                }
                .disabled(enteredAge == nil)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .onAppear { ageFieldFocused = true }
    }

    // MARK: Step 2 — 推定表示＋修正候補グリッド

    private var adultLabel: String {
        NSLocalizedString("grade_fallback_adult", comment: "Adult/Graduate label")
    }

    private var gradeConfirmView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(kid.age)歳")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(GradeSystem.label(grade: estimatedGrade, cutoff: kid.cutoff))ごろ")
                        .font(.subheadline.weight(.semibold))
                }
                Spacer()
                Button("戻る") { step = .ageEntry }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .buttonStyle(.borderless)
            }

            if estimatedGrade > 16 {
                // 大人の場合: ラベル1つ＋「その他」の2択
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    Button {
                        kid.grade = 17
                        kid.customGradeLabel = nil
                        kid.ageGradeConfirmed = true
                        step = .done
                    } label: {
                        Text(adultLabel)
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.accentColor, lineWidth: 1.5))
                            .foregroundStyle(Color.accentColor)
                    }
                    .buttonStyle(.plain)

                    Button {
                        customText = ""
                        step = .customEntry
                    } label: {
                        Text("その他")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                // 通常: 前後学年3つ＋「その他」
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(gradeCandidates) { candidate in
                        gradeCandidateCell(candidate)
                    }
                    Button {
                        customText = ""
                        step = .customEntry
                    } label: {
                        Text("その他")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func gradeCandidateCell(_ candidate: GradeCandidate) -> some View {
        Button {
            kid.grade = candidate.id
            kid.customGradeLabel = nil
            let y = Calendar.current.component(.year, from: Date())
            kid.birthdayYear = y - GradeSystem.suggestAge(fromGrade: candidate.id, cutoff: kid.cutoff)
            kid.ageGradeConfirmed = true
            step = .done
        } label: {
            Text(candidate.label)
                .font(.subheadline.weight(candidate.isEstimate ? .semibold : .regular))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    candidate.isEstimate
                        ? Color.accentColor.opacity(0.12)
                        : Color(.systemGray6),
                    in: RoundedRectangle(cornerRadius: 8)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            candidate.isEstimate ? Color.accentColor : Color.clear,
                            lineWidth: 1.5
                        )
                )
                .foregroundStyle(candidate.isEstimate ? Color.accentColor : Color.primary)
        }
        .buttonStyle(.plain)
    }

    // MARK: Step 3 — その他（社会人 or フリーテキスト）

    private var customEntryView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("学年・状況を選択または入力")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("戻る") { step = .gradeConfirm }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .buttonStyle(.borderless)
            }

            Button {
                kid.grade = 17
                kid.customGradeLabel = nil   // GradeSystem.label が言語に合わせて表示
                kid.ageGradeConfirmed = true
                step = .done
            } label: {
                Text(adultLabel)
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                TextField("学年・状況（自由記入）", text: $customText)
                    .font(.subheadline)
                Button("決定") {
                    let trimmed = customText.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    kid.grade = 17
                    kid.customGradeLabel = trimmed
                    kid.ageGradeConfirmed = true
                    step = .done
                }
                .disabled(customText.trimmingCharacters(in: .whitespaces).isEmpty)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
    }

    // MARK: Step 4 — 確認表示

    private var doneView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("学年・年齢")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(confirmLabel)
                    .font(.subheadline.weight(.medium))
            }
            Spacer()
            Button("変更") {
                ageText = String(kid.age)
                step = .ageEntry
            }
            .font(.caption)
            .buttonStyle(.borderless)
        }
    }

    private var confirmLabel: String {
        let gradePart = kid.customGradeLabel
            ?? GradeSystem.label(grade: kid.grade, cutoff: kid.cutoff)
        return "\(kid.age)歳・\(gradePart)"
    }
}
