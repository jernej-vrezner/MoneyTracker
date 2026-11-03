import WidgetKit
import SwiftUI
import Charts

// MARK: - Barve in pomožne funkcije

private enum Palette {
    static let ink = Color(red: 0.94, green: 0.92, blue: 1.0)
    static let darkInk = Color(red: 0.12, green: 0.09, blue: 0.25)
    static let violet = Color(red: 0.655, green: 0.549, blue: 0.980)
    static let budgetBackground = Color(red: 0.16, green: 0.13, blue: 0.38)
    static let overBackground = Color(red: 0.29, green: 0.12, blue: 0.18)
    static let darkBackground = Color(red: 0.11, green: 0.10, blue: 0.15)
    static let goalBackground = Color(red: 0.27, green: 0.20, blue: 0.60)
    static let reachedBackground = Color(red: 0.09, green: 0.38, blue: 0.31)
    static let mint = Color(red: 0.49, green: 0.90, blue: 0.75)
    static let pink = Color(red: 1.0, green: 0.56, blue: 0.66)
}

private func categoryColor(_ name: String) -> Color {
    switch name {
    case "red": return Color(red: 1.0, green: 0.55, blue: 0.65)
    case "blue": return Color(red: 0.45, green: 0.65, blue: 1.0)
    case "green": return Color(red: 0.45, green: 0.85, blue: 0.55)
    case "orange": return Color(red: 1.0, green: 0.72, blue: 0.35)
    case "purple": return Palette.violet
    case "yellow": return Color(red: 1.0, green: 0.85, blue: 0.35)
    case "pink": return Color(red: 1.0, green: 0.60, blue: 0.80)
    case "teal": return Color(red: 0.35, green: 0.80, blue: 0.80)
    case "indigo": return Color(red: 0.55, green: 0.55, blue: 1.0)
    case "mint": return Palette.mint
    case "cyan": return Color(red: 0.40, green: 0.85, blue: 1.0)
    case "brown": return Color(red: 0.75, green: 0.55, blue: 0.40)
    default: return Palette.violet
    }
}

private func wholeEuro(_ value: Double) -> String {
    Int(value.rounded()).formatted()
}

private func euroText(_ value: Double) -> String {
    value.formatted(.currency(code: "EUR"))
}

private func addURL(type: String, category: String? = nil) -> URL {
    var string = "moneytracker://add?type=\(type)"
    if let category,
       let encoded = category.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
        string += "&category=\(encoded)"
    }
    return URL(string: string) ?? URL(string: "moneytracker://add")!
}

// MARK: - Podatki

struct SnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct SnapshotProvider: TimelineProvider {
    func placeholder(in context: Context) -> SnapshotEntry {
        SnapshotEntry(
            date: Date(),
            snapshot: WidgetSnapshot(
                budgetSpent: 298,
                budgetLimit: 450,
                projected: 480,
                dayOfMonth: 12,
                daysInMonth: 30,
                dailySpend: [12, 8, 30, 5, 22, 0, 18, 9, 40, 15, 25, 14],
                todaySpent: 14,
                categories: [
                    CategorySnapshot(name: "Hrana", icon: "fork.knife", colorName: "red", spent: 72, limit: 120),
                    CategorySnapshot(name: "Dom", icon: "house.fill", colorName: "blue", spent: 45, limit: 80),
                    CategorySnapshot(name: "Avto", icon: "car.fill", colorName: "teal", spent: 30, limit: 40)
                ],
                goals: [GoalSnapshot(name: "MacBook", saved: 300, target: 1000, deadline: Date())],
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

// MARK: - Skupne male komponente

private struct BarMeter: View {
    let progress: Double
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Palette.ink.opacity(0.15))
                Capsule()
                    .fill(color)
                    .frame(width: geometry.size.width * min(max(progress, 0), 1))
            }
        }
        .frame(height: 7)
    }
}

private struct BigEuro: View {
    let text: String
    let color: Color
    var size: CGFloat = 36

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(text)
                .font(.system(size: size, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text("€")
                .font(.system(size: size * 0.5, weight: .bold, design: .rounded))
                .opacity(0.6)
        }
        .foregroundStyle(color)
    }
}

// MARK: - Budget

private struct BudgetSmallView: View {
    let snapshot: WidgetSnapshot

    private var remaining: Double { snapshot.budgetLimit - snapshot.budgetSpent }
    private var hasBudget: Bool { snapshot.budgetLimit > 0 }
    private var over: Bool { hasBudget && remaining < 0 }
    private var daysLeft: Int { max(snapshot.daysInMonth - snapshot.dayOfMonth, 1) }
    private var maxDaily: Double { max(snapshot.dailySpend.max() ?? 0, 1) }

    private var bigText: String {
        if !hasBudget { return wholeEuro(snapshot.budgetSpent) }
        return (over ? "−" : "") + wholeEuro(abs(remaining))
    }

    private var subtitle: String {
        if !hasBudget { return "porabljeno ta mesec" }
        return over ? "čez budget" : "še lahko zapraviš"
    }

    private var footer: String {
        if !hasBudget { return "Nastavi budget v aplikaciji" }
        if over { return "Še \(daysLeft) dni. Brez nakupov?" }
        return "≈ \(wholeEuro(remaining / Double(daysLeft))) € na dan do konca"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("BUDGET")
                Spacer()
                Text("dan \(snapshot.dayOfMonth)/\(snapshot.daysInMonth)")
            }
            .font(.system(size: 9, design: .monospaced))
            .foregroundStyle(Palette.ink.opacity(0.6))

            BigEuro(text: bigText, color: over ? Palette.pink : Palette.ink)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(Palette.ink.opacity(0.85))

            Spacer(minLength: 2)

            HStack(alignment: .bottom, spacing: 1.5) {
                ForEach(0..<snapshot.daysInMonth, id: \.self) { index in
                    if index < snapshot.dailySpend.count {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(over ? Palette.pink : Palette.violet)
                            .frame(height: max(3, 22 * snapshot.dailySpend[index] / maxDaily))
                            .frame(maxWidth: .infinity)
                    } else {
                        Circle()
                            .fill(Palette.ink.opacity(0.3))
                            .frame(width: 2, height: 2)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .frame(height: 22, alignment: .bottom)

            Text(footer)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(Palette.ink.opacity(0.6))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

private struct BudgetMediumView: View {
    let snapshot: WidgetSnapshot

    private var remaining: Double { snapshot.budgetLimit - snapshot.budgetSpent }
    private var hasBudget: Bool { snapshot.budgetLimit > 0 }
    private var over: Bool { hasBudget && remaining < 0 }
    private var daysLeft: Int { max(snapshot.daysInMonth - snapshot.dayOfMonth, 1) }

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("BUDGET · \(Date().formatted(.dateTime.month(.abbreviated)).uppercased())")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Palette.ink.opacity(0.6))

                BigEuro(
                    text: hasBudget ? (over ? "−" : "") + wholeEuro(abs(remaining)) : wholeEuro(snapshot.budgetSpent),
                    color: over ? Palette.pink : Palette.ink
                )

                Text(hasBudget ? (over ? "čez budget" : "še na voljo") : "porabljeno")
                    .font(.caption)
                    .foregroundStyle(Palette.ink.opacity(0.85))

                Spacer(minLength: 0)

                Text(hasBudget && !over
                     ? "dan \(snapshot.dayOfMonth)/\(snapshot.daysInMonth) · \(wholeEuro(remaining / Double(daysLeft))) €/dan"
                     : "dan \(snapshot.dayOfMonth)/\(snapshot.daysInMonth)")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Palette.ink.opacity(0.6))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: 120, alignment: .leading)

            VStack(spacing: 7) {
                if snapshot.categories.isEmpty {
                    Text("Še ni kategorij")
                        .font(.caption)
                        .foregroundStyle(Palette.ink.opacity(0.6))
                } else {
                    ForEach(snapshot.categories.prefix(4)) { category in
                        let isOver = category.limit > 0 && category.spent > category.limit
                        VStack(spacing: 3) {
                            HStack {
                                Text(category.name)
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .lineLimit(1)
                                Spacer(minLength: 4)
                                Text(category.limit > 0
                                     ? "\(wholeEuro(category.spent)) / \(wholeEuro(category.limit)) €"
                                     : "\(wholeEuro(category.spent)) €")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(isOver ? Palette.pink : Palette.ink.opacity(0.6))
                            }
                            .foregroundStyle(Palette.ink)
                            BarMeter(
                                progress: category.limit > 0 ? category.spent / category.limit : 0,
                                color: isOver ? Palette.pink : categoryColor(category.colorName)
                            )
                        }
                    }
                }
            }
        }
    }
}

private struct BudgetEntryView: View {
    let snapshot: WidgetSnapshot
    @Environment(\.widgetFamily) private var family

    private var over: Bool {
        snapshot.budgetLimit > 0 && snapshot.budgetSpent > snapshot.budgetLimit
    }

    var body: some View {
        Group {
            if family == .systemMedium {
                BudgetMediumView(snapshot: snapshot)
            } else {
                BudgetSmallView(snapshot: snapshot)
            }
        }
        .containerBackground(for: .widget) {
            over ? Palette.overBackground : Palette.budgetBackground
        }
    }
}

// MARK: - Projekcija

private struct ProjectionSmallView: View {
    let snapshot: WidgetSnapshot

    private var cumulative: [Double] {
        var total = 0.0
        return snapshot.dailySpend.map { value in
            total += value
            return total
        }
    }

    private var lastDayLabel: String {
        let month = Calendar.current.component(.month, from: Date())
        return "\(snapshot.daysInMonth). \(month)."
    }

    private var difference: Double { snapshot.budgetLimit - snapshot.projected }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("PROJEKCIJA")
                Spacer()
                Text(snapshot.dayOfMonth < 5 ? "dan \(snapshot.dayOfMonth)/\(snapshot.daysInMonth)" : lastDayLabel)
            }
            .font(.system(size: 9, design: .monospaced))
            .foregroundStyle(Palette.ink.opacity(0.6))

            if snapshot.dayOfMonth < 5 {
                Spacer()
                Text("Spoznavam tvoj mesec")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.ink)
                Text("napoved po 5. dnevu")
                    .font(.caption)
                    .foregroundStyle(Palette.ink.opacity(0.6))
            } else {
                BigEuro(text: "~" + wholeEuro(snapshot.projected), color: Palette.ink, size: 30)

                chart
                    .frame(maxHeight: .infinity)

                if snapshot.budgetLimit > 0 {
                    Text(difference >= 0
                         ? "\(wholeEuro(difference)) € pod limitom"
                         : "\(wholeEuro(-difference)) € nad limitom")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(difference >= 0 ? Palette.mint : Palette.pink)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background((difference >= 0 ? Palette.mint : Palette.pink).opacity(0.15))
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var chart: some View {
        let points = cumulative
        let today = max(snapshot.dayOfMonth, 1)
        let todayValue = points.last ?? 0
        let yMax = max(snapshot.budgetLimit, snapshot.projected, todayValue, 1) * 1.1

        return Chart {
            ForEach(points.indices, id: \.self) { index in
                LineMark(
                    x: .value("Dan", index + 1),
                    y: .value("Skupaj", points[index]),
                    series: .value("Vrsta", "dejansko")
                )
                .foregroundStyle(Palette.violet)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }

            LineMark(
                x: .value("Dan", today),
                y: .value("Skupaj", todayValue),
                series: .value("Vrsta", "napoved")
            )
            .foregroundStyle(Palette.violet.opacity(0.7))
            .lineStyle(StrokeStyle(lineWidth: 2, dash: [2, 3]))

            LineMark(
                x: .value("Dan", snapshot.daysInMonth),
                y: .value("Skupaj", snapshot.projected),
                series: .value("Vrsta", "napoved")
            )
            .foregroundStyle(Palette.violet.opacity(0.7))
            .lineStyle(StrokeStyle(lineWidth: 2, dash: [2, 3]))

            if snapshot.budgetLimit > 0 {
                RuleMark(y: .value("Limit", snapshot.budgetLimit))
                    .foregroundStyle(Palette.pink.opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartXScale(domain: 1...max(snapshot.daysInMonth, 2))
        .chartYScale(domain: 0...yMax)
    }
}

private struct ProjectionEntryView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        ProjectionSmallView(snapshot: snapshot)
            .containerBackground(for: .widget) { Palette.darkBackground }
    }
}

// MARK: - Cilji

private struct GoalRing: View {
    let progress: Double
    let reached: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(Palette.ink.opacity(0.15), lineWidth: 20)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(reached ? Palette.mint : Palette.violet, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 110, height: 110)
    }
}

private struct GoalSmallView: View {
    let goal: GoalSnapshot?

    var body: some View {
        if let goal {
            let reached = goal.progress >= 1
            ZStack(alignment: .topTrailing) {
                GoalRing(progress: goal.progress, reached: reached)
                    .offset(x: 38, y: -38)

                VStack(alignment: .leading, spacing: 3) {
                    if reached {
                        HStack(spacing: 4) {
                            Text("Doseženo")
                            Image(systemName: "checkmark")
                        }
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.ink)
                        .minimumScaleFactor(0.6)
                    } else {
                        HStack(alignment: .firstTextBaseline, spacing: 1) {
                            Text("\(Int(goal.progress * 100))")
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                            Text("%")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .opacity(0.6)
                        }
                        .foregroundStyle(Palette.ink)
                    }

                    Spacer(minLength: 0)

                    HStack(spacing: 5) {
                        Image(systemName: "target")
                        Text(goal.name)
                            .lineLimit(1)
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.ink)

                    Text(reached
                         ? "\(wholeEuro(goal.target)) €"
                         : "še \(wholeEuro(goal.target - goal.saved)) € · do \(goal.deadline.formatted(.dateTime.month(.abbreviated)))")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Palette.ink.opacity(0.7))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
        } else {
            VStack(alignment: .leading, spacing: 4) {
                Text("CILJI")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Palette.ink.opacity(0.6))
                Spacer()
                Text("Še nimaš ciljev")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.ink)
                Text("Dodaj prvega v aplikaciji")
                    .font(.caption)
                    .foregroundStyle(Palette.ink.opacity(0.7))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}

private struct GoalMediumView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CILJI")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(Palette.ink.opacity(0.6))

            if snapshot.goals.isEmpty {
                Text("Še nimaš ciljev")
                    .font(.caption)
                    .foregroundStyle(Palette.ink.opacity(0.7))
            } else {
                ForEach(snapshot.goals) { goal in
                    VStack(spacing: 4) {
                        HStack {
                            Text(goal.name)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .lineLimit(1)
                            Spacer()
                            Text("\(Int(goal.progress * 100)) %")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(Palette.ink.opacity(0.7))
                        }
                        .foregroundStyle(Palette.ink)
                        BarMeter(progress: goal.progress, color: goal.progress >= 1 ? Palette.mint : Palette.violet)
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }
}

private struct GoalEntryView: View {
    let snapshot: WidgetSnapshot
    @Environment(\.widgetFamily) private var family

    private var reached: Bool {
        (snapshot.goals.first?.progress ?? 0) >= 1
    }

    var body: some View {
        Group {
            if family == .systemMedium {
                GoalMediumView(snapshot: snapshot)
            } else {
                GoalSmallView(goal: snapshot.goals.first)
            }
        }
        .containerBackground(for: .widget) {
            if family == .systemMedium {
                Palette.darkBackground
            } else {
                reached ? Palette.reachedBackground : Palette.goalBackground
            }
        }
    }
}

// MARK: - Hiter vnos

private struct QuickAddSmallView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Palette.violet)
                .frame(width: 42, height: 42)
                .background(Palette.darkInk)
                .clipShape(Circle())

            Spacer()

            Text("Kaj si kupil?")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.darkInk)
            Text("danes −\(euroText(snapshot.todaySpent))")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Palette.darkInk.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .widgetURL(addURL(type: "expense"))
    }
}

private struct QuickAddTile: View {
    let title: String
    let icon: String
    let color: Color
    let url: URL

    var body: some View {
        Link(destination: url) {
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(color)
                Spacer(minLength: 0)
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
            }
            .padding(10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(color.opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

private struct QuickAddMediumView: View {
    let snapshot: WidgetSnapshot

    private var tiles: [(title: String, icon: String, color: Color, url: URL)] {
        var result: [(title: String, icon: String, color: Color, url: URL)] = []
        for category in snapshot.categories.prefix(3) {
            result.append((
                title: category.name,
                icon: category.icon,
                color: categoryColor(category.colorName),
                url: addURL(type: "expense", category: category.name)
            ))
        }
        result.append((title: "Priliv", icon: "plus", color: Palette.mint, url: addURL(type: "income")))
        return result
    }

    var body: some View {
        HStack(spacing: 8) {
            Link(destination: addURL(type: "expense")) {
                VStack(alignment: .leading, spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Palette.violet)
                        .frame(width: 42, height: 42)
                        .background(Palette.darkInk)
                        .clipShape(Circle())
                    Spacer()
                    Text("Nov vnos")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.darkInk)
                    Text("danes −\(euroText(snapshot.todaySpent))")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Palette.darkInk.opacity(0.7))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .background(Palette.violet)
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }

            let items = tiles
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    ForEach(0..<min(2, items.count), id: \.self) { index in
                        QuickAddTile(title: items[index].title, icon: items[index].icon, color: items[index].color, url: items[index].url)
                    }
                }
                HStack(spacing: 8) {
                    ForEach(2..<max(items.count, 2), id: \.self) { index in
                        QuickAddTile(title: items[index].title, icon: items[index].icon, color: items[index].color, url: items[index].url)
                    }
                }
            }
        }
    }
}

private struct QuickAddEntryView: View {
    let snapshot: WidgetSnapshot
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if family == .systemMedium {
                QuickAddMediumView(snapshot: snapshot)
            } else {
                QuickAddSmallView(snapshot: snapshot)
            }
        }
        .containerBackground(for: .widget) {
            family == .systemMedium ? Palette.darkBackground : Palette.violet
        }
    }
}

// MARK: - Definicije widgetov

struct BudgetWidget: Widget {
    let kind = "BudgetWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SnapshotProvider()) { entry in
            BudgetEntryView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("Budget")
        .description("Koliko še lahko zapraviš ta mesec.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct ProjectionWidget: Widget {
    let kind = "ProjectionWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SnapshotProvider()) { entry in
            ProjectionEntryView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("Projekcija")
        .description("Kje boš pristal do konca meseca.")
        .supportedFamilies([.systemSmall])
    }
}

struct GoalsWidget: Widget {
    let kind = "GoalsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SnapshotProvider()) { entry in
            GoalEntryView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("Cilji")
        .description("Napredek tvojih ciljev.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct QuickAddWidget: Widget {
    let kind = "QuickAddWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SnapshotProvider()) { entry in
            QuickAddEntryView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("Nov vnos")
        .description("Hiter vnos odliva ali priliva.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
