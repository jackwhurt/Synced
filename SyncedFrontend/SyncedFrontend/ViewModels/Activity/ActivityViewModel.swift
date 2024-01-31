import Foundation

class ActivityViewModel: ObservableObject {
    @Published var notifications: [NotificationMetadata] = []
    @Published var errorMessage: String? = nil
    
    private let activityService: ActivityService

    init(activityService: ActivityService) {
        self.activityService = activityService
        Task {
            await loadNotifications()
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
                self.errorMessage = "Failed to load requests. Please try again later."
            }
        }
    }
}
