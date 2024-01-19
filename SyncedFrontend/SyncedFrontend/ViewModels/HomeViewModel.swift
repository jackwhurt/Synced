import Foundation
import SwiftUI

class HomeViewModel: ObservableObject {
    @Published var isLoggedIn: Binding<Bool>
    
    init(isLoggedIn: Binding<Bool>) {
        self.isLoggedIn = isLoggedIn
    }
}
