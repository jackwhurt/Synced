import SwiftUI

struct CreatePlaylistView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appSettings: AppSettings
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
                CollaboratorsSection(collaborators: $createPlaylistViewModel.collaborators,
                    usernameQuery: $createPlaylistViewModel.usernameQuery,
                    deleteCollaborator: createPlaylistViewModel.deleteCollaborator,
                    searchCollaborators: createPlaylistViewModel.searchUsers)
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

struct CollaboratorsSection: View {
    @Binding var collaborators: [UserMetadata]
    @Binding var usernameQuery: String
    var deleteCollaborator: (IndexSet) -> Void
    var searchCollaborators: (String, Int) async -> [UserMetadata]

    @State private var searchResults = [UserMetadata]()
    @State private var isSearching = false

    var body: some View {
        Section(header: Text("Collaborators")) {
            // Displaying selected collaborators
            ForEach(collaborators, id: \.self) { collaborator in
                Text(collaborator.username)
                    .foregroundColor(.syncedBlue)
                    .padding(.vertical, 4)
            }
            .onDelete(perform: deleteCollaborator)

            TextField("Search users", text: $usernameQuery)
                .onChange(of: usernameQuery) {
                    if usernameQuery.isEmpty {
                        searchResults = []
                        isSearching = false
                    } else {
                        Task {
                            let results = await searchCollaborators(usernameQuery, 1)
                            searchResults = results.filter { !collaborators.contains($0) }
                            isSearching = true
                        }
                    }
                }

            // Displaying search results or a message if no results are found
            if isSearching {
                if searchResults.isEmpty {
                    Text("No users found")
                        .foregroundColor(.syncedErrorRed)
                } else {
                    ForEach(searchResults, id: \.self) { result in
                        Text(result.username)
                            .onTapGesture {
                                collaborators.append(result)
                                usernameQuery = ""
                                isSearching = false
                            }
                    }
                }
            }
        }
    }
}

struct CreatePlaylistView_Previews: PreviewProvider {
    static var previews: some View {
        CreatePlaylistView(collaborativePlaylistViewModel: CollaborativePlaylistMenuViewModel(collaborativePlaylistService: DIContainer.shared.provideCollaborativePlaylistService()))
    }
}
