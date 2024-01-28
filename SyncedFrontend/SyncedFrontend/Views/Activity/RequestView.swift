import SwiftUI

struct RequestView: View {
    @State private var selectedTab: Tab = .users
    @StateObject private var requestViewModel: RequestViewModel
    
    init() {
        let activityService = DIContainer.shared.provideActivityService()
        _requestViewModel = StateObject(wrappedValue: RequestViewModel(activityService: activityService))
    }
    
    var body: some View {
        VStack {
            Picker("Requests", selection: $selectedTab) {
                Text("Users").tag(Tab.users)
                Text("Playlists").tag(Tab.playlists)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            if selectedTab == .users {
                UserRequestListView(userRequests: requestViewModel.userRequests)
            } else {
                PlaylistRequestListView(playlistRequests: requestViewModel.playlistRequests)
            }
        }
        .navigationBarTitle("Requests", displayMode: .inline)
        .alert(isPresented: Binding<Bool>(
            get: { requestViewModel.errorMessage != nil },
            set: { _ in requestViewModel.errorMessage = nil }
        )) {
            Alert(title: Text("Error"), message: Text(requestViewModel.errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
        }
    }
}


struct UserRequestListView: View {
    var userRequests: [UserRequest]

    var body: some View {
        List(userRequests, id: \.self) { request in
            Text("Follow request from \(request.createdByUsername)")
        }
        .navigationBarTitle("Users")
    }
}

struct PlaylistRequestListView: View {
    var playlistRequests: [PlaylistRequest]

    var body: some View {
        List(playlistRequests, id: \.self) { request in
            Text("Playlist request from \(request.createdByUsername) for playlist \(request.playlistTitle)")
        }
        .navigationBarTitle("Playlists")
    }
}

enum Tab {
    case users, playlists
}

struct RequestView_Previews: PreviewProvider {
    static var previews: some View {
        RequestView()
    }
}
