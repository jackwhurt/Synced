import SwiftUI

struct CollaborativePlaylistMenuView: View {
    @StateObject private var collaborativePlaylistMenuViewModel: CollaborativePlaylistMenuViewModel
    @State private var showingAddPlaylistSheet = false

    init() {
        let collaborativePlaylistService = DIContainer.shared.provideCollaborativePlaylistService()
        _collaborativePlaylistMenuViewModel = StateObject(wrappedValue: CollaborativePlaylistMenuViewModel(collaborativePlaylistService: collaborativePlaylistService))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    if collaborativePlaylistMenuViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                    }
                    List {
                        addPlaylistSection
                        playlistsSection
                    }
                    .navigationTitle("Playlists")
                }
                .onAppear(perform: loadPlaylists)
            }
            .animation(.easeInOut(duration: 0.2), value: collaborativePlaylistMenuViewModel.isLoading)
            .transition(.slide)
            .alert(isPresented: Binding<Bool>(
                get: { collaborativePlaylistMenuViewModel.errorMessage != nil },
                set: { _ in collaborativePlaylistMenuViewModel.errorMessage = nil }
            )) {
                Alert(title: Text("Error"), message: Text(collaborativePlaylistMenuViewModel.errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private var addPlaylistSection: some View {
        Section {
            Button(action: { showingAddPlaylistSheet = true }) {
                Label("Add New Playlist", systemImage: "plus")
            }
            .foregroundColor(.syncedBlue)
            .sheet(isPresented: $showingAddPlaylistSheet) {
                CreatePlaylistView(collaborativePlaylistViewModel: collaborativePlaylistMenuViewModel)
            }
        }
    }
    
    private var playlistsSection: some View {
        Section {
            if collaborativePlaylistMenuViewModel.playlists.isEmpty {
                Text("No playlists available")
                    .foregroundColor(.gray)
            } else {
                ForEach(collaborativePlaylistMenuViewModel.playlists) { playlist in
                    NavigationLink(destination: CollaborativePlaylistView(
                        playlistId: String(playlist.id.dropFirst(3)))) {
                            PlaylistView(playlist: playlist)
                    }
                }
            }
        }
    }
    
    private func loadPlaylists() {
        Task {
            await collaborativePlaylistMenuViewModel.loadPlaylists()
        }
    }
}

struct PlaylistView: View {
    let playlist: GetCollaborativePlaylistResponse
    
    var body: some View {
        HStack(spacing: 10) {
            MusicAsyncImageLoader(urlString: playlist.coverImageUrl, reloadAfterCacheHit: true, width: 50, height: 50)
            
            Text(playlist.title)
                .foregroundColor(.primary)
                .font(.headline)
        }
    }
}

struct CollaborativePlaylistMenuView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(isLoggedIn: .constant(true))
    }
}
