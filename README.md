# Hermes Agent on Google Colab

Google Colab の A100 GPU 上で、Ollama の `gemma4:31b` を使って Hermes Agent を動かすNotebookです。
Agentの状態と作業ファイルはGoogle Driveへ永続化されます。

## 必要条件

- A100 40GB以上を利用できるGoogle Colab環境
- 24GB以上のシステムRAM
- 30GB以上のColabランタイム空きディスク
- Google Driveへのアクセス権

条件不足の場合、Notebookはモデルを小型版へ変更せず、ハードウェア検査で停止します。
`gemma4:31b` は約20GBあり、モデル自体はDriveへ保存しないため、新しいColab VMごとに再取得されます。

## 実行方法

1. [Hermes_Colab.ipynb](./Hermes_Colab.ipynb) をGoogle Driveへアップロードするか、GitHubからColabで開きます。
2. Colabの「ランタイム」→「ランタイムのタイプを変更」でA100 GPUを選択します。
3. Notebookのセルを上から順に実行します。
4. モデル取得と `hermes doctor` が完了したら、`%llm` または `%%llm` で指示します。
5. GUIを使う場合は `GUI_MODE` でColab DashboardまたはDesktop App接続を選びます。

```text
%llm workspaceにPythonスクリプトを作ってください。
```

複数行の指示では、セルの先頭に `%%llm` を書きます。

```text
%%llm
workspaceの内容を確認してください。
次に行うべき作業を3件提案してください。
```

同じセッションは自動的に継続されます。新しい会話を始める場合は `%llm --new 指示`、複数行なら先頭行を `%%llm --new` にします。
危険操作をその呼び出しだけ許可する場合は `--dangerous` を指定します。最後の結果は `LAST_HERMES_RESULT` に保存されます。

## Notebook API

| 関数 | 用途 |
|---|---|
| `%llm 指示` | 1行の指示を現在のセッションで実行 |
| `%%llm` | セル本文の複数行指示を現在のセッションで実行 |
| `ask_hermes(prompt, session_id=None, allow_dangerous=False)` | 1ターン実行し、終了時に状態とworkspaceをDriveへ保存 |
| `new_session()` | 現在のセッションIDを解除 |
| `checkpoint()` | 手動チェックポイント |
| `restore(force=False)` | 最新の正常なDrive状態を復元。ローカルを置換する場合は `force=True` |
| `status()` | GPU、Ollama、モデル、Hermes、セッション、保存状態を表示 |
| `start_gui(mode)` | `colab-dashboard` または `desktop-app` モードを起動 |
| `stop_gui()` | DashboardとTailscaleを停止し、最終チェックポイントを保存 |
| `gui_status()` | GUIモード、URL、認証、プロセス、自動保存状態を表示 |

`allow_dangerous=True` は該当呼び出しに `--yolo` を渡します。通常は使用しないでください。
デフォルトでは標準入力を閉じるため、非対話セルで危険操作の承認待ちが停止し続けることはありません。

## GUIモード

NotebookのGUI選択セルで次のいずれかを指定します。

```python
GUI_MODE = "colab-dashboard"  # または "desktop-app"
GUI_INFO = start_gui(GUI_MODE)
```

### Colab Web Dashboard

`colab-dashboard`はDashboardをColab VM内で起動し、Googleアカウントで保護されたColabプロキシURLを表示します。
Colabプロキシ固有のHostヘッダーを受け入れるためVM内では`--insecure`を使用しますが、ポート自体は外部公開せず、アクセス制御はColabプロキシが担当します。
追加の秘密情報は不要です。表示されたリンクをブラウザで開くと、管理画面とChatタブを利用できます。

### 手元のDesktop App

`desktop-app`はDashboardをBasic認証付きで起動し、Tailscale Serveで同じtailnetだけに公開します。
Colab上でTailscaleのHTTPS証明書同意フローが完了しない場合は、tailnet内HTTPへ自動フォールバックします。
Colab Secretsへ次を登録し、Notebookからのアクセスを許可してください。

- `TAILSCALE_AUTHKEY`: Tailscale認証キー。ephemeralな再利用可能キーを推奨
- `HERMES_DASHBOARD_USERNAME`: Dashboardログイン名
- `HERMES_DASHBOARD_PASSWORD`: 強いログインパスワード
- `HERMES_DASHBOARD_SECRET`: 32文字以上の固定署名シークレット

手元PCにもTailscaleとHermes Desktop Appを導入し、同じtailnetへ接続します。
起動セルが表示したURLをDesktop Appの「Settings → Gateway → Remote gateway」へ設定し、
Colab Secretsのユーザー名・パスワードでサインインします。

認証キーとDashboard認証情報はプロセス環境へだけ渡し、Google DriveやNotebookには保存しません。
Colabランタイム停止中はどちらのGUIにも接続できません。

どちらのGUIでも、Hermes状態またはworkspaceの変更を検出すると15秒以内を目安にDriveへ自動チェックポイントします。
GUI停止時にも最終チェックポイントを保存します。強制切断の瞬間に発生した変更は失われる可能性があるため、ランタイム破棄前には従来どおり`checkpoint()`の完了を確認してください。

## Google Driveの構成

```text
MyDrive/Hermes/
├── state/       # 最新のHermes設定、記憶、skills、セッションDB
├── workspace/   # Hermesが作成・編集する作業ファイル
└── snapshots/   # SQLite整合性確認済みの状態を最大3世代
```

Hermesは実行中、次のローカルディレクトリを使用します。

- `/content/hermes-home`
- `/content/hermes-workspace`
- `/content/ollama-models`

SQLiteはローカルで使用し、チェックポイント時にSQLite Backup APIでコピーした後、
`PRAGMA integrity_check`を通過したものだけをDriveへ保存します。

次は意図的に同期されません。

- `.env`とAPIキー
- ログ、キャッシュ、ランタイムバイナリ
- Ollamaモデル
- SQLiteの`-wal`、`-shm`ファイル

将来APIキーを追加する場合は、Drive内の`.env`ではなくColab Secretsを使用してください。

## 障害復旧

現在の`state/`が破損している場合、`restore()`は新しい順に正常なスナップショットを探します。
ローカル状態をDriveの状態で置き換える場合は、Hermesが動いていないことを確認して実行します。

```python
restore(force=True)
status()
```

Colabランタイムの強制切断中に実行していたターンは保存されない可能性があります。
重要な変更後は`Checkpoint saved:`の表示を確認してください。

## 設計上の補足

- PlaywrightとTelegramはランタイム機能として使用しません。Hermes Dashboardは選択した場合だけ起動します。
- Notebookは`hermes-agent[all]==0.17.0`へ固定しています。
- Ollamaは公式インストーラーから、その時点のGemma 4互換版を導入します。
- Ollama APIは`127.0.0.1:11434`だけで使用し、外部公開しません。
- コンテキスト長は65,536トークンに設定します。

参考資料:

- [Hermes Agent: Local Ollama Setup](https://hermes-agent.nousresearch.com/docs/guides/local-ollama-setup)
- [Hermes Agent: Desktop App](https://hermes-agent.nousresearch.com/docs/user-guide/desktop)
- [Hermes Agent: Web Dashboard](https://hermes-agent.nousresearch.com/docs/user-guide/features/web-dashboard)
- [Tailscale Serve](https://tailscale.com/kb/1242/tailscale-serve)
- [Ollama: gemma4:31b](https://ollama.com/library/gemma4:31b)
- [Google Colab FAQ](https://research.google.com/colaboratory/faq.html)
