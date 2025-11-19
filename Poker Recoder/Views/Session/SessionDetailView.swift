import SwiftUI
import SwiftData

struct SessionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let session: Session

    @State private var showingEditor = false
    @State private var showingHandEditor = false
    @State private var showingEndSession = false
    @State private var showingPlayerEditor = false
    @State private var editingPlayer: Player?
    @State private var expandedPlayerID: UUID?

    private var sortedPlayers: [Player] {
        session.players.sorted { $0.seatNumber < $1.seatNumber }
    }

    private var sortedHands: [Hand] {
        session.hands.sorted { $0.startTime < $1.startTime }
    }

    var body: some View {
        List {
            Section("牌局信息") {
                HStack {
                    Text("状态")
                        .foregroundColor(.primary)
                    Spacer()
                    Text(session.isActive ? "进行中" : "已结束")
                        .foregroundColor(session.isActive ? .blue : .secondary)
                }

                LabeledContent("开始时间", value: session.startTime, format: .dateTime)

                if !session.isActive {
                    LabeledContent("游戏时长", value: session.formattedDuration)
                }

                if !session.location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    LabeledContent("场地", value: session.location)
                }
                LabeledContent("盲注", value: session.blindLevel)

                HStack {
                    Text("玩家人数")
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(sortedPlayers.count) 人")
                        .foregroundColor(.secondary)
                }

                if !session.isActive {
                    HStack {
                        Text("盈亏")
                            .foregroundColor(.primary)
                        Spacer()
                        HStack(spacing: 4) {
                            Text(session.profit >= 0 ? "+\(session.profit, specifier: "%.0f")" : "\(session.profit, specifier: "%.0f")")
                                .foregroundColor(session.profit >= 0 ? .green : .red)

                            if session.pointsPerHundredBB > 0 {
                                let profitBB = session.profitInBB
                                Text(profitBB >= 0 ? "(+\(profitBB, specifier: "%.1f") BB)" : "(\(profitBB, specifier: "%.1f") BB)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                if !session.note.isEmpty {
                    LabeledContent("备注", value: session.note)
                }
            }

            Section("玩家") {
                if sortedPlayers.isEmpty {
                    Text("暂未添加玩家")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(sortedPlayers) { player in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("玩家 \(player.seatNumber + 1)")
                                    .foregroundColor(.secondary)
                                Text(player.name.isEmpty ? "未命名玩家" : player.name)
                                    .fontWeight(.medium)
                                Spacer()

                                HStack(spacing: 4) {
                                    Text(player.style)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    Text("·")
                                        .foregroundColor(.secondary)
                                    Text(player.level)
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            }

                            HStack(spacing: 12) {
                                Button {
                                    editingPlayer = player
                                    showingPlayerEditor = true
                                } label: {
                                    HStack {
                                        Image(systemName: "pencil")
                                            .font(.caption)
                                        Text("编辑")
                                            .font(.caption)
                                    }
                                }
                                .buttonStyle(.borderless)

                                Button(role: .destructive) {
                                    deletePlayer(player)
                                } label: {
                                    HStack {
                                        Image(systemName: "trash")
                                            .font(.caption)
                                        Text("删除")
                                            .font(.caption)
                                    }
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Button {
                    editingPlayer = nil
                    showingPlayerEditor = true
                } label: {
                    Label("添加玩家", systemImage: "person.badge.plus")
                }
            }

            Section {
                ForEach(sortedHands) { hand in
                    NavigationLink(destination: HandDetailView(hand: hand, session: session)) {
                        HandRowView(hand: hand)
                    }
                }
                .onDelete(perform: deleteHands)

                Button {
                    showingHandEditor = true
                } label: {
                    Label("添加手牌", systemImage: "plus.circle.fill")
                }
            } header: {
                HStack {
                    Text("手牌记录")
                    Spacer()
                    Text("共 \(sortedHands.count) 手")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if session.isActive {
                Section {
                    Button {
                        showingEndSession = true
                    } label: {
                        Label("结束牌局", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .navigationTitle("牌局详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingEditor = true
                } label: {
                    Text("编辑")
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            SessionEditorView(session: session)
        }
        .sheet(isPresented: $showingHandEditor) {
            HandEditorView(session: session)
        }
        .sheet(isPresented: $showingEndSession) {
            EndSessionView(session: session)
        }
        .sheet(isPresented: $showingPlayerEditor) {
            PlayerEditorView(session: session, player: editingPlayer)
        }
    }

    private func deleteHands(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sortedHands[index])
        }
    }

    private func deletePlayer(_ player: Player) {
        let deletedSeat = player.seatNumber
        modelContext.delete(player)

        // 优化：直接更新后续玩家的座位号，避免不必要的排序 - 从 O(n log n) 优化到 O(n)
        for p in session.players where p.seatNumber > deletedSeat {
            p.seatNumber -= 1
        }
    }
}

struct HandRowView: View {
    let hand: Hand

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                // 显示手牌简介或默认编号
                if !hand.handSummary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(hand.handSummary)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                } else {
                    // 显示默认编号
                    if let session = hand.session,
                       let index = session.hands.firstIndex(where: { $0.id == hand.id }) {
                        Text("手牌\(index + 1)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("手牌")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Text(emojiString(for: hand.holeCards))
                    .font(.headline)
                    .fontWeight(.semibold)

                if hand.isKeyHand {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
            }

            // 显示街信息摘要（只显示公共牌）
            if !hand.streets.isEmpty {
                let summary = hand.streets
                    .filter { !$0.cards.isEmpty }
                    .map { street -> String in
                        let cardsEmoji = emojiString(for: street.cards)
                        return "\(street.name): \(cardsEmoji)"
                    }
                    .joined(separator: " • ")

                if !summary.isEmpty {
                    Text(summary)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            // 显示总底池大小
            if let session = hand.session, session.pointsPerHundredBB > 0 {
                let potBB = hand.computedPotSize / (session.pointsPerHundredBB / 100.0)
                HStack {
                    Text("底池: \(potBB, specifier: "%.1f") BB")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func emojiString(for raw: String) -> String {
        let chars = Array(raw)
        guard !chars.isEmpty else { return raw }

        var components: [String] = []
        var i = 0

        while i + 1 < chars.count {
            let rank = String(chars[i])
            let suit = chars[i + 1]

            let symbol: String
            switch suit {
            case "s": symbol = "♠️"
            case "h": symbol = "♥️"
            case "d": symbol = "♦️"
            case "c": symbol = "♣️"
            default:  symbol = "?"
            }

            components.append(rank + symbol)
            i += 2
        }

        return components.joined(separator: " ")
    }
}

struct PlayerEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let session: Session
    let player: Player?

    @State private var name: String
    @State private var selectedStyle: String
    @State private var selectedLevel: String

    // 相对位置选择
    @State private var referencePlayerIndex: Int
    @State private var relativePosition: RelativePosition

    enum RelativePosition: String, CaseIterable {
        case before = "上家"  // 参考玩家的左边（逆时针）
        case nextTo = "下家"  // 参考玩家的右边（顺时针）
    }

    init(session: Session, player: Player?) {
        self.session = session
        self.player = player
        _name = State(initialValue: player?.name ?? "")

        let defaultStyle = player?.style ?? "TAG"
        let defaultLevel = player?.level ?? "Reg"
        _selectedStyle = State(initialValue: defaultStyle)
        _selectedLevel = State(initialValue: defaultLevel)

        // 按座位号排序，seatNumber 保证 0...N-1 连续，
        // 且「0 是 1 的上家，以此类推」。
        let sorted = session.players.sorted { $0.seatNumber < $1.seatNumber }

        if let player = player {
            // 编辑现有玩家：默认参考玩家为当前玩家的下家，相对位置为"上家"
            // 这样可以保持当前玩家的位置不变
            if let currentIndex = sorted.firstIndex(where: { $0.id == player.id }) {
                let nextIndex = (currentIndex + 1) % max(sorted.count, 1)
                let others = sorted.filter { $0.id != player.id }
                if let refPlayerIndex = others.firstIndex(where: { $0.id == sorted[nextIndex].id }) {
                    _referencePlayerIndex = State(initialValue: refPlayerIndex)
                    _relativePosition = State(initialValue: .before)  // 默认为"上家"
                } else {
                    _referencePlayerIndex = State(initialValue: 0)
                    _relativePosition = State(initialValue: .nextTo)
                }
            } else {
                _referencePlayerIndex = State(initialValue: 0)
                _relativePosition = State(initialValue: .nextTo)
            }
        } else {
            // 新增玩家：默认参考最后一个玩家，作为其下家
            let defaultRef = sorted.isEmpty ? 0 : sorted.count - 1
            _referencePlayerIndex = State(initialValue: defaultRef)
            _relativePosition = State(initialValue: .nextTo)
        }
    }

    private var sortedPlayers: [Player] {
        session.players.sorted { $0.seatNumber < $1.seatNumber }
    }

    private var otherPlayers: [Player] {
        if let player = player {
            return sortedPlayers.filter { $0.id != player.id }
        }
        return sortedPlayers
    }

    private func displayName(for player: Player) -> String {
        player.name.isEmpty ? "玩家 \(player.seatNumber + 1)" : player.name
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("玩家信息") {
                    TextField("玩家昵称", text: $name)
                        .textInputAutocapitalization(.words)

                    // 风格
                    VStack(alignment: .leading, spacing: 8) {
                        Text("风格")
                            .font(.subheadline)
                        Picker("风格", selection: $selectedStyle) {
                            Text("TAG 紧凶").tag("TAG")
                            Text("LAG 松凶").tag("LAG")
                            Text("TP 紧弱").tag("TP")
                            Text("LP 松弱").tag("LP")
                        }
                        .pickerStyle(.segmented)
                    }

                    // 水平
                    VStack(alignment: .leading, spacing: 8) {
                        Text("水平")
                            .font(.subheadline)
                        Picker("水平", selection: $selectedLevel) {
                            Text("鱼 Fish").tag("Fish")
                            Text("鲸 Whale").tag("Whale")
                            Text("Reg 常客").tag("Reg")
                            Text("Pro 职业").tag("Pro")
                        }
                        .pickerStyle(.segmented)
                    }
                }

                // 座位位置选择
                if otherPlayers.isEmpty {
                    Section("座位位置") {
                        Text("将作为第一个玩家")
                            .foregroundColor(.secondary)
                    }
                } else {
                    Section("座位位置") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("选择参考玩家")
                                .font(.subheadline)

                            Picker("参考玩家", selection: $referencePlayerIndex) {
                                ForEach(0..<otherPlayers.count, id: \.self) { index in
                                    Text(displayName(for: otherPlayers[index])).tag(index)
                                }
                            }
                            .pickerStyle(.menu)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("相对位置")
                                .font(.subheadline)

                            Picker("相对位置", selection: $relativePosition) {
                                ForEach(RelativePosition.allCases, id: \.self) { position in
                                    Text(position.rawValue).tag(position)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        // 显示位置预览
                        HStack {
                            Text("位置预览")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(positionPreview)
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle(player == nil ? "添加玩家" : "编辑玩家")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(player == nil ? "添加" : "保存") {
                        save()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private var positionPreview: String {
        guard !otherPlayers.isEmpty, referencePlayerIndex < otherPlayers.count else {
            return ""
        }

        let refPlayer = otherPlayers[referencePlayerIndex]
        let refName = displayName(for: refPlayer)

        switch relativePosition {
        case .before:
            return "在 \(refName) 的上家"
        case .nextTo:
            return "在 \(refName) 的下家"
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        if let player = player {
            // 编辑现有玩家
            player.name = trimmedName
            player.style = selectedStyle
            player.level = selectedLevel

            // 如果有其他玩家，根据相对位置调整座位
            if !otherPlayers.isEmpty && referencePlayerIndex < otherPlayers.count {
                let refPlayer = otherPlayers[referencePlayerIndex]
                var players = sortedPlayers

                // 移除当前玩家
                guard let currentIndex = players.firstIndex(where: { $0.id == player.id }) else {
                    dismiss()
                    return
                }
                players.remove(at: currentIndex)

                // 找到参考玩家在新数组中的位置
                guard let refIndex = players.firstIndex(where: { $0.id == refPlayer.id }) else {
                    dismiss()
                    return
                }

                // 根据相对位置计算插入位置
                let insertIndex: Int
                switch relativePosition {
                case .before:
                    // 上家：插入到参考玩家之前
                    insertIndex = refIndex
                case .nextTo:
                    // 下家：插入到参考玩家之后
                    insertIndex = refIndex + 1
                }

                players.insert(player, at: insertIndex)

                // 重新分配座位号
                for (index, p) in players.enumerated() {
                    p.seatNumber = index
                }

                session.players = players
            }
        } else {
            // 添加新玩家
            let newPlayer = Player(
                name: trimmedName,
                seatNumber: 0,
                style: selectedStyle,
                level: selectedLevel
            )

            // 重要：在设置关系之前先获取当前玩家列表，避免 SwiftData 自动添加导致的问题
            var players = sortedPlayers

            if players.isEmpty {
                // 第一个玩家，直接添加
                players.append(newPlayer)
            } else if referencePlayerIndex < players.count {
                // 根据相对位置插入
                let refPlayer = players[referencePlayerIndex]

                guard let refIndex = players.firstIndex(where: { $0.id == refPlayer.id }) else {
                    dismiss()
                    return
                }

                let insertIndex: Int
                switch relativePosition {
                case .before:
                    // 上家：插入到参考玩家之前
                    insertIndex = refIndex
                case .nextTo:
                    // 下家：插入到参考玩家之后
                    insertIndex = refIndex + 1
                }

                players.insert(newPlayer, at: insertIndex)
            } else {
                // 默认添加到最后
                players.append(newPlayer)
            }

            // 重新分配座位号
            for (index, p) in players.enumerated() {
                p.seatNumber = index
            }

            // 最后再设置关系和插入到 context
            session.players = players
            newPlayer.session = session
            modelContext.insert(newPlayer)
        }

        dismiss()
    }
}
