# Poker Recoder

一个用于记录线下德州扑克牌局、手牌和盈亏情况的 SwiftUI 应用，支持按积分制记账并自动换算为 BB 和人民币，适合家庭局 / 朋友局做简单牌谱与数据统计。

## 功能概览

- 牌局管理：创建、编辑、结束牌局，记录时间、盲注级别、备注等信息。
- 玩家管理：维护一桌玩家名单、座位顺序，标记玩家风格（TAG/LAG/TP/LP）和水平（Fish/Whale/Reg/Pro）。
- 手牌记录：按 Preflop/Flop/Turn/River 分街记录公共牌与每个位置的行动轨迹。
- 底池与换算：根据行动自动累计底池积分，按牌局配置换算为 BB 和人民币金额。
- 关键牌标记：对重要手牌加星标，便于后续复盘查看。
- 摊牌信息：记录其他玩家在摊牌时的真实手牌，辅助复盘思考。
- 统计视图：汇总多场牌局的总买入、总退筹、整体盈利和胜率，并列出最近记录。

## 技术栈与运行环境

- 语言与框架：Swift 5、SwiftUI、SwiftData。
- 平台支持：iOS / iPadOS / macOS / visionOS（由 Xcode 工程配置的 `SUPPORTED_PLATFORMS` 决定）。
- 工具链：Xcode 16.x（工程 `LastUpgradeCheck = 2610`，SwiftData 需要较新 Xcode）。
- 最低系统：工程当前设置 `IPHONEOS_DEPLOYMENT_TARGET = 26.1`、`MACOSX_DEPLOYMENT_TARGET = 26.1`，可在 Xcode 中自行调低以适配实际设备。

## 项目结构

- `Poker Recoder/`
  - `Poker_RecoderApp.swift`：应用入口，配置 SwiftData `ModelContainer`，注册 `Session`、`Hand`、`Player` 模型。
  - `ContentView.swift`、`Item.swift`：Xcode 模板示例代码，目前业务中基本未使用。
  - `Models/`
    - `Session.swift`：牌局模型，包含盲注信息、积分换算参数、买入/退筹、是否进行中、关联的手牌和玩家。
    - `Hand.swift`：单手牌模型，记录英雄位置、手牌、参与人数、街道数据、底池积分、关键牌标记、玩家快照与其他玩家摊牌。
    - `Player.swift`：玩家模型，包含昵称、座位号、风格和水平，并与所属牌局关联。
    - `ActionModels.swift`：行动相关结构体与枚举，包括 `ActionType`、`PlayerAction`、`Street` 等，并提供街道牌面显示和底池计算辅助。
  - `Views/`
    - `MainTabView.swift`：主界面 Tab，分为“牌局”和“统计”两个入口。
    - `Color+Theme.swift`：应用统一配色与毛玻璃卡片风格。
    - `Session/`
      - `SessionListView.swift`：牌局列表，展示进行中/已结束状态、盲注级别和盈亏摘要。
      - `SessionEditorView.swift`：新建/编辑牌局，配置日期、盲注、积分换算比例、人数等。
      - `SessionDetailView.swift`：牌局详情，展示玩家列表、手牌列表，可编辑玩家、添加手牌、结束牌局。
      - `EndSessionView.swift`：结束牌局时录入买入和退筹，支持以积分或 BB 为单位输入并互相换算。
    - `Hand/`
      - `HandEditorView.swift`：手牌编辑器，选择庄位、玩家位置、公共牌和行动，并可自动补盲注与补全未行动玩家的 Fold。
      - `HandDetailView.swift`：手牌详情，按街展示公共牌和每一步行动，并显示底池变化和换算后的 BB。
      - `CardPickerView.swift`：扑克牌选择器，支持选择手牌和公共牌，内部使用 `AhKd` / `Th7s5c` 等字符串编码。
    - `Stats/`
      - `StatsView.swift`：总体统计页面，计算所有牌局的总买入/退筹/盈利（人民币）和胜率，并列出最近几场牌局。
  - `Assets.xcassets/`：应用图标与主题颜色资源。
  - `Poker Recoder.xcodeproj/`：Xcode 工程文件与 SwiftPM 配置。
  - `LICENSE`：Apache 2.0 协议文本。

## 核心数据模型与换算约定

- `Session`
  - 表示一整场牌局（Session），包含：
    - 基本信息：`sessionName`、`location`、`blindLevel`（如 `"1/2"`）、备注 `note`。
    - 时间信息：`playedAt`、`startTime`、`endTime`，以及计算得到的 `formattedDuration`。
    - 记账字段：`buyIn`、`cashOut`、`profit`（统一视为“积分”单位）。
    - 换算参数：
      - `bigBlind`：大盲金额（人民币）。
      - `pointsPerHundredBB`：每 100BB 对应多少积分（例如盲注 1/2，100BB = 200 元 = 1000 积分，则填入 `1000`）。
    - 关联关系：一对多 `hands: [Hand]`、`players: [Player]`（级联删除）。
  - 提供 `profitInBB` 等辅助属性，用于把积分制盈亏换算为 BB。

- `Player`
  - 表示单个玩家：
    - `name`：昵称，首次建局时会默认生成“我”与“玩家 N”。
    - `seatNumber`：座位号（从 0 开始连号），用于确定行动顺序和庄家位置。
    - `style` / `level`：玩家风格与水平，使用字符串存储。
  - 在界面中通过 `PlayerEditorView` 实现：
    - 选择参考玩家并指定“上家/下家”，自动插入到正确的座位位置。
    - 删除玩家时自动重新编号后续座位，保持座位号连续。

- `Hand`
  - 表示单手牌：
    - 基本字段：`position`（英雄位置）、`holeCards`（如 `"AhKd"`）、`playersCount`、`isKeyHand`、`handSummary`、`note`。
    - 时间字段：`startTime`、`endTime`。
    - 结构化数据：
      - `streets: [Street]`：四条街的公共牌与行动列表，以 JSON 编/解码后存储在 `streetsData`。
      - `playersSnapshot: [PlayerSnapshot]`：记录创建手牌时的玩家昵称、座位、风格、水平，用于后续展示时保持当时的桌面状态。
      - `otherPlayers: [RevealedHand]`：摊牌时其他玩家的真实手牌。
    - 底池计算：
      - `Hand.potIncrement(for:)`：根据每条街的行动计算该街对底池的增量。
      - `Hand.potSize(for:)` 与 `computedPotSize`：累积所有街道的底池积分。
      - `potSizeInBB`：结合 Session 的 `pointsPerHundredBB`，把积分换算为 BB。

- 行动与街道
  - `ActionType`：`fold/check/call/bet/raise/allin/smallBlind/bigBlind`。
  - `PlayerAction`：记录单次行动的玩家位置、行动类型和金额（积分）。
  - `Street`：
    - `name`：`"Preflop" / "Flop" / "Turn" / "River"`。
    - `cards`：公共牌字符串，例如 `"Th7s5c"`。
    - `actions: [PlayerAction]`：本街所有行动。
    - `displayCards`：以 `"Th 7s 5c"` 形式格式化显示。

- 位置与行动顺序
  - `HandEditorView` 中根据庄家位置与玩家人数计算标准位置队列（UTG, HJ, CO, BTN, SB, BB 等）。
  - 支持 Heads-up 特殊规则（Button 同时是 SB/BTN）。
  - 自动推导 Preflop 行动顺序以及翻牌后行动顺序，保证记录与实际顺序一致。

## 使用说明

### 1. 打开工程并运行

- 使用 Xcode 打开根目录下的 `Poker Recoder.xcodeproj`。
- 选择目标平台（iOS 模拟器或真机、macOS、visionOS Simulator 等）。
- 首次运行时（尤其是 SwiftData 数据模型调整后）应用会在本地创建或重建数据容器。

### 2. 新建牌局

- 在“牌局” Tab 点击右上角 `+` 打开 `SessionEditorView`。
- 填写：
  - 牌局名称与日期。
  - 人数（滑块 2–10 人），可选择是否有 Straddle（目前主要用于记录，不参与自动换算）。
  - 盲注级别，例如 `1/2`、`2/5`。
  - “每 100BB 对应积分”：根据你的积分制度填写数值（积分/100BB）。
  - 备注（可选）。
- 保存后会自动：
  - 创建一个进行中的 Session。
  - 按人数初始化玩家列表，Seat 0 命名为“我”，其余为“玩家 N”。

### 3. 管理玩家与座位

- 在牌局详情页的“玩家”区：
  - 可编辑任意玩家的昵称、风格和水平。
  - 通过选择“参考玩家 + 上家/下家”调整座位顺序，系统会自动更新所有玩家的 `seatNumber`。
  - 删除玩家时，其后所有座位号会顺延，保持 0…N-1 连续。

### 4. 记录单手牌

- 在牌局详情页的“手牌记录”区点击“添加手牌”进入 `HandEditorView`。
- 建议步骤：
  1. 确认庄家位置：根据本手牌真实庄位选择 Button 对应玩家。
  2. 选择“我的位置”和手牌：
     - 通过卡牌选择器选择两张手牌，内部以 `"AhKd"` 形式存储。
  3. 为每条街（Preflop/Flop/Turn/River）录入：
     - 公共牌：使用 `CardPickerView` 选择 3/1/1 张牌，存为 `"Th7s5c"` 等字符串。
     - 玩家行动：按顺序添加玩家行动（call/raise/allin 等），金额单位为 **积分**。
  4. 利用自动化功能：
     - “自动添加盲注”：根据牌局 `blindLevel` 和 `pointsPerHundredBB` 自动计算 SB/BB 的积分并插入行动。
     - “自动补全 Fold”：为 Preflop 未行动的玩家自动补上 Fold，并清理后续街中已 Fold 玩家多余的行动。
  5. 如有需要：
     - 勾选“标记为关键牌”以方便在列表中突出显示。
     - 在“其他玩家手牌”区记录摊牌玩家及其手牌，支持从当前玩家昵称中选择持牌者。
     - 添加备注，记录思路或读牌。

### 5. 查看手牌详情与底池

- 在“手牌记录”区点击某手牌进入 `HandDetailView`。
- 页面将展示：
  - 开始时间、我的位置、玩家人数。
  - 玩家昵称与标准位置对应关系（基于当时的玩家快照）。
  - 每条街的公共牌与所有行动，并在可换算时显示行动对应的 BB。
  - 每条街开始前和结束后的底池大小，以及最终总底池（积分与 BB）。
  - 其他玩家在摊牌时的真实手牌。
  - 本手牌备注内容。

### 6. 结束牌局并记录盈亏

- 在牌局详情页底部点击“结束牌局”，进入 `EndSessionView`。
- 选择输入单位：
  - “使用大盲(BB)为输入单位”：
    - 直接以 BB 填写买入和退筹，系统根据 `pointsPerHundredBB` 换算为积分并存储。
  - 关闭开关：
    - 以积分填入买入与退筹，系统可反算出对应 BB。
- 页面会同时展示：
  - 本场盈亏（人民币）：按照 big blind 金额换算。
  - 对应的积分差值及盈亏 BB 数。
- 点击“完成”后，该牌局被标记为已结束，并记录结束时间。

### 7. 查看总体统计

- 切换到“统计” Tab：
  - 查看累计总场次、总买入、总退筹和总盈利（人民币）。
  - 查看整体胜率：盈利场次占总场次的百分比。
  - 在“最近记录”区快速浏览最近几场牌局的时间、地点、名称与单场盈亏。

## 卡牌与字符串格式约定

- 手牌字符串：
  - 每张牌由“点数 + 花色”两字符组成，例如：
    - A 黑桃：`"As"`，K 红桃：`"Kh"`，T 方块：`"Td"`，7 梅花：`"7c"`。
  - 手牌示例：`"AhKd"` 表示 Ah + Kd。
- 公共牌字符串：
  - 多张牌按顺序拼接，例如 Flop `"Th7s5c"`，Turn 后变为 `"Th7s5c2d"`。
- 点数字符集：`A K Q J T 9 8 7 6 5 4 3 2`。
- 花色字符集：`s`（黑桃）、`h`（红桃）、`d`（方块）、`c`（梅花）。

## 开发与扩展建议

- 持久化
  - 当前使用 SwiftData 本地存储，`ModelContainer` 初始化失败时会尝试删除旧数据库并重新创建，以保证在模型变更后仍可正常运行。
- 多平台
  - 工程已启用多平台编译目标，如需只支持 iOS 或 macOS，可在 Xcode 的 Target 设置中简化平台配置。
- 潜在扩展方向（仅示例）：
  - 导出牌谱为文本 / Markdown / 图片。
  - iCloud/CloudKit 同步多设备数据。
  - 更丰富的统计维度（按 Blind、按地点、按玩家等）。
  - 自定义牌桌视图与更直观的行动时间线。

## 许可证

本项目使用 Apache License 2.0 授权，详情见根目录下的 `LICENSE` 文件。

