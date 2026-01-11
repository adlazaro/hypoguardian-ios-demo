//
//  TodayView.swift
//  HypoGuardian
//
//  Created by Adrian Lazaro on 28/10/24.
//

import SwiftUI
import Charts

struct TodayView: View {
    
    @Environment(HealthKitManager.self) private var healthKitManager
    
    @StateObject var viewModel = TodayViewModel()
    
    @State private var glucoseDataOnlyToday: [GlucoseSample] = []
    @State private var selectedDate: Date = .now
    
    @AppStorage("hasSeenPermissionPriming") private var hasSeenPermissionPriming = false
    
    @State private var isShowingPermissionPrimingSheet = false
    
    @State private var addDataDate: Date = .now
    @State private var valueToAdd: String = ""
    @State private var isShowingAddData = false
    
    @State private var animateChart = false
    @State private var animateHyperHyposCount = false
    
    //Drag gesture on the glucose chart
    @State private var selectedSample: GlucoseSample?
    @State private var chartProxy: ChartProxy?
    
    @State var alertItem: AlertItem?
    
    var body: some View {
        
        NavigationStack {
            ScrollView {
                VStack (spacing: 30) {
                    HStack {
                        Button {
                            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate)!
                            Task {
                                glucoseDataOnlyToday = await healthKitManager.fetchGlucoseDataSpecificDay(for: selectedDate)
                                viewModel.analyzeGlucoseData(from: glucoseDataOnlyToday)
                                //Assign most recent value as selected
                                selectedSample = glucoseDataOnlyToday.sorted(by: { $0.date > $1.date }).first
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 24))
                                .fontWeight(.bold)
                        }

                        Spacer()

                        Text(formattedDateLabel(for: selectedDate))
                            .font(.system(size: 22))
                            .fontWeight(.semibold)

                        Spacer()

                        Button {
                            let nextDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate)!
                            if nextDate <= Date() {
                                selectedDate = nextDate
                                Task {
                                    glucoseDataOnlyToday = await healthKitManager.fetchGlucoseDataSpecificDay(for: selectedDate)
                                    viewModel.analyzeGlucoseData(from: glucoseDataOnlyToday)
                                    //Assign most recent value as selected
                                    selectedSample = glucoseDataOnlyToday.sorted(by: { $0.date > $1.date }).first
                                }
                            }
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 24))
                                .fontWeight(.bold)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    VStack {
                        HStack {
                            VStack (alignment: .leading) {
                                Label("Blood Glucose", systemImage: "drop.fill")
                                    .font(.title3)
                                    .fontWeight(.heavy)
                                    .foregroundStyle(.pink)
                                
                                Text("Average: \(viewModel.averageGlucose, specifier: "%.1f") mg/dL")
                                    .font(.callout)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Button {
                                isShowingAddData = true
                            } label: {
                                Image(systemName: "plus")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 25)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.pink)
                            }
                        }
                        .padding()
                        
                        ZStack(alignment: .topLeading) {
                            Chart {
                                RuleMark(y: .value("HYPER", 180))
                                    .foregroundStyle(Color("HighColor"))
                                    .lineStyle(.init(lineWidth: 1, dash: [5]))
                                
                                RuleMark(y: .value("HYPO", 70))
                                    .foregroundStyle(Color("LowColor"))
                                    .lineStyle(.init(lineWidth: 1, dash: [5]))
                                
                                ForEach(glucoseDataOnlyToday) { sample in
                                    let color: Color = {
                                        if sample.value < 70 {
                                            return Color("LowColor")
                                        } else if sample.value > 180 {
                                            return Color("HighColor")
                                        } else {
                                            return Color("InRangeColor")
                                        }
                                    }()
                                    
                                    PointMark(
                                        x: .value("Date", sample.date),
                                        y: .value("mg/dL", sample.value)
                                    )
                                    .symbol(Circle())
                                    .symbolSize(sample == selectedSample ? 150 : 40)
                                    .foregroundStyle(color)
                                }
                                .foregroundStyle(Color.pink.gradient)
                                
                            }
                            .chartYScale(domain: 20...270)
                            .chartYAxis {
                                AxisMarks(position: .trailing, values: [70, 180]) { value in
                                    AxisValueLabel{
                                        if let yValue = value.as(Double.self) {
                                            Text("\(Int(yValue))")
                                                .font(.footnote)
                                                .fontWeight(.bold)
                                                .foregroundStyle(
                                                    yValue == 70 ? Color("LowColor") :
                                                    yValue == 180 ? Color("HighColor") :
                                                    .primary
                                                )
                                                
                                        }
                                    }

                                }
                            }
                            .chartXScale(domain: Date.customStartOfDay(for: selectedDate)...Date.customEndOfDay(for: selectedDate))
                            .chartXAxis {
                                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                                    AxisGridLine()
                                    AxisTick()
                                    AxisValueLabel {
                                        if let date = value.as(Date.self) {
                                            Text(date.formatted(date: .omitted, time: .shortened))
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundStyle(Color.secondary)
                                            }
                                    }
                                }
                            }
                            .chartOverlay { proxy in
                                GeometryReader { geo in
                                    Rectangle().fill(.clear)
                                        .contentShape(Rectangle())
                                        .gesture(
                                            DragGesture()
                                                .onChanged { value in
                                                    let location = value.location
                                                    if let date: Date = proxy.value(atX: location.x) {
                                                        let closest = glucoseDataOnlyToday.min(by: {
                                                            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                                                        })
                                                        if selectedSample?.date != closest?.date {
                                                            selectedSample = closest
                                                        }
                                                    }
                                                }
                                        )
                                        .overlay(alignment: .topLeading) {
                                            if let sample = selectedSample,
                                               let xPosition = proxy.position(forX: sample.date) {
                                                ZStack(alignment: .topLeading) {
                                                    //Vertical line
                                                    Rectangle()
                                                        .fill(Color.pink.opacity(0.5))
                                                        .frame(width: 1, height: geo.size.height)
                                                        .offset(x: xPosition)
                                                    
                                                    //Tooltip
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text("\(Int(sample.value)) mg/dL")
                                                            .font(.caption)
                                                            .fontWeight(.bold)
                                                        Text(sample.date.formatted(date: .omitted, time: .shortened))
                                                            .font(.caption2)
                                                            .foregroundStyle(.secondary)
                                                    }
                                                    .padding(8)
                                                    .background(.ultraThinMaterial)
                                                    .cornerRadius(8)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .stroke(Color.pink.opacity(0.5), lineWidth: 1)
                                                    )
                                                    .offset(x: xPosition - 35, y: 0)
                                                }
                                            }
                                        }
                                    }
                                }
                            .frame(height: 250)
                            .padding(.leading, 7)
                            }
                    }
                    .background(RoundedRectangle(cornerRadius: 22).fill(Color(.secondarySystemBackground)))
                    
                    VStack {
                        HStack {
                            Label("Time in range", systemImage: "chart.line.text.clipboard")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.inRange)
                        
                            Spacer()
                        }
                        .padding(.top, 15)
                        .padding(.leading, 10)
                        
                        HStack(alignment: .center) {
                            Chart(viewModel.getAnimatedRangeStats(animated: animateChart)) { stat in
                                SectorMark(
                                    angle: .value("Percentage", stat.percentage),
                                    innerRadius: .ratio(0.8),
                                    angularInset: 1.5
                                )
                                .foregroundStyle(stat.color)
                                .cornerRadius(20)
                            }
                            .frame(width: 120, height: 125)
                            .onChange(of: glucoseDataOnlyToday) {
                                animateChart = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation(.bouncy(duration: 0.75)) {
                                        animateChart = true
                                    }
                                }
                            }
                            .rotationEffect(.degrees(0))
                            .chartBackground { proxy in
                                GeometryReader { geo in
                                    let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                                    Text("\(viewModel.inRangePercentage)%")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .position(center)
                                }
                            }
                            .padding(.leading, 10)
                    
                            Spacer()
                            
                            VStack(alignment: .leading, spacing: 16) {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .foregroundStyle(Color("HighColor"))
                                        .font(.title3)
                                    Text("\(viewModel.hyperCount) Hyperglycemias")
                                        .foregroundStyle(Color("HighColor"))
                                        .fontWeight(.semibold)
                                }
                                
                                HStack(spacing: 8) {
                                    Image(systemName: "target")
                                        .foregroundStyle(Color("InRangeColor"))
                                        .font(.title3)
                                    Text("\(viewModel.inRangeCount) in range")
                                        .foregroundStyle(Color("InRangeColor"))
                                        .fontWeight(.semibold)
                                }
                                
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.down.circle.fill")
                                        .foregroundStyle(Color("LowColor"))
                                        .font(.title3)
                                    Text("\(viewModel.hypoCount) Hypoglycemias")
                                        .foregroundStyle(Color("LowColor"))
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                        .padding()
                        .padding(.bottom, 20)
                    }
                    .background(RoundedRectangle(cornerRadius: 22).fill(Color(.secondarySystemBackground)))
                }
                .padding(10)
                .background(Color(.systemBackground))
                .navigationBarTitleDisplayMode(.inline)
                .task { // .task gives you async context
                    isShowingPermissionPrimingSheet = !hasSeenPermissionPriming
                    glucoseDataOnlyToday = await healthKitManager.fetchGlucoseDataSpecificDay(for: selectedDate)
                    viewModel.analyzeGlucoseData(from: glucoseDataOnlyToday)
                    //Assign most recent value as selected
                    selectedSample = glucoseDataOnlyToday.sorted(by: { $0.date > $1.date }).first
                }
                .sheet(isPresented: $isShowingAddData) {
                    addDataView
                }
                .fullScreenCover(isPresented: $isShowingPermissionPrimingSheet) {
                    //Fetch data
                } content: {
                    HealthKitPermissionPrimingView(hasSeen: $hasSeenPermissionPriming)
                }
                .alert(item: $alertItem) { alertItem in
                    Alert(title: alertItem.title,
                          message: alertItem.message,
                          dismissButton: alertItem.dismissButton)
                }
            }
        }
    }
        
    var addDataView: some View { //Having views as variables might be a good choice if simple and only used here, allows to access variables
        NavigationStack {
            Form {
                DatePicker("Date", selection: $addDataDate, in: ...Date.now, displayedComponents: .date.union(.hourAndMinute))
                HStack {
                    Text("Glucose")
                    Spacer()
                    TextField("mg/dL", text: $valueToAdd)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 140)
                        .keyboardType(.decimalPad)
                }
            }
            .font(.title3)
            .fontWeight(.semibold)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        isShowingAddData = false
                    }
                    .font(.title2)
                    .fontWeight(.medium)
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Glucose")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add Data") {
                        Task {
                            guard let value = Double(valueToAdd) else { return }
                            if (value > 400 || value < 50) {
                                alertItem = AlertContext.invalidGlucoseData
                                return
                            }
                            
                            do {
                                try await healthKitManager.saveGlucoseEntry(value: value, date: addDataDate)
                                glucoseDataOnlyToday = await healthKitManager.fetchGlucoseDataOnlyToday()
                                viewModel.analyzeGlucoseData(from: glucoseDataOnlyToday)
                                isShowingAddData = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    alertItem = AlertContext.glucoseSaveSuccess
                                }
                            } catch {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    alertItem = AlertContext.glucoseSaveError
                                }
                                print("❌ Failed to save entry: \(error)")
                            }
                        }
                    }
                    .font(.title2)
                    .fontWeight(.semibold)
                }
            }
        }
        .tint(.pink)
        .alert(item: $alertItem) { alertItem in
            Alert(title: alertItem.title,
                  message: alertItem.message,
                  dismissButton: alertItem.dismissButton)
        }
    }
    
    func formattedDateLabel(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd MMM yyyy"
            return formatter.string(from: date)
        }
    }
}

#Preview {
    TodayView()
        .environment(HealthKitManager())
}
