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
    var birthdayDay: Int?    // preserved from existing data; not shown in new UI
    /// nil = standard grade; non-nil = 社会人 or free-text label (preserved on edit)
    var customGradeLabel: String?
    /// false = new draft (flow not yet completed); true = loaded from existing or age entered
    var ageGradeConfirmed: Bool
    /// true = cutoff was auto-inferred from device locale; false = user manually selected
    var cutoffAutoDetected: Bool

    init() {
        id                 = UUID().uuidString
        name               = ""
        gender             = nil
        grade              = 1
        age                = 7
        cutoff             = CutoffType.defaultForLocale()
        cutoffAutoDetected = true
        birthdayYear       = nil
        birthdayMonth      = nil
        birthdayDay        = nil
        customGradeLabel   = nil
        ageGradeConfirmed  = false
    }

    init(from kid: Kid) {
        id                 = kid.id
        name               = kid.name
        gender             = kid.gender
        grade              = kid.gradeWhenAdded
        age                = kid.ageWhenAdded
        cutoff             = kid.cutoff
        cutoffAutoDetected = false
        birthdayYear       = kid.birthdayYear
        birthdayMonth      = kid.birthdayMonth
        birthdayDay        = kid.birthdayDay
        customGradeLabel   = kid.customGradeLabel
        ageGradeConfirmed  = true
    }
}

// MARK: - KidFormSection

struct KidFormSection: View {
    @Binding var kid: KidDraft
    var onRemove: (() -> Void)?

    var body: some View {
        Section {
            // MARK: Name (no country picker)
            TextField("名前（任意）", text: $kid.name)

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

            // MARK: Age / Birth month / Grade — 1-screen flow
            AgeGradeInlineView(kid: $kid)
                .padding(.vertical, 4)

            // MARK: Delete child
            if let remove = onRemove {
                Button(role: .destructive, action: remove) {
                    Text("このお子さんの情報を削除")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }
}

// MARK: - AgeGradeInlineView

private struct AgeGradeInlineView: View {
    @Binding var kid: KidDraft

    @State private var ageText: String
    @State private var showBirthMonth: Bool = false
    @FocusState private var ageFieldFocused: Bool

    init(kid: Binding<KidDraft>) {
        _kid     = kid
        _ageText = State(initialValue: kid.wrappedValue.ageGradeConfirmed
                            ? String(kid.wrappedValue.age) : "")
    }

    // MARK: Helpers

    private var enteredAge: Int? {
        guard let n = Int(ageText.trimmingCharacters(in: .whitespaces)),
              n >= 0, n <= 50 else { return nil }
        return n
    }

    private func computeGrade(age: Int) -> Int {
        if let y = kid.birthdayYear, let m = kid.birthdayMonth {
            return GradeSystem.suggestGradeFromBirthYearMonth(
                year: y,
                month: m,
                schoolYearStartMonth: kid.cutoff.schoolYearStartMonth
            )
        }
        return GradeSystem.suggestGradeFromAge(age,
                                               schoolYearStartMonth: kid.cutoff.schoolYearStartMonth)
    }

    private func gradeDisplayLabel(_ grade: Int) -> String {
        GradeSystem.label(grade: grade, cutoff: kid.cutoff)
    }

    private var birthYearRange: ClosedRange<Int> {
        let y = Calendar.current.component(.year, from: Date())
        return (y - 25)...y
    }

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // ① 年齢入力
            ageInputRow

            if enteredAge != nil {
                // ② 生年月トグル（任意）
                birthMonthSection

                // ③ 学年チップ ＋ ④ 学期開始月ピル
                gradeAndCutoffArea
            }
        }
        .onChange(of: ageText) { _, _ in
            guard let age = enteredAge else {
                kid.ageGradeConfirmed = false
                return
            }
            kid.age   = age
            kid.grade = computeGrade(age: age)
            kid.ageGradeConfirmed = true
        }
        .onChange(of: kid.cutoff) { _, _ in
            guard let age = enteredAge else { return }
            kid.grade = computeGrade(age: age)
        }
        .onChange(of: kid.birthdayYear)  { _, _ in refreshGrade() }
        .onChange(of: kid.birthdayMonth) { _, _ in refreshGrade() }
    }

    private func refreshGrade() {
        guard let age = enteredAge else { return }
        kid.grade = computeGrade(age: age)
    }

    // MARK: ① 年齢入力行

    private var ageInputRow: some View {
        HStack(spacing: 8) {
            Text("年齢")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            TextField("例: 8", text: $ageText)
                .keyboardType(.numberPad)
                .font(.title3.weight(.medium))
                .multilineTextAlignment(.center)
                .frame(width: 64)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 8))
                .focused($ageFieldFocused)
            Text("歳")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .onAppear {
            if !kid.ageGradeConfirmed { ageFieldFocused = true }
        }
    }

    // MARK: ② 生年月トグルセクション

    private var birthMonthSection: some View {
        DisclosureGroup(
            isExpanded: $showBirthMonth,
            content: {
                HStack(spacing: 0) {
                    Picker("年", selection: $kid.birthdayYear) {
                        Text("未設定").tag(Int?.none)
                        ForEach(birthYearRange.reversed(), id: \.self) { y in
                            Text(verbatim: String(
                                format: NSLocalizedString("year_picker_format", comment: ""), y
                            )).tag(Int?.some(y))
                        }
                    }
                    Picker("月", selection: $kid.birthdayMonth) {
                        Text("未設定").tag(Int?.none)
                        ForEach(1...12, id: \.self) { m in
                            Text(verbatim: String(
                                format: NSLocalizedString("month_picker_format", comment: ""), m
                            )).tag(Int?.some(m))
                        }
                    }
                }
            },
            label: {
                Text("生まれた年月も入力する（任意）")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        )
    }

    // MARK: ③④ 学年チップ ＋ 学期開始月ピル

    private var gradeAndCutoffArea: some View {
        VStack(spacing: 10) {
            // ③ 学年チップ（横スクロール、-3〜17）
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(-3...17, id: \.self) { g in
                            gradeChip(grade: g, isCenter: g == kid.grade)
                                .id(g)
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .onAppear {
                    proxy.scrollTo(kid.grade, anchor: .center)
                }
                .onChange(of: kid.grade) { _, newGrade in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(newGrade, anchor: .center)
                    }
                }
            }

            // ④ 学期開始月ピル（社会人・Graduate は非表示）
            if (-2...16).contains(kid.grade) {
                VStack(spacing: 4) {
                    Text("新学期はいつから？")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        cutoffPill(.jp, label: "4月")
                        cutoffPill(.us, label: "9月")
                        cutoffPill(.kr, label: "3月")
                    }
                    if kid.cutoffAutoDetected {
                        Text("（端末設定から推定）")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func gradeChip(grade: Int, isCenter: Bool) -> some View {
        Button {
            kid.grade = grade
            kid.customGradeLabel = nil
        } label: {
            Text(gradeDisplayLabel(grade))
                .font(isCenter ? .subheadline.weight(.semibold) : .caption)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    isCenter ? Color.accentColor.opacity(0.12) : Color(.systemGray6),
                    in: RoundedRectangle(cornerRadius: 20)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isCenter ? Color.accentColor : Color.clear, lineWidth: 1.5)
                )
                .foregroundStyle(isCenter ? Color.accentColor : Color.secondary)
        }
        .buttonStyle(.plain)
    }

    private func cutoffPill(_ cutoff: CutoffType, label: String) -> some View {
        let selected = kid.cutoff == cutoff
        return Button {
            kid.cutoff = cutoff
            kid.cutoffAutoDetected = false
            if let age = enteredAge {
                kid.grade = computeGrade(age: age)
            }
        } label: {
            Text(LocalizedStringKey(label))
                .font(.caption.weight(selected ? .semibold : .regular))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    selected ? Color.accentColor.opacity(0.15) : Color(.systemGray6),
                    in: Capsule()
                )
                .overlay(
                    Capsule()
                        .stroke(selected ? Color.accentColor : Color.clear, lineWidth: 1.5)
                )
                .foregroundStyle(selected ? Color.accentColor : Color.secondary)
        }
        .buttonStyle(.plain)
    }
}
