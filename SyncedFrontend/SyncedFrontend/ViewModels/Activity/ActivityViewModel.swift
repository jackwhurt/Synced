import Foundation

class ActivityViewModel: ObservableObject {
    @Published var notifications: [NotificationMetadata] = []
    @Published var userRequests: [UserRequest] = []
    @Published var playlistRequests: [PlaylistRequest] = []
    @Published var errorMessage: String? = nil
    
    private let activityService: ActivityService
    
    init(activityService: ActivityService) {
        self.activityService = activityService
        loadCachedData()
    }
    
    func loadActivities() {
        Task {
            await loadRequests()
            await loadNotifications()
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
    
    private func loadCachedData() {
        if let cachedNotifications: [NotificationMetadata] = CachingService.shared.load(forKey: "notificationsCache", type: [NotificationMetadata].self) {
            self.notifications = cachedNotifications
        }
        
        if let cachedUserRequests: [UserRequest] = CachingService.shared.load(forKey: "userRequestsCache", type: [UserRequest].self) {
            self.userRequests = cachedUserRequests
        }
        
        if let cachedPlaylistRequests: [PlaylistRequest] = CachingService.shared.load(forKey: "playlistRequestsCache", type: [PlaylistRequest].self) {
            self.playlistRequests = cachedPlaylistRequests
        }
    }
    
    private func loadRequests() async {
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
    
    private func loadNotifications() async {
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
}
