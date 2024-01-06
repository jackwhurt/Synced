import Foundation

class CreatePlaylistViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var collaborators: [String] = []
    @Published var newCollaborator: String = ""
    @Published var errorMessage: String?
    
    func addNewCollaborator() {
        if !newCollaborator.isEmpty {
            collaborators.append(newCollaborator)
            newCollaborator = "" // Reset the field
        }
    }

    func deleteCollaborator(at offsets: IndexSet) {
        collaborators.remove(atOffsets: offsets)
    }

    func save() async {
        do {
            throw CollaborativePlaylistServiceError.failedToFormatTimestamp
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
