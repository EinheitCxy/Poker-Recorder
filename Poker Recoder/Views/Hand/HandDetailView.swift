import SwiftUI
import SwiftData

struct HandDetailView: View {
    let hand: Hand
    let session: Session

    @State private var showingEditor = false

    // 使用玩家快照（如果有），否则回退到当前玩家列表
    private var playersSnapshot: [PlayerSnapshot] {
        let snapshot = hand.playersSnapshot
        if !snapshot.isEmpty {
            return snapshot
        }

        // 回退：如果没有快照（旧数据），使用当前玩家列表创建临时快照
        let sorted = session.players.sorted { $0.seatNumber < $1.seatNumber }
        let count = min(hand.playersCount, sorted.count)
        return Array(sorted.prefix(count)).map { PlayerSnapshot(from: $0) }
    }

    // 计算标准位置列表（使用手牌创建时的玩家数）
    private var standardPositions: [String] {
        HandEditorView.calculateStandardPositions(
            playerCount: hand.playersCount,
            buttonPlayerIndex: hand.buttonSeatIndex ?? 0
        )
    }

    // 获取玩家名称列表（使用快照）
    private var playerNames: [String] {
        playersSnapshot.map { $0.name.isEmpty ? "玩家 \(($0.seatNumber + 1))" : $0.name }
    }

    private var blindInfo: (smallBlind: String, bigBlind: String)? {
        guard !playersSnapshot.isEmpty else { return nil }

        let count = hand.playersCount
        guard count >= 2 else { return nil }

        guard let storedButtonIndex = hand.buttonSeatIndex else { return nil }
        let buttonIndex = ((storedButtonIndex % count) + count) % count

        let sbIndex: Int
        let bbIndex: Int

        if count == 2 {
            // Heads-up：button 同时是 SB/BTN，另一位是 BB
            sbIndex = buttonIndex
            bbIndex = (buttonIndex + 1) % count
        } else {
            sbIndex = (buttonIndex + 1) % count
            bbIndex = (buttonIndex + 2) % count
        }

        func displayName(for index: Int) -> String {
            guard index < playersSnapshot.count else {
                return "座位 \(index + 1)"
            }
            let player = playersSnapshot[index]
            if !player.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return player.name
            } else {
                return "座位 \(player.seatNumber + 1)"
            }
        }

        return (smallBlind: displayName(for: sbIndex),
                bigBlind: displayName(for: bbIndex))
    }

    private struct DisplayCard: Identifiable {
        let id = UUID()
        let rank: String
        let suit: Character

        var suitSymbol: String {
            switch suit {
            case "s": return "♠️"
            case "h": return "♥️"
            case "d": return "♦️"
            case "c": return "♣️"
            default:  return "?"
            }
        }

        var isRed: Bool {
            suit == "h" || suit == "d"
        }
    }

    private func displayCards(from raw: String) -> [DisplayCard] {
        let chars = Array(raw)
        var result: [DisplayCard] = []
        var i = 0

        while i + 1 < chars.count {
            let rank = String(chars[i])
            let suit = chars[i + 1]
            result.append(DisplayCard(rank: rank, suit: suit))
            i += 2
        }

        return result
    }

    var body: some View {
        List {
            Section("基本信息") {
                HStack {
                    Text("开始时间")
                    Spacer()
                    Text(hand.startTime, format: .dateTime.hour().minute())
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("我的位置")
                    Spacer()
                    Text(hand.position)
                        .foregroundColor(.secondary)
                }

                if !hand.holeCards.isEmpty {
                    HStack {
                        Text("我的手牌")
                        Spacer()
                        HStack(spacing: 4) {
                            ForEach(displayCards(from: hand.holeCards)) { card in
                                Text("\(card.rank)\(card.suitSymbol)")
                                    .foregroundColor(card.isRed ? .red : .primary)
                            }
                        }
                    }
                }

                HStack {
                    Text("玩家人数")
                    Spacer()
                    Text("\(hand.playersCount) 人")
                        .foregroundColor(.secondary)
                }

                // 位置对应关系
                if !playersSnapshot.isEmpty && !standardPositions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("位置对应")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(0..<min(playerNames.count, standardPositions.count), id: \.self) { index in
                                    VStack(spacing: 4) {
                                        Text(playerNames[index])
                                            .font(.caption)
                                            .foregroundColor(.primary)
                                        Text(standardPositions[index])
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.secondary.opacity(0.1))
                                    .cornerRadius(6)
                                }
                            }
                        }
                    }
                }

                PotSizeRow(pot: hand.computedPotSize, session: session)

                if hand.isKeyHand {
                    Label("关键牌", systemImage: "star.fill")
                        .foregroundColor(.yellow)
                }
            }

            ForEach(Array(hand.streets.enumerated()), id: \.element.id) { index, street in
                if !street.cards.isEmpty || !street.actions.isEmpty {
                    let potBefore = Hand.potSize(for: Array(hand.streets.prefix(index)))
                    let streetIncrement = Hand.potIncrement(for: street)
                    let potAfter = potBefore + streetIncrement

                    Section {
                        if !street.cards.isEmpty {
                            HStack {
                                Text("公共牌")
                                Spacer()
                                HStack(spacing: 4) {
                                    ForEach(displayCards(from: street.cards)) { card in
                                        Text("\(card.rank)\(card.suitSymbol)")
                                            .foregroundColor(card.isRed ? .red : .primary)
                                    }
                                }
                            }
                        }

                        ForEach(street.actions) { action in
                            HStack(alignment: .firstTextBaseline) {
                                Text(action.description)
                                Spacer()
                                if let amount = action.amount,
                                   session.pointsPerHundredBB > 0 {
                                    let bb = amount / (session.pointsPerHundredBB / 100.0)
                                    Text(String(format: "%.1f BB", bb))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }

                        if potAfter > 0 {
                            HStack {
                                Spacer()
                                Text(currentStreetPotText(potAfter: potAfter))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 4)
                        }
                    } header: {
                        Text(headerTitle(for: street, potBefore: potBefore))
                    }
                }
            }

            // 其他玩家摊牌信息
            let others = hand.otherPlayers.filter { !$0.cards.isEmpty }
            if !others.isEmpty {
                Section("其他玩家手牌") {
                    ForEach(others) { info in
                        HStack {
                            Text(info.owner.isEmpty ? "未知玩家" : info.owner)
                            Spacer()
                            HStack(spacing: 4) {
                                ForEach(displayCards(from: info.cards)) { card in
                                    Text("\(card.rank)\(card.suitSymbol)")
                                        .foregroundColor(card.isRed ? .red : .primary)
                                }
                            }
                        }
                    }
                }
            }

            if !hand.note.isEmpty {
                Section("备注") {
                    Text(hand.note)
                }
            }
        }
        .navigationTitle({
            // 优先显示手牌简介
            if !hand.handSummary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return hand.handSummary
            }
            // 如果没有简介，显示手牌编号
            if let index = session.hands.firstIndex(where: { $0.id == hand.id }) {
                return "手牌\(index + 1)"
            }
            return "手牌详情"
        }())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("编辑") {
                    showingEditor = true
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            HandEditorView(hand: hand, session: session)
        }
    }
}

private extension HandDetailView {
    func headerTitle(for street: Street, potBefore: Double) -> String {
        guard potBefore > 0, street.name != "Preflop" else {
            return street.name
        }

        if session.pointsPerHundredBB > 0 {
            let bbValue = potBefore / (session.pointsPerHundredBB / 100.0)
            let potInt = Int(potBefore.rounded())
            let bbString = String(format: "%.1f", bbValue)
            return "\(street.name)(pot:\(potInt)/\(bbString)bb)"
        } else {
            let potInt = Int(potBefore.rounded())
            return "\(street.name)(pot:\(potInt))"
        }
    }

    func currentStreetPotText(potAfter: Double) -> String {
        guard potAfter > 0 else { return "" }

        if session.pointsPerHundredBB > 0 {
            let bbValue = potAfter / (session.pointsPerHundredBB / 100.0)
            let potInt = Int(potAfter.rounded())
            let bbString = String(format: "%.1f", bbValue)
            return "此时底池 \(potInt)/\(bbString)bb"
        } else {
            let potInt = Int(potAfter.rounded())
            return "此时底池 \(potInt)"
        }
    }
}

struct PotSizeRow: View {
    let pot: Double
    let session: Session

    var body: some View {
        if pot > 0 {
            HStack {
                Text("总底池")
                Spacer()
                if session.pointsPerHundredBB > 0 {
                    let potBB = pot / (session.pointsPerHundredBB / 100.0)
                    Text(String(format: "%.1f BB", potBB))
                        .foregroundColor(.secondary)
                } else {
                    Text(String(format: "%.0f", pot))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
