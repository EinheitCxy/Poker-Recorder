import Foundation
import SwiftData

@Model
final class Hand {
    var id: UUID
    var position: String // UTG, MP, CO, BTN, SB, BB
    var holeCards: String // 如 "AhKd"
    var playersCount: Int
    var potSize: Double
    var isKeyHand: Bool
    var handSummary: String  // 手牌简介
    var note: String
    /// 庄家所在的座位索引（相对于 Session.players 按 seatNumber 排序的结果），可选
    var buttonSeatIndex: Int?
    var startTime: Date
    var endTime: Date?

    // 其他玩家的摊牌信息
    @Attribute(.transformable(by: "NSSecureUnarchiveFromDataTransformer"))
    var otherPlayersData: Data?

    // 结构化的街数据
    @Attribute(.transformable(by: "NSSecureUnarchiveFromDataTransformer"))
    var streetsData: Data?

    // 玩家快照数据（保存手牌创建时的玩家信息）
    @Attribute(.transformable(by: "NSSecureUnarchiveFromDataTransformer"))
    var playersSnapshotData: Data?

    // 反向关联到Session
    var session: Session?

    // 计算属性：从 Data 解码 streets
    var streets: [Street] {
        get {
            guard let data = streetsData,
                  let decoded = try? JSONDecoder().decode([Street].self, from: data) else {
                return []
            }
            return decoded
        }
        set {
            streetsData = try? JSONEncoder().encode(newValue)
        }
    }

    // 计算属性：从 Data 解码玩家快照
    var playersSnapshot: [PlayerSnapshot] {
        get {
            guard let data = playersSnapshotData,
                  let decoded = try? JSONDecoder().decode([PlayerSnapshot].self, from: data) else {
                return []
            }
            return decoded
        }
        set {
            playersSnapshotData = try? JSONEncoder().encode(newValue)
        }
    }

    init(
        position: String = "BTN",
        holeCards: String = "",
        playersCount: Int = 9,
        potSize: Double = 0,
        isKeyHand: Bool = false,
        handSummary: String = "",
        note: String = "",
        streets: [Street] = [],
        buttonSeatIndex: Int? = nil,
        playersSnapshot: [PlayerSnapshot] = [],
        startTime: Date = Date(),
        endTime: Date? = nil
    ) {
        self.id = UUID()
        self.position = position
        self.holeCards = holeCards
        self.playersCount = playersCount
        self.potSize = potSize
        self.isKeyHand = isKeyHand
        self.handSummary = handSummary
        self.note = note
        self.buttonSeatIndex = buttonSeatIndex
        self.startTime = startTime
        self.endTime = endTime
        self.streetsData = try? JSONEncoder().encode(streets)
        self.playersSnapshotData = try? JSONEncoder().encode(playersSnapshot)
        self.otherPlayersData = nil
    }
}

extension Hand {
    /// 计算单条街道对底池的增量（积分）
    static func potIncrement(for street: Street) -> Double {
        var contributions: [String: Double] = [:]  // 当前街每个玩家在本街的总投入

        for action in street.actions {
            let player = action.position
            let previous = contributions[player] ?? 0

            switch action.actionType {
            case .smallBlind, .bigBlind, .bet, .raise, .allin, .call:
                guard let amount = action.amount, amount > 0 else { continue }
                // amount 被理解为该玩家在本街道的总投入，增量是和之前相比的差值
                let increment = max(amount - previous, 0)
                contributions[player] = previous + increment
            case .check, .fold:
                continue
            }
        }

        return contributions.values.reduce(0, +)
    }

    /// 根据街道行动自动计算总底池大小
    static func potSize(for streets: [Street]) -> Double {
        streets.reduce(0) { total, street in
            total + potIncrement(for: street)
        }
    }

    /// 从当前 streets 计算的底池大小
    var computedPotSize: Double {
        Self.potSize(for: streets)
    }

    /// 将底池积分转换为BB单位（使用动态计算的底池大小）
    var potSizeInBB: Double {
        guard let session = session, session.pointsPerHundredBB > 0 else { return 0 }
        // 使用 computedPotSize（动态计算）而不是 potSize（保存时的值）
        // 1 BB = pointsPerHundredBB / 100 积分
        return computedPotSize / (session.pointsPerHundredBB / 100.0)
    }

    /// 其他玩家的摊牌信息（按玩家或位置存储）
    var otherPlayers: [RevealedHand] {
        get {
            guard let data = otherPlayersData,
                  let decoded = try? JSONDecoder().decode([RevealedHand].self, from: data) else {
                return []
            }
            return decoded
        }
        set {
            otherPlayersData = try? JSONEncoder().encode(newValue)
        }
    }
}

/// 单个玩家的摊牌信息
struct RevealedHand: Codable, Identifiable {
    var id: UUID
    var owner: String  // 玩家标识（昵称或位置）
    var cards: String  // 手牌，如 "AhKd"

    init(id: UUID = UUID(), owner: String, cards: String) {
        self.id = id
        self.owner = owner
        self.cards = cards
    }
}

/// 玩家信息快照（保存手牌创建时的玩家状态）
struct PlayerSnapshot: Codable, Identifiable {
    var id: UUID
    var name: String
    var seatNumber: Int
    var style: String
    var level: String

    init(id: UUID = UUID(), name: String, seatNumber: Int, style: String, level: String) {
        self.id = id
        self.name = name
        self.seatNumber = seatNumber
        self.style = style
        self.level = level
    }

    /// 从 Player 对象创建快照
    init(from player: Player) {
        self.id = player.id
        self.name = player.name
        self.seatNumber = player.seatNumber
        self.style = player.style
        self.level = player.level
    }
}
