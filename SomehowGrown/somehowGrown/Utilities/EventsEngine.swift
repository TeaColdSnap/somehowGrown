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

// MARK: - Milestone tables (localized)

private func jpMilestones() -> [Int: String] {[
     1: NSLocalizedString("jp_milestone_elementary", comment: ""),
     7: NSLocalizedString("jp_milestone_middle",     comment: ""),
    10: NSLocalizedString("jp_milestone_high",       comment: ""),
    13: NSLocalizedString("jp_milestone_college",    comment: ""),
]}

private func jpGraduations() -> [Int: String] {[
     6: NSLocalizedString("jp_graduation_elementary", comment: ""),
     9: NSLocalizedString("jp_graduation_middle",     comment: ""),
    12: NSLocalizedString("jp_graduation_high",       comment: ""),
]}

private func usMilestones() -> [Int: String] {[
     0: NSLocalizedString("us_milestone_kindergarten", comment: ""),
     1: NSLocalizedString("us_milestone_elementary",   comment: ""),
     6: NSLocalizedString("us_milestone_middle",       comment: ""),
     9: NSLocalizedString("us_milestone_high",         comment: ""),
    13: NSLocalizedString("us_milestone_college",      comment: ""),
]}

private func usGraduations() -> [Int: String] {[
     5: NSLocalizedString("us_graduation_elementary", comment: ""),
     8: NSLocalizedString("us_graduation_middle",     comment: ""),
    12: NSLocalizedString("us_graduation_high",       comment: ""),
]}

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
                            eventLabel: String(format: NSLocalizedString("birthday_age_event", comment: ""), age),
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
                let milestones  = kid.cutoff == .jp ? jpMilestones()  : usMilestones()
                let graduations = kid.cutoff == .jp ? jpGraduations() : usGraduations()

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
