import SwiftUI

struct ContentView: View {
    @StateObject private var contentViewModel: ContentViewModel
        
    init() {
        _contentViewModel = StateObject(wrappedValue: ContentViewModel(authenticationService: DIContainer.shared.provideAuthenticationService()))
    }
    
    var body: some View {
        ZStack {
            Color("SyncedBackground")
                .ignoresSafeArea()
            if contentViewModel.isLoggedIn {
                CollaborativePlaylistsView(isLoggedIn: $contentViewModel.isLoggedIn)
            } else {
                LoginView(isLoggedIn: $contentViewModel.isLoggedIn)
            }
        }
        .onAppear {
            contentViewModel.recheckSession()
        }
    }
}

// For preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
