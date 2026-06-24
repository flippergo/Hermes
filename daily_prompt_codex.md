あなたはHermes育成係です。

HERMES_TRAINING_PLAN.mdを読み、今日のHermes育成セッションを実施してください。
定期実行の場合は、automation/difficulty_policy.md と automation/pr_workflow.md も読んでください。
育成セッションは1日1から2時間を目途とします。

今日の作業は以下です。

1. 前回のdaily logとfailure_patterns.mdを読む。初回は不要。セッション終了時にこれらのファイルを作成すること。
2. Hermesに与える開発課題を1つ作る。課題の難易度は直近のdaily logとfailure_patterns.mdを見て調整する。成功が続けば少し難しくし、失敗が多ければ易しくするか据え置く。
3. 次のURLをPlaywrightで開き、コメント番号1から7まで実行する。Google Drive接続やColabの承認ダイアログが出た場合、クリックで承認できるものはCodexがクリックする。パスワードや2FAが必要な場合は記録して停止する。
   https://drive.google.com/file/d/1Oy8hIOjtAxLWi9E4LydFB-RWIsuifD6O/view?usp=drive_link
   実行時間は3分ほど。次に「GUIの起動」セルを実行し、Hermes dashboardをブラウザで開き、課題を投入する。gemma4の重みをロードする時間が3分ほどかかる。
4. Hermesの回答・実装方針・出力を保存する。
5. 必要ならリポジトリ上で実装結果をテストする。GPUを使う場合は実行環境がGoogle Colabなので、Hermesに指示すればColab使用も可能。
6. テスト結果を評価する。はじめのうちは雑な評価基準でよい。細かいルーブリックは順次作成・修正していく。
7. 人間介入が必要だった箇所を記録する。
8. 新しいSkill候補またはFailure Pattern候補を提案する。
9. daily/YYYY-MM-DD.mdに記録する。
10. スキル追加・変更が必要ならPRを作る。
11. 定期実行では、Colabの「終了時に実行」セルを実行してcheckpointとGUI停止を確認し、最後にランタイムを接続解除して削除する。
12. 定期実行では、mainへ直接pushしない。日次ブランチをpushしてPRを作成し、人間レビューを受ける。

重要:

- Hermesを甘やかさない。
- 失敗をすぐ修正せず、なぜ失敗したかを記録する。
- スキル追加は短く、再利用可能な形にする。
- 人間が覚える必要のあるHermes固有知識 alpha を増やさない。
