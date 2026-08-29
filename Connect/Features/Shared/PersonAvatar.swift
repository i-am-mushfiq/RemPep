import SwiftUI
import UIKit

struct PersonAvatar: View {
    let person: Person
    var size: CGFloat = 48

    var body: some View {
        Group {
            if let data = person.photoData, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                ZStack {
                    Circle().fill(ConnectTheme.elevated)
                    Text(initials).font(.system(size: size * 0.34, weight: .semibold, design: .rounded)).foregroundStyle(ConnectTheme.accent)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }

    private var initials: String {
        person.name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined().uppercased()
    }
}
