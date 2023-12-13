import SwiftUI

struct CollaborativePlaylistsView: View {
    @StateObject private var cpViewModel: CollaborativePlaylistsViewModel
    
    init(isLoggedIn: Binding<Bool>) {
        _cpViewModel = StateObject(wrappedValue: CollaborativePlaylistsViewModel(
            authenticationService: DIContainer.shared.provideAuthenticationService(),
            appleMusicService: DIContainer.shared.provideAppleMusicService()
            )
        )
    }
    
    var body: some View {
        VStack {
            if cpViewModel.isLoggedIn {
                Text("Logged in. Hello, World!")
                Button("Logout") {
                    cpViewModel.logout()
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.red)
                .cornerRadius(10)
                Button("Connect Apple Music") {
                    cpViewModel.connectAppleMusic()
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
        CollaborativePlaylistsView(isLoggedIn: .constant(false))
    }
}
