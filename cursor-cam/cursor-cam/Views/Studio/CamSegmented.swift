import SwiftUI

struct CamSegmented<T: Hashable>: View {
    @Binding var selection: T
    let options: [(T, String)]

    @Namespace private var ns

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options.indices, id: \.self) { idx in
                segment(value: options[idx].0, label: options[idx].1)
            }
        }
        .padding(2)
        .background(background)
        .focusable(false)
    }

    private func segment(value: T, label: String) -> some View {
        let selected = selection == value
        return ZStack {
            if selected {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(Color.accentColor.opacity(0.18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(Color.accentColor.opacity(0.4), lineWidth: 0.5)
                    )
                    .matchedGeometryEffect(id: "pill", in: ns)
            }
            Text(label)
                .font(.system(size: 11, weight: selected ? .semibold : .regular))
                .foregroundStyle(selected ? Color.accentColor : Studio.textPrimary.opacity(0.55))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 26)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                selection = value
            }
        }
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: 13, style: .continuous)
            .fill(Studio.chipFill)
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(Studio.chipStroke, lineWidth: 0.5)
            )
    }
}
