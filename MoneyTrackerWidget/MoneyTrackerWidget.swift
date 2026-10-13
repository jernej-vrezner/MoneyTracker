import WidgetKit
import SwiftUI

private let brand = Color(red: 0.43, green: 0.31, blue: 0.88)

private func euro(_ value: Double) -> String {
    value.formatted(.currency(code: "EUR"))
}

struct SnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct SnapshotProvider: TimelineProvider {
    func placeholder(in context: Context) -> SnapshotEntry {
        SnapshotEntry(
            date: Date(),
            snapshot: WidgetSnapshot(
                budgetSpent: 320,
                budgetLimit: 450,
                projected: 510,
                goals: [GoalSnapshot(name: "MacBook", saved: 620, target: 1000)],
                updatedAt: Date()
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        completion(SnapshotEntry(date: Date(), snapshot: WidgetSnapshot.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        let entry = SnapshotEntry(date: Date(), snapshot: WidgetSnapshot.load())
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct RingView: View {
    let progress: Double
    var lineWidth: CGFloat = 8

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.25), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(brand, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))%")
                .font(.system(.caption, design: .monospaced).weight(.bold))
        }
        .padding(lineWidth / 2)
    }
}

struct BudgetWidgetView: View {
    let snapshot: WidgetSnapshot

    private var progress: Double {
        guard snapshot.budgetLimit > 0 else { return 0 }
        return min(snapshot.budgetSpent / snapshot.budgetLimit, 1)
    }

    private var remaining: Double {
        max(snapshot.budgetLimit - snapshot.budgetSpent, 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("BUDGET")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.secondary)

            Text(euro(snapshot.budgetSpent))
                .font(.system(.title2, design: .monospaced).weight(.bold))
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text("od \(euro(snapshot.budgetLimit))")
                .font(.caption)
                .foregroundStyle(.secondary)

            ProgressView(value: progress)
                .tint(progress >= 1 ? .red : brand)

            Text("ostane \(euro(remaining))")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }
}

struct ProjectionWidgetView: View {
    let snapshot: WidgetSnapshot

    private var overBudget: Bool {
        snapshot.budgetLimit > 0 && snapshot.projected > snapshot.budgetLimit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("PROJEKCIJA")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.secondary)

            Text(euro(snapshot.projected))
                .font(.system(.title2, design: .monospaced).weight(.bold))
                .foregroundStyle(overBudget ? .red : .primary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text("do konca meseca")
                .font(.caption)
                .foregroundStyle(.secondary)

            if snapshot.budgetLimit > 0 {
                Text(overBudget
                     ? "nad budgetom za \(euro(snapshot.projected - snapshot.budgetLimit))"
                     : "v okviru budgeta")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(overBudget ? .red : .green)
            }
        }
    }
}

struct GoalsWidgetView: View {
    let snapshot: WidgetSnapshot
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if snapshot.goals.isEmpty {
            Text("Še nimaš ciljev")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else if family == .systemSmall, let goal = snapshot.goals.first {
            VStack(alignment: .leading, spacing: 6) {
                Text("CILJ")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
                HStack {
                    RingView(progress: goal.progress, lineWidth: 7)
                        .frame(width: 54, height: 54)
                    Spacer(minLength: 0)
                }
                Text(goal.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text("\(euro(goal.saved)) / \(euro(goal.target))")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text("CILJI")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
                ForEach(snapshot.goals) { goal in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(goal.name)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                            Spacer()
                            Text("\(Int(goal.progress * 100)) %")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                        ProgressView(value: goal.progress)
                            .tint(brand)
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }
}

struct BudgetWidget: Widget {
    let kind = "BudgetWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SnapshotProvider()) { entry in
            BudgetWidgetView(snapshot: entry.snapshot)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Budget")
        .description("Poraba tega meseca glede na budget.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct ProjectionWidget: Widget {
    let kind = "ProjectionWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SnapshotProvider()) { entry in
            ProjectionWidgetView(snapshot: entry.snapshot)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Projekcija")
        .description("Ocena porabe do konca meseca.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct GoalsWidget: Widget {
    let kind = "GoalsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SnapshotProvider()) { entry in
            GoalsWidgetView(snapshot: entry.snapshot)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Cilji")
        .description("Napredek tvojih ciljev.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
