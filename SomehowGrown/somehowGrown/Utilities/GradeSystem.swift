import Foundation

// MARK: - Grade label tables

private let jpGrades: [Int: String] = [
    -3: "未就園",
    -2: "年少",
    -1: "年中",
     0: "年長",
     1: "小1",  2: "小2",  3: "小3",  4: "小4",  5: "小5",  6: "小6",
     7: "中1",  8: "中2",  9: "中3",
    10: "高1", 11: "高2", 12: "高3",
    13: "大学1年", 14: "大学2年", 15: "大学3年", 16: "大学4年",
]

private let usGrades: [Int: String] = [
    -3: "Toddler",
    -2: "Pre-K 3",
    -1: "Pre-K",
     0: "Kindergarten",
     1: "1st",  2: "2nd",  3: "3rd",  4: "4th",  5: "5th",  6: "6th",
     7: "7th",  8: "8th",
     9: "9th", 10: "10th", 11: "11th", 12: "12th",
    13: "College Fr.", 14: "College So.", 15: "College Jr.", 16: "College Sr.",
]

// MARK: - GradeSystem

enum GradeSystem {

    // MARK: Grade picker items

    static func selectableGrades(cutoff: CutoffType) -> [(value: Int, label: String)] {
        let map = cutoff == .jp ? jpGrades : usGrades
        return map.sorted { $0.key < $1.key }.map { (value: $0.key, label: $0.value) }
    }

    // MARK: Label

    static func label(grade: Int, cutoff: CutoffType) -> String {
        let map = cutoff == .jp ? jpGrades : usGrades
        if grade < -3 { return map[-3] ?? (cutoff == .jp ? "未就園" : "Toddler") }
        if grade > 16 { return NSLocalizedString("grade_fallback_adult", comment: "Adult/Graduate label") }
        return map[grade] ?? "\(grade)"
    }

    // MARK: School year number

    /// JP: school year starts April 1  → month >= 4 ? year : year-1
    /// US: school year starts Sept 1   → month >= 9 ? year : year-1
    static func schoolYear(for date: Date, cutoff: CutoffType) -> Int {
        let cal = Calendar.current
        let month = cal.component(.month, from: date)
        let year  = cal.component(.year,  from: date)
        return month >= cutoff.schoolYearStartMonth ? year : year - 1
    }

    // MARK: Current grade (auto-advances each school year)

    static func currentGrade(gradeWhenAdded: Int, dateRecorded: Date, cutoff: CutoffType) -> Int {
        let then = schoolYear(for: dateRecorded, cutoff: cutoff)
        let now  = schoolYear(for: Date(),        cutoff: cutoff)
        return gradeWhenAdded + (now - then)
    }

    // MARK: Current age (full calendar years since recorded)

    static func currentAge(ageWhenAdded: Int, dateRecorded: Date) -> Int {
        let years = Calendar.current
            .dateComponents([.year], from: dateRecorded, to: Date()).year ?? 0
        return ageWhenAdded + years
    }

    // MARK: Grade from exact birthday (most accurate — handles cutoff edge cases)

    /// Derives the current grade directly from the full birthday.
    /// JP cutoff: April 1  (born April 2+ → grade 0 starts one year later)
    /// US cutoff: Sept 1   (born Sept 1+  → Kindergarten starts one year later)
    static func gradeFromBirthday(year: Int, month: Int, day: Int, cutoff: CutoffType) -> Int {
        let grade0EntrySchoolYear: Int
        if cutoff == .jp {
            grade0EntrySchoolYear = (month > 4 || (month == 4 && day >= 2)) ? year + 6 : year + 5
        } else {
            grade0EntrySchoolYear = (month > 9 || (month == 9 && day >= 1)) ? year + 6 : year + 5
        }
        let currentSY = schoolYear(for: Date(), cutoff: cutoff)
        return currentSY - grade0EntrySchoolYear
    }

    // MARK: Bidirectional suggestions (legacy — kept for EventsEngine / currentGrade compatibility)

    static func suggestAge(fromGrade grade: Int, cutoff: CutoffType) -> Int {
        return grade + 5
    }

    static func suggestGrade(fromAge age: Int, cutoff: CutoffType) -> Int {
        return age - 5
    }

    // MARK: New grade estimation (used by the 1-screen input flow)

    /// Estimate grade from integer age.
    /// Formula: age - 6, then -1 if current month is before school year start.
    static func suggestGradeFromAge(_ age: Int, schoolYearStartMonth: Int) -> Int {
        let currentMonth = Calendar.current.component(.month, from: Date())
        var grade = age - 6
        if currentMonth < schoolYearStartMonth {
            grade -= 1
        }
        return grade
    }

    /// Estimate grade from birth year/month for higher precision.
    /// Computes exact age in whole years, then calls suggestGradeFromAge.
    static func suggestGradeFromBirthYearMonth(year: Int, month: Int, schoolYearStartMonth: Int) -> Int {
        let cal = Calendar.current
        let now = Date()
        let currentYear  = cal.component(.year,  from: now)
        let currentMonth = cal.component(.month, from: now)
        var age = currentYear - year
        if currentMonth < month { age -= 1 }
        return suggestGradeFromAge(age, schoolYearStartMonth: schoolYearStartMonth)
    }
}
