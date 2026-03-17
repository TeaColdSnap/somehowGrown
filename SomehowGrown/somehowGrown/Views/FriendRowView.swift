import SwiftUI

struct FriendRowView: View {
    let friend: Friend
    let accentColor: Color

    private var kidsSummary: String {
        friend.kids.map { kid in
            let grade = GradeSystem.currentGrade(
                gradeWhenAdded: kid.gradeWhenAdded,
                dateRecorded:   kid.dateRecorded,
                cutoff:         kid.cutoff
            )
            return "\(kid.gender.emoji)\(GradeSystem.label(grade: grade, cutoff: kid.cutoff))"
        }.joined(separator: " ")
    }

    var body: some View {
        HStack(spacing: 12) {
            // Colored initial avatar
            Circle()
                .fill(accentColor)
                .frame(width: 44, height: 44)
                .overlay(
                    Text(friend.name.prefix(1).uppercased())
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                )

            HStack(spacing: 8) {
                Text(friend.name)
                    .font(.headline)
                    .layoutPriority(1)
                Spacer(minLength: 4)
                if friend.kids.isEmpty {
                    Text("子供なし")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .italic()
                } else {
                    Text(kidsSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
