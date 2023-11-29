import SwiftUI

struct TextLink<Destination: View>: View {
    let title: String
    let destination: Destination

    var body: some View {
        NavigationLink(destination: destination) {
            Text(title)
                .foregroundColor(Color("SyncedDarkGrey"))
                .font(.body)
        }
    }
}
