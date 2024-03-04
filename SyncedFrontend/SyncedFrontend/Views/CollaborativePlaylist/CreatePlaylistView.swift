import SwiftUI

// TODO: add pps to collaborator search
struct CreatePlaylistView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appSettings: AppSettings
    
    @State private var isSaving = false
    @State private var showErrorAlert = false
    @StateObject private var createPlaylistViewModel: CreatePlaylistViewModel
    
    init(collaborativePlaylistViewModel: CollaborativePlaylistMenuViewModel) {
        _createPlaylistViewModel = StateObject(wrappedValue: CreatePlaylistViewModel(collaborativePlaylistService: DIContainer.shared.provideCollaborativePlaylistService(), userService: DIContainer.shared.provideUserService(), collaborativePlaylistViewModel: collaborativePlaylistViewModel))
    }

    var body: some View {
        NavigationView {
            Form {
                TitleSection(title: $createPlaylistViewModel.title)
                DescriptionSection(description: $createPlaylistViewModel.description)
                PlaylistCreationToggles(createPlaylistViewModel: createPlaylistViewModel)
                UserSelect(collaborators: $createPlaylistViewModel.collaborators,
                    searchCollaborators: createPlaylistViewModel.searchUsers)
            }
            .navigationBarTitle("New Playlist", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel", action: { dismiss() }), trailing: saveButton)
            .alert(isPresented: $showErrorAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(createPlaylistViewModel.errorMessage ?? "Unknown error"),
                    dismissButton: .default(Text("OK"), action: {
                        // Clear the error message here
                        createPlaylistViewModel.errorMessage = nil
                    })
                )
            }
        }
        .accentColor(Color("SyncedBlue"))
    }
    
    private var saveButton: some View {
        Group {
            if isSaving {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                Button("Save", action: {
                    Task {
                        isSaving = true
                        await createPlaylistViewModel.save()
                        
                        if createPlaylistViewModel.errorMessage != nil {
                            showErrorAlert = true
                            isSaving = false
                        } else {
                            dismiss()
                        }
                    }
                })
            }
        }
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
    @StateObject var createPlaylistViewModel: CreatePlaylistViewModel
    @EnvironmentObject var appSettings: AppSettings

    var body: some View {
        Section(header: Text("Streaming Service Playlists")) {
            StreamingServiceToggles(isOnAppleMusic: Binding(
                get: { self.createPlaylistViewModel.createAppleMusicPlaylist },
                set: { self.createPlaylistViewModel.createAppleMusicPlaylist = $0 }
            ), isOnSpotify:  Binding(
                get: { self.createPlaylistViewModel.createSpotifyPlaylist },
                set: { self.createPlaylistViewModel.createSpotifyPlaylist = $0 }
            ))
        }
    }
}

struct CreatePlaylistView_Previews: PreviewProvider {
    static var previews: some View {
        CreatePlaylistView(collaborativePlaylistViewModel: CollaborativePlaylistMenuViewModel(collaborativePlaylistService: DIContainer.shared.provideCollaborativePlaylistService()))
    }
}
