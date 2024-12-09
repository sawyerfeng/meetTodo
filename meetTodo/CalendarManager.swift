import EventKit

class CalendarManager {
    static let shared = CalendarManager()
    private let eventStore = EKEventStore()
    
    private init() {}
    
    func checkAuthorizationStatus() async -> EKAuthorizationStatus {
        return EKEventStore.authorizationStatus(for: .event)
    }
    
    func requestAccess() async -> Bool {
        do {
            return try await eventStore.requestAccess(to: .event)
        } catch {
            print("Failed to request calendar access: \(error)")
            return false
        }
    }
    
    func getCalendars() -> [EKCalendar] {
        let calendars = eventStore.calendars(for: .event)
        return calendars.filter { $0.allowsContentModifications }
    }
    
    func addEvent(title: String, startDate: Date, location: String?, to calendarIdentifier: String) {
        guard let calendar = eventStore.calendar(withIdentifier: calendarIdentifier) else { return }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: startDate) ?? startDate
        event.calendar = calendar
        
        if let location = location {
            event.location = location
        }
        
        do {
            try eventStore.save(event, span: .thisEvent)
        } catch {
            print("Failed to save event with error: \(error)")
        }
    }
} 