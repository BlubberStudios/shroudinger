import SwiftUI
import Foundation

struct CompactTestingLogsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var logs: [LogEntry] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var refreshTimer: Timer?
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            if !settingsManager.servicesRunning {
                compactServiceNotRunningView
            } else if isLoading && logs.isEmpty {
                compactLoadingView
            } else if let error = error {
                compactErrorView(error)
            } else if logs.isEmpty {
                compactEmptyView
            } else {
                compactLogsView
            }
        }
        .onAppear {
            if settingsManager.servicesRunning {
                loadLogs()
                startAutoRefresh()
            }
        }
        .onDisappear {
            stopAutoRefresh()
        }
        .onChange(of: settingsManager.servicesRunning) { isRunning in
            if isRunning {
                loadLogs()
                startAutoRefresh()
            } else {
                stopAutoRefresh()
                logs = []
                error = nil
            }
        }
    }
    
    private var compactLoadingView: some View {
        HStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(0.8)
            
            Text("Loading logs...")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Spacer()
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
    }
    
    private func compactErrorView(_ error: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.error)
            
            Text("Error loading logs")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.error)
            
            Spacer()
            
            Button("Retry") {
                loadLogs()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.mini)
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
    }
    
    private var compactEmptyView: some View {
        HStack {
            Image(systemName: "tray")
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Text("No middleware activity")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Spacer()
            
            Text("Enable testing mode to see logs")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .opacity(0.7)
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
    }
    
    private var compactServiceNotRunningView: some View {
        HStack {
            Image(systemName: "power.circle")
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Text("Services not running")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Spacer()
            
            Text("Toggle DNS Protection ON")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .opacity(0.7)
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
    }
    
    private var compactLogsView: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(Array(logs.prefix(5))) { log in
                    CompactLogEntryView(log: log)
                }
                
                if logs.count > 5 {
                    HStack {
                        Spacer()
                        Text("... and \(logs.count - 5) more")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .opacity(0.7)
                        Spacer()
                    }
                    .padding(.top, DesignSystem.Spacing.xs)
                }
            }
        }
        .frame(maxHeight: 150)
    }
    
    // MARK: - Actions
    
    private func loadLogs() {
        isLoading = true
        error = nil
        
        Task {
            do {
                let fetchedLogs = try await LogsService.fetchLogs()
                await MainActor.run {
                    self.logs = fetchedLogs.sorted { $0.timestamp > $1.timestamp }
                    self.isLoading = false
                    self.error = nil
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isLoading = false
                    print("🔴 Error loading logs: \(error)")
                }
            }
        }
    }
    
    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            loadLogs()
        }
    }
    
    private func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}

// MARK: - Compact Log Entry View

struct CompactLogEntryView: View {
    let log: LogEntry
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            // Level indicator
            Circle()
                .fill(levelColor)
                .frame(width: 6, height: 6)
            
            // Timestamp
            Text(timeString)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .frame(width: 45, alignment: .leading)
            
            // Service
            Text(log.service)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .frame(width: 60, alignment: .leading)
            
            // Event (truncated)
            Text(log.event)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Status code (if available)
            if let statusCode = log.statusCode, statusCode > 0 {
                Text("\(statusCode)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(statusColor)
                    .frame(width: 30, alignment: .trailing)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.xs)
        .padding(.vertical, DesignSystem.Spacing.xxs)
        .background(log.level == "ERROR" ? DesignSystem.Colors.error.opacity(0.1) : Color.clear)
        .cornerRadius(3)
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: log.timestamp)
    }
    
    private var levelColor: Color {
        switch log.level {
        case "ERROR":
            return DesignSystem.Colors.error
        case "WARN":
            return DesignSystem.Colors.warning
        case "INFO":
            return DesignSystem.Colors.success
        default:
            return DesignSystem.Colors.textSecondary
        }
    }
    
    private var statusColor: Color {
        guard let statusCode = log.statusCode else {
            return DesignSystem.Colors.textSecondary
        }
        switch statusCode {
        case 200...299:
            return DesignSystem.Colors.success
        case 400...499:
            return DesignSystem.Colors.warning
        case 500...599:
            return DesignSystem.Colors.error
        default:
            return DesignSystem.Colors.textSecondary
        }
    }
}

#Preview {
    CompactTestingLogsView()
        .padding()
}