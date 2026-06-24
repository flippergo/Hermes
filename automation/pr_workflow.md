# Hermes Daily PR Workflow

当面の定期実行では、`main`へ直接pushしない。Codexは日次ブランチをpushし、PRを作成する。

## 手順

1. 作業開始前に `main` を最新化する。
2. 日次ブランチを作成する。

```powershell
git switch main
git pull --ff-only origin main
git switch -c daily/hermes-YYYY-MM-DD
```

3. Hermes育成セッションを実施する。
4. `daily/YYYY-MM-DD.md`、`failure_patterns.md`、必要なSkill案や運用ファイルを更新する。
5. Colabの「終了時に実行」セルを実行し、checkpoint成功を確認する。
6. Colabランタイムを接続解除して削除する。
7. 差分を確認する。

```powershell
git status --short
git diff --stat
```

8. コミットする。

```powershell
git add daily/YYYY-MM-DD.md failure_patterns.md
git commit -m "Add Hermes training log YYYY-MM-DD"
```

9. ブランチをpushし、PRを作成する。

```powershell
git push -u origin daily/hermes-YYYY-MM-DD
gh pr create --base main --head daily/hermes-YYYY-MM-DD --title "Hermes training log YYYY-MM-DD" --body-file PR_BODY.md
```

## レビュー方針

- 人間がPRを確認してからmainへmergeする。
- 明らかな記録ミス、不要な生成物、過剰なSkill追加があれば修正する。
- Colabランタイム破棄が確認できない場合は、PR本文に未確認として明記する。

## main直pushを許可する条件

以下が安定してから検討する。

- 連続14日以上、不要差分がない。
- Colab終了処理の失敗がない。
- PRレビューで重大修正がほぼ不要。
- 難易度調整がdaily logに一貫して記録されている。
