# Band Click Player

Band Click Player は、バンド練習で使用する macOS 専用の「オケ + クリック」再生アプリです。

主な目的は、Moises などで作成したオケ音源とクリック音源を同期再生し、ZOOM AMS-24 のような 4ch 出力対応オーディオインターフェースで、オケを PA 側、クリックをドラマー側へ分けて出力することです。

---

## 想定ユースケース

- 既存曲のコピー練習
- スタジオでのバンド練習
- ドラマーのみがクリックを聴く
- バンド全体にはオケだけを流す
- Moises の Smart Metronome やステム分離を活用する

---

## 想定機材

- MacBook
- ZOOM AMS-24
- 有線イヤホンまたはヘッドホン
- スタジオミキサーへ接続するケーブル

---

## 基本構成

```text
MacBook
  ↓
Band Click Player
  ↓
ZOOM AMS-24
  ├ Output 1/2 → スタジオミキサー（オケ）
  └ Output 3/4 → ドラマーのイヤホン（クリック）
```

---

## ローカル環境構築

### 必要なもの

- macOS 13.0 以降
- Xcode 15 以降

### 手順

```bash
# リポジトリをクローン
git clone https://github.com/tomipetit/band-cue-player.git
cd band-cue-player

# Xcode でプロジェクトを開く
open BandClickPlayer.xcodeproj
```

Xcode が開いたら:

1. ツールバーの Scheme が `BandClickPlayer` になっていることを確認する
2. `⌘R` でビルド & 実行する

### 署名について

初回ビルド時、Signing & Capabilities で Team を自分の Apple ID に設定する。

`BandClickPlayer` ターゲット → Signing & Capabilities → Team を選択。

### 動作確認

- ZOOM AMS-24 など 4ch 出力デバイスを接続した状態で Output Device に表示されることを確認する
- 2ch デバイス（MacBook 内蔵スピーカーなど）でも起動・再生は可能（オケとクリックが同じ出力にミックスされる）

---

## 開発方針

このアプリは DAW の代替ではありません。

目的を「オケ + クリックの同期再生」と「4ch 出力の振り分け」に絞ります。

最初から多機能化せず、以下の順で段階的に作成します。

---

# Phase 1: MVP

## 目的

2つの音声ファイルを同期再生し、別々の出力チャンネルへ送ることを確認します。

## 入力ファイル

- オケ音源
- クリック音源

対応形式:

- wav
- mp3
- aiff
- m4a

## 出力

- オケ: Output 1/2
- クリック: Output 3/4

## 必須機能

- オケファイル選択
- クリックファイル選択
- Play
- Stop
- 出力デバイス選択
- ステータス表示

## 完了条件

- オケとクリックが同時に再生される
- 再生開始時にズレが発生しにくい
- オケが AMS-24 の Output 1/2 へ出る
- クリックが AMS-24 の Output 3/4 へ出る
- クリックが PA 側に混ざらない

---

# Phase 2: 曲管理

## 目的

複数曲を一覧管理し、練習時に曲を選んで再生できるようにします。

## 機能

- 曲一覧表示
- 曲名表示
- 再生時間表示
- 次の曲
- 前の曲
- 曲選択

## 想定 UI

```text
01. 曲A  04:20
02. 曲B  03:58
03. 曲C  05:10
```

---

# Phase 3: Moises フォルダ構成対応

## 目的

Moises から書き出した音源を扱いやすくします。

## 推奨フォルダ構成

```text
songs/
  01_song-a/
    accompaniment.wav
    click.wav

  02_song-b/
    accompaniment.wav
    click.wav
```

## 機能

- songs フォルダ読み込み
- 各曲フォルダの自動検出
- accompaniment / click の自動ペアリング

---

# Phase 4: バンド練習特化

## 目的

スタジオ練習での操作を減らします。

## 機能候補

- セットリスト保存
- 曲順変更
- 曲間メモ
- 4カウント追加
- ガイド音声対応
- ホットキー
- フットスイッチ対応

---

## 技術選定

## SwiftUI

UI 実装に使用します。

理由:

- macOS ネイティブアプリとして軽い
- UI がシンプルなため SwiftUI で十分
- Xcode だけで開発できる

## AVFoundation / AVAudioEngine

音声再生とルーティングに使用します。

理由:

- macOS 標準の音声 API を利用できる
- 複数トラックの同期再生に向いている
- 4ch 出力へのルーティングを実装しやすい

---

## 推奨ディレクトリ構成

```text
BandClickPlayer/
  BandClickPlayerApp.swift
  ContentView.swift
  Audio/
    AudioEngineManager.swift
    AudioDeviceManager.swift
  Models/
    SongFiles.swift
    Song.swift
    Playlist.swift
```

---

## Claude Code への実装指示

まず Phase 1 のみを実装してください。

重要事項:

- DAW のような多機能アプリにはしない
- 2ファイル同期再生に集中する
- AMS-24 専用実装にはしない
- 一般的な 4ch 出力対応 Core Audio デバイスとして扱う
- 出力先はまず固定でよい
  - オケ: Output 1/2
  - クリック: Output 3/4
- UI は最低限でよい
- 外部ライブラリはできるだけ使わない

---

## Phase 1 UI 案

```text
Band Click Player

[オケを選択]      selected-accompaniment.wav
[クリックを選択]  selected-click.wav

Output Device: [ZOOM AMS-24]

オケ出力:      1/2
クリック出力:  3/4

[Play] [Stop]

Status: Ready
```

---

## 注意点

- Moises 単体では AMS-24 の Output 1/2 と 3/4 を直接使い分けられない
- 本アプリは、その振り分けだけを行う小型プレイヤーとして作る
- オケとクリックを別々のプレイヤーで単純に同時再生すると、長時間でズレる可能性がある
- AVAudioEngine 上で同期再生する設計にする
- クリックが PA 側に漏れないことを最優先にする

---

## 最初のゴール

Xcode でビルドできる macOS アプリを作成し、以下を確認します。

1. AMS-24 が出力デバイスとして選択できる
2. オケ音源を選択できる
3. クリック音源を選択できる
4. Play で同時再生される
5. Stop で停止する
6. Output 1/2 と 3/4 に分離して出力される
