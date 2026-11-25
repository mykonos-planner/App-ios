import SwiftUI

// MARK: - Palette

enum Palette {
    static let ivory = Color(hex: "#F7F3EC")
    static let surface = Color(hex: "#FFFDF9")
    static let ink = Color(hex: "#1D1B18")
    static let inkSoft = Color(hex: "#6E675C")
    static let brass = Color(hex: "#9A7B4C")
    static let olive = Color(hex: "#46523F")
    static let hairline = Color(hex: "#E4DCCF")
    static let warning = Color(hex: "#A65342")
}

enum Metrics {
    static let corner: CGFloat = 20
}

// MARK: - Tipografia

extension Font {
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static func sans(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}

// MARK: - Etichette

struct Kicker: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.sans(10, .semibold))
            .tracking(1.8)
            .foregroundColor(Palette.brass)
    }
}

struct ScreenHeader: View {
    let kicker: String
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Kicker(text: kicker)
            Text(title)
                .font(.serif(38))
                .foregroundColor(Palette.ink)
            if let subtitle {
                Text(subtitle)
                    .font(.sans(13))
                    .foregroundColor(Palette.inkSoft)
            }
        }
    }
}

struct FieldLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.sans(10, .semibold))
            .tracking(1.4)
            .foregroundColor(Palette.inkSoft)
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label.uppercased())
                .font(.sans(10, .semibold))
                .tracking(1.2)
                .foregroundColor(Palette.inkSoft)
            Spacer(minLength: 12)
            Text(value)
                .font(.sans(13, .medium))
                .foregroundColor(Palette.ink)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Bottoni

struct CTAButtonStyle: ButtonStyle {
    var filled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.sans(14, .semibold))
            .foregroundColor(filled ? Palette.surface : Palette.ink)
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(filled ? Palette.ink : Palette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(filled ? Color.clear : Palette.hairline, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct CircleIconButton: View {
    let icon: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Palette.ink)
                .frame(width: 34, height: 34)
                .background(Circle().fill(Palette.surface))
                .overlay(Circle().stroke(Palette.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct Chip: View {
    let title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.sans(12, .medium))
                .foregroundColor(isSelected ? Palette.surface : Palette.inkSoft)
                .padding(.horizontal, 13)
                .padding(.vertical, 7)
                .background(Capsule().fill(isSelected ? Palette.ink : Palette.surface))
                .overlay(Capsule().stroke(isSelected ? Color.clear : Palette.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Punteggio

struct ScoreRing: View {
    let score: Int
    var size: CGFloat = 116
    var lineWidth: CGFloat = 10

    private var ringColor: Color {
        switch score {
        case 86...: return Color(hex: "#4F6B4A")
        case 72..<86: return Color(hex: "#77803F")
        case 58..<72: return Palette.brass
        default: return Palette.warning
        }
    }

    var body: some View {
        ZStack {
            Circle().stroke(Palette.hairline, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: CGFloat(min(max(score, 0), 100)) / 100)
                .stroke(ringColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(score)")
                    .font(.serif(size * 0.32, .semibold))
                    .foregroundColor(Palette.ink)
                Text("su 100")
                    .font(.sans(size * 0.09, .medium))
                    .foregroundColor(Palette.inkSoft)
            }
        }
        .frame(width: size, height: size)
        .animation(.easeInOut(duration: 0.45), value: score)
    }
}

struct MetricBar: View {
    let label: String
    let value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(label.uppercased())
                    .font(.sans(9, .semibold))
                    .tracking(1.2)
                    .foregroundColor(Palette.inkSoft)
                Spacer()
                Text("\(value)")
                    .font(.sans(11, .semibold))
                    .foregroundColor(Palette.ink)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.hairline)
                    Capsule()
                        .fill(Palette.brass)
                        .frame(width: max(0, geometry.size.width * CGFloat(min(max(value, 0), 100)) / 100))
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Card

struct CardBackground: ViewModifier {
    var padding: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: Metrics.corner, style: .continuous)
                    .fill(Palette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.corner, style: .continuous)
                    .stroke(Palette.hairline, lineWidth: 1)
            )
            .shadow(color: Palette.ink.opacity(0.04), radius: 14, x: 0, y: 8)
    }
}

extension View {
    func card(padding: CGFloat = 18) -> some View {
        modifier(CardBackground(padding: padding))
    }
}

// MARK: - Contenitore per le schermate modali

struct ModalScaffold<Content: View>: View {
    let title: String
    let kicker: String?
    let trailing: AnyView?
    private let content: Content

    @Environment(\.dismiss) private var dismiss

    init(title: String,
         kicker: String? = nil,
         trailing: AnyView? = nil,
         @ViewBuilder content: () -> Content) {
        self.title = title
        self.kicker = kicker
        self.trailing = trailing
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    if let kicker {
                        Text(kicker.uppercased())
                            .font(.sans(9, .semibold))
                            .tracking(1.6)
                            .foregroundColor(Palette.brass)
                    }
                    Text(title)
                        .font(.serif(24, .semibold))
                        .foregroundColor(Palette.ink)
                }
                Spacer(minLength: 8)
                if let trailing { trailing }
                CircleIconButton(icon: "xmark") { dismiss() }
            }
            .padding(.horizontal, 22)
            .padding(.top, 20)
            .padding(.bottom, 14)

            Divider().overlay(Palette.hairline)

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Palette.ivory.ignoresSafeArea())
    }
}
