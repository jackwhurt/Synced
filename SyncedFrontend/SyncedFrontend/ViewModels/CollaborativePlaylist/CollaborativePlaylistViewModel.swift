import Foundation

class CollaborativePlaylistViewModel: ObservableObject {
    @Published var playlist: GetCollaborativePlaylistByIdResponse?
    @Published var errorMessage: String?
    @Published var isEditing = false
    
    private let playlistId: String
    private let collaborativePlaylistService: CollaborativePlaylistService
    private var savedPlaylist: GetCollaborativePlaylistByIdResponse? = nil
    private var songsToDelete: [SongMetadata] = []
    private var songsToAdd: [SongMetadata] = []

    init(playlistId: String, collaborativePlaylistService: CollaborativePlaylistService) {
        self.playlistId = playlistId
        self.collaborativePlaylistService = collaborativePlaylistService
    }

    func loadPlaylist() async {
        do {
            let fetchedPlaylist = try await collaborativePlaylistService.getPlaylistById(playlistId: playlistId)
            DispatchQueue.main.async {
                self.playlist = fetchedPlaylist
            }
        } catch {
            print("Failed to load playlist: \(playlistId)")
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Failed to load playlist, please try again later"
            }
        }
    }
    
    func deleteSong(song: SongMetadata) {
        songsToDelete.append(song)
    }
    
    func addSong(song: SongMetadata) {
        songsToAdd.append(song)
    }
    
    func setEditingTrue() {
        DispatchQueue.main.async {
            self.isEditing = true
        }
        self.savedPlaylist = self.playlist
    }
    
    func saveChanges() async {
        do {
            try await collaborativePlaylistService.editSongs(appleMusicPlaylistId: playlist?.appleMusicPlaylistId, playlistId: playlistId, songsToDelete: songsToDelete, songsToAdd: songsToAdd, allSongs: playlist?.songs ?? [])
            DispatchQueue.main.async {
                self.isEditing = false
            }
        } catch {
            
        }
    }

    func cancelChanges() {
        DispatchQueue.main.async {
            self.isEditing = false
            self.playlist = self.savedPlaylist
        }
    }
}
