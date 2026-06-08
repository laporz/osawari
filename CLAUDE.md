# **美少女お触りシミュレーションゲーム（仮）開発ガイド**

## **📌 プロジェクト概要**

女の子の立ち絵（または2D/3Dモデル）の特定の部位（コライダー）をタップ/クリックすることで、部位ごとのリアクション、好感度、および特定のステータス（興奮度、羞恥度など）が変化する2Dシミュレーションゲーム。

* **開発環境:** Godot Engine 4.x (GDExtension非使用、純粋なGDScript)
* **画面構成:** 基本は 1280x720 (16:9) ※ターゲットに合わせて調整

## **🛠 共通コマンド**

AIアシスタントは、コード生成やリファクタリングの際に以下のGodot 4の規約とプロジェクト構造を遵守すること。

* **静的型付け:** GDScriptでは可能な限り静的型付け（var hp: int = 100 や func _ready() -> void）を徹底すること。

## **📂 ディレクトリ構造 (Project Structure)**

プロジェクトは以下のクリーンな構造を維持すること。

```
res://
├── assets/                  # 素材ファイル
│   ├── images/              # 立ち絵、部位ごとの差分、背景
│   └── audio/               # ボイス、SE、BGM
├── scenes/                  # 各種画面シーン
│   ├── TitleScene.tscn      # タイトル画面
│   ├── main_game.tscn       # メインのゲーム画面
│   ├── EndingScene.tscn     # エンディング画面
│   └── ui/                  # UI（ステータス表示、設定パネル等）
│       ├── StatusBar.tscn
│       └── SettingsPanel.tscn
├── src/                     # スクリプト類
│   ├── autoload/            # グローバル管理
│   │   └── GameManager.gd
│   ├── characters/          # キャラクター制御
│   │   ├── BodyPartArea2D.gd
│   │   └── CharacterController.gd
│   └── ui/                  # UI制御
│       ├── TitleScene.gd
│       ├── SettingsPanel.gd
│       ├── StatusUI.gd
│       └── EndingScene.gd
└── README.md
```

## **🎯 主要システム・仕様ルール**

### **1. タッチ/クリック判定 (Touch Area System)**

* キャラクターの各部位（頭、胸、手など）は Area2D と CollisionShape2D（または CollisionPolygon2D）で表現する。
* マウス入力またはタッチ入力を _input_event で検知し、部位に応じた一意の識別子（StringName）をシグナルで発信する。

### **2. ステータス・好感度管理 (Status & Affinity System)**

* グローバルな状態（全体の好感度、興奮度、羞恥度）は Autoload された GameManager.gd で管理する。
* GameManager はセーブ/ロード機能（ConfigFile 使用）とエンディング分岐判定メソッドも持つ。
* 部位ごとの固有ステータス（感度、お触り回数）は、キャラクターノード内の Dictionary で保持する。

### **3. リアクション・アニメーション (Reaction & Animation)**

* お触り検知時、Tween を用いて立ち絵の微振動やスケール変更によるリアクション（ぷるぷる、ビクッとする動き）を実装する。
* 差分画像（表情の変化）は Sprite2D の texture 変更で管理する。

### **4. シーン構成・遷移フロー**

```
TitleScene
  ├─ [ゲームスタート] → main_game.tscn（GameManager をリセット）
  ├─ [セーブのロード] → main_game.tscn（GameManager.load_game() 経由）
  ├─ [設定]           → SettingsPanel（ポップアップ表示）
  └─ [ゲーム終了]     → get_tree().quit()

main_game.tscn
  └─ [お触り終了]     → EndingScene（GOOD / NORMAL / BAD の3分岐）

EndingScene
  └─ [タイトルへ戻る] → TitleScene
```

#### TitleScene 仕様
* ボタン4つ：ゲームスタート・セーブのロード・設定・ゲーム終了

#### SettingsPanel 仕様
* 解像度選択（OptionButton）
* BGM / SE 音量スライダー（AudioServer で制御）
* フルスクリーン / ウインドウ切り替えチェックボックス（DisplayServer で制御）
* 設定値は ConfigFile で永続化（`user://settings.cfg`）

#### EndingScene 仕様
* GameManager からエンディング種別（GOOD / NORMAL / BAD）を受け取る
* 分岐条件（閾値は GameManager の定数で管理）：
  * GOOD END：affinity が高い
  * NORMAL END：中程度
  * BAD END：低い / arousal 過多
* メッセージウィンドウでストーリーテキストを1行ずつ送る（クリック/タップで次へ）
* ストーリー終了後「タイトルへ戻る」ボタンを表示
* エンディングごとのテキストは外部リソース（Resource または JSON）で管理

## **📝 コーディング規約 (Coding Guidelines)**

* **シグナル（Signal）の活用:** Area2D（部位）からメインスクリプトへの通知には、必ずカスタムシグナルを使用すること。
  * 例: `signal touch_detected(body_part_name: StringName)`
* **Godot 4 スタイル:** @onready アノテーションを適切に使用し、connect はラムダ式か Callable の形式で行うこと。
* **UIとの分離:** キャラクターのデータ（ロジック）と画面上のUI表示はシグナルを介して疎結合にすること。

## **🗺 実装順序**

| 順 | ファイル | 役割 |
|---|---|---|
| 1 | `src/autoload/GameManager.gd` | ステータス・セーブ・エンディング分岐管理 |
| 2 | `scenes/TitleScene.tscn` + `src/ui/TitleScene.gd` | タイトル画面 |
| 3 | `scenes/ui/SettingsPanel.tscn` + `src/ui/SettingsPanel.gd` | 設定パネル |
| 4 | `src/characters/BodyPartArea2D.gd` | 部位タッチ検知 |
| 5 | `src/characters/CharacterController.gd` | キャラ制御・アニメ |
| 6 | `scenes/main_game.tscn` | メインシーン組み立て |
| 7 | `src/ui/StatusUI.gd` + `scenes/ui/StatusBar.tscn` | ステータスUI表示 |
| 8 | `scenes/EndingScene.tscn` + `src/ui/EndingScene.gd` | エンディング画面 |
