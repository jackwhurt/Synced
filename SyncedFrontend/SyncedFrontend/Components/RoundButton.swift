import SwiftUI

struct RoundButtonStyle: ButtonStyle {
    let backgroundColour: Color
    let foregroundColour: Color
    var width: CGFloat? = 200
    var height: CGFloat? = 50
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: width, height: height)
            .background(backgroundColour)
            .foregroundColor(foregroundColour)
            .cornerRadius(20)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct RoundButton: View {
    let title: String
    let action: () -> Void
    var backgroundColour: Color = Color.syncedBlue
    var foregroundColour: Color = Color.white
    var width: CGFloat? = 200
    var height: CGFloat? = 50

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(RoundButtonStyle(
            backgroundColour: backgroundColour,
            foregroundColour: foregroundColour,
            width: width,
            height: height
        ))
    }
}

struct RoundButton_Previews: PreviewProvider {
    static var previews: some View {
        RoundButton(
            title: "Sample Button",
            action: {}
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
