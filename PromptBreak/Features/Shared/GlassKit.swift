import SwiftUI
import AppKit

// MARK: - Brand

enum Brand {
    // Tech-orange accent (solid) used for tints.
    static let accent = Color(red: 1.0, green: 0.46, blue: 0.15)   // #FF7526
    // Very subtle orange gradient for large text fills (barely perceptible).
    static let gradient = LinearGradient(
        colors: [Color(red: 1.0, green: 0.52, blue: 0.20), Color(red: 0.96, green: 0.40, blue: 0.11)],
        startPoint: .top, endPoint: .bottom
    )
    static let background = Color(red: 0.07, green: 0.07, blue: 0.085)
}

// MARK: - Background

struct GlassBackground: View {
    var body: some View { Brand.background.ignoresSafeArea() }
}

// MARK: - Native Liquid Glass helper (macOS 26) with a graceful fallback

@available(macOS 26.0, *)
private func makeGlass(tint: Color?, interactive: Bool) -> Glass {
    var g: Glass = .regular
    if let tint { g = g.tint(tint) }
    if interactive { g = g.interactive() }
    return g
}

extension View {
    @ViewBuilder
    func pbGlass<S: Shape>(tint: Color? = nil, interactive: Bool = true, in shape: S) -> some View {
        if #available(macOS 26.0, *) {
            self.glassEffect(makeGlass(tint: tint, interactive: interactive), in: shape)
        } else {
            self.background(.ultraThinMaterial, in: shape)
                .overlay(shape.stroke(.white.opacity(0.12), lineWidth: 1))
        }
    }

    func pbGlassCapsule(tint: Color? = nil, interactive: Bool = true) -> some View {
        pbGlass(tint: tint, interactive: interactive, in: Capsule())
    }
}

// MARK: - Low-contrast content card (integrates with the solid background)

struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 20
    var padding: CGFloat = 18
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.white.opacity(0.035), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 20, padding: CGFloat = 18) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius, padding: padding))
    }
}

// MARK: - Buttons (native glass on macOS 26)

struct PBPrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var trailing: String? = nil
    var fullWidth: Bool = false
    var enabled: Bool = true
    var key: KeyEquivalent? = nil
    let action: () -> Void

    var body: some View {
        if let key {
            button.keyboardShortcut(key, modifiers: .command)
        } else {
            button
        }
    }

    private var button: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title)
            }
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .overlay(alignment: .trailing) {
                if let trailing {
                    Text(trailing)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .modifier(PBPrimaryStyle())
        .disabled(!enabled)
    }
}

private struct PBPrimaryStyle: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content.buttonStyle(.glassProminent).tint(Brand.accent).controlSize(.large)
        } else {
            content.buttonStyle(.borderedProminent).tint(Brand.accent).controlSize(.large)
        }
    }
}

struct PBSecondaryButton: View {
    let title: String
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
        }
        .modifier(PBSecondaryStyle())
        .disabled(!enabled)
    }
}

private struct PBSecondaryStyle: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content.buttonStyle(.glass).controlSize(.large)
        } else {
            content.buttonStyle(.bordered).controlSize(.large)
        }
    }
}

// MARK: - Glass chips (single-select)

struct GlassChips<T: Hashable>: View {
    let options: [(value: T, label: String)]
    @Binding var selection: T

    var body: some View {
        HStack(spacing: 8) {
            ForEach(options, id: \.value) { opt in
                let active = opt.value == selection
                Button {
                    withAnimation(.smooth(duration: 0.2)) { selection = opt.value }
                } label: {
                    Text(opt.label)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(active ? AnyShapeStyle(.white) : AnyShapeStyle(.secondary))
                        .padding(.horizontal, 13)
                        .padding(.vertical, 7)
                }
                .buttonStyle(.plain)
                .pbGlassCapsule(tint: active ? Brand.accent : nil, interactive: true)
            }
        }
    }
}

// MARK: - Selectable glass card (one row = one option)

struct SelectableCard: View {
    let title: String
    var appIcon: NSImage? = nil
    var systemIcon: String? = nil
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let appIcon {
                    Image(nsImage: appIcon).resizable().frame(width: 24, height: 24)
                } else if let systemIcon {
                    Image(systemName: systemIcon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(selected ? AnyShapeStyle(.white) : AnyShapeStyle(Brand.accent))
                        .frame(width: 24)
                }
                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(selected ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
                    .lineLimit(1)
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundStyle(selected ? AnyShapeStyle(.white) : AnyShapeStyle(.secondary.opacity(0.4)))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
        }
        .buttonStyle(.plain)
        .pbGlass(tint: selected ? Brand.accent : nil, interactive: true,
                 in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

func formatTokens(_ n: Int) -> String {
    if n >= 1_000_000 {
        let m = Double(n) / 1_000_000
        return m == m.rounded() ? "\(Int(m))M" : String(format: "%.1fM", m)
    }
    if n >= 1_000 { return "\(n / 1000)k" }
    return "\(n)"
}

// MARK: - Glass dropdown menu

struct GlassMenu<T: Hashable>: View {
    let title: String
    let options: [(value: T, label: String)]
    @Binding var selection: T

    private var currentLabel: String {
        options.first { $0.value == selection }?.label ?? title
    }

    var body: some View {
        Menu {
            ForEach(options, id: \.value) { opt in
                Button(opt.label) { selection = opt.value }
            }
        } label: {
            HStack(spacing: 8) {
                Text(currentLabel).lineLimit(1)
                Spacer()
                Image(systemName: "chevron.up.chevron.down").font(.system(size: 10, weight: .semibold))
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .pbGlass(in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
    }
}
