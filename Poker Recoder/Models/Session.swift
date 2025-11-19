import Foundation
import SwiftData

@Model
final class Session {
    var id: UUID
    var playedAt: Date  // 保留用于兼容性，实际使用 startTime
    var startTime: Date  // 开始时间
    var endTime: Date?   // 结束时间（可选）
    var sessionName: String  // 牌局名称
    var location: String
    var blindLevel: String
    var bigBlind: Double  // 大盲金额
    var pointsPerHundredBB: Double  // 每 100BB（一手）对应的积分
    var buyIn: Double
    var cashOut: Double
    var note: String
    var isActive: Bool  // true=进行中, false=已结束

    // 一对多关系：一个Session包含多个Hand
    @Relationship(deleteRule: .cascade, inverse: \Hand.session)
    var hands: [Hand]

    // 一对多关系：一个Session包含多个Player
    @Relationship(deleteRule: .cascade, inverse: \Player.session)
    var players: [Player]

    // 计算属性：盈亏
    var profit: Double {
        cashOut - buyIn
    }

    // 计算属性：游戏时长（秒）
    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }

    // 计算属性：格式化的游戏时长
    var formattedDuration: String {
        guard let duration = duration else { return "进行中" }
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }

    init(
        playedAt: Date = Date(),
        startTime: Date = Date(),
        endTime: Date? = nil,
        sessionName: String = "",
        location: String = "",
        blindLevel: String = "",
        bigBlind: Double = 0,
        pointsPerHundredBB: Double = 0,
        buyIn: Double = 0,
        cashOut: Double = 0,
        note: String = "",
        isActive: Bool = true
    ) {
        self.id = UUID()
        self.playedAt = playedAt
        self.startTime = startTime
        self.endTime = endTime
        self.sessionName = sessionName
        self.location = location
        self.blindLevel = blindLevel
        self.bigBlind = bigBlind
        self.pointsPerHundredBB = pointsPerHundredBB
        self.buyIn = buyIn
        self.cashOut = cashOut
        self.note = note
        self.isActive = isActive
        self.hands = []
        self.players = []
    }
}

extension Session {
    /// 将积分制盈亏换算为 BB 单位盈亏
    /// 前提是已经设置了每 100BB 对应的积分比例。
    var profitInBB: Double {
        guard pointsPerHundredBB > 0 else { return 0 }
        // profit 是积分，pointsPerHundredBB 表示 100BB 对应多少积分
        // => 1BB 对应 pointsPerHundredBB / 100 积分
        // profit / (pointsPerHundredBB / 100) = profit * 100 / pointsPerHundredBB
        return profit * 100.0 / pointsPerHundredBB
    }
}
