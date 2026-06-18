# =========================================
# AI_USB_setup.ps1  v2.0
# Portable CPU-only AI Skeleton Builder
# Compatible: PowerShell 5.1+
# =========================================

#Requires -Version 5.1

# --- Self-elevate if needed (no install, just unblock execution) ---
param([switch]$Elevated)

# --- Detect USB root (where this script resides) ---
$USB_ROOT = Split-Path -Parent $MyInvocation.MyCommand.Definition

# --- Inner AI_USB folder where skeleton should live ---
$TARGET_DIR = Join-Path $USB_ROOT "AI_USB"

# ---- Helper: Write colored status lines ----
function Write-Status {
    param([string]$Msg, [string]$Color = "Cyan")
    Write-Host "  [+] $Msg" -ForegroundColor $Color
}
function Write-Warn {
    param([string]$Msg)
    Write-Host "  [!] $Msg" -ForegroundColor Yellow
}
function Write-Err {
    param([string]$Msg)
    Write-Host "  [X] $Msg" -ForegroundColor Red
}

Clear-Host
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "   AI USB Toolkit  -  Setup v2.1            " -ForegroundColor Cyan
Write-Host "   PowerShell $($PSVersionTable.PSVersion)  " -ForegroundColor DarkCyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  USB Root  : $USB_ROOT"
Write-Host "  Target Dir: $TARGET_DIR"
Write-Host ""

# ---- Create folder skeleton ----
$folders = @(
    "$TARGET_DIR\runtimes\llama.cpp\models",
    "$TARGET_DIR\runtimes\gemma\models",
    "$TARGET_DIR\notes",
    "$TARGET_DIR\study",
    "$TARGET_DIR\templates",
    "$TARGET_DIR\scripts",
    "$TARGET_DIR\config",
    "$TARGET_DIR\logs"
)

Write-Host "  Creating folder structure..." -ForegroundColor White
foreach ($folder in $folders) {
    if (-not (Test-Path $folder)) {
        try {
            New-Item -ItemType Directory -Path $folder -Force | Out-Null
            Write-Status "Created: $($folder.Replace($USB_ROOT,'.'))"
        } catch {
            Write-Err "Failed to create: $folder  ($_)"
        }
    } else {
        Write-Warn "Exists (skipped): $($folder.Replace($USB_ROOT,'.'))"
    }
}

# ---- Write config/settings.json ----
$configFile = "$TARGET_DIR\config\settings.json"
$configContent = @'
{
    "default_model": "",
    "threads": -1,
    "ctx": 2048,
    "top_p": 0.9,
    "temperature": 0.7,
    "runtime_paths": {
        "llama": "runtimes/llama.cpp",
        "gemma": "runtimes/gemma"
    },
    "output_dir": "notes",
    "study_dir": "study",
    "log_sessions": true
}
'@
Set-Content -Path $configFile -Value $configContent -Encoding UTF8
Write-Status "Written: config\settings.json"

# ---- Write HELP.txt ----
$helpFile = "$TARGET_DIR\HELP.txt"
$helpContent = @"
(!) This program is designed to function on PowerShell 5.1+
AI USB Toolkit - User Guide
============================================================

Welcome! This USB stick contains a fully offline AI toolkit
designed for writing, studying, and note organization.
No software installs on the host PC. Just plug in and go!

CREDITS
-------
Developed and maintained by **Blake Von Jett**.

FOLDER LAYOUT
-------------
AI_USB\
  runtimes\llama.cpp\models\  - Place .gguf model files here
  runtimes\gemma\models\      - Place Gemma model files here
  notes\                      - Chat sessions and text outputs
  study\                      - Flashcards and study input/output
  templates\                  - Essay, outline, CV templates
  scripts\                    - Launcher and AI workflow scripts
  config\settings.json        - Runtime settings (edit this!)
  logs\                       - Session logs (auto-generated)

QUICK START
-----------
1. Plug in the USB drive.
2. Run AI_USB_setup.ps1 once (already done if you see this).
3. Drop a .gguf model into runtimes\llama.cpp\models\
   (or a Gemma model into runtimes\gemma\models\).
4. (Optional) Edit config\settings.json and set "default_model"
   to the filename you want pre-selected, e.g. "mistral-7b-q4.gguf".
   You can keep multiple models in the folder and pick at runtime.
5. Double-click Run_Toolkit.bat  (or run ai_usb_launcher.ps1).
   You'll be asked which AI program to use, then which model/brain
   to load, then asked to confirm before it loads. After loading,
   pick what to do (chat, summarise, flashcards). At the end of a
   chat you'll be asked whether to save the transcript.
6. Unplug when done -- nothing is left on the host PC.

SETTINGS REFERENCE (config\settings.json)
------------------------------------------
default_model  : filename of the model to load (blank = prompt at runtime)
threads        : CPU threads to use (-1 = auto-detect)
ctx            : Context window size (2048 recommended for low-RAM PCs)
temperature    : Creativity (0.1=focused, 1.0=creative). Default 0.7
top_p          : Nucleus sampling. Default 0.9
log_sessions   : true/false  -- saves transcripts to logs\

RECOMMENDED FREE MODELS (download separately)
---------------------------------------------
- Mistral 7B Q4_K_M  (~4 GB) -- great all-rounder
- Phi-3 Mini Q4      (~2 GB) -- fast on low-RAM PCs
- Gemma 2B           (~1.5 GB) -- study/writing tasks
"@
Set-Content -Path $helpFile -Value $helpContent -Encoding UTF8
Write-Status "Written: HELP.txt"

# ---- Write placeholder files ----
$placeholders = @{
    "$TARGET_DIR\notes\last_session.txt"       = "# Last session transcript will appear here.`n"
    "$TARGET_DIR\study\input.txt"              = "# Paste study text here for flashcard generation.`n"
    "$TARGET_DIR\study\flashcards.txt"         = "# Generated flashcards will appear here.`n"
    "$TARGET_DIR\templates\essay_outline.txt"  = "Title:`nThesis:`n`nI. Introduction`n   A.`n   B.`nII. Body Point 1`n   A.`n   B.`nIII. Body Point 2`n   A.`n   B.`nIV. Conclusion`n"
    "$TARGET_DIR\templates\cv_template.txt"    = "NAME`nEmail | Phone | Location`n`n--- SUMMARY ---`n`n--- EXPERIENCE ---`nJob Title | Company | Dates`n- Achievement`n`n--- EDUCATION ---`nDegree | School | Year`n`n--- SKILLS ---`n"
}
foreach ($kv in $placeholders.GetEnumerator()) {
    if (-not (Test-Path $kv.Key)) {
        Set-Content -Path $kv.Key -Value $kv.Value -Encoding UTF8
        Write-Status "Created: $($kv.Key.Replace($USB_ROOT,'.'))"
    }
}

# ---- Write the main launcher script ----
$launcherPath = "$TARGET_DIR\scripts\ai_usb_launcher.ps1"
$launcherContent = @'
# =============================================
# ai_usb_launcher.ps1  v2.3
# AI USB Toolkit - Main Launcher
# =============================================
#Requires -Version 5.1

# ══════════════════════════════════════════
#  PATHS & CONFIG
# ══════════════════════════════════════════
$SCRIPT_DIR  = Split-Path -Parent $MyInvocation.MyCommand.Definition
$AI_USB_ROOT = Split-Path -Parent $SCRIPT_DIR
$USB_ROOT    = Split-Path -Parent $AI_USB_ROOT
$CONFIG_FILE = "$AI_USB_ROOT\config\settings.json"
$NOTES_DIR   = "$AI_USB_ROOT\notes"
$LOGS_DIR    = "$AI_USB_ROOT\logs"
$STUDY_DIR   = "$AI_USB_ROOT\study"

if (-not (Test-Path $CONFIG_FILE)) {
    Write-Host "  ERROR: settings.json not found. Run AI_USB_setup.ps1 first." -ForegroundColor Red
    pause; exit 1
}
$cfg = Get-Content $CONFIG_FILE -Raw | ConvertFrom-Json

$threads = $cfg.threads
if ($threads -le 0) {
    $threads = (Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue).NumberOfLogicalProcessors
    if (-not $threads) { $threads = 4 }
}

# ══════════════════════════════════════════
#  COLOUR PALETTE  (single place to change)
# ══════════════════════════════════════════
# Border / chrome       → DarkBlue
# Header title text     → Cyan
# Subtitle / page name  → White
# Section labels        → Yellow
# Body text / options   → White
# Dim / metadata        → DarkGray
# Success               → Green
# Warning               → Yellow
# Error                 → Red
# Prompt arrows         → Cyan (You) / Green (AI)

# ══════════════════════════════════════════
#  UI HELPERS
# ══════════════════════════════════════════
$W = 55   # inner width of the box (between the vertical bars)

function Show-Header {
    param([string]$Page = "")
    Clear-Host
    $top    = "═" * $W
    $blank  = " " * $W
    $title  = " AI  USB  TOOLKIT "
    $tPad   = $title.PadLeft([math]::Floor(($W + $title.Length) / 2)).PadRight($W)

    Write-Host ""
    Write-Host "  ╔$top╗"         -ForegroundColor DarkBlue
    Write-Host "  ║$tPad║"        -ForegroundColor Cyan
    if ($Page) {
        $pLine = " $Page "
        $pPad  = $pLine.PadLeft([math]::Floor(($W + $pLine.Length) / 2)).PadRight($W)
        Write-Host "  ║$pPad║"    -ForegroundColor White
    } else {
        Write-Host "  ║$blank║"   -ForegroundColor DarkBlue
    }
    Write-Host "  ╚$top╝"         -ForegroundColor DarkBlue
    Write-Host ""
}

function Show-Info {
    # Single-line info bar shown on most screens
    param([string]$Runtime = "", [string]$Model = "")
    $drive   = $USB_ROOT
    $modShow = if ($Model.Length -gt 28) { $Model.Substring(0,25) + "..." } else { $Model }
    $line1   = "  Drive : $drive   Threads : $threads   CTX : $($cfg.ctx)"
    Write-Host $line1 -ForegroundColor DarkGray
    if ($Runtime -or $Model) {
        Write-Host "  Engine: $Runtime   Model: $modShow" -ForegroundColor DarkGray
    }
    Write-Host ("  " + ("─" * 51)) -ForegroundColor DarkBlue
    Write-Host ""
}

function Write-MenuLine {
    # Numbered option: key in Yellow, text in White
    param([string]$Key, [string]$Label, [string]$Dim = "")
    Write-Host "    " -NoNewline
    Write-Host "[$Key]" -NoNewline -ForegroundColor Yellow
    Write-Host "  $Label" -NoNewline -ForegroundColor White
    if ($Dim) { Write-Host "  $Dim" -NoNewline -ForegroundColor DarkGray }
    Write-Host ""
}

function Write-Divider  { Write-Host ("  " + ("─" * 51)) -ForegroundColor DarkBlue }
function Write-OK       { param([string]$M); Write-Host "  ✓  $M" -ForegroundColor Green }
function Write-Warn     { param([string]$M); Write-Host "  !  $M" -ForegroundColor Yellow }
function Write-Err      { param([string]$M); Write-Host "  ✗  $M" -ForegroundColor Red }
function Write-Dim      { param([string]$M); Write-Host "     $M" -ForegroundColor DarkGray }

function Write-SectionTitle {
    param([string]$Title)
    Write-Host "  $Title" -ForegroundColor Yellow
    Write-Divider
    Write-Host ""
}

function Show-Spinner {
    param([string]$Label, [int]$Ms = 1200)
    $frames = @("|","/"," -","\")
    $end    = (Get-Date).AddMilliseconds($Ms)
    $i      = 0
    while ((Get-Date) -lt $end) {
        Write-Host "`r  $($frames[$i % 4])  $Label  " -NoNewline -ForegroundColor Cyan
        Start-Sleep -Milliseconds 100
        $i++
    }
    Write-Host "`r" -NoNewline
    Write-OK $Label
}

# ══════════════════════════════════════════
#  FILE PICKER  (Windows dialog, fallback to typed path)
# ══════════════════════════════════════════
function Pick-File {
    param(
        [string]$Title      = "Select a file",
        [string]$Filter     = "Text Files (*.txt)|*.txt|All Files (*.*)|*.*",
        [string]$InitialDir = $env:USERPROFILE
    )
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        $dlg = New-Object System.Windows.Forms.OpenFileDialog
        $dlg.Title            = $Title
        $dlg.Filter           = $Filter
        $dlg.InitialDirectory = $InitialDir
        $dlg.Multiselect      = $false
        if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { return $dlg.FileName }
        return $null
    } catch {
        Write-Warn "GUI picker unavailable — type the path below."
        $typed = (Read-Host "  Path (or drag-and-drop)").Trim('"')
        if (Test-Path $typed) { return $typed }
        Write-Err "Not found: $typed"
        return $null
    }
}

# ══════════════════════════════════════════
#  STUDY FILE BROWSER
# ══════════════════════════════════════════
function Pick-StudyFile {
    $files = @(Get-ChildItem -Path $STUDY_DIR -Filter "*.txt" -ErrorAction SilentlyContinue |
               Where-Object { $_.Length -gt 30 })

    Show-Header "FLASHCARDS — SELECT FILE"
    Show-Info

    Write-SectionTitle "Files in study\"
    if ($files.Count -eq 0) {
        Write-Warn "No .txt files found in study\   Add a file or use Browse."
        Write-Host ""
    } else {
        for ($i = 0; $i -lt $files.Count; $i++) {
            $kb = [math]::Round($files[$i].Length / 1KB, 1)
            Write-Host ("    ") -NoNewline
            Write-Host ("[{0}]" -f ($i+1)) -NoNewline -ForegroundColor Yellow
            Write-Host ("  {0,-38}" -f $files[$i].Name) -NoNewline -ForegroundColor White
            Write-Host ("{0,5} KB" -f $kb) -ForegroundColor DarkGray
        }
        Write-Host ""
    }

    Write-MenuLine "B" "Browse filesystem"
    Write-MenuLine "S" "Search by filename"
    Write-Host ""
    $pick = Read-Host "  Choice"

    if ($pick -match '^[Bb]$') { return Pick-File -Title "Select study file" -InitialDir $STUDY_DIR }

    if ($pick -match '^[Ss]$') {
        $q = Read-Host "  Search term"
        $hits = @(Get-ChildItem -Path $STUDY_DIR -Filter "*$q*.txt" -Recurse -ErrorAction SilentlyContinue)
        if ($hits.Count -eq 0) { Write-Warn "No matches."; return $null }
        Write-Host ""
        for ($i = 0; $i -lt $hits.Count; $i++) {
            Write-Host "    " -NoNewline
            Write-Host "[$($i+1)]" -NoNewline -ForegroundColor Yellow
            Write-Host "  $($hits[$i].FullName)" -ForegroundColor White
        }
        Write-Host ""
        $idx = Read-Host "  Pick number"
        if ($idx -match '^\d+$' -and [int]$idx -ge 1 -and [int]$idx -le $hits.Count) {
            return $hits[[int]$idx - 1].FullName
        }
        return $null
    }

    if ($pick -match '^\d+$' -and [int]$pick -ge 1 -and [int]$pick -le $files.Count) {
        return $files[[int]$pick - 1].FullName
    }
    return $null
}

# ══════════════════════════════════════════
#  RUNTIME DETECTION
# ══════════════════════════════════════════
function Resolve-Runtime { param([string]$Key); return Join-Path $AI_USB_ROOT $cfg.runtime_paths.$Key }
function Get-ModelList   { param([string]$Dir);  return @(Get-ChildItem (Join-Path $Dir "models") -Filter "*.gguf" -ErrorAction SilentlyContinue) }

$llamaDir = Resolve-Runtime "llama"
$gemmaDir = Resolve-Runtime "gemma"
$llamaExe = Join-Path $llamaDir "llama-cli.exe"
if (-not (Test-Path $llamaExe)) { $llamaExe = Join-Path $llamaDir "main.exe" }
$gemmaExe = Join-Path $gemmaDir "gemma.exe"

$runtimes = @()
if (Test-Path $llamaExe) { $runtimes += "llama" }
if (Test-Path $gemmaExe) { $runtimes += "gemma" }

# ══════════════════════════════════════════
#  SCREEN 1 — SELECT ENGINE
# ══════════════════════════════════════════
Show-Header "SELECT ENGINE"
Show-Info

if ($runtimes.Count -eq 0) {
    Write-Err "No runtime executables found."
    Write-Dim "Place llama-cli.exe in:  $llamaDir"
    Write-Dim "Or gemma.exe in:         $gemmaDir"
    Write-Host ""
    pause; exit 1
}

$activeRuntime = $runtimes[0]
if ($runtimes.Count -gt 1) {
    Write-SectionTitle "Available Engines"
    for ($i = 0; $i -lt $runtimes.Count; $i++) {
        Write-MenuLine ($i+1) $runtimes[$i]
    }
    Write-Host ""
    $pick = Read-Host "  Choose engine (default=1)"
    if ($pick -match '^\d+$' -and [int]$pick -ge 1 -and [int]$pick -le $runtimes.Count) {
        $activeRuntime = $runtimes[[int]$pick - 1]
    }
} else {
    Write-OK "Engine: $activeRuntime"
    Write-Host ""
}

# ══════════════════════════════════════════
#  SCREEN 2 — SELECT MODEL
# ══════════════════════════════════════════
$runtimeDir = if ($activeRuntime -eq "llama") { $llamaDir } else { $gemmaDir }
$runtimeExe = if ($activeRuntime -eq "llama") { $llamaExe } else { $gemmaExe }
$models     = Get-ModelList -Dir $runtimeDir

if ($models.Count -eq 0) {
    Show-Header "NO MODEL FOUND"
    Write-Err "No .gguf model in:  $runtimeDir\models\"
    Write-Dim "Drop a .gguf file there and relaunch."
    Write-Host ""
    pause; exit 1
}

Show-Header "SELECT MODEL"
Show-Info -Runtime $activeRuntime

$modelPath  = $null
$defaultIdx = 0

if ($models.Count -eq 1) {
    $modelPath = $models[0].FullName
    Write-OK "Only one model found — auto-selected:"
    Write-Dim $models[0].Name
    Write-Host ""
} else {
    Write-SectionTitle "Available Models"
    for ($i = 0; $i -lt $models.Count; $i++) {
        if ($models[$i].Name -eq $cfg.default_model) { $defaultIdx = $i }
        $gb  = "{0:N2} GB" -f ($models[$i].Length / 1GB)
        $tag = if ($models[$i].Name -eq $cfg.default_model) { "(default)" } else { "" }
        Write-Host "    " -NoNewline
        Write-Host "[$($i+1)]" -NoNewline -ForegroundColor Yellow
        Write-Host ("  {0,-42}" -f $models[$i].Name) -NoNewline -ForegroundColor White
        Write-Host ("{0,7}  {1}" -f $gb, $tag) -ForegroundColor DarkGray
    }
    Write-Host ""
    $pick = Read-Host "  Choose model (default=$($defaultIdx+1))"
    $chosenIdx = $defaultIdx
    if ($pick -match '^\d+$' -and [int]$pick -ge 1 -and [int]$pick -le $models.Count) {
        $chosenIdx = [int]$pick - 1
    }
    $modelPath = $models[$chosenIdx].FullName
}

# ══════════════════════════════════════════
#  SCREEN 3 — CONFIRM & LOAD
# ══════════════════════════════════════════
$modelLeaf = Split-Path $modelPath -Leaf

Show-Header "CONFIRM"
Show-Info -Runtime $activeRuntime -Model $modelLeaf

Write-SectionTitle "Ready to Load"
Write-Host "    Engine  :  $activeRuntime"  -ForegroundColor White
Write-Host "    Model   :  $modelLeaf"       -ForegroundColor White
Write-Host ""
$confirm = Read-Host "  Load now? (Y/n)"
if ($confirm -match '^[nN]') {
    Write-Dim "Cancelled."
    Start-Sleep -Milliseconds 500
    exit 0
}

Show-Header "LOADING"
Show-Spinner "Initialising $activeRuntime" -Ms 1400
Show-Spinner "Loading model weights" -Ms 1100
Write-Host ""

# ══════════════════════════════════════════
#  SESSION SETUP
# ══════════════════════════════════════════
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile   = "$LOGS_DIR\session_$timestamp.txt"
$noteFile  = "$NOTES_DIR\chat_$timestamp.txt"

# ══════════════════════════════════════════
#  SAVE HELPER  — writes full transcript to Notes
# ══════════════════════════════════════════
function Save-ChatTranscript {
    param([string]$TranscriptPath, [string[]]$FallbackLines)
    Write-Host ""
    Write-Divider
    $save = Read-Host "  Save this chat to Notes? (Y/n)"
    Write-Divider
    if ($save -match '^[nN]') {
        Write-Dim "Chat not saved."
        return
    }

    $header = @(
        "═══════════════════════════════════════════════════════",
        "  AI USB Toolkit — Chat Transcript",
        "  Date    : $(Get-Date -Format 'yyyy-MM-dd  HH:mm:ss')",
        "  Engine  : $activeRuntime",
        "  Model   : $modelLeaf",
        "═══════════════════════════════════════════════════════",
        ""
    )

    if ($TranscriptPath -and (Test-Path $TranscriptPath)) {
        # Read the raw PowerShell transcript, strip the PS header/footer lines,
        # keep only the lines from our chat marker onward.
        $raw   = Get-Content $TranscriptPath -Encoding UTF8
        $start = 0
        for ($i = 0; $i -lt $raw.Count; $i++) {
            if ($raw[$i] -match "CHAT_SESSION_START") { $start = $i + 1; break }
        }
        $chatLines = $raw[$start..($raw.Count - 1)] |
                     Where-Object { $_ -notmatch "^\*\*\*\*\*" }   # strip PS transcript chrome
        $output = $header + $chatLines
    } else {
        # Fallback: use the in-memory lines we captured
        $output = $header + $FallbackLines
    }

    $output | Set-Content -Path $noteFile  -Encoding UTF8
    Copy-Item  $noteFile "$NOTES_DIR\last_chat.txt" -Force
    Write-Host ""
    Write-OK "Chat saved to:  notes\chat_$timestamp.txt"
}

# ══════════════════════════════════════════
#  LLAMA ARG BUILDER
# ══════════════════════════════════════════
function Test-LlamaSupportsConv {
    param([string]$Exe)
    try {
        $h = & $Exe --help 2>&1 | Out-String
        return ($h -match '-cnv' -or $h -match '--conversation')
    } catch { return $true }
}

function Get-LlamaArgs {
    param([string]$Prompt, [switch]$Interactive, [bool]$UseConv = $true)
    $a = @("-m", $modelPath, "-t", $threads, "-c", $cfg.ctx,
           "--temp", $cfg.temperature, "--top-p", $cfg.top_p)
    if ($Interactive) {
        if ($UseConv) {
            $a += "-cnv"
            $a += "-p", $Prompt
        } else {
            $a += "-i", "--interactive-first", "--color", "-r", "User:", "-p", $Prompt
        }
    } else {
        $a += "-p", $Prompt, "-n", "512"
    }
    return $a
}

# ══════════════════════════════════════════
#  SCREEN 4 — MAIN MENU
# ══════════════════════════════════════════
Show-Header "MAIN MENU"
Show-Info -Runtime $activeRuntime -Model $modelLeaf

Write-SectionTitle "Choose an action"
Write-MenuLine "1" "Interactive Chat"
Write-MenuLine "2" "Summarise a file"
Write-MenuLine "3" "Generate flashcards from a study file"
Write-MenuLine "4" "Exit"
Write-Host ""
$choice = Read-Host "  Choice"

# ══════════════════════════════════════════
#  [1]  INTERACTIVE CHAT
# ══════════════════════════════════════════
if ($choice -eq "1") {

    # ── Optional pre-chat file inject ──────
    Show-Header "INTERACTIVE CHAT"
    Show-Info -Runtime $activeRuntime -Model $modelLeaf
    Write-SectionTitle "Load a context file? (optional)"
    Write-MenuLine "1" "Yes — pick a .txt file to discuss"
    Write-MenuLine "2" "No  — start chat without context"
    Write-Host ""
    $injectChoice = Read-Host "  Choice"

    $systemPrompt = "You are a helpful offline AI assistant."

    if ($injectChoice -eq "1") {
        $injectPath = Pick-File -Title "Select context file" -InitialDir $AI_USB_ROOT
        if ($injectPath -and (Test-Path $injectPath)) {
            $injectContent = Get-Content $injectPath -Raw -Encoding UTF8
            if ($injectContent.Length -gt 6000) { $injectContent = $injectContent.Substring(0,6000) }
            $fname = Split-Path $injectPath -Leaf
            $systemPrompt  = "You are a helpful offline AI assistant. " +
                             "The user has loaded the following document — refer to it when answering.`n`n" +
                             "--- BEGIN: $fname ---`n$injectContent`n--- END: $fname ---"
            Write-Host ""
            Write-OK "Context loaded: $fname"
            Start-Sleep -Milliseconds 700
        } else {
            Write-Warn "No file selected. Starting without context."
            Start-Sleep -Milliseconds 500
        }
    }

    # ── Chat screen ─────────────────────────
    Show-Header "INTERACTIVE CHAT"
    Show-Info -Runtime $activeRuntime -Model $modelLeaf
    Write-Host "  Commands:  " -NoNewline -ForegroundColor DarkGray
    Write-Host "/exit" -NoNewline -ForegroundColor Yellow
    Write-Host "  to quit     " -NoNewline -ForegroundColor DarkGray
    Write-Host "/inject" -NoNewline -ForegroundColor Yellow
    Write-Host "  to load a file mid-chat" -ForegroundColor DarkGray
    Write-Divider
    Write-Host ""

    # ── Transcript capture for llama ────────
    $transcriptFile = "$LOGS_DIR\transcript_$timestamp.txt"
    $inMemoryLines  = @()

    if ($activeRuntime -eq "llama") {
        # Start-Transcript captures everything printed to the console,
        # including llama-cli's own output, so we get the full exchange.
        $null = Start-Transcript -Path $transcriptFile -Force -ErrorAction SilentlyContinue
        Write-Host "CHAT_SESSION_START" | Out-Null   # marker we search for later
        # Write marker directly to transcript file by outputting to host
        Write-Output "CHAT_SESSION_START" > $null
        # Simpler: write marker as a comment line the transcript will capture
        Write-Host "# CHAT_SESSION_START" -ForegroundColor Black  # invisible on most themes

        $useConv   = Test-LlamaSupportsConv -Exe $runtimeExe
        $llamaArgs = Get-LlamaArgs -Interactive -Prompt $systemPrompt -UseConv $useConv
        & $runtimeExe @llamaArgs

        $null = Stop-Transcript -ErrorAction SilentlyContinue
        Save-ChatTranscript -TranscriptPath $transcriptFile -FallbackLines $inMemoryLines

    } else {
        # Gemma: we run our own loop so we capture every line directly
        $running     = $true
        $contextNote = ""
        while ($running) {
            Write-Host ""
            Write-Host "  You  " -NoNewline -ForegroundColor Cyan
            Write-Host "› " -NoNewline -ForegroundColor DarkGray
            $userInput = Read-Host

            if ($userInput -eq "/exit") { $running = $false; break }

            if ($userInput -eq "/inject") {
                $ip = Pick-File -Title "Select file to inject" -InitialDir $AI_USB_ROOT
                if ($ip -and (Test-Path $ip)) {
                    $extra = Get-Content $ip -Raw -Encoding UTF8
                    if ($extra.Length -gt 4000) { $extra = $extra.Substring(0,4000) }
                    $contextNote = "[Injected file — $(Split-Path $ip -Leaf)]: $extra"
                    Write-OK "Injected: $(Split-Path $ip -Leaf)"
                    $inMemoryLines += "--- File injected: $(Split-Path $ip -Leaf) ---"
                } else {
                    Write-Warn "No file selected."
                }
                continue
            }

            $fullPrompt = if ($contextNote) { "$contextNote`n`nUser: $userInput" } else { $userInput }
            $inMemoryLines += "You:  $userInput"

            $response = & $runtimeExe --model $modelPath --prompt $fullPrompt --max_tokens 512 2>&1
            $responseText = ($response -join " ").Trim()

            Write-Host ""
            Write-Host "  AI   " -NoNewline -ForegroundColor Green
            Write-Host "› " -NoNewline -ForegroundColor DarkGray
            Write-Host $responseText -ForegroundColor White
            $inMemoryLines += "AI:   $responseText"
            $inMemoryLines += ""
        }

        Save-ChatTranscript -TranscriptPath "" -FallbackLines $inMemoryLines
    }
}

# ══════════════════════════════════════════
#  [2]  SUMMARISE
# ══════════════════════════════════════════
elseif ($choice -eq "2") {
    Show-Header "SUMMARISE A FILE"
    Show-Info -Runtime $activeRuntime -Model $modelLeaf
    Write-SectionTitle "Select a file to summarise"
    Write-Dim "A file browser window will open."
    Write-Host ""

    $filePath = Pick-File -Title "Select file to summarise" `
                          -Filter "Text Files (*.txt)|*.txt|All Files (*.*)|*.*" `
                          -InitialDir $USB_ROOT

    if (-not $filePath) {
        Write-Warn "No file selected."
    } else {
        $content = Get-Content $filePath -Raw -Encoding UTF8
        if ($content.Length -gt 3000) { $content = $content.Substring(0,3000) }
        $prompt  = "Summarise the following text concisely:`n`n$content"

        Write-Host ""
        Show-Spinner "Summarising  $(Split-Path $filePath -Leaf)" -Ms 700

        if ($activeRuntime -eq "llama") {
            $result = & $runtimeExe @(Get-LlamaArgs -Prompt $prompt) 2>&1
        } else {
            $result = & $runtimeExe --model $modelPath --prompt $prompt --max_tokens 512 2>&1
        }

        Write-Host ""
        Write-Divider
        Write-Host "  SUMMARY" -ForegroundColor Yellow
        Write-Divider
        Write-Host ""
        $result | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
        Write-Host ""
        Write-Divider

        $outFile = "$NOTES_DIR\summary_$timestamp.txt"
        $result | Set-Content -Path $outFile -Encoding UTF8
        Write-Host ""
        Write-OK "Saved  →  notes\summary_$timestamp.txt"
    }
}

# ══════════════════════════════════════════
#  [3]  FLASHCARDS
# ══════════════════════════════════════════
elseif ($choice -eq "3") {
    $inputFile = Pick-StudyFile

    if (-not $inputFile) {
        Show-Header "FLASHCARDS"
        Write-Warn "No file selected."
    } else {
        $content = Get-Content $inputFile -Raw -Encoding UTF8
        if ($content.Length -gt 3000) { $content = $content.Substring(0,3000) }
        $prompt  = "Create 10 question-and-answer flashcards from this text. " +
                   "Format each as:`nQ: <question>`nA: <answer>`n`n$content"

        Show-Header "GENERATING FLASHCARDS"
        Show-Info -Runtime $activeRuntime -Model $modelLeaf
        Show-Spinner "Reading  $(Split-Path $inputFile -Leaf)" -Ms 600
        Show-Spinner "Generating flashcards" -Ms 900
        Write-Host ""

        if ($activeRuntime -eq "llama") {
            $result = & $runtimeExe @(Get-LlamaArgs -Prompt $prompt) 2>&1
        } else {
            $result = & $runtimeExe --model $modelPath --prompt $prompt --max_tokens 512 2>&1
        }

        Write-Divider
        Write-Host "  FLASHCARDS" -ForegroundColor Yellow
        Write-Divider
        Write-Host ""
        $result | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
        Write-Host ""
        Write-Divider

        $outFile = "$STUDY_DIR\flashcards_$timestamp.txt"
        $result | Set-Content -Path $outFile -Encoding UTF8
        Write-Host ""
        Write-OK "Saved  →  study\flashcards_$timestamp.txt"
    }
}

# ══════════════════════════════════════════
#  [4]  EXIT
# ══════════════════════════════════════════
else {
    Show-Header "GOODBYE"
    Write-Host ""
    Write-Dim "Session ended.  Safe to unplug."
    Write-Host ""
}

Write-Host ""
pause
'@
Set-Content -Path $launcherPath -Value $launcherContent -Encoding UTF8
Write-Status "Written: scripts\ai_usb_launcher.ps1"

# ---- Write Run_Toolkit.bat ----
$batPath = "$USB_ROOT\Run_Toolkit.bat"
$batContent = @'
@echo off
set "USB_ROOT=%~dp0"
title AI USB Toolkit

:: Check PowerShell availability
where powershell >nul 2>&1
if errorlevel 1 (
    echo [ERROR] PowerShell not found on this system.
    pause
    exit /b 1
)

:: Launch the main script
powershell -NoProfile -ExecutionPolicy Bypass -File "%USB_ROOT%AI_USB\scripts\ai_usb_launcher.ps1"

pause
'@
Set-Content -Path $batPath -Value $batContent -Encoding ASCII
Write-Status "Written: Run_Toolkit.bat (USB root)"

# ---- Write Powershell_Command.txt ----
$cmdTxtPath = "$USB_ROOT\Powershell_Command.txt"
$cmdContent = @'
# Run this in PowerShell if double-clicking Run_Toolkit.bat is blocked:
# (Replace E: with your USB drive letter)

PowerShell -NoProfile -ExecutionPolicy Bypass -File "E:\AI_USB\scripts\ai_usb_launcher.ps1"

# --- FIRST TIME SETUP (run once) ---
PowerShell -NoProfile -ExecutionPolicy Bypass -File "E:\AI_USB_setup.ps1"
'@
Set-Content -Path $cmdTxtPath -Value $cmdContent -Encoding UTF8
Write-Status "Written: Powershell_Command.txt"

Write-Host ""
Write-Host "  =============================================" -ForegroundColor Green
Write-Host "  Setup complete!  Skeleton created in:" -ForegroundColor Green
Write-Host "  $TARGET_DIR" -ForegroundColor White
Write-Host ""
Write-Host "  NEXT STEPS:" -ForegroundColor Cyan
Write-Host "  1. Download a GGUF model (e.g. mistral-7b-q4_k_m.gguf)"
Write-Host "  2. Place it in: AI_USB\runtimes\llama.cpp\models\"
Write-Host "  3. Download llama-cli.exe and place it in: AI_USB\runtimes\llama.cpp\"
Write-Host "     (Get it from: https://github.com/ggerganov/llama.cpp/releases)"
Write-Host "  4. Double-click Run_Toolkit.bat"
Write-Host "  =============================================" -ForegroundColor Green
Write-Host ""
