import Foundation
import SwiftUI

// MARK: - FriendColor

enum FriendColor: String, Codable, CaseIterable {
    case slateBlue  = "slateBlue"
    case dustyGreen = "dustyGreen"
    case mutedTeal  = "mutedTeal"
    case warmGray   = "warmGray"
    case softPlum   = "softPlum"
    case earthBrown = "earthBrown"
    case steelGray  = "steelGray"
    case deepMoss   = "deepMoss"

    var color: Color {
        switch self {
        case .slateBlue:  return Color(hex: "5B6C8F")
        case .dustyGreen: return Color(hex: "6B8A73")
        case .mutedTeal:  return Color(hex: "5F8C8A")
        case .warmGray:   return Color(hex: "8A817C")
        case .softPlum:   return Color(hex: "7C6A8A")
        case .earthBrown: return Color(hex: "8C6F5A")
        case .steelGray:  return Color(hex: "6E7B85")
        case .deepMoss:   return Color(hex: "667A5A")
        }
    }

    var label: String {
        switch self {
        case .slateBlue:  return "Slate Blue"
        case .dustyGreen: return "Dusty Green"
        case .mutedTeal:  return "Muted Teal"
        case .warmGray:   return "Warm Gray"
        case .softPlum:   return "Soft Plum"
        case .earthBrown: return "Earth Brown"
        case .steelGray:  return "Steel Gray"
        case .deepMoss:   return "Deep Moss"
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
