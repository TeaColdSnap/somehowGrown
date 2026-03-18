import Foundation

// MARK: - LifeEvent

struct LifeEvent: Identifiable {
    let id = UUID()
    let friendID: String
    let friendName: String
    let kidName: String
    let eventLabel: String
    let date: Date
    let daysUntil: Int

    enum EventType { case birthday, schoolMilestone }
    let type: EventType
}

// MARK: - Milestone tables

private let jpMilestones: [Int: String] = [
     1: "小学校入学 🎒",
     7: "中学校入学 🏫",
    10: "高校入学 🎓",
    13: "大学入学 🎓",
]

private let jpGraduations: [Int: String] = [
     6: "小学校卒業 🌸",
     9: "中学校卒業 🌸",
    12: "高校卒業 🌸",
]

private let usMilestones: [Int: String] = [
     0: "Kindergarten 🎒",
     1: "Elementary Start 🏫",
     6: "Middle School 🏫",
     9: "High School 🎓",
    13: "College 🎓",
]

private let usGraduations: [Int: String] = [
     5: "Elementary Graduation 🌸",
     8: "Middle School Graduation 🌸",
    12: "High School Graduation 🎓",
]

// MARK: - Engine

enum EventsEngine {

    static func upcomingEvents(friends: [Friend], lookAheadDays: Int = 120) -> [LifeEvent] {
        let cal = Calendar.current
        let now = Date()
        var events: [LifeEvent] = []

        for friend in friends {
            for kid in friend.kids {

                // MARK: Birthday
                if let bMonth = kid.birthdayMonth {
                    let bDay = kid.birthdayDay ?? 1
                    var comps = DateComponents()
                    comps.month = bMonth
                    comps.day   = bDay
                    comps.year  = cal.component(.year, from: now)
                    var nextBday = cal.date(from: comps)!
                    if nextBday < now {
                        nextBday = cal.date(byAdding: .year, value: 1, to: nextBday)!
                    }
                    let days = cal.dateComponents([.day], from: now, to: nextBday).day ?? 0
                    if days <= lookAheadDays {
                        let age = GradeSystem.currentAge(
                            ageWhenAdded: kid.ageWhenAdded,
                            dateRecorded: kid.dateRecorded
                        )
                        events.append(LifeEvent(
                            friendID:   friend.id,
                            friendName: friend.name,
                            kidName:    kid.name,
                            eventLabel: "\(age)歳の誕生日 🎂",
                            date:       nextBday,
                            daysUntil:  days,
                            type:       .birthday
                        ))
                    }
                }

                // MARK: School milestones
                // Use birthday-derived grade when full birthday is available (handles cutoff edge cases);
                // fall back to the recorded grade otherwise.
                let currentGrade: Int
                if let by = kid.birthdayYear, let bm = kid.birthdayMonth, let bd = kid.birthdayDay {
                    currentGrade = GradeSystem.gradeFromBirthday(year: by, month: bm, day: bd, cutoff: kid.cutoff)
                } else {
                    currentGrade = GradeSystem.currentGrade(
                        gradeWhenAdded: kid.gradeWhenAdded,
                        dateRecorded:   kid.dateRecorded,
                        cutoff:         kid.cutoff
                    )
                }
                let milestones  = kid.cutoff == .jp ? jpMilestones  : usMilestones
                let graduations = kid.cutoff == .jp ? jpGraduations : usGraduations

                // Next grade → entrance milestone
                let nextGrade = currentGrade + 1
                if let label = milestones[nextGrade] {
                    let date = nextSchoolYearStart(cutoff: kid.cutoff)
                    let days = cal.dateComponents([.day], from: now, to: date).day ?? 0
                    if days >= 0 && days <= lookAheadDays {
                        events.append(LifeEvent(
                            friendID:   friend.id,
                            friendName: friend.name,
                            kidName:    kid.name,
                            eventLabel: label,
                            date:       date,
                            daysUntil:  days,
                            type:       .schoolMilestone
                        ))
                    }
                }

                // Current grade → graduation
                if let label = graduations[currentGrade] {
                    let date = graduationDate(cutoff: kid.cutoff)
                    let days = cal.dateComponents([.day], from: now, to: date).day ?? 0
                    if days >= 0 && days <= lookAheadDays {
                        events.append(LifeEvent(
                            friendID:   friend.id,
                            friendName: friend.name,
                            kidName:    kid.name,
                            eventLabel: label,
                            date:       date,
                            daysUntil:  days,
                            type:       .schoolMilestone
                        ))
                    }
                }
            }
        }

        return events.sorted { $0.daysUntil < $1.daysUntil }
    }

    // MARK: - Date helpers

    private static func nextSchoolYearStart(cutoff: CutoffType) -> Date {
        let cal = Calendar.current
        let now  = Date()
        var comps = DateComponents()
        comps.month = cutoff.schoolYearStartMonth
        comps.day   = 1
        comps.year  = cal.component(.year, from: now)
        let date = cal.date(from: comps)!
        return date < now ? cal.date(byAdding: .year, value: 1, to: date)! : date
    }

    private static func graduationDate(cutoff: CutoffType) -> Date {
        let cal = Calendar.current
        let now  = Date()
        var comps = DateComponents()
        comps.month = cutoff == .jp ? 3 : 6  // JP: 3月, US: 6月
        comps.day   = 15
        comps.year  = cal.component(.year, from: now)
        let date = cal.date(from: comps)!
        return date < now ? cal.date(byAdding: .year, value: 1, to: date)! : date
    }
}
