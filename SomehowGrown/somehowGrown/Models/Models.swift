import Foundation
import SwiftUI

// MARK: - FriendColor

enum FriendColor: String, Codable, CaseIterable {
    case darkTeal   = "darkTeal"   // #264653
    case oceanTeal  = "oceanTeal"  // #2A9D8F
    case sunYellow  = "sunYellow"  // #E9C46A
    case sandOrange = "sandOrange" // #F4A261
    case coral      = "coral"      // #E76F51

    var color: Color {
        switch self {
        case .darkTeal:   return Color(hex: "264653")
        case .oceanTeal:  return Color(hex: "2A9D8F")
        case .sunYellow:  return Color(hex: "E9C46A")
        case .sandOrange: return Color(hex: "F4A261")
        case .coral:      return Color(hex: "E76F51")
        }
    }

    var label: String {
        switch self {
        case .darkTeal:   return "Dark Teal"
        case .oceanTeal:  return "Ocean Teal"
        case .sunYellow:  return "Sun Yellow"
        case .sandOrange: return "Sand Orange"
        case .coral:      return "Coral"
        }
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >>  8) & 0xFF) / 255
        let b = Double( rgb        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }

    static let appTheme  = Color(hex: "FFCFA4")
    static let appSub    = Color(hex: "C7E9C0")
    static let appAccent = Color(hex: "A5D8DD")
}

// MARK: - Gender

enum Gender: String, Codable, CaseIterable {
    case male = "M"
    case female = "F"

    var emoji: String {
        self == .male ? "👦" : "👧"
    }

    var label: String {
        self == .male
            ? NSLocalizedString("gender_male", comment: "Boy gender label")
            : NSLocalizedString("gender_female", comment: "Girl gender label")
    }
}

// MARK: - CutoffType

enum CutoffType: String, Codable, CaseIterable {
    case us = "US"
    case jp = "JP"

    var label: String {
        self == .us
            ? NSLocalizedString("cutoff_us", comment: "US school system")
            : NSLocalizedString("cutoff_jp", comment: "JP school system")
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
    var birthdayYear: Int?
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
    /// nil = auto-assigned by FriendStore; non-nil = user override
    var colorTag: FriendColor?
}
