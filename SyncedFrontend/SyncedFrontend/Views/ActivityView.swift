import SwiftUI

struct ActivityView: View {
    let notifications = ["New follow request", "New comment on your post"]

    var body: some View {
        NavigationView {
            List {
                Section {
                    TextLink(title: "View Requests", destination: RequestsView())
                }

                Section(header: Text("Notifications")) {
                    ForEach(notifications, id: \.self) { notification in
                        Text(notification)
                    }
                }
            }
            .navigationBarTitle("Activities")
        }
    }
}

struct RequestsView: View {
    enum Tab {
        case users, playlists
    }

    @State private var selectedTab: Tab = .users

    var body: some View {
        VStack {
            Picker("Requests", selection: $selectedTab) {
                Text("Users").tag(Tab.users)
                Text("Playlists").tag(Tab.playlists)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            // Display the view based on the selected tab
            if selectedTab == .users {
                RequestsListView(requests: ["User1 wants to connect", "User2 sent a friend request"], title: "User Requests")
            } else {
                RequestsListView(requests: ["Playlist invite from User3", "Playlist invite from User4"], title: "Playlist Invitations")
            }
        }
        .navigationBarTitle("Requests", displayMode: .inline)
    }
}

struct RequestsListView: View {
    var requests: [String]
    var title: String

    var body: some View {
        List(requests, id: \.self) { request in
            Text(request)
            // Add buttons for accept/decline actions if needed
        }
        .navigationBarTitle(title)
    }
}


struct ActivityView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityView()
    }
}
