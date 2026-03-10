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
        if grade < -3 { return cutoff == .jp ? "未就園" : "Toddler" }
        if grade > 16 { return cutoff == .jp ? "社会人" : "Graduate" }
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

    // MARK: Bidirectional suggestions

    static func suggestAge(fromGrade grade: Int, cutoff: CutoffType) -> Int {
        // JP: 小1(1) → 6歳,  US: K(0) → 5歳  — formula same for both
        return grade + 5
    }

    static func suggestGrade(fromAge age: Int, cutoff: CutoffType) -> Int {
        return age - 5
    }
}
