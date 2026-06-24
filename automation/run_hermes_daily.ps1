param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = "C:\Users\hoppe\work\Hermes"
$PromptFile = Join-Path $RepoRoot "automation\hermes_daily_run.md"
$LogDir = Join-Path $RepoRoot "automation\logs"
$Stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$LastMessageFile = Join-Path $LogDir "codex-last-message-$Stamp.md"
$RunLogFile = Join-Path $LogDir "codex-run-$Stamp.log"

New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

$CodexCommand = Get-Command codex -ErrorAction Stop
$CodexExe = $CodexCommand.Source

if (-not (Test-Path -LiteralPath $PromptFile)) {
    throw "Prompt file not found: $PromptFile"
}

Set-Location -LiteralPath $RepoRoot

$Prompt = Get-Content -Raw -Encoding UTF8 -LiteralPath $PromptFile
$Today = Get-Date -Format "yyyy-MM-dd"
$Prompt = $Prompt + "`r`n`r`n" +
    "Additional automation instructions:`r`n" +
    "- Today is $Today.`r`n" +
    "- Treat this as a scheduled run. Do not push directly to main. Push a daily branch and create a PR.`r`n" +
    "- Include the Colab shutdown-cell result and runtime deletion confirmation in the PR body.`r`n"

$ArgsList = @(
    "exec",
    "-C", $RepoRoot,
    "-s", "danger-full-access",
    "-o", $LastMessageFile,
    $Prompt
)

if ($DryRun) {
    Write-Host "DRY RUN: Codex executable: $CodexExe"
    Write-Host "DRY RUN: Repo root: $RepoRoot"
    Write-Host "DRY RUN: Prompt file: $PromptFile"
    Write-Host "DRY RUN: Last message file: $LastMessageFile"
    Write-Host "DRY RUN: Log file: $RunLogFile"
    Write-Host "DRY RUN: Prompt length: $($Prompt.Length)"
    Write-Host "DRY RUN: Command:"
    Write-Host "`"$CodexExe`" exec -C `"$RepoRoot`" -s danger-full-access -o `"$LastMessageFile`" <prompt>"
    exit 0
}

& $CodexExe @ArgsList *> $RunLogFile
$ExitCode = $LASTEXITCODE

if ($ExitCode -ne 0) {
    throw "Codex daily run failed with exit code $ExitCode. See $RunLogFile"
}

Write-Host "Codex daily run completed."
Write-Host "Log: $RunLogFile"
Write-Host "Last message: $LastMessageFile"
