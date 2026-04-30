import SwiftUI

// MARK: - Calendar Mode
enum CalendarMode: Int, Comparable {
    case year = 0
    case month = 1
    case week = 2
    case day = 3
    
    static func < (lhs: CalendarMode, rhs: CalendarMode) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

struct CalendarView: View {
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var themeManager: ThemeManager
    private let calendar = Calendar.current
    
    @State private var mode: CalendarMode = .year
    @State private var referenceDate: Date = Date()
    
    // Tab selection offsets (simulating infinite scroll)
    @State private var yearOffset: Int = 0
    @State private var monthOffset: Int = 0
    @State private var weekOffset: Int = 0
    @State private var dayOffset: Int = 0
    
    // For popping to root
    @State private var navigationId = UUID()
    
    // A stable base date for offset calculations
    private let baseDate = Calendar.current.startOfDay(for: Date())
    
    private var workoutDays: Set<Date> {
        Set(dataManager.workouts.map { calendar.startOfDay(for: $0.date) })
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                navigationHeader
                Divider()
                
                ZStack {
                    if mode == .year {
                        TabView(selection: $yearOffset) {
                            ForEach(-50...50, id: \.self) { offset in
                                YearPage(
                                    date: date(byAdding: .year, value: offset, to: baseDate),
                                    colorForDay: colorFor(day:),
                                    onMonthTap: zoomToMonth
                                )
                                .tag(offset)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .transition(.asymmetric(insertion: .scale(scale: 0.8).combined(with: .opacity),
                                                removal: .scale(scale: 1.2).combined(with: .opacity)))
                    } else if mode == .month {
                        TabView(selection: $monthOffset) {
                            ForEach(-600...600, id: \.self) { offset in
                                MonthPage(
                                    date: date(byAdding: .month, value: offset, to: baseDate),
                                    workoutDays: workoutDays,
                                    colorForDay: colorFor(day:),
                                    onDayTap: zoomToWeek
                                )
                                .tag(offset)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .transition(.asymmetric(insertion: .scale(scale: 0.8).combined(with: .opacity),
                                                removal: .scale(scale: 1.2).combined(with: .opacity)))
                    } else if mode == .week {
                        TabView(selection: $weekOffset) {
                            ForEach(-2600...2600, id: \.self) { offset in
                                WeekPage(
                                    date: date(byAdding: .weekOfYear, value: offset, to: baseDate),
                                    workoutDays: workoutDays,
                                    colorForDay: colorFor(day:),
                                    colorForWorkout: colorFor(workout:),
                                    onDayTap: zoomToDay
                                )
                                .tag(offset)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .transition(.asymmetric(insertion: .scale(scale: 0.8).combined(with: .opacity),
                                                removal: .scale(scale: 1.2).combined(with: .opacity)))
                    } else if mode == .day {
                        TabView(selection: $dayOffset) {
                            ForEach(-10000...10000, id: \.self) { offset in
                                DayPage(
                                    date: date(byAdding: .day, value: offset, to: baseDate)
                                )
                                .tag(offset)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .transition(.asymmetric(insertion: .scale(scale: 0.8).combined(with: .opacity),
                                                removal: .scale(scale: 1.2).combined(with: .opacity)))
                    }
                }
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Today") {
                        goToToday()
                    }
                }
            }
            .id(navigationId)
            .onReceive(dataManager.$popToRootCalendar) { _ in
                // When we receive a pop signal, we reset to year mode and today
                withAnimation(.spring()) {
                    mode = .year
                    goToToday()
                    navigationId = UUID() // Force refresh
                }
            }
        }
    }
    
    // MARK: - Navigation
    @ViewBuilder
    private var navigationHeader: some View {
        HStack {
            if mode != .year {
                Button(action: zoomOut) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text(backButtonTitle)
                    }
                    .font(.headline)
                    .foregroundColor(.accentColor)
                }
            }
            Spacer()
            Text(headerTitle)
                .font(.headline)
                .fontWeight(.bold)
            Spacer()
            // Placeholder to keep title centered
            if mode != .year {
                Text(backButtonTitle).hidden().overlay(Image(systemName: "chevron.left").hidden(), alignment: .leading)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var backButtonTitle: String {
        switch mode {
        case .month: return "Year"
        case .week: return "Month"
        case .day: return "Week"
        default: return ""
        }
    }
    
    private var headerTitle: String {
        switch mode {
        case .year:
            let d = date(byAdding: .year, value: yearOffset, to: baseDate)
            return "\(calendar.component(.year, from: d))"
        case .month:
            let d = date(byAdding: .month, value: monthOffset, to: baseDate)
            let fmt = DateFormatter(); fmt.dateFormat = "MMMM yyyy"
            return fmt.string(from: d)
        case .week:
            let d = date(byAdding: .weekOfYear, value: weekOffset, to: baseDate)
            let weekStart = startOfWeek(for: d)
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
            let fmt = DateFormatter(); fmt.dateFormat = "MMM d"
            return "\(fmt.string(from: weekStart)) – \(fmt.string(from: weekEnd))"
        case .day:
            let d = date(byAdding: .day, value: dayOffset, to: baseDate)
            let fmt = DateFormatter(); fmt.dateStyle = .long
            return fmt.string(from: d)
        }
    }
    
    // MARK: - Zooming & Actions
    private func zoomToMonth(date: Date) {
        let offset = calendar.dateComponents([.month], from: baseDate, to: date).month ?? 0
        monthOffset = offset
        withAnimation(.spring()) {
            mode = .month
        }
    }
    
    private func zoomToWeek(date: Date) {
        let offset = calendar.dateComponents([.weekOfYear], from: baseDate, to: date).weekOfYear ?? 0
        weekOffset = offset
        withAnimation(.spring()) {
            mode = .week
        }
    }
    
    private func zoomToDay(date: Date) {
        let offset = calendar.dateComponents([.day], from: baseDate, to: date).day ?? 0
        dayOffset = offset
        withAnimation(.spring()) {
            mode = .day
        }
    }
    
    private func zoomOut() {
        withAnimation(.spring()) {
            if mode == .day {
                // Sync week offset
                let d = date(byAdding: .day, value: dayOffset, to: baseDate)
                weekOffset = calendar.dateComponents([.weekOfYear], from: baseDate, to: d).weekOfYear ?? 0
                mode = .week
            } else if mode == .week {
                // Sync month offset
                let d = date(byAdding: .weekOfYear, value: weekOffset, to: baseDate)
                monthOffset = calendar.dateComponents([.month], from: baseDate, to: d).month ?? 0
                mode = .month
            } else if mode == .month {
                // Sync year offset
                let d = date(byAdding: .month, value: monthOffset, to: baseDate)
                yearOffset = calendar.dateComponents([.year], from: baseDate, to: d).year ?? 0
                mode = .year
            }
        }
    }
    
    private func goToToday() {
        withAnimation(.spring()) {
            yearOffset = 0
            monthOffset = 0
            weekOffset = 0
            dayOffset = 0
        }
    }
    
    // MARK: - Helpers
    private func date(byAdding comp: Calendar.Component, value: Int, to date: Date) -> Date {
        return calendar.date(byAdding: comp, value: value, to: date) ?? date
    }
    
    private func startOfWeek(for date: Date) -> Date {
        let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: comps) ?? date
    }
    
    private func colorFor(day: Date) -> Color {
        guard workoutDays.contains(day) else { return Color.clear }
        let dayWorkouts = dataManager.workouts.filter { calendar.isDate($0.date, inSameDayAs: day) }
        let splits = Set(dayWorkouts.compactMap { $0.split?.id.uuidString })
        if splits.count > 1 {
            return themeManager.multipleSplitsColor
        } else if let splitId = splits.first, let c = themeManager.splitColors[splitId] {
            return c
        } else {
            return themeManager.calendarBoxColor
        }
    }
    
    private func colorFor(workout: WorkoutModel) -> Color {
        if let splitId = workout.split?.id.uuidString, let c = themeManager.splitColors[splitId] {
            return c
        }
        return themeManager.calendarBoxColor
    }
}

// MARK: - Pages

struct YearPage: View {
    let date: Date
    let colorForDay: (Date) -> Color
    let onMonthTap: (Date) -> Void
    private let calendar = Calendar.current
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 15), count: 3), spacing: 20) {
                ForEach(1...12, id: \.self) { month in
                    MiniMonthView(
                        year: calendar.component(.year, from: date),
                        month: month,
                        colorForDay: colorForDay,
                        onMonthTap: onMonthTap
                    )
                }
            }
            .padding()
        }
    }
}

struct MonthPage: View {
    let date: Date
    let workoutDays: Set<Date>
    let colorForDay: (Date) -> Color
    let onDayTap: (Date) -> Void
    private let calendar = Calendar.current
    
    var body: some View {
        let year  = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let days  = daysInMonth(year: year, month: month)
        let firstWeekday = days.first.map { calendar.component(.weekday, from: $0) } ?? 1
        let columns = Array(repeating: GridItem(.flexible()), count: 7)
        
        return ScrollView {
            VStack(spacing: 8) {
                HStack {
                    ForEach(calendar.shortWeekdaySymbols, id: \.self) { sym in
                        Text(sym.prefix(1))
                            .frame(maxWidth: .infinity)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 8)
                
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(0..<(firstWeekday - 1), id: \.self) { _ in Color.clear }
                    ForEach(days, id: \.self) { day in
                        let isWorkout = workoutDays.contains(day)
                        let isToday = calendar.isDateInToday(day)
                        Button(action: { onDayTap(day) }) {
                            ZStack {
                                Circle()
                                    .fill(isWorkout ? colorForDay(day) :
                                            isToday ? Color.accentColor.opacity(0.15) : Color(.systemGray6))
                                    .frame(width: 38, height: 38)
                                Text("\(calendar.component(.day, from: day))")
                                    .font(.system(size: 14, weight: isToday ? .bold : .regular))
                                    .foregroundColor(isWorkout ? .white : .primary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
            }
            .padding(.vertical, 8)
        }
    }
    
    private func daysInMonth(year: Int, month: Int) -> [Date] {
        var result: [Date] = []
        let comps = DateComponents(year: year, month: month)
        guard let start = calendar.date(from: comps),
              let range = calendar.range(of: .day, in: .month, for: start) else { return result }
        for day in range {
            if let d = calendar.date(from: DateComponents(year: year, month: month, day: day)) {
                result.append(d)
            }
        }
        return result
    }
}

struct WeekPage: View {
    let date: Date
    let workoutDays: Set<Date>
    let colorForDay: (Date) -> Color
    let colorForWorkout: (WorkoutModel) -> Color
    let onDayTap: (Date) -> Void
    
    @EnvironmentObject private var dataManager: DataManager
    private let calendar = Calendar.current
    
    var body: some View {
        let weekStart = startOfWeek(for: date)
        let days = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
        
        return VStack(spacing: 0) {
            HStack(spacing: 6) {
                ForEach(days, id: \.self) { day in
                    let isWorkout = workoutDays.contains(day)
                    let isToday = calendar.isDateInToday(day)
                    Button(action: { onDayTap(day) }) {
                        VStack(spacing: 6) {
                            Text(shortWeekday(for: day))
                                .font(.caption2).foregroundColor(.secondary)
                            ZStack {
                                Circle()
                                    .fill(isWorkout ? colorForDay(day) :
                                            isToday ? Color.accentColor.opacity(0.2) : Color(.systemGray6))
                                    .frame(width: 44, height: 44)
                                Text("\(calendar.component(.day, from: day))")
                                    .font(.system(size: 15, weight: isToday ? .bold : .regular))
                                    .foregroundColor(isWorkout ? .white : .primary)
                            }
                            Circle()
                                .fill(isWorkout ? colorForDay(day) : Color.clear)
                                .frame(width: 5, height: 5)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6).opacity(0.5))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(days, id: \.self) { day in
                        let dayWorkouts = dataManager.workouts.filter {
                            calendar.isDate($0.date, inSameDayAs: day)
                        }
                        if !dayWorkouts.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(day.formatted(.dateTime.weekday(.wide).month().day()))
                                    .font(.headline)
                                    .padding(.horizontal)
                                ForEach(dayWorkouts) { w in
                                    HStack {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(colorForWorkout(w))
                                            .frame(width: 4)
                                        VStack(alignment: .leading) {
                                            Text(w.name).font(.subheadline).fontWeight(.medium)
                                            Text("\(w.exerciseArray.count) exercises · \(w.duration) min")
                                                .font(.caption).foregroundColor(.secondary)
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    if days.allSatisfy({ day in !workoutDays.contains(day) }) {
                        Text("No workouts this week.")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 30)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    private func startOfWeek(for date: Date) -> Date {
        let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: comps) ?? date
    }
    
    private func shortWeekday(for date: Date) -> String {
        let sym = calendar.shortWeekdaySymbols
        let idx = calendar.component(.weekday, from: date) - 1
        return String(sym[idx].prefix(1))
    }
}

struct DayPage: View {
    let date: Date
    @EnvironmentObject private var dataManager: DataManager
    private let calendar = Calendar.current
    
    private var workoutsOnDate: [WorkoutModel] {
        dataManager.workouts.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    var body: some View {
        Group {
            if workoutsOnDate.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 50)).foregroundColor(.secondary)
                    Text("No Workouts")
                        .font(.title3.bold())
                    Text("Nothing was logged on this day.")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(workoutsOnDate) { workout in
                        NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(workout.name).font(.headline)
                                Text("\(workout.exerciseArray.count) exercises · \(workout.duration) min")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
    }
}

// MARK: - Mini Month View (used in Year view)
struct MiniMonthView: View {
    let year: Int
    let month: Int
    let colorForDay: (Date) -> Color
    let onMonthTap: (Date) -> Void
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.fixed(16), spacing: 2), count: 7)
    
    private var monthName: String {
        DateFormatter().monthSymbols[month - 1]
    }
    
    private var days: [Date] {
        var result: [Date] = []
        let comps = DateComponents(year: year, month: month)
        guard let start = calendar.date(from: comps),
              let range = calendar.range(of: .day, in: .month, for: start) else { return [] }
        for d in range {
            if let date = calendar.date(from: DateComponents(year: year, month: month, day: d)) {
                result.append(date)
            }
        }
        return result
    }
    
    private var leadingBlanks: Int {
        guard let first = days.first else { return 0 }
        return (calendar.component(.weekday, from: first) - 1)
    }
    
    var body: some View {
        Button(action: {
            let comps = DateComponents(year: year, month: month, day: 1)
            if let d = calendar.date(from: comps) { onMonthTap(d) }
        }) {
            VStack(alignment: .leading, spacing: 4) {
                Text(monthName)
                    .font(.caption).fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 1), count: 7), spacing: 1) {
                    ForEach(0..<leadingBlanks, id: \.self) { _ in Color.clear.aspectRatio(1, contentMode: .fit) }
                    ForEach(days, id: \.self) { day in
                        let c = colorForDay(day)
                        Rectangle()
                            .fill(c == .clear ? Color(.systemGray5) : c)
                            .aspectRatio(1, contentMode: .fit)
                            .cornerRadius(2)
                    }
                }
            }
            .padding(8)
            .frame(minHeight: 140, alignment: .top) // Consistent height for all months
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
        }
        .buttonStyle(.plain)
    }
}
