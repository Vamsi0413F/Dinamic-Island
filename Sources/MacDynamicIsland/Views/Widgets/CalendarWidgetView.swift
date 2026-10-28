import SwiftUI

public struct CalendarWidgetView: View {
    @EnvironmentObject var calendarService: CalendarService
    @EnvironmentObject var settingsStore: SettingsStore
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 10) {
            if !calendarService.isAuthorized {
                // Unauthorized / Request access card
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 26))
                        .foregroundColor(.orange)
                    
                    Text("Calendar Access Required")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Grant Calendar access to view today's schedule and meeting countdowns directly in the Dynamic Island.")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    Button("Authorize Calendar") {
                        Task {
                            await calendarService.requestAccess()
                        }
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(settingsStore.accentColor)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 20)
            } else if calendarService.events.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.4))
                    Text("No more events scheduled today")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Button("Refresh") {
                        calendarService.fetchTodayEvents()
                    }
                    .font(.system(size: 11))
                    .foregroundColor(settingsStore.accentColor)
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 30)
            } else {
                // Events list
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(spacing: 8) {
                        ForEach(calendarService.events) { ev in
                            eventRow(ev)
                        }
                    }
                }
                .frame(maxHeight: 220)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    
    @ViewBuilder
    private func eventRow(_ ev: CalendarEventItem) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(settingsStore.accentColor)
                .frame(width: 3, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(ev.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Text(formatTimeRange(start: ev.startDate, end: ev.endDate, isAllDay: ev.isAllDay))
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))
                    
                    if let location = ev.location, !location.isEmpty {
                        Text("• " + location)
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.4))
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            if let url = ev.url {
                Button {
                    NSWorkspace.shared.open(url)
                } label: {
                    Image(systemName: "video.fill")
                        .font(.system(size: 11))
                        .foregroundColor(settingsStore.accentColor)
                        .padding(6)
                        .background(settingsStore.accentColor.opacity(0.15))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Join Meeting")
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func formatTimeRange(start: Date, end: Date, isAllDay: Bool) -> String {
        if isAllDay { return "All Day" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}
