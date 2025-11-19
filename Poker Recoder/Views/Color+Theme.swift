import SwiftUI

extension Color {
    /// App 主背景色：深蓝色桌布风格
    static let appBackground = Color(red: 10 / 255, green: 20 / 255, blue: 40 / 255)

    /// 卡片前景色：比背景稍浅的蓝色
    static let appCardBackground = Color(red: 20 / 255, green: 32 / 255, blue: 60 / 255)

    /// 统一强调色（按钮/选中状态）：柔和的天蓝色
    static let appAccent = Color(red: 100 / 255, green: 150 / 255, blue: 220 / 255)
}

extension View {
    /// 统一的信息卡片毛玻璃样式
    func glassCard(cornerRadius: CGFloat = 12) -> some View {
        self
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: cornerRadius)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 5, y: 2)
    }
}
