import Foundation
import SwiftUI

class EditCollaboratorsViewModel: ObservableObject {
    @Published var collaborators: [UserMetadata] = []
    @Published var errorMessage: String? = nil
    @Published var playlistId: String
    @Published var isLoading: Bool = false
    
    private let collaborativePlaylistService: CollaborativePlaylistService
    
    init(playlistId: String, collaborativePlaylistService: CollaborativePlaylistService) {
        self.playlistId = playlistId
        self.collaborativePlaylistService = collaborativePlaylistService
        loadCachedCollaborators()
    }
    
    func loadCollaborators() {
        if !CachingService.shared.exists(forKey: "collaborators_\(playlistId)") {
            isLoading = true
        }
        
        Task {
            do {
                let response = try await collaborativePlaylistService.getCollaborators(playlistId: playlistId)
                DispatchQueue.main.async {
                    self.collaborators = response
                }
            } catch {
                print("Failed to load collaborators")
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load collaborators, please try again later."
                }
            }
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
    
    func deleteCollaborator(collaboratorId: String) async {
        do {
            try await collaborativePlaylistService.deleteCollaborators(playlistId: playlistId, collaboratorIds: [collaboratorId])
            loadCollaborators()
        } catch {
            print("Failed to delete collaborator")
            DispatchQueue.main.async {
                self.errorMessage = "Failed to delete collaborator, please try again later."
            }
        }
    }
    
    func deleteCollaboratorInList(at indices: IndexSet) {
        for index in indices {
            let collaboratorId = collaborators[index].userId
            Task {
                await deleteCollaborator(collaboratorId: collaboratorId)
            }
        }
        
        DispatchQueue.main.async {
            self.collaborators.remove(atOffsets: indices)
        }
    }
    
    private func loadCachedCollaborators() {
        if let cachedCollaborators: [UserMetadata] = CachingService.shared.load(forKey: "collaborators_\(playlistId)", type: [UserMetadata].self) {
            DispatchQueue.main.async { [weak self] in
                self?.collaborators = cachedCollaborators
            }
        }
    }
}
