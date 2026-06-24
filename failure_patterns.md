# Hermes Failure Patterns

## Dashboard PTY Control Sequence Submitted As Prompt

- 初回観測日: 2026-06-25
- 状態: 対応中。`automation/hermes_daily_run.md`に再発防止手順を追加済み。
- 兆候: Hermes TUIがreadyになる前にdashboard PTYへresize/control sequenceを送ると、`(de)` のような制御断片がプロンプト本文として解釈される。
- 影響: 意図しないセッションが作られ、日次課題とは別の成果物がworkspaceに残ることがある。
- 次回の対策候補: PTYには課題本文だけを送る。送信直後に `/api/sessions/{id}/messages` で意図した課題が1回だけ入ったことを確認し、混入成果物があれば `checkpoint()` 前に削除する。

## CLI Output Contract Not Tested

- 初回観測日: 2026-06-24
- 状態: 対応済み候補。Hermes側に `cli-output-contract-tests` Skillを追加済み。
- 兆候: CLI課題で `lines/words/chars/top_words` のような出力キーが指定されているのに、テストが内部関数だけを見てCLI出力形式を検証しない。
- 影響: pytestは通るが、呼び出し側が期待する機械可読な出力契約を満たさない可能性が残る。
- 次回の対策候補: `subprocess.run` でCLIを実行し、指定キー名とソート順を検証するテストを要求する。

## Dashboard Prompt Submission Ambiguity

- 初回観測日: 2026-06-24
- 状態: 候補
- 兆候: Hermes dashboardのTerminal入力で、送信済みか処理中かが分かりにくく、同じ課題を再投入しやすい。
- 影響: セッション内に重複ターンが発生し、評価ログが汚れる。
- 次回の対策候補: 課題投入後はLogsの `agent.turn_context` またはSessions APIでセッション開始を確認してから再送判断する。

## Dashboard Session Text Hidden From Snapshot

- 初回観測日: 2026-06-24
- 状態: 候補
- 兆候: Playwright snapshotや `document.body.innerText` にChat本文が出ない。
- 影響: Hermesの回答保存が手作業になりやすい。
- 次回の対策候補: `window.__HERMES_SESSION_TOKEN__` を使い、`X-Hermes-Session-Token` ヘッダ付きで `/api/sessions/{id}/messages` を取得する。
