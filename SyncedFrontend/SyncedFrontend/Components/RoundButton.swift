import SwiftUI

struct RoundButtonStyle: ButtonStyle {
    let backgroundColor: Color
    let foregroundColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 200, height: 50) // Set a fixed size for the button
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(20) // Increase corner radius for a rounder button
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct RoundButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(RoundButtonStyle(
            backgroundColor: Color("SyncedBlue"),
            foregroundColor: Color.white
        ))
    }
}

// Preview for the RoundButton
struct RoundButton_Previews: PreviewProvider {
    static var previews: some View {
        RoundButton(
            title: "Sample Button"
        ) {
            // Action
        }
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
