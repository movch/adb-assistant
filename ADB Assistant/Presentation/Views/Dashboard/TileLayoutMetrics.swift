import AppKit
import SwiftUI

enum TileLayoutMetrics {
    static let uiScale: CGFloat = 0.5

    static let baseTileSize: CGFloat = 200
    static let baseTileCornerRadius: CGFloat = 22
    static let baseTileContentPadding: CGFloat = 18
    static let baseGridSpacing: CGFloat = 16
    static let baseSectionSpacing: CGFloat = 28
    static let baseSectionInnerSpacing: CGFloat = 20

    static var tileSize: CGFloat { baseTileSize * uiScale }
    static var tileCornerRadius: CGFloat { baseTileCornerRadius * uiScale }
    static var tileContentPadding: CGFloat { baseTileContentPadding * uiScale }
    static var gridSpacing: CGFloat { baseGridSpacing * uiScale }
    static var sectionSpacing: CGFloat { baseSectionSpacing * uiScale }
    static let sectionHeaderSpacing: CGFloat = 6
    static var sectionInnerSpacing: CGFloat { baseSectionInnerSpacing * uiScale }
    static let contentInsets = EdgeInsets(top: 28, leading: 28, bottom: 40, trailing: 28)
    static let backgroundColor = Color(NSColor.windowBackgroundColor)
}
