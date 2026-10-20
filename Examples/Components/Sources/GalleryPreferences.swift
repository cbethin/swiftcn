import SwiftUI

enum GalleryPreferences {
    static let darkKey = "swiftcn.gallery.dark"
    static let defaultModeKey = "swiftcn.gallery.defaultMode"
    static let previewGridKey = "swiftcn.gallery.previewGrid"

    static func defaultMode(in defaults: UserDefaults = .standard) -> GalleryWorkspaceMode {
        defaults.string(forKey: defaultModeKey).flatMap(GalleryWorkspaceMode.init(rawValue:)) ?? .split
    }
}
