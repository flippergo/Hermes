param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$env:PYTHONUTF8 = "1"

$RepoRoot = "C:\Users\hoppe\work\Hermes"
$PromptFile = Join-Path $RepoRoot "automation\hermes_daily_run.md"
$LogDir = Join-Path $RepoRoot "automation\logs"
$Stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$LastMessageFile = Join-Path $LogDir "codex-last-message-$Stamp.md"
$RunLogFile = Join-Path $LogDir "codex-run-$Stamp.log"
$PreflightLogFile = Join-Path $LogDir "preflight-$Stamp.log"

New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

function Write-PreflightLog {
    param([string]$Message)
    $Message | Out-File -FilePath $PreflightLogFile -Encoding UTF8 -Append
}

function Resolve-CodexExecutable {
    $CodexCommand = Get-Command codex -ErrorAction SilentlyContinue
    if ($null -ne $CodexCommand) {
        return $CodexCommand.Source
    }

    $ExtensionRoot = Join-Path $env:USERPROFILE ".vscode\extensions"
    if (Test-Path -LiteralPath $ExtensionRoot) {
        $Candidates = Get-ChildItem -LiteralPath $ExtensionRoot -Directory -Filter "openai.chatgpt-*-win32-x64" |
            Sort-Object Name -Descending |
            ForEach-Object { Join-Path $_.FullName "bin\windows-x86_64\codex.exe" } |
            Where-Object { Test-Path -LiteralPath $_ }
        if ($Candidates) {
            return $Candidates[0]
        }
    }

    throw "Codex executable not found on PATH or under $ExtensionRoot"
}

try {
    Write-PreflightLog "started=$(Get-Date -Format o)"
    Write-PreflightLog "repo=$RepoRoot"
    Write-PreflightLog "user=$env:USERDOMAIN\$env:USERNAME"
    Write-PreflightLog "path=$env:PATH"
    $CodexExe = Resolve-CodexExecutable

    Write-PreflightLog "codex=$CodexExe"

    if (-not (Test-Path -LiteralPath $PromptFile)) {
        throw "Prompt file not found: $PromptFile"
    }
    Write-PreflightLog "prompt=$PromptFile"

    Set-Location -LiteralPath $RepoRoot

    $Prompt = Get-Content -Raw -Encoding UTF8 -LiteralPath $PromptFile
    $Today = Get-Date -Format "yyyy-MM-dd"
    $Prompt = $Prompt + "`r`n`r`n" +
        "Additional automation instructions:`r`n" +
        "- Today is $Today.`r`n" +
        "- Treat this as a scheduled run. Do not push directly to main. Push a daily branch and create a PR.`r`n" +
        "- Include the Colab shutdown-cell result and runtime deletion confirmation in the PR body.`r`n" +
        "- Keep Hermes task evaluation separate from automation/process failures in the daily log.`r`n" +
        "- If dashboard prompt submission fails, record the failure, avoid duplicate or conflicting tasks, and do not checkpoint unintended artifacts.`r`n"
    Write-PreflightLog "prompt_length=$($Prompt.Length)"

    $ArgsList = @(
        "exec",
        "-C", $RepoRoot,
        "-s", "danger-full-access",
        "-o", $LastMessageFile,
        "-"
    )

    if ($DryRun) {
        Write-Host "DRY RUN: Codex executable: $CodexExe"
        Write-Host "DRY RUN: Repo root: $RepoRoot"
        Write-Host "DRY RUN: Prompt file: $PromptFile"
        Write-Host "DRY RUN: Last message file: $LastMessageFile"
        Write-Host "DRY RUN: Log file: $RunLogFile"
        Write-Host "DRY RUN: Prompt length: $($Prompt.Length)"
        Write-Host "DRY RUN: Command:"
        Write-Host "`"$CodexExe`" exec -C `"$RepoRoot`" -s danger-full-access -o `"$LastMessageFile`" - <prompt>"
        exit 0
    }

    Write-PreflightLog "codex_start=$(Get-Date -Format o)"
    $PreviousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $Prompt | & $CodexExe @ArgsList *> $RunLogFile
        $ExitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $PreviousErrorActionPreference
    }
    Write-PreflightLog "codex_exit=$ExitCode"

    if ($ExitCode -ne 0) {
        throw "Codex daily run failed with exit code $ExitCode. See $RunLogFile"
    }

    Write-Host "Codex daily run completed."
    Write-Host "Log: $RunLogFile"
    Write-Host "Last message: $LastMessageFile"
} catch {
    Write-PreflightLog "error=$($_.Exception.Message)"
    Write-PreflightLog "error_record=$($_ | Out-String)"
    throw
}
