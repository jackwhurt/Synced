import Foundation

// TODO: Double request on appear
class ActivityViewModel: ObservableObject {
    @Published var notifications: [NotificationMetadata] = []
    @Published var userRequests: [UserRequest] = []
    @Published var playlistRequests: [PlaylistRequest] = []
    @Published var errorMessage: String? = nil
    @Published var isLoading: Bool = false
    
    private let activityService: ActivityService
    
    init(activityService: ActivityService) {
        self.activityService = activityService
        loadCachedData()
    }
    
    func loadActivities() {
        Task {
            await self.loadRequests()
            await self.loadNotifications()
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
        var cacheMiss = false
        
        if let cachedNotifications: [NotificationMetadata] = CachingService.shared.load(forKey: "notificationsCache", type: [NotificationMetadata].self) {
            self.notifications = cachedNotifications
        } else {
            cacheMiss = true
        }
        
        if let cachedUserRequests: [UserRequest] = CachingService.shared.load(forKey: "userRequestsCache", type: [UserRequest].self) {
            self.userRequests = cachedUserRequests
        } else {
            cacheMiss = true
        }
        
        if let cachedPlaylistRequests: [PlaylistRequest] = CachingService.shared.load(forKey: "playlistRequestsCache", type: [PlaylistRequest].self) {
            self.playlistRequests = cachedPlaylistRequests
        } else {
            cacheMiss = true
        }
        
        if cacheMiss {
            DispatchQueue.main.async {
                Task {
                    self.isLoading = true
                    await self.loadRequests()
                    await self.loadNotifications()
                    self.isLoading = false
                }
            }
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
            print("Failed to load requests: \(error)")
            DispatchQueue.main.async {
                self.errorMessage = "Failed to load requests, please try again later."
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
            print("Failed to load notifications: \(error)")
            DispatchQueue.main.async {
                self.errorMessage = "Failed to load notifications, please try again later."
            }
        }
    }
}
