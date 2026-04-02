import Foundation
import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
  case companion
  case memory
  case settings

  var id: String { rawValue }

  var title: String {
    switch self {
    case .companion:
      return "Companion"
    case .memory:
      return "Memory"
    case .settings:
      return "Settings"
    }
  }

  var systemImage: String {
    switch self {
    case .companion:
      return "bubble.left.and.bubble.right.fill"
    case .memory:
      return "sparkles.rectangle.stack.fill"
    case .settings:
      return "slider.horizontal.3"
    }
  }
}

