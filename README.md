# SomehowGrown — SwiftUI版

友人の子供の学年・年齢を記憶し、主要な学校イベントをリマインドするiOSアプリ。

## Xcodeプロジェクトのセットアップ手順

このリポジトリにはSwiftソースのみが含まれます。
Xcodeで初回プロジェクトを作成し、ソースを追加してください。

### 1. Xcodeで新規プロジェクトを作成

```
File > New > Project
  Platform : iOS
  Template  : App
  Product Name : SomehowGrown
  Interface    : SwiftUI
  Language     : Swift
  Bundle ID    : （任意: com.yourname.somehoWgrown）
```

### 2. ソースファイルを追加

Xcodeプロジェクト内のデフォルト `ContentView.swift` を削除し、
このリポジトリの `SomehowGrown/` 以下のファイルをすべてドラッグ＆ドロップ。
「Copy items if needed」にチェックを入れる。

```
SomehowGrown/
├── SomehowGrownApp.swift
├── Models/
│   ├── Models.swift
│   └── FriendStore.swift
├── Views/
│   ├── ContentView.swift
│   ├── FriendRowView.swift
│   ├── AddFriendSheet.swift
│   └── KidFormSection.swift
└── Utilities/
    ├── GradeSystem.swift
    ├── EventsEngine.swift
    ├── NotificationManager.swift
    └── ContactPicker.swift
```

### 3. Info.plist に権限を追加

| Key | Value |
|-----|-------|
| `NSContactsUsageDescription` | 友人の名前を電話帳から選択するために使用します |

### 4. Signing & Capabilities

- Signing: 自身のApple IDでサインイン
- Capabilities: 追加不要（通知・連絡先はコードで権限リクエスト済み）

---

## アーキテクチャ

```
Models/
  Models.swift        — Friend, Kid, Gender, CutoffType (Codable)
  FriendStore.swift   — ObservableObject, JSON永続化 (Documents/friends_v1.json)

Utilities/
  GradeSystem.swift       — 学年ラベル / 学年↔年齢変換 / 現在学年の自動計算
  EventsEngine.swift      — 入学・卒業・誕生日イベント生成
  NotificationManager.swift — UNUserNotificationCenter ラッパー
  ContactPicker.swift     — CNContactPickerViewController ラッパー

Views/
  ContentView.swift    — メインリスト + 近日イベントセクション
  FriendRowView.swift  — 友人1件の表示 (子供チップ付き)
  AddFriendSheet.swift — 友人追加/編集シート
  KidFormSection.swift — 子供入力フォーム (KidDraft)
```

## データプライバシー (ver2 広告対応の準備)

- **`Friend.contactIdentifier`** には `CNContact.identifier`（不透明ID）のみ保存。氏名・電話番号はアプリ内に記録しない。
- データはデバイスローカル（`Documents/friends_v1.json`）にのみ保存。iCloudSync・外部APIへの送信なし。
- ver2で広告を導入する際は、`contactIdentifier` を送信しないよう注意。

## 動作要件

- iOS 17+
- Xcode 15+
