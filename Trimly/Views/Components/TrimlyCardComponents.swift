import SwiftUI

enum TrimlyCardStyle {
	case surface
	case elevated
	case popup
    
	var backgroundColor: Color {
		#if os(macOS)
		let base = Color(nsColor: .windowBackgroundColor)
		#else
		let base = Color(.secondarySystemBackground)
		#endif
		switch self {
		case .surface:
			return base
		case .elevated:
			return base.opacity(0.98)
		case .popup:
			return base
		}
	}
    
	var borderColor: Color? {
		switch self {
		case .surface:
			return nil
		case .elevated:
			return Color.white.opacity(0.04)
		case .popup:
			return Color.white.opacity(0.08)
		}
	}
    
	var borderWidth: CGFloat {
		borderColor == nil ? 0 : 1
	}
    
	var shadow: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
		switch self {
		case .surface:
			return (.clear, 0, 0, 0)
		case .elevated:
			return (Color.black.opacity(0.08), 18, 0, 10)
		case .popup:
			return (Color.black.opacity(0.12), 20, 0, 12)
		}
	}
    
	var cornerRadius: CGFloat {
		switch self {
		case .popup:
			return 20
		default:
			return 24
		}
	}
    
	var defaultPadding: CGFloat {
		switch self {
		case .popup:
			return 18
		default:
			return 20
		}
	}
    
	var defaultContentSpacing: CGFloat {
		switch self {
		case .popup:
			return 10
		default:
			return 12
		}
	}
    
	var titleFont: Font {
		switch self {
		case .popup:
			return .headline
		default:
			return .title3.weight(.semibold)
		}
	}
    
	var descriptionFont: Font {
		switch self {
		case .popup:
			return .subheadline
		default:
			return .callout
		}
	}
}

struct TrimlyCardContainer<Content: View>: View {
	private let style: TrimlyCardStyle
	private let contentPadding: CGFloat?
	@ViewBuilder private let contentBuilder: () -> Content
    
	init(style: TrimlyCardStyle = .surface, padding: CGFloat? = nil, @ViewBuilder content: @escaping () -> Content) {
		self.style = style
		self.contentPadding = padding
		self.contentBuilder = content
	}
    
	var body: some View {
		contentBuilder()
			.padding(contentPadding ?? style.defaultPadding)
			.background(
				RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
					.fill(style.backgroundColor)
			)
			.overlay {
				if let borderColor = style.borderColor {
					RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
						.stroke(borderColor, lineWidth: style.borderWidth)
				}
			}
			.shadow(color: style.shadow.color,
				radius: style.shadow.radius,
				x: style.shadow.x,
				y: style.shadow.y)
	}
}

struct TrimlyCardSection<Content: View>: View {
	private let title: String
	private let description: String?
	private let style: TrimlyCardStyle
	private let spacing: CGFloat
	@ViewBuilder private let contentBuilder: () -> Content
    
	init(title: String, description: String? = nil, style: TrimlyCardStyle = .surface, spacing: CGFloat? = nil, @ViewBuilder content: @escaping () -> Content) {
		self.title = title
		self.description = description
		self.style = style
		self.spacing = spacing ?? style.defaultContentSpacing
		self.contentBuilder = content
	}
    
	var body: some View {
		TrimlyCardContainer(style: style) {
			VStack(alignment: .leading, spacing: spacing) {
				Text(title)
					.font(style.titleFont)
				if let description {
					Text(description)
						.font(style.descriptionFont)
						.foregroundStyle(.secondary)
				}
				contentBuilder()
			}
			.frame(maxWidth: .infinity, alignment: .leading)
		}
	}
}
