import Foundation
import EventKit

public struct CalendarEventItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let startDate: Date
    public let endDate: Date
    public let isAllDay: Bool
    public let location: String?
    public let url: URL?
    
    public init(
        id: String,
        title: String,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool,
        location: String?,
        url: URL?
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.location = location
        self.url = url
    }
}

@MainActor
public final class CalendarService: ObservableObject {
    public static let shared = CalendarService()
    
    @Published public private(set) var events: [CalendarEventItem] = []
    @Published public private(set) var authorizationStatus: EKAuthorizationStatus = .notDetermined
    
    private let eventStore = EKEventStore()
    
    public init() {
        checkStatus()
    }
    
    public func checkStatus() {
        if #available(macOS 14.0, *) {
            self.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        } else {
            self.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        }
        
        if isAuthorized {
            fetchTodayEvents()
        }
    }
    
    public var isAuthorized: Bool {
        if #available(macOS 14.0, *) {
            return authorizationStatus == .fullAccess || authorizationStatus == .writeOnly
        } else {
            return authorizationStatus == .authorized
        }
    }
    
    public func requestAccess() async {
        do {
            if #available(macOS 14.0, *) {
                let granted = try await eventStore.requestFullAccessToEvents()
                checkStatus()
                if granted {
                    fetchTodayEvents()
                }
            } else {
                let granted = try await eventStore.requestAccess(to: .event)
                checkStatus()
                if granted {
                    fetchTodayEvents()
                }
            }
        } catch {
            print("[CalendarService] Permission request failed: \(error.localizedDescription)")
            checkStatus()
        }
    }
    
    public func fetchTodayEvents() {
        guard isAuthorized else { return }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }
        
        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
        let rawEvents = eventStore.events(matching: predicate)
        
        self.events = rawEvents
            .sorted(by: { $0.startDate < $1.startDate })
            .map { ev in
                CalendarEventItem(
                    id: ev.eventIdentifier ?? UUID().uuidString,
                    title: ev.title ?? "Event",
                    startDate: ev.startDate,
                    endDate: ev.endDate,
                    isAllDay: ev.isAllDay,
                    location: ev.location,
                    url: ev.url
                )
            }
    }
}
