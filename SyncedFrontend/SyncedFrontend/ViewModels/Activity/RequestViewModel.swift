import Foundation

class RequestViewModel: ObservableObject {
    @Published var userRequests: [UserRequest] = []
    @Published var playlistRequests: [PlaylistRequest] = []
    @Published var errorMessage: String? = nil

    private let activityService: ActivityService

    init(activityService: ActivityService) {
        self.activityService = activityService
        loadRequests()
    }

    func loadRequests() {
        Task {
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
    }
}
