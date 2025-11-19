import SwiftUI
import SwiftData

struct HandEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let hand: Hand?
    let session: Session

    @State private var position: String
    @State private var holeCards: String
    @State private var isKeyHand: Bool
    @State private var handSummary: String = ""
    @State private var note: String
    @State private var streets: [Street]
    @State private var otherPlayers: [RevealedHand] = []
    @State private var buttonPlayerIndex: Int = 0
    @State private var showingCardPicker = false
    @State private var activeStreetForCardPicker: IdentifiableUUID?
    @State private var activeStreetForActionEditor: IdentifiableUUID?
    @State private var activeOtherPlayerForCardPicker: IdentifiableUUID?

    // 获取原始玩家列表（按座位号排序）
    private var namedPlayers: [String] {
        Self.namedPlayers(from: session)
    }

    // 预计算的行动顺序（环形链表）
    private var preflopOrder: [String] {
        calculateActionOrder(isPreflop: true)
    }

    private var postflopOrder: [String] {
        calculateActionOrder(isPreflop: false)
    }

    // 计算行动顺序（只计算一次）
    private func calculateActionOrder(isPreflop: Bool) -> [String] {
        let players = positions
        guard players.count > 0 else { return [] }

        // 使用 standardPositions 找到关键位置
        let playersWithPos: [(player: String, seatIndex: Int, stdPos: String)] = players.enumerated().compactMap { index, player in
            guard index < standardPositions.count else { return nil }
            return (player: player, seatIndex: index, stdPos: standardPositions[index])
        }

        // 找到起始位置
        let startPlayer: (player: String, seatIndex: Int, stdPos: String)?

        if players.count == 2 {
            // Heads-up 特殊处理
            if isPreflop {
                // Preflop：从 SB/BTN 开始
                startPlayer = playersWithPos.first { $0.stdPos.contains("SB") }
            } else {
                // Postflop：从 BB 开始
                startPlayer = playersWithPos.first { $0.stdPos == "BB" }
            }
        } else {
            if isPreflop {
                // Preflop：找第一个非盲注位置（BB 左手第一人）
                let nonBlindPlayers = playersWithPos.filter { !$0.stdPos.contains("SB") && $0.stdPos != "BB" }
                // 提前查找 BB 位置，避免在 min(by:) 中重复查找 - 优化从 O(n²) 到 O(n)
                let bbSeat = playersWithPos.first { $0.stdPos == "BB" }?.seatIndex ?? 0
                startPlayer = nonBlindPlayers.min(by: {
                    let dist1 = ($0.seatIndex - bbSeat + players.count) % players.count
                    let dist2 = ($1.seatIndex - bbSeat + players.count) % players.count
                    return dist1 < dist2
                })
            } else {
                // Postflop：从 SB 开始
                startPlayer = playersWithPos.first { $0.stdPos.contains("SB") }
            }
        }

        guard let start = startPlayer else {
            return players
        }

        // 从起始位置开始，按座位号顺时针遍历（环形）
        var result: [String] = []
        let totalSeats = players.count

        for offset in 0..<totalSeats {
            let seatIndex = (start.seatIndex + offset) % totalSeats
            result.append(players[seatIndex])
        }

        return result
    }

    // 自动计算桌面人数：优先使用玩家昵称数量，否则使用默认 9 人
    private var playersCount: Int {
        !namedPlayers.isEmpty ? namedPlayers.count : 9
    }

    // 位置选项：根据庄家位置重新排列玩家（有昵称时返回玩家名），
    // 或使用标准位置名称（无昵称时，按桌面人数推导）
    // 返回的数组顺序：从座位0开始，按座位号顺序排列
    private var positions: [String] {
        if !namedPlayers.isEmpty {
            // 有玩家昵称时，直接返回玩家名列表（按座位号排序）
            return namedPlayers
        } else {
            return Self.defaultPositions(for: playersCount)
        }
    }

    // 获取标准位置列表（用于显示位置信息）
    // 根据庄家位置动态计算每个座位对应的标准位置
    private var standardPositions: [String] {
        let count = !namedPlayers.isEmpty ? namedPlayers.count : playersCount
        return Self.calculateStandardPositions(playerCount: count, buttonPlayerIndex: buttonPlayerIndex)
    }

    // 静态方法：计算标准位置列表（供其他视图复用）
    static func calculateStandardPositions(playerCount: Int, buttonPlayerIndex: Int) -> [String] {
        let basePositions = defaultPositions(for: playerCount)
        let normalizedButtonIndex = ((buttonPlayerIndex % playerCount) + playerCount) % playerCount

        // 计算标准位置中 BTN 的索引
        let canonicalButtonIndex: Int
        if playerCount == 2 {
            canonicalButtonIndex = 0  // HU: 第一个位置是 SB/BTN
        } else if playerCount >= 3 {
            canonicalButtonIndex = max(playerCount - 3, 0)  // 多人桌：BTN 在倒数第三个
        } else {
            canonicalButtonIndex = 0
        }

        // 为每个座位计算对应的标准位置
        return (0..<playerCount).map { seatIndex in
            // 计算该座位相对于庄家的偏移
            let offset = (seatIndex - normalizedButtonIndex + playerCount) % playerCount
            // 计算在标准位置列表中的索引
            let posIndex = (canonicalButtonIndex + offset) % playerCount
            return basePositions[posIndex]
        }
    }

    static func defaultPositions(for playerCount: Int) -> [String] {
        switch playerCount {
        case 9:
            return ["UTG", "UTG+1", "UTG+2", "LJ", "HJ", "CO", "BTN", "SB", "BB"]
        case 8:
            return ["UTG", "UTG+1", "LJ", "HJ", "CO", "BTN", "SB", "BB"]
        case 7:
            return ["UTG", "LJ", "HJ", "CO", "BTN", "SB", "BB"]
        case 6:
            return ["UTG", "HJ", "CO", "BTN", "SB", "BB"]
        case 5:
            return ["HJ", "CO", "BTN", "SB", "BB"]
        case 2:
            // Heads-up：SB/BTN、BB
            return ["SB/BTN", "BB"]
        default:
            return (1...playerCount).map { "玩家\($0)" }
        }
    }

    private static func namedPlayers(from session: Session) -> [String] {
        session.players
            .sorted { $0.seatNumber < $1.seatNumber }
            .map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    init(hand: Hand? = nil, session: Session) {
        self.hand = hand
        self.session = session

        let existingNamedPlayers = Self.namedPlayers(from: session)

        // 确定玩家数量：优先使用玩家昵称数量，否则使用默认 9 人
        let playerCount = !existingNamedPlayers.isEmpty ? existingNamedPlayers.count : 9

        // 确定位置列表（仅用于初始化默认位置）
        let positionsList: [String] = !existingNamedPlayers.isEmpty
            ? existingNamedPlayers
            : HandEditorView.defaultPositions(for: playerCount)

        _position = State(initialValue: hand?.position ?? (positionsList.first ?? "BTN"))
        _holeCards = State(initialValue: hand?.holeCards ?? "")
        _isKeyHand = State(initialValue: hand?.isKeyHand ?? false)
        _handSummary = State(initialValue: hand?.handSummary ?? "")
        _note = State(initialValue: hand?.note ?? "")
        _streets = State(initialValue: hand?.streets ?? [
            Street(name: "Preflop"),
            Street(name: "Flop"),
            Street(name: "Turn"),
            Street(name: "River")
        ])
        _otherPlayers = State(initialValue: hand?.otherPlayers ?? [])
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("手牌信息") {
                    TextField("手牌简介（可选）", text: $handSummary)

                    if !namedPlayers.isEmpty {
                        Picker("庄家位置", selection: $buttonPlayerIndex) {
                            ForEach(0..<namedPlayers.count, id: \.self) { index in
                                Text(namedPlayers[index]).tag(index)
                            }
                        }

                        // 位置对应：每个玩家对应一个座位位置（根据庄家自动计算）
                        VStack(alignment: .leading, spacing: 4) {
                            Text("位置对应")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(0..<positions.count, id: \.self) { index in
                                        VStack(spacing: 4) {
                                            Text(positions[index])
                                                .font(.caption)
                                                .foregroundColor(.primary)
                                            if index < standardPositions.count {
                                                Text(standardPositions[index])
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color.gray.opacity(0.1))
                                        )
                                    }
                                }
                            }
                        }
                    }

                    HStack {
                        Text("我的手牌")
                        Spacer()
                        Button(holeCards.isEmpty ? "选择手牌" : holeCards) {
                            showingCardPicker = true
                        }
                    }

                    // 显示当前桌面人数（只读）
                    if !namedPlayers.isEmpty {
                        HStack {
                            Text("桌面人数")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(playersCount)人")
                                .foregroundColor(.secondary)
                        }
                        .font(.caption)
                    }
                }

                ForEach($streets) { $street in
                    StreetEditorSection(
                        street: $street,
                        positions: positions,
                        standardPositions: standardPositions,
                        session: session,
                        allStreets: streets,
                        onSelectCommunityCards: {
                            activeStreetForCardPicker = IdentifiableUUID(id: street.id)
                        },
                        onAddAction: {
                            activeStreetForActionEditor = IdentifiableUUID(id: street.id)
                        }
                    )
                }

                Section("其他玩家手牌") {
                    if otherPlayers.isEmpty {
                        Text("可在摊牌后记录其他玩家的手牌")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach($otherPlayers) { $info in
                            VStack(alignment: .leading, spacing: 8) {
                                Text("玩家")
                                    .font(.subheadline)

                                // 水平滑动选择玩家（默认使用牌局中的玩家昵称顺序）
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(namedPlayers, id: \.self) { name in
                                            let isSelected = info.owner == name
                                            Button {
                                                info.owner = name
                                            } label: {
                                                Text(name)
                                                    .font(.caption)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 6)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .fill(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                                    )
                                                    .foregroundColor(isSelected ? .blue : .primary)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }

                                HStack {
                                    Text(info.owner.isEmpty ? "未选择玩家" : info.owner)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Button(info.cards.isEmpty ? "选择手牌" : info.cards) {
                                        activeOtherPlayerForCardPicker = IdentifiableUUID(id: info.id)
                                    }
                                    .foregroundColor(.blue)
                                }
                            }
                        }
                    }

                    Button {
                        let newOwner = defaultOtherPlayerOwner()
                        let new = RevealedHand(owner: newOwner, cards: "")
                        otherPlayers.append(new)
                    } label: {
                        Label("添加玩家手牌", systemImage: "plus.circle")
                    }
                }

                Section("其他") {
                    Toggle("标记为关键牌", isOn: $isKeyHand)

                    if !note.isEmpty || hand != nil {
                        TextEditor(text: $note)
                            .frame(minHeight: 60)
                    }
                }
            }
            .navigationTitle(hand == nil ? "新建手牌" : "编辑手牌")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveHand()
                    }
                }
                if hand != nil {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("删除", role: .destructive) {
                            deleteHand()
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCardPicker) {
                CardPickerView(selectedCards: $holeCards, maxCards: 2)
            }
            .sheet(item: $activeStreetForActionEditor) { identifiable in
                if let street = streets.first(where: { $0.id == identifiable.id }) {
                    let currentActions = street.actions
                    let actionOrder = street.name == "Preflop" ? preflopOrder : postflopOrder
                    ActionEditorView(
                        positions: positions,
                        actionOrder: actionOrder,
                        session: session,
                        streetName: street.name,
                        currentActions: currentActions,
                        allStreets: streets
                    ) { actions in
                        if let index = streets.firstIndex(where: { $0.id == identifiable.id }) {
                            streets[index].actions.append(contentsOf: actions)
                        }
                    }
                }
            }
            .sheet(item: $activeStreetForCardPicker) { identifiable in
                let streetName = streets.first(where: { $0.id == identifiable.id })?.name ?? ""
                let maxCards = streetName == "Flop" ? 3 : 1

                let cardsBinding = Binding<String>(
                    get: {
                        streets.first(where: { $0.id == identifiable.id })?.cards ?? ""
                    },
                    set: { newValue in
                        if let index = streets.firstIndex(where: { $0.id == identifiable.id }) {
                            streets[index].cards = newValue
                        }
                    }
                )

                CardPickerView(selectedCards: cardsBinding, maxCards: maxCards)
            }
            .sheet(item: $activeOtherPlayerForCardPicker) { identifiable in
                let cardsBinding = Binding<String>(
                    get: {
                        otherPlayers.first(where: { $0.id == identifiable.id })?.cards ?? ""
                    },
                    set: { newValue in
                        if let index = otherPlayers.firstIndex(where: { $0.id == identifiable.id }) {
                            otherPlayers[index].cards = newValue
                        }
                    }
                )

                CardPickerView(selectedCards: cardsBinding, maxCards: 2)
            }
        }
    }

    /// 计算默认的“其他玩家”拥有者：优先取“我”的下家，否则取第一个玩家的下家。
    private func defaultOtherPlayerOwner() -> String {
        let players = namedPlayers
        guard !players.isEmpty else { return "" }

        let heroIndex = players.firstIndex(of: "我") ?? 0
        let nextIndex = (heroIndex + 1) % players.count
        return players[nextIndex]
    }

    /// 计算当前手牌中“我”的位置名称（例如 BTN、CO、UTG）。
    /// 如果找不到名为“我”的玩家，则使用第一个玩家作为默认。
    private func heroPositionValue() -> String {
        let players = namedPlayers
        guard !players.isEmpty else {
            return position
        }

        let heroIndex = players.firstIndex(of: "我") ?? 0
        // 使用已经根据庄家旋转过的标准位置数组，确保「我」对应的是 BTN/HJ/UTG 等标准坑位
        guard heroIndex < standardPositions.count else {
            return position
        }
        return standardPositions[heroIndex]
    }

    private func saveHand() {
        // 先自动补充盲注，再自动补充 Preflop 未行动玩家的 Fold，
        // 确保底池计算包含大小盲并且所有玩家状态明确。
        autoAddBlinds()
        // 在保存前自动为 Preflop 未行动的玩家补充 Fold 行动
        autoFoldRemainingPreflopPlayers()

        let computedPot = Hand.potSize(for: streets)

        // 自动计算“我的位置”：优先使用名字为“我”的玩家，否则使用第一个玩家
        let heroPosition = heroPositionValue()

        // 保存当前庄家座位索引（仅在有玩家昵称时有意义）
        let buttonIndexToStore: Int?
        if !namedPlayers.isEmpty {
            let count = namedPlayers.count
            buttonIndexToStore = ((buttonPlayerIndex % count) + count) % count
        } else {
            buttonIndexToStore = nil
        }

        // 创建玩家快照：保存当前时刻的玩家信息
        let currentPlayers = session.players.sorted { $0.seatNumber < $1.seatNumber }
        let playersToSnapshot = Array(currentPlayers.prefix(playersCount))
        let snapshot = playersToSnapshot.map { PlayerSnapshot(from: $0) }

        if let hand = hand {
            hand.position = heroPosition
            hand.holeCards = holeCards
            hand.playersCount = playersCount
            hand.potSize = computedPot
            hand.isKeyHand = isKeyHand
            hand.handSummary = handSummary
            hand.note = note
            hand.streets = streets
            hand.buttonSeatIndex = buttonIndexToStore
            hand.playersSnapshot = snapshot
            hand.otherPlayers = otherPlayers
        } else {
            let newHand = Hand(
                position: heroPosition,
                holeCards: holeCards,
                playersCount: playersCount,
                potSize: computedPot,
                isKeyHand: isKeyHand,
                handSummary: handSummary,
                note: note,
                streets: streets,
                buttonSeatIndex: buttonIndexToStore,
                playersSnapshot: snapshot
            )
            newHand.session = session
            modelContext.insert(newHand)
        }
        dismiss()
    }

    private func deleteHand() {
        if let hand = hand {
            modelContext.delete(hand)
            dismiss()
        }
    }

    /// 自动添加小盲和大盲的行动到 Preflop 街道
    private func autoAddBlinds() {
        guard let preflopIndex = streets.firstIndex(where: { $0.name == "Preflop" }) else {
            return
        }

        var preflop = streets[preflopIndex]

        // 检查是否已经有盲注行动
        let hasSmallBlind = preflop.actions.contains { $0.actionType == .smallBlind }
        let hasBigBlind = preflop.actions.contains { $0.actionType == .bigBlind }

        // 如果已经有盲注，不重复添加
        if hasSmallBlind && hasBigBlind {
            return
        }

        // 从 blindLevel 解析小盲和大盲的人民币金额
        let components = session.blindLevel.split(separator: "/")
        guard components.count == 2,
              let smallBlindYuan = Double(components[0].trimmingCharacters(in: .whitespaces)),
              let bigBlindYuan = Double(components[1].trimmingCharacters(in: .whitespaces)),
              bigBlindYuan > 0 else {
            return  // 无法解析盲注级别，不添加盲注
        }

        // 计算小盲的BB数量：小盲金额 / 大盲金额
        // 例如：1/2 -> 1/2 = 0.5 BB
        //      2/5 -> 2/5 = 0.4 BB
        let smallBlindBB = smallBlindYuan / bigBlindYuan

        // 计算盲注金额（积分）
        // 1 BB = pointsPerHundredBB / 100 积分
        let pointsPerBB = session.pointsPerHundredBB / 100.0
        let bigBlindAmount = 1.0 * pointsPerBB  // 1 BB 的积分
        let smallBlindAmount = smallBlindBB * pointsPerBB  // 小盲BB数 × 每BB积分

        // 获取实际的 SB 和 BB 位置（玩家名）
        let actualSBPosition: String
        let actualBBPosition: String

        if !namedPlayers.isEmpty {
            // 有玩家昵称时，根据 standardPositions 找到 SB 和 BB 对应的玩家
            if let sbIndex = standardPositions.firstIndex(where: { $0.contains("SB") }),
               sbIndex < positions.count {
                actualSBPosition = positions[sbIndex]
            } else {
                actualSBPosition = positions.count >= 2 ? positions[positions.count - 2] : (positions.first ?? "SB")
            }

            if let bbIndex = standardPositions.firstIndex(of: "BB"),
               bbIndex < positions.count {
                actualBBPosition = positions[bbIndex]
            } else {
                actualBBPosition = positions.last ?? "BB"
            }
        } else {
            // 无玩家昵称时，使用标准位置名称
            if playersCount == 2 {
                actualSBPosition = "SB/BTN"
                actualBBPosition = "BB"
            } else {
                actualSBPosition = "SB"
                actualBBPosition = "BB"
            }
        }

        // 创建盲注行动数组
        var blindActions: [PlayerAction] = []

        if !hasSmallBlind {
            blindActions.append(PlayerAction(
                position: actualSBPosition,
                actionType: .smallBlind,
                amount: smallBlindAmount
            ))
        }

        if !hasBigBlind {
            blindActions.append(PlayerAction(
                position: actualBBPosition,
                actionType: .bigBlind,
                amount: bigBlindAmount
            ))
        }

        // 将盲注行动插入到 Preflop 行动列表的开头
        preflop.actions.insert(contentsOf: blindActions, at: 0)

        streets[preflopIndex] = preflop
    }

    /// 为 Preflop 未行动的玩家自动补充 Fold 行动，
    /// 以当前手牌的座位顺序和桌面人数为准。
    private func autoFoldRemainingPreflopPlayers() {
        guard let preflopIndex = streets.firstIndex(where: { $0.name == "Preflop" }) else {
            return
        }

        var preflop = streets[preflopIndex]

        // 没有任何行动时，不做自动补全，保留「未记录完整」的可能
        guard !preflop.actions.isEmpty else { return }

        // 只考虑当前桌面人数内的玩家
        let seatCount = max(0, min(playersCount, positions.count))
        guard seatCount > 0 else { return }

        let activeSeats = Array(positions.prefix(seatCount))
        let actedPositions = Set(preflop.actions.map { $0.position })

        // 找出在 Preflop 完全没有行动的玩家
        let positionsToFold = activeSeats.filter { !actedPositions.contains($0) }
        guard !positionsToFold.isEmpty else { return }

        // 按座位顺序追加 Fold 行动
        for pos in positionsToFold {
            preflop.actions.append(
                PlayerAction(position: pos, actionType: .fold, amount: nil)
            )
        }

        streets[preflopIndex] = preflop

        // 清理后续街道中已fold玩家的重复fold行动
        cleanupFoldedPlayersInLaterStreets()
    }

    /// 清理后续街道（Flop/Turn/River）中已fold玩家的重复fold行动
    private func cleanupFoldedPlayersInLaterStreets() {
        var foldedPlayers = Set<String>()

        for (index, street) in streets.enumerated() {
            // 收集当前街道所有fold行动的玩家（包括自动补充和主动选择的）
            for action in street.actions where action.actionType == .fold {
                foldedPlayers.insert(action.position)
            }

            // 清理后续街道中已fold玩家的所有行动
            if index < streets.count - 1 {
                for laterIndex in (index + 1)..<streets.count {
                    streets[laterIndex].actions.removeAll { action in
                        foldedPlayers.contains(action.position)
                    }
                }
            }
        }
    }
}

// 街编辑区域
struct StreetEditorSection: View {
    @Binding var street: Street
    /// 底层用于 ActionEditorView 的位置列表：
    /// - 有昵称时：玩家昵称按座位顺序排列
    /// - 无昵称时：标准位置名称（UTG/HJ/...）
    let positions: [String]
    /// 每个座位对应的标准位置名称（已根据庄家旋转），
    /// 下标与 namedPlayers 在有昵称时一一对应。
    let standardPositions: [String]
    let session: Session
    let allStreets: [Street]  // 所有街道，用于检查已fold玩家
    let onSelectCommunityCards: () -> Void
    let onAddAction: () -> Void

    // 获取玩家昵称列表
    private var namedPlayers: [String] {
        session.players
            .sorted { $0.seatNumber < $1.seatNumber }
            .map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    // 获取之前街道已fold的玩家
    private var foldedPlayers: Set<String> {
        var folded = Set<String>()
        let streetOrder = ["Preflop", "Flop", "Turn", "River"]
        guard let currentIndex = streetOrder.firstIndex(of: street.name) else { return folded }

        // 遍历当前街道之前的所有街道
        for i in 0..<currentIndex {
            let previousStreetName = streetOrder[i]
            if let previousStreet = allStreets.first(where: { $0.name == previousStreetName }) {
                for action in previousStreet.actions where action.actionType == .fold {
                    folded.insert(action.position)
                }
            }
        }
        return folded
    }

    // 过滤后的行动列表：移除之前街道已fold玩家的行动
    private var filteredActions: [PlayerAction] {
        street.actions.filter { !foldedPlayers.contains($0.position) }
    }

    // 生成带位置信息的行动描述
    private func actionDescription(for action: PlayerAction) -> String {
        let owner = action.position

        // 有玩家昵称时，action.position 存的是玩家名；需要映射到标准位置
        if !namedPlayers.isEmpty,
           let seatIndex = namedPlayers.firstIndex(of: owner),
           seatIndex < standardPositions.count {
            let stdPos = standardPositions[seatIndex]
            let positionInfo = "\(owner) (\(stdPos))"

            switch action.actionType {
            case .fold, .check, .call:
                return "\(positionInfo) \(action.actionType.rawValue)"
            case .bet, .raise, .allin, .smallBlind, .bigBlind:
                if let amount = action.amount {
                    return "\(positionInfo) \(action.actionType.rawValue) \(amount)"
                }
                return "\(positionInfo) \(action.actionType.rawValue)"
            }
        }

        // 无昵称模式：action.position 本身就是标准位置名，直接使用原始描述
        return action.description
    }

    var body: some View {
        Section(street.name) {
            // 公共牌输入（Flop/Turn/River）
            if street.name != "Preflop" {
                HStack {
                    Text("公共牌")
                    Spacer()
                    Button(street.cards.isEmpty ? "选择公共牌" : street.displayCards) {
                        onSelectCommunityCards()
                    }
                }
            }

            // 行动列表（过滤掉之前街道已fold的玩家）
            ForEach(filteredActions) { action in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(actionDescription(for: action))

                        // 如果有金额且可以转换为BB，显示BB数量
                        if let amount = action.amount, amount > 0, session.pointsPerHundredBB > 0 {
                            let bb = amount / (session.pointsPerHundredBB / 100.0)
                            Text(String(format: "%.1f BB", bb))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    Button {
                        street.actions.removeAll { $0.id == action.id }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                    }
                }
            }

            // 添加行动按钮
            Button {
                onAddAction()
            } label: {
                Label("添加行动", systemImage: "plus.circle")
            }
        }
    }
}

// 行动编辑器
struct ActionEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let positions: [String]
    let actionOrder: [String]  // 预计算的行动顺序（环形链表）
    let session: Session
    let streetName: String
    let currentActions: [PlayerAction]
    let allStreets: [Street]
    let onSave: ([PlayerAction]) -> Void

    @State private var selectedPosition: String
    @State private var selectedActionType: ActionType = .fold
    @State private var chipAmount: String = ""
    @State private var bbAmount: String = ""

    init(positions: [String], actionOrder: [String], session: Session, streetName: String, currentActions: [PlayerAction], allStreets: [Street], onSave: @escaping ([PlayerAction]) -> Void) {
        self.positions = positions
        self.actionOrder = actionOrder
        self.session = session
        self.streetName = streetName
        self.currentActions = currentActions
        self.allStreets = allStreets
        self.onSave = onSave

        // 计算活跃玩家列表（剔除已fold的玩家）
        let foldedPlayers = Self.getFoldedPlayers(streetName: streetName, allStreets: allStreets)
        let activePlayers = actionOrder.filter { !foldedPlayers.contains($0) }

        _selectedPosition = State(initialValue: activePlayers.first ?? positions.first ?? "BTN")
    }

    // 静态方法：获取已fold的玩家
    private static func getFoldedPlayers(streetName: String, allStreets: [Street]) -> Set<String> {
        var folded = Set<String>()
        let streetOrder = ["Preflop", "Flop", "Turn", "River"]
        guard let currentStreetIndex = streetOrder.firstIndex(of: streetName) else { return folded }

        for i in 0..<currentStreetIndex {
            let previousStreetName = streetOrder[i]
            if let previousStreet = allStreets.first(where: { $0.name == previousStreetName }) {
                for action in previousStreet.actions {
                    if action.actionType == .fold {
                        folded.insert(action.position)
                    }
                }
            }
        }
        return folded
    }

    // 获取活跃玩家列表（剔除已fold的玩家）
    private var activePlayers: [String] {
        // 获取之前街道fold的玩家
        var foldedPlayers = Self.getFoldedPlayers(streetName: streetName, allStreets: allStreets)

        // 也要过滤掉当前街道已经fold的玩家
        for action in currentActions {
            if action.actionType == .fold {
                foldedPlayers.insert(action.position)
            }
        }

        return actionOrder.filter { !foldedPlayers.contains($0) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("位置", selection: $selectedPosition) {
                    ForEach(activePlayers, id: \.self) { pos in
                        Text(pos).tag(pos)
                    }
                }

                Picker("行动", selection: $selectedActionType) {
                    Text("Fold").tag(ActionType.fold)
                    Text("Check").tag(ActionType.check)
                    Text("Call").tag(ActionType.call)
                    Text("Bet").tag(ActionType.bet)
                    Text("Raise").tag(ActionType.raise)
                    Text("Allin").tag(ActionType.allin)
                }

                if needsAmount {
                    Section("金额") {
                        HStack {
                            TextField("积分", text: $chipAmount)
                                .keyboardType(.decimalPad)
                                .onChange(of: chipAmount) { _, newValue in
                                    if !newValue.isEmpty, let points = Double(newValue), session.pointsPerHundredBB > 0 {
                                        // 积分 → BB：积分 / (pointsPerHundredBB / 100)
                                        let bb = points / (session.pointsPerHundredBB / 100.0)
                                        // 如果是整数，不显示小数点；否则显示小数
                                        if bb.truncatingRemainder(dividingBy: 1) == 0 {
                                            bbAmount = String(format: "%.0f", bb)
                                        } else {
                                            bbAmount = String(bb)
                                        }
                                    } else if newValue.isEmpty {
                                        bbAmount = ""
                                    }
                                }
                            Text("分")
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            TextField("大盲(BB)", text: $bbAmount)
                                .keyboardType(.decimalPad)
                                .onChange(of: bbAmount) { _, newValue in
                                    if !newValue.isEmpty, let bb = Double(newValue), session.pointsPerHundredBB > 0 {
                                        // BB → 积分：BB × (pointsPerHundredBB / 100)
                                        let points = bb * (session.pointsPerHundredBB / 100.0)
                                        // 如果是整数，不显示小数点；否则显示小数
                                        if points.truncatingRemainder(dividingBy: 1) == 0 {
                                            chipAmount = String(format: "%.0f", points)
                                        } else {
                                            chipAmount = String(points)
                                        }
                                    } else if newValue.isEmpty {
                                        chipAmount = ""
                                    }
                                }
                            Text("BB")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("添加行动")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        addAction()
                    }
                }
            }
        }
    }

    private var needsAmount: Bool {
        // Bet / Raise / Allin 需要手动输入金额；
        // Call 作为“跟注”，金额由当前街已存在的最高投入自动推导。
        [.bet, .raise, .allin].contains(selectedActionType)
    }

    private func addAction() {
        var actionsToAdd: [PlayerAction] = []

        // 计算被跳过的位置并自动添加fold
        let skippedPositions = getSkippedPositions()
        for position in skippedPositions {
            actionsToAdd.append(PlayerAction(position: position, actionType: .fold, amount: nil))
        }

        // 计算当前行动的金额（积分）
        let amount: Double?
        switch selectedActionType {
        case .call:
            amount = autoCallAmount()
        case .bet, .raise, .allin:
            amount = Double(chipAmount)
        default:
            amount = nil
        }

        // 添加用户选择的行动
        let action = PlayerAction(
            position: selectedPosition,
            actionType: selectedActionType,
            amount: amount
        )
        actionsToAdd.append(action)

        onSave(actionsToAdd)
        dismiss()
    }

    private func getSkippedPositions() -> [String] {
        // 找到最后一个 Bet/Raise/Allin 行动，确定当前轮次的起始位置
        var currentRoundOrder = actionOrder

        // 查找最后一个加注行动
        if let lastRaiseAction = currentActions.last(where: { $0.actionType == .bet || $0.actionType == .raise || $0.actionType == .allin }) {
            // 找到加注者在行动顺序中的位置
            if let raiserIndex = actionOrder.firstIndex(of: lastRaiseAction.position) {
                // 从加注者的下家开始，重新排列行动顺序（环形）
                let totalSeats = actionOrder.count
                currentRoundOrder = (0..<totalSeats).map { offset in
                    actionOrder[(raiserIndex + 1 + offset) % totalSeats]
                }
            }
        }

        // 使用当前轮次的行动顺序
        guard let selectedIndex = currentRoundOrder.firstIndex(of: selectedPosition) else { return [] }
        let positionsBeforeSelected = Array(currentRoundOrder[0..<selectedIndex])

        // 获取当前街道已经有任何行动记录的玩家（包括check、fold等所有行动）
        let actedPlayers = Set(currentActions.map { $0.position })

        // 只有完全没有行动记录的玩家才需要自动fold
        return positionsBeforeSelected.filter { !actedPlayers.contains($0) }
    }

    /// 计算当前街道中每个玩家在本街的累计投入（积分）
    private func currentStreetContributions() -> [String: Double] {
        var contributions: [String: Double] = [:]

        for action in currentActions {
            let player = action.position
            let previous = contributions[player] ?? 0

            switch action.actionType {
            case .smallBlind, .bigBlind, .bet, .raise, .allin, .call:
                guard let amount = action.amount, amount > 0 else { continue }
                let increment = max(amount - previous, 0)
                contributions[player] = previous + increment
            case .check, .fold:
                continue
            }
        }

        return contributions
    }

    /// 自动计算 Call 的总投入金额：跟注到当前街的最高投入
    private func autoCallAmount() -> Double? {
        let contributions = currentStreetContributions()
        let maxContribution = contributions.values.max() ?? 0
        // 如果当前街还没有任何下注，则不需要跟注金额
        guard maxContribution > 0 else { return nil }
        return maxContribution
    }

}
