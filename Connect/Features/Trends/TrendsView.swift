import SwiftUI
import SwiftData
import Charts

struct TrendsView: View {
    @Query private var people: [Person]
    @Query private var settingsList: [UserSettings]

    private var active: [Person] { people.filter { $0.archivedAt == nil } }
    private var settings: UserSettings { settingsList.first ?? UserSettings() }
    private var metrics: MetricsService { MetricsService() }
    private var weekly: WeeklySummary { metrics.weeklySummary(active, target: settings.dailyTarget) }
    private var coverage: Double { metrics.coverage(active) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ConnectCard {
                        SectionLabel(text: "Relationship coverage")
                        Text(coverage, format: .percent.precision(.fractionLength(0))).font(.system(size: 52, weight: .bold, design: .rounded)).foregroundStyle(ConnectTheme.accent)
                        Text("\(Int((coverage * Double(active.count)).rounded())) of \(active.count) relationships within their intended rhythm").font(.subheadline).foregroundStyle(.secondary)
                    }
                    SectionLabel(text: "This week")
                    HStack(spacing: 10) {
                        MetricCard(value: "\(weekly.connections)", label: "Connections")
                        MetricCard(value: "\(weekly.peopleReached)", label: "People reached")
                        MetricCard(value: "\(weekly.meaningful)", label: "Meaningful")
                    }
                    ConnectCard {
                        SectionLabel(text: "Last 14 days")
                        Chart(metrics.dailyMetrics(active, target: settings.dailyTarget)) { item in
                            BarMark(x: .value("Day", item.date, unit: .day), y: .value("Connections", item.connections)).foregroundStyle(ConnectTheme.accent.gradient).cornerRadius(4)
                            RuleMark(y: .value("Target", item.target)).foregroundStyle(.secondary.opacity(0.5)).lineStyle(.init(dash: [4]))
                        }.frame(height: 190).chartYAxis { AxisMarks(position: .leading) }.padding(.top, 8)
                    }
                    ConnectCard {
                        SectionLabel(text: "Your week")
                        Text(weekly.rhythm, format: .percent.precision(.fractionLength(0))).font(.title.bold()).padding(.top, 3)
                        Text(weekly.rhythm >= 0.8 ? "You stayed in rhythm with most of your intended connections." : "Every connection counts. Your schedule can adapt to what feels manageable.").foregroundStyle(.secondary)
                    }
                }.padding()
            }.background(ConnectTheme.background).navigationTitle("Trends")
        }
    }
}

private struct MetricCard: View {
    let value: String; let label: String
    var body: some View { VStack(alignment: .leading, spacing: 4) { Text(value).font(.title.bold()); Text(label).font(.caption).foregroundStyle(.secondary).lineLimit(2) }.frame(maxWidth: .infinity, minHeight: 70, alignment: .leading).padding(12).background(ConnectTheme.card, in: RoundedRectangle(cornerRadius: 16)) }
}
