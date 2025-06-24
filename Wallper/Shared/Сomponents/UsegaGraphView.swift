import Foundation
import SwiftUI
import Combine
import IOKit
import IOKit.ps
import Charts
import MachO

struct UsageDataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let cpu: Double
    let ramMB: Double
}

class UsageStatsHistory: ObservableObject {
    @Published var data: [UsageDataPoint] = []

    func add(cpu: Double, ramBytes: UInt64) {
        let ramMB = Double(ramBytes) / 1024 / 1024
        data.append(UsageDataPoint(timestamp: Date(), cpu: cpu, ramMB: ramMB))
        if data.count > 60 { data.removeFirst() }
    }
}

struct UsageGraphView: View {
    @ObservedObject var history: UsageStatsHistory

    var body: some View {
        let totalCPULogicalCores = ProcessInfo.processInfo.processorCount
        let currentCPU = history.data.last?.cpu ?? 0

        VStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 6) {
                Text(String(format: "Wallper: %.1f%% (of total %d%%)", currentCPU, totalCPULogicalCores * 100))
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .medium))
                    .padding([.top, .leading])

                Text("Real-time graph showing your Mac's CPU load over the last 60 seconds. Helps visualize performance spikes and app activity.")
                    .foregroundColor(.white.opacity(0.45))
                    .font(.system(size: 10, weight: .regular))
                    .padding(.leading)
            }.padding(.bottom, 12)

            Chart {
                ForEach(history.data) { point in
                    LineMark(
                        x: .value("Time", point.timestamp),
                        y: .value("CPU Usage (%)", point.cpu)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.linearGradient(
                        Gradient(colors: [.blue, .cyan]),
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    AreaMark(
                        x: .value("Time", point.timestamp),
                        y: .value("CPU Usage (%)", point.cpu)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        .linearGradient(
                            Gradient(colors: [.blue.opacity(0.3), .clear]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.hour().minute().second(), centered: true)
                }
            }
            .chartYScale(domain: 0...min(
                max(100, ceil((history.data.map { $0.cpu }.max() ?? 100) * 1.2)),
                Double(totalCPULogicalCores * 100)
            ))

            .padding()
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding()
        }
        .frame(width: 600, height: 400)
        .background(.ultraThinMaterial)
    }
}

