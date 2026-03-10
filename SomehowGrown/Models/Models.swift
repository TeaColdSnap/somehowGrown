import Foundation

// MARK: - Gender

enum Gender: String, Codable, CaseIterable {
    case male = "M"
    case female = "F"

    var emoji: String {
        self == .male ? "👦" : "👧"
    }

    var label: String {
        self == .male ? "男の子" : "女の子"
    }
}

// MARK: - CutoffType

enum CutoffType: String, Codable, CaseIterable {
    case jp = "JP"
    case us = "US"

    var label: String {
        self == .jp ? "🇯🇵 日本" : "🇺🇸 アメリカ"
    }

    /// 1-indexed month when the new school year starts (JP: 4月, US: 9月)
    var schoolYearStartMonth: Int {
        self == .jp ? 4 : 9
    }
}

// MARK: - Kid

struct Kid: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var name: String
    var gender: Gender

    /// Unified grade number:
    ///   -3 = 未就園 / Toddler
    ///   -2 = 年少   / Pre-K 3
    ///   -1 = 年中   / Pre-K
    ///    0 = 年長   / Kindergarten
    ///  1-6 = 小学   / Elementary
    ///  7-9 = 中学   / Middle
    /// 10-12= 高校   / High School
    ///   13+= 大学   / College
    var gradeWhenAdded: Int
    var ageWhenAdded: Int
    var dateRecorded: Date
    var cutoff: CutoffType

    /// Optional birthday (month: 1-indexed)
    var birthdayMonth: Int?
    var birthdayDay: Int?
}

// MARK: - Friend

struct Friend: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var name: String
    /// CNContact.identifier — only the opaque ID is stored, no raw PII
    var contactIdentifier: String?
    var kids: [Kid]
    var createdAt: Date = Date()
}
