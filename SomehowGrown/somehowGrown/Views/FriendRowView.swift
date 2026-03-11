import SwiftUI

struct FriendRowView: View {
    let friend: Friend
    let accentColor: Color

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

            VStack(alignment: .leading, spacing: 6) {
                Text(friend.name)
                    .font(.headline)

                if friend.kids.isEmpty {
                    Text("子供の情報なし")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .italic()
                } else {
                    ForEach(Array(friend.kids.enumerated()), id: \.element.id) { index, kid in
                        KidChipView(kid: kid, index: index, accentColor: accentColor)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Kid chip

private struct KidChipView: View {
    let kid: Kid
    let index: Int
    let accentColor: Color

    private var currentGrade: Int {
        GradeSystem.currentGrade(
            gradeWhenAdded: kid.gradeWhenAdded,
            dateRecorded:   kid.dateRecorded,
            cutoff:         kid.cutoff
        )
    }

    private var currentAge: Int {
        GradeSystem.currentAge(ageWhenAdded: kid.ageWhenAdded, dateRecorded: kid.dateRecorded)
    }

    private var displayName: String {
        kid.name.isEmpty ? "お子さん\(index + 1)" : kid.name
    }

    var body: some View {
        HStack(spacing: 6) {
            Text(kid.gender.emoji)
            Text(displayName)
                .italic(kid.name.isEmpty)
                .foregroundStyle(kid.name.isEmpty ? .secondary : .primary)
            Spacer()
            Text("\(currentAge)歳・\(GradeSystem.label(grade: currentGrade, cutoff: kid.cutoff))")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(accentColor)
            Text(kid.cutoff.rawValue)
                .font(.caption2)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 4))
        }
        .font(.subheadline)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }
}
