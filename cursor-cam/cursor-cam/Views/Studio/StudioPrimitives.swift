import SwiftUI

struct CamRow<Trailing: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Studio.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundStyle(Studio.textMuted)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            Spacer(minLength: 8)
            trailing()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct KeyChip: View {
    let key: String

    init(_ key: String) { self.key = key }

    var body: some View {
        Text(key)
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .foregroundStyle(Studio.textPrimary.opacity(0.75))
            .frame(minWidth: 18, minHeight: 18)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Studio.chipFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(Studio.chipStroke, lineWidth: 0.5)
                    )
            )
    }
}

struct CamToggleChip: View {
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Spacer(minLength: 0)
            CamToggle(isOn: $isOn)
            Spacer(minLength: 0)
        }
        .frame(height: 30)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(Studio.chipFill)
                .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(Studio.chipStroke, lineWidth: 0.5))
        )
    }
}
