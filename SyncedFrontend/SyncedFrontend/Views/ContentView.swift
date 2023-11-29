import SwiftUI

struct ContentView: View {
    @State private var isLoggedIn = false

    var body: some View {
        ZStack {
            Color("SyncedBackground")
                .ignoresSafeArea()
            if isLoggedIn {
                CollaborativePlaylistsView()
            } else {
                LoginView(isLoggedIn: $isLoggedIn)
            }
        }
    }
}

// For preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
