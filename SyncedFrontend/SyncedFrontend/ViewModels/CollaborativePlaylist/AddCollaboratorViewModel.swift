import Foundation
import SwiftUI

class AddCollaboratorViewModel: ObservableObject {
    @Published var errorMessage: String? = nil
    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false
    @Published var playlistId: String
    @Published var selectedCollaborators: [UserMetadata] = []
    @Published var currentCollaborators: [UserMetadata]

    private let collaborativePlaylistService: CollaborativePlaylistService
    private let userService: UserService
    
    init(playlistId: String, currentCollaborators: [UserMetadata], collaborativePlaylistService: CollaborativePlaylistService, userService: UserService) {
        self.playlistId = playlistId
        self.currentCollaborators = currentCollaborators
        self.collaborativePlaylistService = collaborativePlaylistService
        self.userService = userService
    }

    func searchUsers(usernameQuery: String, page: Int) async -> [UserMetadata] {
        do {
            DispatchQueue.main.async {
                self.isLoading = true
            }
            let response = try await userService.getUsers(usernameQuery: usernameQuery, page: page)
            DispatchQueue.main.async {
                self.isLoading = false
            }
            return response.users
        } catch {
            print("Failed to retrieve users")
            DispatchQueue.main.async {
                self.errorMessage = "Failed to retrieve users, please try again later."
                self.isLoading = false
            }
            return []
        }
    }
    
    func addCollaborators() async {
        let newCollaborators = selectedCollaborators.filter { newUser in
            !currentCollaborators.contains(where: { currentUser in
                currentUser.userId == newUser.userId
            })
        }
        
        guard !newCollaborators.isEmpty else { return }
        
        DispatchQueue.main.async {
            self.isSaving = true
        }
        
        do {
            try await collaborativePlaylistService.addCollaborators(playlistId: playlistId, collaboratorIds: newCollaborators.map { $0.userId })
        } catch {
            print("Failed to add collaborators, \(error)")
            DispatchQueue.main.async {
                self.errorMessage = "Failed to add collaborators, please try again later."
            }
        }
        
        DispatchQueue.main.async {
            self.isSaving = false
        }
    }
}
