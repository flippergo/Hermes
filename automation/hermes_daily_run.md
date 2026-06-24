# Hermes Daily Training Run

このファイルは、毎日午前7時にCodexへ渡す定期実行用プロンプトの標準形である。

## 実行プロンプト

```text
あなたはHermes育成係です。

C:\Users\hoppe\work\Hermes に移動し、HERMES_TRAINING_PLAN.md、daily_prompt_codex.md、automation/difficulty_policy.md、failure_patterns.md、直近の daily/*.md を読んでください。

今日のHermes育成セッションを実施してください。課題は1つだけ作成し、直近の成績に応じて難易度を少しずつ調整してください。

Google ColabはPlaywrightで開いてください。Google Drive接続やColabの承認ダイアログが表示された場合、クリックで承認できるものはCodexがクリックしてください。パスワードや2FAなどCodexだけで処理できない認証が必要な場合は、その状態を記録して停止してください。

Colabではコメント番号1から7まで実行し、「GUIの起動」セルを実行してHermes dashboardを開き、課題を投入してください。

Hermes dashboardへの課題投入では、PTYのresize/control sequenceをユーザー入力として送らないでください。Hermes TUIが `ready` になっていることを確認してから課題本文だけを送信してください。送信直後に `/api/sessions/{id}/messages` などで、意図した課題文が1回だけ入っていることを確認してください。

課題投入に失敗した場合は、同じセッションに別課題を重ねて投入しないでください。失敗セッションや混入成果物は記録し、checkpoint前に意図しない成果物を削除してください。

Hermesの回答、実装方針、出力、テスト結果、人間介入、Skill候補、Failure Pattern候補を保存してください。

セッション終了時は、Colabの「終了時に実行」セルを実行してcheckpointとGUI停止を確認し、最後にランタイムを接続解除して削除してください。

daily/YYYY-MM-DD.md と必要な関連ファイルを更新してください。daily logでは、Hermesの課題遂行評価と、Codex/Colab/dashboardなど育成実行プロセスの不備を別セクションに分けてください。変更は main に直接pushせず、日次ブランチを作成してcommitし、originへpushしてPRを作成してください。
```

## 想定スケジュール

- 実行時刻: 毎日 07:00
- 実行方法: `automation/run_hermes_daily.ps1` をWindows Task Schedulerから起動する
- 公開方法: `main`直pushではなく日次ブランチ + PR

## Task Scheduler登録

```powershell
.\automation\register_hermes_daily_task.ps1
```

ドライラン:

```powershell
.\automation\run_hermes_daily.ps1 -DryRun
```

## 日次ブランチ名

```text
daily/hermes-YYYY-MM-DD
```

## PRタイトル

```text
Hermes training log YYYY-MM-DD
```

## PR本文に含める内容

- 今日の課題
- Hermesの結果
- 評価
- 失敗パターン
- Skill追加・変更候補
- Colab終了処理とランタイム破棄の確認
