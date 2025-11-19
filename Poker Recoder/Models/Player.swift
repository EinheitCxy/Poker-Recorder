import Foundation
import SwiftData

@Model
final class Player {
    var id: UUID
    var name: String
    var seatNumber: Int  // 座位号，用于排序
    var style: String    // 风格：TAG / LAG / TP / LP
    var level: String    // 水平：Fish / Whale / Reg / Pro

    // 反向关联到Session
    var session: Session?

    init(
        name: String = "",
        seatNumber: Int = 0,
        style: String = "TAG",
        level: String = "Reg"
    ) {
        self.id = UUID()
        self.name = name
        self.seatNumber = seatNumber
        self.style = style
        self.level = level
    }
}
