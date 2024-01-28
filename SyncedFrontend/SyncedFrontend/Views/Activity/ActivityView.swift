import SwiftUI

struct ActivityView: View {
    let notifications = ["New follow request", "New comment on your post"]

    var body: some View {
        NavigationView {
            List {
                Section {
                    TextLink(title: "View Requests", destination: RequestView())
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

struct ActivityView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityView()
    }
}
