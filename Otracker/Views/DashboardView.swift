import SwiftUI
import SwiftData
import Charts

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let category: String
    let totalAmount: Double
}

struct MonthlyTrendData: Identifiable {
    var id: String { category }
    let category: String
    let currentMonthAmount: Double
    let previousMonthAmount: Double
}

struct TrendComparisonData {
    let percentage: Double?
    let trendColor: Color
    let trendIconName: String
    let isPositive: Bool
}

enum TimeRange: String, CaseIterable, Identifiable {
    case daily = "dashboard_daily"
    case weekly = "dashboard_weekly"
    case monthly = "dashboard_monthly"
    var id: String { self.rawValue }
}

struct DashboardView: View {
    @State private var selectedTimeRange: TimeRange = .monthly
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]

    private var summaryData: (total: Double, transactions: [Transaction]) {
        let calendar = Calendar.current
        let now = Date()
        let dateRange: ClosedRange<Date>
        
        switch selectedTimeRange {
        case .daily:
            let startOfDay = calendar.startOfDay(for: now)
            dateRange = startOfDay...now
        case .weekly:
            guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else { return (0, []) }
            dateRange = startOfWeek...now
        case .monthly:
            guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else { return (0, []) }
            dateRange = startOfMonth...now
        }
        
        let filteredTransactions = transactions.filter { dateRange.contains($0.date) }
        let total = filteredTransactions.reduce(0) { $0 + $1.amount }
        return (total, filteredTransactions)
    }
    
    private var chartData: [ChartDataPoint] {
            let filteredTransactions = summaryData.transactions
            let noCategoryString = NSLocalizedString("dashboard_no_category", comment: "Fallback for uncategorized items")
            
            let groupedByCategory = Dictionary(grouping: filteredTransactions) {
                $0.category?.name ?? noCategoryString
            }
            
            return groupedByCategory.map { categoryName, transactions in
                let totalAmount = transactions.reduce(0) { $0 + $1.amount }
                return ChartDataPoint(category: categoryName, totalAmount: totalAmount)
            }
    }
    
    private var spendingTrendsChartData: (previousMonthTotal: Double, chartData: [MonthlyTrendData]) {
        let calendar = Calendar.current
        let now = Date()
        
        guard let currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let previousMonthStart = calendar.date(byAdding: .month, value: -1, to: currentMonthStart)
        else { return (0, []) }
        
        let currentMonthRange = currentMonthStart...now
        let previousMonthRange = previousMonthStart..<currentMonthStart
        
        let currentMonthTransactions = transactions.filter { currentMonthRange.contains($0.date) }
        let previousMonthTransactions = transactions.filter { previousMonthRange.contains($0.date) }
        
        let previousMonthTotal = previousMonthTransactions.reduce(0) { $0 + $1.amount }
        
        let allCategories = Set(
            (currentMonthTransactions + previousMonthTransactions).compactMap { $0.category }
        )
        
        var trendData: [MonthlyTrendData] = []
        for category in allCategories.sorted(by: { $0.name < $1.name }) {
            let currentAmount = currentMonthTransactions.filter { $0.category == category }.reduce(0) { $0 + $1.amount }
            let previousAmount = previousMonthTransactions.filter { $0.category == category }.reduce(0) { $0 + $1.amount }
            
            if currentAmount > 0 || previousAmount > 0 {
                trendData.append(.init(category: category.name, currentMonthAmount: currentAmount, previousMonthAmount: previousAmount))
            }
        }
        
        return (previousMonthTotal, trendData)
    }
    
    private var trendComparison: TrendComparisonData {

        guard let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) else {
            return .init(percentage: nil, trendColor: .secondary, trendIconName: "questionmark.circle", isPositive: false)
        }
        let currentMonthTotal = transactions.filter { $0.date >= startOfMonth }.reduce(0, { $0 + $1.amount })
        let previousMonthTotal = spendingTrendsChartData.previousMonthTotal
        
        if previousMonthTotal == 0 && currentMonthTotal == 0 {
            return .init(percentage: nil, trendColor: .secondary, trendIconName: "arrow.left.and.right", isPositive: false)
        }
        
        let difference = currentMonthTotal - previousMonthTotal
        var percentage: Double? = nil
        
        if previousMonthTotal > 0 {
            percentage = (difference / previousMonthTotal) * 100
        } else if currentMonthTotal > 0 {
            percentage = 100
        }
        
        let isPositive = difference > 0
        let trendColor: Color = isPositive ? .red : (difference < 0 ? .green : .secondary)
        let trendIcon: String = isPositive ? "chart.line.uptrend.xyaxis" : (difference < 0 ? "chart.line.downtrend.xyaxis" : "arrow.left.and.right")
        
        return .init(percentage: percentage, trendColor: trendColor, trendIconName: trendIcon, isPositive: isPositive)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack {
                        Picker(LocalizedStringKey("dashboard_SelectedTimeRange"), selection: $selectedTimeRange) {
                                                    ForEach(TimeRange.allCases) { range in
                                                        Text(LocalizedStringKey(range.rawValue)).tag(range)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        Text(
                                String(format: NSLocalizedString("dashboard_spending_for", comment: "Label for spending period"),
                                NSLocalizedString(selectedTimeRange.rawValue, comment: "The selected time range"))
                                )
                                    .font(.headline).foregroundColor(.secondary).padding(.top, 8)
                                                Text(summaryData.total, format: .currency(code: "IDR"))
                                                    .font(.system(size: 40, weight: .bold, design: .rounded)).foregroundColor(.green)
                        
                        if !chartData.isEmpty {
                            Chart(chartData) { dataPoint in
                                SectorMark(angle: .value(NSLocalizedString("dashboard_amount", comment: ""), dataPoint.totalAmount), innerRadius: .ratio(0.618), angularInset: 1.5)
                                    .foregroundStyle(by: .value(NSLocalizedString("dashboard_category", comment: ""), NSLocalizedString(dataPoint.category, comment: "")))
                                    .cornerRadius(5)
                            }
                            .frame(height: 250)
                            .chartLegend(position: .bottom, alignment: .center)
                        } else {
                            ContentUnavailableView("dashboard_no_data", systemImage: "chart.bar.xaxis").frame(height: 250)
                        }
                    }
                    
                    Divider()

                    VStack(alignment: .leading, spacing: 16) {
                        Text("dashboard_trend_title")
                            .font(.title2.bold())
                        
                        HStack {
                            let comparison = trendComparison
                            
                            VStack(alignment: .leading) {
                                Text("dashboard_vs_last_month")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                if let percentage = comparison.percentage {
                                    Text("\(comparison.isPositive ? "+" : "")\(percentage, specifier: "%.0f")%")
                                        .font(.title.bold())
                                        .foregroundStyle(comparison.trendColor)
                                } else {
                                    Text("N/A")
                                        .font(.title.bold())
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: comparison.trendIconName)
                                .font(.largeTitle)
                                .foregroundStyle(comparison.trendColor)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        Text("dashboard_category_comparison")
                            .font(.headline)
                        
                        let chartData = spendingTrendsChartData.chartData
                        if !chartData.isEmpty {
                            Chart(chartData) { data in
                                BarMark(x: .value("dashboard_amount", data.currentMonthAmount), y: .value("dashboard_category", data.category))
                                    .foregroundStyle(by: .value("Bulan", "Bulan Ini"))
                                    .position(by: .value("Bulan", "Bulan Ini"))
                                
                                BarMark(x: .value("dashboard_amount", data.previousMonthAmount), y: .value("dashboard_category", data.category))
                                    .foregroundStyle(by: .value("Bulan", "Bulan Lalu"))
                                    .position(by: .value("Bulan", "Bulan Lalu"))
                            }
                            .chartYAxis { AxisMarks(position: .leading) }
                            .chartLegend(position: .top, alignment: .trailing)
                            .frame(height: CGFloat(chartData.count) * 60)
                        } else {
                            ContentUnavailableView("dashboard_no_data", systemImage: "chart.bar")
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("dashboard_title")
        }
    }
}
