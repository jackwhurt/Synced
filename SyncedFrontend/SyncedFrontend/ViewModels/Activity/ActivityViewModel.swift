import Foundation

class ActivityViewModel: ObservableObject {
    @Published var notifications: [NotificationMetadata] = []
    @Published var userRequests: [UserRequest] = []
    @Published var playlistRequests: [PlaylistRequest] = []
    @Published var errorMessage: String? = nil
    
    private let activityService: ActivityService

    init(activityService: ActivityService) {
        self.activityService = activityService
        Task {
            await loadNotifications()
            await loadRequests()
        }
    }
    
    func loadRequests() async {
        do {
            let requests = try await activityService.getRequests()
            DispatchQueue.main.async {
                self.userRequests = requests.userRequests
                self.playlistRequests = requests.playlistRequests
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to load requests. Please try again later."
            }
        }
    }
    
    func loadNotifications() async {
        do {
            let response = try await activityService.getNotifications()
            DispatchQueue.main.async {
                self.notifications = response
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to load notifications. Please try again later."
            }
        }
    }

    func convertTimestamp(_ isoString: String?) -> String {
        guard let string = isoString else {
            print("Input string is nil")
            return ""
        }
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = dateFormatter.date(from: string) else {
            print("Date parsing failed")
            return ""
        }
        
        let now = Date()
        let componentsFormatter = DateComponentsFormatter()
        componentsFormatter.unitsStyle = .abbreviated
        componentsFormatter.allowedUnits = [.year, .month, .weekOfMonth, .day, .hour, .minute, .second]
        componentsFormatter.maximumUnitCount = 1 
        
        guard let timeSinceDate = componentsFormatter.string(from: date, to: now) else {
            print("Could not compute time since date")
            return ""
        }
        
        return timeSinceDate
    }

}
