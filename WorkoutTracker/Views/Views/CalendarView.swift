import SwiftUI

// MARK: - Calendar Mode
enum CalendarMode: String, CaseIterable {
    case year = "Year"
    case month = "Month"
    case week = "Week"
}

// MARK: - Enhanced Calendar View (Feature 4)
struct CalendarView: View {
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var themeManager: ThemeManager
    private let calendar = Calendar.current

    // View state
    @State private var calendarMode: CalendarMode = .year
    @State private var selectedDate: Date = Date()
    @State private var showingDayDetail = false
    @State private var dayDetailDate: Date = Date()

    // Pinch-to-zoom
    @State private var magnifyScale: CGFloat = 1.0
    @GestureState private var pinchScale: CGFloat = 1.0

    // Navigation offset (for swipe left/right in month/week mode)
    @State private var offset: CGFloat = 0
    @GestureState private var dragOffset: CGFloat = 0

    private var workoutDays: Set<Date> {
        Set(dataManager.workouts.map { calendar.startOfDay(for: $0.date) })
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Mode selector
                Picker("View", selection: $calendarMode) {
                    ForEach(CalendarMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Header with navigation arrows
                navigationHeader

                Divider()

                // Main calendar content
                Group {
                    switch calendarMode {
                    case .year:  yearView
                    case .month: monthView
                    case .week:  weekView
                    }
                }
                .gesture(
                    // Pinch gesture: zoom in → month → week, zoom out reverses
                    MagnificationGesture()
                        .updating($pinchScale) { value, state, _ in state = value }
                        .onEnded { value in
                            if value > 1.3 {
                                // Zoom in
                                switch calendarMode {
                                case .year:  withAnimation { calendarMode = .month }
                                case .month: withAnimation { calendarMode = .week }
                                case .week:  break
                                }
                            } else if value < 0.75 {
                                // Zoom out
                                switch calendarMode {
                                case .week:  withAnimation { calendarMode = .month }
                                case .month: withAnimation { calendarMode = .year }
                                case .year:  break
                                }
                            }
                        }
                )
            }
            .navigationTitle("Calendar")
            .sheet(isPresented: $showingDayDetail) {
                DayWorkoutDetailSheet(date: dayDetailDate)
                    .environmentObject(dataManager)
            }
        }
    }

    // MARK: - Navigation Header
    @ViewBuilder
    private var navigationHeader: some View {
        HStack {
            Button(action: navigateBackward) {
                Image(systemName: "chevron.left")
                    .font(.title3).padding(8)
            }
            Spacer()
            Text(headerTitle)
                .font(.headline).fontWeight(.semibold)
            Spacer()
            Button(action: navigateForward) {
                Image(systemName: "chevron.right")
                    .font(.title3).padding(8)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    private var headerTitle: String {
        switch calendarMode {
        case .year:
            return "\(calendar.component(.year, from: selectedDate))"
        case .month:
            let fmt = DateFormatter(); fmt.dateFormat = "MMMM yyyy"
            return fmt.string(from: selectedDate)
        case .week:
            let weekStart = startOfWeek(for: selectedDate)
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
            let fmt = DateFormatter(); fmt.dateFormat = "MMM d"
            return "\(fmt.string(from: weekStart)) – \(fmt.string(from: weekEnd))"
        }
    }

    private func navigateBackward() {
        withAnimation(.easeInOut(duration: 0.25)) {
            switch calendarMode {
            case .year:
                selectedDate = calendar.date(byAdding: .year, value: -1, to: selectedDate) ?? selectedDate
            case .month:
                selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
            case .week:
                selectedDate = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedDate) ?? selectedDate
            }
        }
    }

    private func navigateForward() {
        withAnimation(.easeInOut(duration: 0.25)) {
            switch calendarMode {
            case .year:
                selectedDate = calendar.date(byAdding: .year, value: 1, to: selectedDate) ?? selectedDate
            case .month:
                selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
            case .week:
                selectedDate = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedDate) ?? selectedDate
            }
        }
    }

    // MARK: - Year View
    private var yearView: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                ForEach(1...12, id: \.self) { month in
                    MiniMonthView(
                        year: calendar.component(.year, from: selectedDate),
                        month: month,
                        workoutDays: workoutDays,
                        accentColor: themeManager.calendarBoxColor
                    ) { tappedDate in
                        selectedDate = tappedDate
                        withAnimation { calendarMode = .month }
                    }
                }
            }
            .padding()
        }
        .transition(.opacity)
    }

    // MARK: - Month View
    private var monthView: some View {
        let year  = calendar.component(.year, from: selectedDate)
        let month = calendar.component(.month, from: selectedDate)
        let days  = daysInMonth(year: year, month: month)
        let firstWeekday = days.first.map { calendar.component(.weekday, from: $0) } ?? 1
        let columns = Array(repeating: GridItem(.flexible()), count: 7)

        return ScrollView {
            VStack(spacing: 8) {
                // Weekday headers
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
                    // Leading blank cells
                    ForEach(0..<(firstWeekday - 1), id: \.self) { _ in Color.clear }
                    // Day cells
                    ForEach(days, id: \.self) { day in
                        let isWorkout = workoutDays.contains(day)
                        let isToday = calendar.isDateInToday(day)
                        Button(action: {
                            dayDetailDate = day
                            showingDayDetail = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(isWorkout ? themeManager.calendarBoxColor :
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
        .transition(.slide)
    }

    // MARK: - Week View
    private var weekView: some View {
        let weekStart = startOfWeek(for: selectedDate)
        let days = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }

        return VStack(spacing: 0) {
            // Day strips
            HStack(spacing: 6) {
                ForEach(days, id: \.self) { day in
                    let isWorkout = workoutDays.contains(day)
                    let isToday = calendar.isDateInToday(day)
                    Button(action: {
                        dayDetailDate = day
                        showingDayDetail = true
                    }) {
                        VStack(spacing: 6) {
                            Text(shortWeekday(for: day))
                                .font(.caption2).foregroundColor(.secondary)
                            ZStack {
                                Circle()
                                    .fill(isWorkout ? themeManager.calendarBoxColor :
                                            isToday ? Color.accentColor.opacity(0.2) : Color(.systemGray6))
                                    .frame(width: 44, height: 44)
                                Text("\(calendar.component(.day, from: day))")
                                    .font(.system(size: 15, weight: isToday ? .bold : .regular))
                                    .foregroundColor(isWorkout ? .white : .primary)
                            }
                            // Dot if has workout
                            Circle()
                                .fill(isWorkout ? themeManager.calendarBoxColor : Color.clear)
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

            // Workouts for each day with a workout this week
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
                                            .fill(themeManager.calendarBoxColor)
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
        .transition(.slide)
    }

    // MARK: - Helpers
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

// MARK: - Mini Month View (used in Year view)
struct MiniMonthView: View {
    let year: Int
    let month: Int
    let workoutDays: Set<Date>
    let accentColor: Color
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
        VStack(alignment: .leading, spacing: 4) {
            Button(action: {
                let comps = DateComponents(year: year, month: month, day: 1)
                if let d = calendar.date(from: comps) { onMonthTap(d) }
            }) {
                Text(monthName)
                    .font(.caption).fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .buttonStyle(.plain)

            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(0..<leadingBlanks, id: \.self) { _ in Color.clear.frame(width: 16, height: 16) }
                ForEach(days, id: \.self) { day in
                    let isWorkout = workoutDays.contains(day)
                    Rectangle()
                        .fill(isWorkout ? accentColor : Color(.systemGray5))
                        .frame(width: 16, height: 16)
                        .cornerRadius(3)
                }
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
    }
}

// MARK: - Day Workout Detail Sheet
struct DayWorkoutDetailSheet: View {
    let date: Date
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode
    private let calendar = Calendar.current

    private var workoutsOnDate: [WorkoutModel] {
        dataManager.workouts.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }

    var body: some View {
        NavigationView {
            Group {
                if workoutsOnDate.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 50)).foregroundColor(.secondary)
                        Text("No Workouts")
                            .font(.title3.bold())
                        Text("Nothing was logged on \(date.formatted(.dateTime.weekday().month().day().year())).")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        Section(header: Text(date.formatted(.dateTime.weekday(.wide).month().day().year()))) {
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
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Workout Log")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
