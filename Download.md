# Poker Recoder - 免费分发与安装指南 (AltStore 方案)

本项目采用 **AltStore 旁加载 (Sideloading)** 方式进行分发。无需越狱，无需 App Store 审核，完全免费。

---

## 🛠 开发者篇：如何从 Xcode 提取 .ipa

由于没有付费开发者账号，无法使用 Xcode 的 Archive -> Distribute 功能。我们需要使用构建缓存提取法。

### 1. 准备签名 (Signing)
1.  在 Xcode 中打开项目。
2.  点击左侧项目根目录 -> **Targets** -> **Poker Recoder** -> **Signing & Capabilities**。
3.  **Team**: 选择你的个人 Apple ID (显示为 `你的名字 (Personal Team)` )。
4.  **Bundle Identifier**: 如果报错，尝试修改 ID (例如在末尾加数字) 直到报错消失。

### 2. 编译 (Build)
1.  **设备选择**: 顶部工具栏必须选择 **"Any iOS Device (arm64)"** 或你连接的 **真机**。
    * 🚫 **禁止选择**: iPhone Simulator (模拟器)。
2.  **执行编译**: 点击菜单栏 `Product` -> `Build` (或 `Cmd + B`)。
3.  等待提示 **Build Succeeded**。

### 3. 提取与打包 ("偷梁换柱"法)
1.  **定位文件**:
    * 在 Xcode 左侧导航栏找到 `Products` 文件夹。
    * 右键点击 `Poker Recoder.app` -> **Show in Finder**。
    * *注：如果图标显示为“禁止符号”是正常的，因为 iOS 应用无法在 Mac 上直接运行。*
2.  **制作 IPA**:
    * 在桌面新建一个文件夹，严格命名为：`Payload` (首字母大写)。
    * 将刚才找到的 `Poker Recoder.app` 复制到 `Payload` 文件夹中。
    * 右键压缩 `Payload` 文件夹，生成 `Payload.zip`。
    * 将 `Payload.zip` 重命名为 **`Poker Recoder.ipa`** (确认修改后缀)。

✅ **现在，你可以将这个 .ipa 文件发送给朋友了。**

---

## 📱 用户篇：如何安装与续期

### 第一阶段：环境准备 (只需做一次)

你需要一台电脑 (Win/Mac) 将 AltStore (安装器) 装入手机。

#### Windows 用户：
1.  **下载 iTunes & iCloud (非商店版)**:
    * 请务必去 Apple 官网下载安装包，**不要**使用 Microsoft Store 版本。
2.  **下载 AltServer**: 访问 [altstore.io](https://altstore.io) 下载并安装。
3.  **连接**: 运行 AltServer (右下角任务栏出现图标)，手机插线连接电脑。
4.  **关键设置**: 打开 iTunes -> 手机摘要页 -> 勾选 **"通过 Wi-Fi 与此 iPhone 同步"** -> 应用。

#### Mac 用户：
1.  下载 Mac 版 AltServer 并运行。
2.  点击菜单栏 AltServer 图标 -> **Install Mail Plug-in**。
3.  打开“邮件”App -> 设置 -> 管理插件 -> 勾选 `AltPlugin` -> 重启邮件 App。

#### 安装 AltStore 到手机：
1.  点击电脑端 AltServer 图标 -> **Install AltStore** -> 选择你的手机。
2.  输入 Apple ID 和密码 (用于申请免费证书)。
3.  安装完成后，手机设置 -> 通用 -> VPN与设备管理 -> **信任** 你的证书。
4.  (iOS 16+) 手机设置 -> 隐私与安全性 -> 开启 **开发者模式**。

---

### 第二阶段：安装 Poker Recoder

1.  将朋友发来的 `Poker Recoder.ipa` 保存到手机的“文件”App 中。
2.  打开手机上的 **AltStore**。
3.  点击底部 **My Apps** -> 左上角 **+** 号。
4.  选择 `.ipa` 文件，等待进度条完成。
5.  安装成功！App 现在可以正常打开使用。

---

### 第三阶段：关于“7天续期” (重要!)

由于苹果免费证书的限制，App **有效期只有 7 天**。

#### 如何续命 (推荐)：
* **条件**: 电脑开着 AltServer，手机和电脑连着同一个 WiFi。
* **操作**: 打开手机 AltStore -> My Apps -> 点击 **"Refresh All"**。
* **结果**: 有效期会重置回 7 天。建议每隔几天点一下。

#### 如果不小心过期了 (打不开 App)：
* **不要删除 App！** 删除会导致数据丢失。
* **解决方法**: 把手机插上电脑，重新运行电脑端的 "Install AltStore"。
* 重新安装后，App 会恢复正常，**所有数据（记录）依然都在**。