//
//  ContactAvatarView.swift
//  ContactsExplorer
//

import SwiftUI
import UIKit

struct ContactAvatarView: View {
    let contact: Contact
    var imageData: Data? = nil
    let size: CGFloat

    var body: some View {
        Group {
            if let data = imageData ?? contact.thumbnailData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                initialsAvatar
            }
        }
        .frame(width: size, height: size)
        .clipShape(.circle)
    }

    private var initialsAvatar: some View {
        ZStack {
            Circle()
                .fill(Color.gray.gradient)
            Text(contact.initials)
                .font(.system(size: size * 0.4, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
        }
    }
}
