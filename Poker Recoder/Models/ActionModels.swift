import Foundation

// 行动类型
enum ActionType: String, Codable {
    case fold = "Fold"
    case check = "Check"
    case call = "Call"
    case bet = "Bet"
    case raise = "Raise"
    case allin = "Allin"
    case smallBlind = "SB"
    case bigBlind = "BB"
}

// 单个玩家行动
struct PlayerAction: Codable, Identifiable {
    var id: UUID
    var position: String  // UTG, MP, HJ, CO, BTN, SB, BB
    var actionType: ActionType
    var amount: Double?  // 可选，用于 Bet/Raise/Allin

    init(position: String = "BTN", actionType: ActionType = .fold, amount: Double? = nil) {
        self.id = UUID()
        self.position = position
        self.actionType = actionType
        self.amount = amount
    }

    var description: String {
        switch actionType {
        case .fold, .check, .call:
            return "\(position) \(actionType.rawValue)"
        case .bet, .raise, .allin, .smallBlind, .bigBlind:
            if let amount = amount {
                return "\(position) \(actionType.rawValue) \(amount)"
            }
            return "\(position) \(actionType.rawValue)"
        }
    }
}

// 街（Preflop/Flop/Turn/River）
struct Street: Codable, Identifiable {
    var id: UUID
    var name: String  // Preflop, Flop, Turn, River
    var cards: String  // 公共牌，如 "Th7s5c"
    var actions: [PlayerAction]

    init(name: String, cards: String = "", actions: [PlayerAction] = []) {
        self.id = UUID()
        self.name = name
        self.cards = cards
        self.actions = actions
    }

    var displayCards: String {
        guard !cards.isEmpty else { return "" }
        // 格式化显示，每两个字符一组
        var result = ""
        for i in stride(from: 0, to: cards.count, by: 2) {
            let start = cards.index(cards.startIndex, offsetBy: i)
            let end = cards.index(start, offsetBy: min(2, cards.count - i))
            result += String(cards[start..<end]) + " "
        }
        return result.trimmingCharacters(in: .whitespaces)
    }
}

// UUID 包装类型，用于 sheet(item:)
struct IdentifiableUUID: Identifiable {
    let id: UUID
}
