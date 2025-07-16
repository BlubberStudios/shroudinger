import SwiftUI
import Foundation

struct TestingLogsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var logs: [LogEntry] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var autoRefresh = true
    @State private var refreshTimer: Timer?
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Header with testing warning
            testingWarningHeader
            
            // Controls
            logsControlsHeader
            
            // Logs content
            if !settingsManager.servicesRunning {
                serviceNotRunningView
            } else if isLoading && logs.isEmpty {
                loadingView
            } else if let error = error {
                errorView(error)
            } else {
                logsListView
            }
        }
        .padding(DesignSystem.Spacing.sectionMargin)
        .background(DesignSystem.Colors.backgroundPrimary)
        .onAppear {
            if settingsManager.servicesRunning {
                loadLogs()
                if autoRefresh {
                    startAutoRefresh()
                }
            }
        }
        .onDisappear {
            stopAutoRefresh()
        }
        .onChange(of: autoRefresh) { enabled in
            if enabled && settingsManager.servicesRunning {
                startAutoRefresh()
            } else {
                stopAutoRefresh()
            }
        }
        .onChange(of: settingsManager.servicesRunning) { isRunning in
            if isRunning {
                loadLogs()
                if autoRefresh {
                    startAutoRefresh()
                }
            } else {
                stopAutoRefresh()
                logs = []
                error = nil
            }
        }
    }
    
    private var testingWarningHeader: some View {
        ModernCard {
            VStack(spacing: DesignSystem.Spacing.md) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(DesignSystem.Colors.warning)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                        Text("Testing Mode Only")
                            .font(DesignSystem.Typography.headline)
                            .foregroundColor(DesignSystem.Colors.warning)
                        
                        Text("This logging window is for testing purposes only and is disabled in production builds.")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                }
                
                HStack {
                    Image(systemName: "shield.checkered")
                        .foregroundColor(DesignSystem.Colors.success)
                        .font(.caption)
                    
                    Text("No sensitive data (domains, IPs, or user information) is logged")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Spacer()
                }
            }
        }
    }
    
    private var logsControlsHeader: some View {
        ModernCard {
            HStack {
                Label("Middleware Activity", systemImage: "list.bullet.rectangle")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                // Auto-refresh toggle
                Toggle("Auto-refresh", isOn: $autoRefresh)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                
                // Refresh button
                Button(action: loadLogs) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                        Text("Refresh")
                            .font(DesignSystem.Typography.caption)
                    }
                }
                .disabled(isLoading)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                // Clear button
                Button(action: clearLogs) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "trash")
                            .font(.caption)
                        Text("Clear")
                            .font(DesignSystem.Typography.caption)
                    }
                }
                .disabled(isLoading)
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }
    
    private var loadingView: some View {
        ModernCard {
            VStack(spacing: DesignSystem.Spacing.md) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                
                Text("Loading logs...")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: 200)
        }
    }
    
    private func errorView(_ error: String) -> some View {
        ModernCard {
            VStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundColor(DesignSystem.Colors.error)
                
                Text("Error Loading Logs")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(error)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                
                Button("Retry") {
                    loadLogs()
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, minHeight: 200)
        }
    }
    
    private var logsListView: some View {
        ModernCard {
            ScrollView {
                LazyVStack(spacing: DesignSystem.Spacing.sm) {
                    if logs.isEmpty {
                        emptyLogsView
                    } else {
                        ForEach(logs) { log in
                            LogEntryView(log: log)
                                .padding(.horizontal, DesignSystem.Spacing.sm)
                        }
                    }
                }
                .padding(.vertical, DesignSystem.Spacing.md)
            }
            .frame(maxHeight: 400)
        }
    }
    
    private var emptyLogsView: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Text("No logs available")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text("Middleware activity will appear here when testing mode is enabled")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
    }
    
    private var serviceNotRunningView: some View {
        ModernCard {
            VStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: "power.circle")
                    .font(.largeTitle)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Text("Services Not Running")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Toggle DNS Protection ON to start services and see middleware logs")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                
                Button("Start Services") {
                    Task {
                        await settingsManager.startServices()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, minHeight: 200)
        }
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
    
    private func clearLogs() {
        Task {
            do {
                try await LogsService.clearLogs()
                await MainActor.run {
                    self.logs = []
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }
        }
    }
    
    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            loadLogs()
        }
    }
    
    private func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}

// MARK: - Supporting Views

struct LogEntryView: View {
    let log: LogEntry
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // Level indicator
            Circle()
                .fill(levelColor)
                .frame(width: 8, height: 8)
            
            // Timestamp
            Text(timeString)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .frame(width: 60, alignment: .leading)
            
            // Service
            Text(log.service)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .frame(width: 80, alignment: .leading)
            
            // Event
            Text(log.event)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Status code (if available)
            if let statusCode = log.statusCode, statusCode > 0 {
                Text("\(statusCode)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(statusColor)
                    .frame(width: 40, alignment: .trailing)
            }
            
            // Response time (if available)
            if let responseTime = log.responseTime, !responseTime.isEmpty {
                Text(responseTime)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .frame(width: 60, alignment: .trailing)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .background(log.level == "ERROR" ? DesignSystem.Colors.error.opacity(0.1) : Color.clear)
        .cornerRadius(4)
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

// MARK: - Data Models

struct LogEntry: Codable, Identifiable {
    let id = UUID()
    let timestamp: Date
    let level: String
    let service: String
    let event: String
    let statusCode: Int?
    let responseTime: String?
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case timestamp, level, service, event
        case statusCode = "status_code"
        case responseTime = "response_time"
        case error
    }
}

// MARK: - Logs Service

class LogsService {
    static let baseURL = "http://localhost:8083"
    
    static func fetchLogs() async throws -> [LogEntry] {
        guard let url = URL(string: "\(baseURL)/testing/logs") else {
            throw LogsError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LogsError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw LogsError.serverError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try multiple date formats
            let formatters = [
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX",  // Full microseconds
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSXXXXX",   // 5 digits
                "yyyy-MM-dd'T'HH:mm:ss.SSSSXXXXX",    // 4 digits
                "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX",     // 3 digits
                "yyyy-MM-dd'T'HH:mm:ss.SSXXXXX",      // 2 digits
                "yyyy-MM-dd'T'HH:mm:ss.SXXXXX",       // 1 digit
                "yyyy-MM-dd'T'HH:mm:ssXXXXX"          // No fractional seconds
            ]
            
            for formatString in formatters {
                let formatter = DateFormatter()
                formatter.dateFormat = formatString
                formatter.locale = Locale(identifier: "en_US_POSIX")
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }
            
            // Fallback to ISO8601
            if let date = ISO8601DateFormatter().date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
        }
        
        let logsResponse = try decoder.decode(LogsResponse.self, from: data)
        return logsResponse.logs
    }
    
    static func clearLogs() async throws {
        guard let url = URL(string: "\(baseURL)/testing/logs") else {
            throw LogsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LogsError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw LogsError.serverError(httpResponse.statusCode)
        }
    }
}

struct LogsResponse: Codable {
    let logs: [LogEntry]
    let count: Int
    let maxEntries: Int
    let testingMode: Bool
    
    enum CodingKeys: String, CodingKey {
        case logs, count
        case maxEntries = "max_entries"
        case testingMode = "testing_mode"
    }
}

enum LogsError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code):
            return "Server error: \(code)"
        }
    }
}