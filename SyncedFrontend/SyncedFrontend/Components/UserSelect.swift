import SwiftUI

struct UserSelect: View {
    @Binding var collaborators: [UserMetadata]
    var searchCollaborators: (String, Int) async -> [UserMetadata]

    @State private var usernameQuery = ""
    @State private var searchResults = [UserMetadata]()
    @State private var isSearching = false

    var body: some View {
        Section(header: Text("Collaborators")) {
            ForEach(collaborators, id: \.self) { collaborator in
                Text(collaborator.username)
                    .foregroundColor(.syncedBlue)
                    .padding(.vertical, 4)
            }
            .onDelete(perform: deleteCollaborator)

            TextField("Search users", text: $usernameQuery)
                .onChange(of: usernameQuery) { _, newValue in
                    performSearch(with: newValue)
                }

            if isSearching {
                if searchResults.isEmpty {
                    Text("No users found")
                        .foregroundColor(.syncedErrorRed)
                } else {
                    ForEach(searchResults, id: \.self) { result in
                        Text(result.username)
                            .onTapGesture {
                                collaborators.append(result)
                                usernameQuery = ""
                                isSearching = false
                                searchResults = []
                            }
                    }
                }
            }
        }
    }

    private func deleteCollaborator(at offsets: IndexSet) {
        collaborators.remove(atOffsets: offsets)
    }

    private func performSearch(with query: String) {
        if query.isEmpty {
            searchResults = []
            isSearching = false
        } else {
            Task {
                let results = await searchCollaborators(query, 1)
                searchResults = results.filter { !collaborators.contains($0) }
                isSearching = true
            }
        }
    }
}
