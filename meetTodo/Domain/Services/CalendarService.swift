import EventKit
import UIKit

protocol CalendarService {
    func requestAccess() async throws -> Bool
    func addEvent(title: String, startDate: Date, location: String?) async throws -> String
    func removeEvent(eventIdentifier: String) async throws
    func updateEvent(eventIdentifier: String, title: String, startDate: Date, location: String?) async throws
    func checkAuthorizationStatus() -> EKAuthorizationStatus
    func openSettings()
}

class DefaultCalendarService: CalendarService {
    static let shared = DefaultCalendarService()
    private let eventStore = EKEventStore()
    private init() {}
    
    func checkAuthorizationStatus() -> EKAuthorizationStatus {
        return EKEventStore.authorizationStatus(for: .event)
    }
    
    func requestAccess() async throws -> Bool {
        let status = checkAuthorizationStatus()
        
        switch status {
        case .authorized:
            return true
            
        case .notDetermined:
            if #available(iOS 17.0, *) {
                return (try? await eventStore.requestFullAccessToEvents()) ?? false
            } else {
                return await withCheckedContinuation { continuation in
                    eventStore.requestAccess(to: .event) { granted, _ in
                        continuation.resume(returning: granted)
                    }
                }
            }
            
        case .denied, .restricted:
            return false
            
        case .fullAccess, .writeOnly:
            return true
            
        @unknown default:
            return false
        }
    }
    
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    private func hasExistingEvent(title: String, startDate: Date, endDate: Date) -> Bool {
        let searchStart = Calendar.current.date(byAdding: .hour, value: -1, to: startDate)!
        let searchEnd = Calendar.current.date(byAdding: .hour, value: 1, to: startDate)!
        
        let predicate = eventStore.predicateForEvents(withStart: searchStart,
                                                    end: searchEnd,
                                                    calendars: nil)
        
        let existingEvents = eventStore.events(matching: predicate)
        
        return existingEvents.contains { event in
            event.title == title &&
            abs(event.startDate.timeIntervalSince(startDate)) < 60 &&
            abs(event.endDate.timeIntervalSince(endDate)) < 60
        }
    }
    
    func addEvent(title: String, startDate: Date, location: String?) async throws -> String {
        let status = checkAuthorizationStatus()
        
        guard status != .denied && status != .restricted else {
            throw CalendarError.permissionDenied
        }
        
        guard try await requestAccess() else {
            throw CalendarError.permissionDenied
        }
        
        let endDate = Calendar.current.date(byAdding: .hour, value: 1, to: startDate)!
        
        if hasExistingEvent(title: title, startDate: startDate, endDate: endDate) {
            throw CalendarError.eventExists
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.location = location
        event.calendar = eventStore.defaultCalendarForNewEvents
        event.addAlarm(EKAlarm(relativeOffset: -3600))
        
        do {
            try eventStore.save(event, span: .thisEvent)
            return event.eventIdentifier
        } catch {
            throw CalendarError.saveFailed(error)
        }
    }
    
    func removeEvent(eventIdentifier: String) async throws {
        guard let event = eventStore.event(withIdentifier: eventIdentifier) else {
            throw CalendarError.eventNotFound
        }
        
        do {
            try eventStore.remove(event, span: .thisEvent)
        } catch {
            throw CalendarError.deleteFailed(error)
        }
    }
    
    func updateEvent(eventIdentifier: String, title: String, startDate: Date, location: String?) async throws {
        guard let event = eventStore.event(withIdentifier: eventIdentifier) else {
            throw CalendarError.eventNotFound
        }
        
        event.title = title
        event.startDate = startDate
        event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: startDate)!
        event.location = location
        
        do {
            try eventStore.save(event, span: .thisEvent)
        } catch {
            throw CalendarError.updateFailed(error)
        }
    }
}

enum CalendarError: Error {
    case permissionDenied
    case eventExists
    case eventNotFound
    case saveFailed(Error)
    case updateFailed(Error)
    case deleteFailed(Error)
} 