import SwiftUI

struct CreatePlaylistView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var createPlaylistViewModel: CreatePlaylistViewModel
    @State private var showErrorAlert = false
    
    init(collaborativePlaylistViewModel: CollaborativePlaylistMenuViewModel) {
        _createPlaylistViewModel = StateObject(wrappedValue: CreatePlaylistViewModel(collaborativePlaylistService: DIContainer.shared.provideCollaborativePlaylistService(), collaborativePlaylistViewModel: collaborativePlaylistViewModel))
    }

    var body: some View {
        NavigationView {
            Form {
                TitleSection(title: $createPlaylistViewModel.title)
                DescriptionSection(description: $createPlaylistViewModel.description)
                PlaylistCreationToggles(createSpotifyPlaylist: $createPlaylistViewModel.createSpotifyPlaylist,
                    createAppleMusicPlaylist: $createPlaylistViewModel.createAppleMusicPlaylist)
                CollaboratorsSection(collaborators: $createPlaylistViewModel.collaborators, newCollaborator: $createPlaylistViewModel.newCollaborator, addCollaborator: createPlaylistViewModel.addNewCollaborator, deleteCollaborator: createPlaylistViewModel.deleteCollaborator)
            }
            .navigationBarTitle("New Playlist", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel", action: { dismiss() }), trailing: Button("Save", action: {
                Task {
                    await createPlaylistViewModel.save()
                    if (createPlaylistViewModel.errorMessage != nil) {
                        showErrorAlert = true
                    } else {
                        dismiss()
                    }
                }
            }))
            .alert(isPresented: $showErrorAlert) {
                Alert(title: Text("Error"), message: Text(createPlaylistViewModel.errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
            }
        }
        .accentColor(Color("SyncedBlue"))
    }
}

struct TitleSection: View {
    @Binding var title: String

    var body: some View {
        Section(header: Text("Title")) {
            TextField("Title", text: $title)
        }
    }
}

struct DescriptionSection: View {
    @Binding var description: String

    var body: some View {
        Section(header: Text("Description")) {
            TextField("Description", text: $description)
        }
    }
}

struct PlaylistCreationToggles: View {
    @Binding var createSpotifyPlaylist: Bool
    @Binding var createAppleMusicPlaylist: Bool

    var body: some View {
        Section(header: Text("Streaming Service Playlists")) {
            Toggle("Spotify Playlist", isOn: $createSpotifyPlaylist)
            Toggle("Apple Music Playlist", isOn: $createAppleMusicPlaylist)
        }
    }
}

struct CollaboratorsSection: View {
    @Binding var collaborators: [String]
    @Binding var newCollaborator: String
    var addCollaborator: () -> Void
    var deleteCollaborator: (IndexSet) -> Void

    var body: some View {
        Section(header: Text("Collaborators")) {
            ForEach(collaborators, id: \.self) { collaborator in
                Text(collaborator)
            }
            .onDelete(perform: deleteCollaborator)
            TextField("New Collaborator", text: $newCollaborator)
            Button("Add Collaborator", action: addCollaborator)
        }
    }
}

struct CreatePlaylistView_Previews: PreviewProvider {
    static var previews: some View {
        CreatePlaylistView(collaborativePlaylistViewModel: CollaborativePlaylistMenuViewModel(collaborativePlaylistService: DIContainer.shared.provideCollaborativePlaylistService()))
    }
}
