import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    @StateObject private var cpViewModel = CollaborativePlaylistsViewModel()
    
    var body: some View {
        ZStack {
            Color("SyncedBackground")
                .ignoresSafeArea()
            if viewModel.isLoggedIn {
                CollaborativePlaylistsView()
            } else {
                LoginView(isLoggedIn: $viewModel.isLoggedIn)
            }
        }
        .onAppear {
            viewModel.recheckSession()
        }
    }
}

// For preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
