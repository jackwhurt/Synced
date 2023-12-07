import SwiftUI

struct CollaborativePlaylistsView: View {
    @StateObject private var viewModel = CollaborativePlaylistsViewModel()

    var body: some View {
        VStack {
            if viewModel.isLoggedIn {
                Text("Logged in. Hello, World!")
                Button("Logout") {
                    viewModel.logout()
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.red)
                .cornerRadius(10)
                Button("Connect Apple Music") {
                    viewModel.connectAppleMusic()
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.red)
                .cornerRadius(10)
            } else {
                Text("Not logged in.")
            }
        }
    }
}

// For preview
struct CollaborativePlaylistsView_Previews: PreviewProvider {
    static var previews: some View {
        CollaborativePlaylistsView()
    }
}
