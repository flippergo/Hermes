# Hermes Failure Patterns

## Colab Playwright Session Requires Google Password

- 初回観測日: 2026-06-28
- 状態: 候補
- 兆候: PlaywrightでColabノートブックは開けるが、右上が `ログイン` のままで、対象アカウント選択後にGoogleアカウントの `パスワードを入力` 画面へ進む。
- 影響: Codexだけでは認証を完了できず、Drive mount、A100確認、dashboard起動、課題投入、checkpoint、ランタイム破棄まで進めない。
- 次回の対策候補: Colabを開いた直後にログイン状態と `変更は保存されません` 表示の有無を確認する。パスワードや2FAが必要な場合はセル実行やdashboard投入を開始せず、認証ブロックとして停止・記録する。

## Workspace File Search False Negative

- 初回観測日: 2026-06-27
- 状態: 候補
- 兆候: `/content/hermes-workspace` に既存ファイルが存在するのに、Hermesの `search_files` が `{"total_count": 0}` を返し、存在しないと判断する。
- 影響: 既存コード修正課題で、実装・テストに入る前に誤って停止する。
- 次回の対策候補: 既存ファイル前提の課題では、Codexが課題投入前にdashboard Files APIまたはNotebook上の `Path.exists()` で前提を確認する。Hermesには、`search_files` が0件でも停止前に `read_file` で対象の絶対パスを直接読むか、ディレクトリ一覧を確認するよう要求する。

## Dashboard PTY Control Sequence Submitted As Prompt

- 初回観測日: 2026-06-25
- 状態: 対応済み候補。2026-06-26は専用 `/api/pty` WebSocket channelとSessions API確認で再発なし。
- 兆候: Hermes TUIがreadyになる前にdashboard PTYへresize/control sequenceを送ると、`(de)` のような制御断片がプロンプト本文として解釈される。
- 影響: 意図しないセッションが作られ、日次課題とは別の成果物がworkspaceに残ることがある。
- 次回の対策候補: PTYには課題本文だけを送る。必要ならEnterのみを追加送信して確定する。送信直後に `/api/sessions/{id}/messages` で意図した課題が1回だけ入ったことを確認し、混入成果物があれば `checkpoint()` 前に削除する。

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

## Dashboard Execution Permission Prompt Is Not Visible In Snapshot

- 初回観測日: 2026-06-28
- 状態: 対応済み候補
- 原因: Hermes dashboardのツール実行許可待ちが、Playwright snapshotや `document.body.innerText` では明示的に見えない場合がある。ログ上も長いツール実行中または `Active Sessions: 0/1` のように見え、許可待ちと判別しにくい。
- 影響: 実画面ではユーザーに実行許可待ちが表示されているのに、Codexが「待っていない」と誤判定するとHermes処理が停止する。今回の2026-06-28手動再実行では、複数回の許可を通した後にpatch、pytest、最終報告まで進んだ。
- 次回の対策: dashboard許可画面については、ユーザーの実画面報告を最優先する。許可待ちと言われたら、ログやsnapshotで確認できなくても対象dashboardタブに `y` + Enter を送る。許可送信後は `/api/logs` と `/api/sessions/{id}/messages` でツール実行が進んだことを確認する。
