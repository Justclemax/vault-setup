#Requires -Version 5.1
# ════════════════════════════════════════════════════════════════════
#  vault-setup.ps1  —  Universal Vault installer for Windows
#  Language : English · Français
#  Modes    : Development · Production
#  Version  : 2.0.0
#
#  Usage:
#    PowerShell -ExecutionPolicy Bypass -File vault-setup.ps1
#    PowerShell -ExecutionPolicy Bypass -File vault-setup.ps1 -Uninstall
# ════════════════════════════════════════════════════════════════════

param([switch]$Uninstall)

$VERSION       = "2.0.0"
$SECURE_DIR    = "$env:USERPROFILE\.vault-secure"
$VAULT_LOG     = "$env:TEMP\vault-setup.log"
$CADDY_LOG     = "$env:TEMP\caddy-setup.log"
$NTFY_LOG      = "$env:TEMP\ntfy-setup.log"
$VAULT_PORT    = 8200
$CADDY_PORT    = 443
$NTFY_PORT     = 2586
$VAULT_DOMAIN  = "vault.local"
$HOSTS_FILE    = "C:\Windows\System32\drivers\etc\hosts"

# ── Require Administrator ──────────────────────────────────────────
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    $args = if ($Uninstall) { "-Uninstall" } else { "" }
    Start-Process PowerShell -Verb RunAs "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $args"
    Exit
}

# ── Output helpers ─────────────────────────────────────────────────
function ok($m)   { Write-Host "  [OK] $m" -ForegroundColor Green }
function warn($m) { Write-Host "  [!!] $m" -ForegroundColor Yellow }
function err($m)  { Write-Host "  [XX] $m" -ForegroundColor Red; Exit 1 }
function info($m) { Write-Host "  [..] $m" -ForegroundColor Cyan }

function title($m) {
    $line = "─" * 62
    Write-Host ""
    Write-Host "  ┌$line┐" -ForegroundColor Cyan
    Write-Host "  │  $m" -ForegroundColor White
    Write-Host "  └$line┘" -ForegroundColor Cyan
}

$STEP_N = 0
function step($m) {
    $script:STEP_N++
    Write-Host ""
    Write-Host "  [$($script:STEP_N)] $m" -ForegroundColor White -BackgroundColor DarkBlue
}

# ════════════════════════════════════════════════════════════════════
# LANGUAGE
# ════════════════════════════════════════════════════════════════════
$LANG = "en"

function Select-Language {
    Write-Host ""
    Write-Host "  ┌────────────────────────────────┐"
    Write-Host "  │  Language / Langue             │"
    Write-Host "  │  1) English                    │"
    Write-Host "  │  2) Français                   │"
    Write-Host "  └────────────────────────────────┘"
    $c = Read-Host "  > "
    if ($c -eq "2") { $script:LANG = "fr" } else { $script:LANG = "en" }
}

function T($key) {
    $t = @{
        mode_title    = @{ en = "Installation mode";                              fr = "Mode d'installation" }
        mode_dev      = @{ en = "1) Development  — quick, data lost on restart";  fr = "1) Développement — rapide, données perdues au redémarrage" }
        mode_prod     = @{ en = "2) Production   — persistent data, auto-start";  fr = "2) Production    — données persistantes, service automatique" }
        notif_title   = @{ en = "Notification method";                            fr = "Mode de notification" }
        notif_1       = @{ en = "1) ntfy  (mobile app)";                          fr = "1) ntfy  (app mobile)" }
        notif_2       = @{ en = "2) Email (Outlook)";                             fr = "2) Email (Outlook)" }
        notif_3       = @{ en = "3) Both";                                        fr = "3) Les deux" }
        notif_4       = @{ en = "4) None  (screen only)";                         fr = "4) Aucune (écran uniquement)" }
        deps_check    = @{ en = "Checking dependencies...";                        fr = "Vérification des dépendances..." }
        deps_missing  = @{ en = "Missing packages:";                              fr = "Paquets manquants :" }
        deps_auto_q   = @{ en = "Auto-install? [Y/n]";                            fr = "Installer automatiquement ? [O/n]" }
        deps_ok       = @{ en = "All dependencies present";                        fr = "Toutes les dépendances sont présentes" }
        domain_q      = @{ en = "Vault domain [vault.local]: ";                   fr = "Domaine Vault [vault.local] : " }
        email_q       = @{ en = "Recipient email: ";                              fr = "Email du destinataire : " }
        vault_ok      = @{ en = "Vault running";                                  fr = "Vault démarré" }
        caddy_ok      = @{ en = "Caddy running";                                  fr = "Caddy démarré" }
        svc_done      = @{ en = "Task scheduled — Vault starts at boot";           fr = "Tâche planifiée — Vault démarre au boot" }
        unseal_warn   = @{ en = "Save these keys — required to unseal after restart!"; fr = "Sauvegardez ces clés ! Requises pour déverrouiller après redémarrage !" }
        uninstall_w   = @{ en = "UNINSTALL — removes Vault, Caddy, ntfy and all data."; fr = "DÉSINSTALLATION — supprime Vault, Caddy, ntfy et toutes les données." }
        uninstall_q   = @{ en = "Type 'yes' to confirm: ";                        fr = "Tapez 'oui' pour confirmer : " }
        ntfy_first    = @{ en = "FIRST-TIME ntfy SETUP";                          fr = "PREMIÈRE CONFIGURATION ntfy" }
    }
    if ($t.ContainsKey($key)) { return $t[$key][$script:LANG] }
    return $key
}

# ════════════════════════════════════════════════════════════════════
# ASCII BANNER
# ════════════════════════════════════════════════════════════════════
function Show-Banner {
    Clear-Host
    $c = "Cyan"
    try { [Console]::CursorVisible = $false } catch {}
    $W = $Host.UI.RawUI.WindowSize.Width
    Write-Host ""

    # ── Naruto court à travers l'écran ────────────────────────────
    $frames = @(
        @("  _o>","  /|_",">>|  ","  / \","_/   "),
        @("  _o>","  /|_",">>|  "," _/\ ","     "),
        @("  _o>","  /|_",">>|  ","  /\ ","  \  "),
        @("  _o>","  /|_",">>|  ","  /  ","_/ \ ")
    )
    for ($i = 0; $i -lt 5; $i++) { Write-Host "" }
    $p = 0; $fi = 0
    while ($p -lt ($W - 14)) {
        $esc = [char]27
        Write-Host -NoNewline "${esc}[5A"
        $pad = " " * $p
        $frame = $frames[$fi % 4]
        foreach ($ln in $frame) {
            Write-Host "${esc}[2K${pad}${ln}" -ForegroundColor $c
        }
        Start-Sleep -Milliseconds 50
        $p += 3; $fi++
    }
    # Effacer les 5 lignes d'animation
    $esc = [char]27
    Write-Host -NoNewline "${esc}[5A"
    for ($i = 0; $i -lt 5; $i++) { Write-Host "${esc}[2K" }
    Write-Host -NoNewline "${esc}[5A"
    Start-Sleep -Milliseconds 150

    # ── Art Braille ligne par ligne ────────────────────────────────
    $art = @(
        "⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠻⣿⣿⣿⣿⣿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿",
        "⣿⣿⣿⣿⣿⣿⣏⢩⣛⠿⢿⢰⡙⣿⢟⣯⡞⣼⣿⣿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿",
        "⣿⣿⣿⠿⠿⠿⠿⠆⣿⣿⣦⣼⣷⣶⣿⣿⣧⣽⣶⢇⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿",
        "⣿⣿⣿⣷⣌⠻⣿⣿⣿⣿⣿⣿⣿⡿⣿⣿⣿⣿⣿⡶⢟⣭⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿",
        "⣿⣿⡿⠟⣡⣶⣿⣿⡿⠋⢉⣠⣤⣄⠈⢿⡟⢯⢿⣷⣯⣛⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠿⠛⠉⠉⠁⠀⠀⠀⠀⠹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿",
        "⡿⠋⢴⣿⣿⣿⣿⠋⣠⣎⢿⣿⣿⡿⠇⢀⣙⠀⠁⠙⣏⢿⣾⣿⣿⣿⣿⢟⣝⠿⠟⠋⠁⠀⠀⠀⠀⢀⣀⣀⣀⣤⣤⣤⣈⣻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿",
        "⣿⣿⣶⢆⣽⣿⡟⣺⣿⣇⠿⣋⡵⣴⣿⠿⣿⣿⣷⣤⣨⢎⠛⠛⠛⠛⠋⢸⣿⣧⠀⢀⣠⣤⣶⣾⣿⣿⠟⠻⠿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿",
        "⣿⡿⢣⣾⢿⣿⡇⠹⠿⢣⣾⣿⣿⣿⣴⣿⡿⢋⣵⣶⠇⣼⣰⣤⣤⣤⣤⢸⣿⣿⡏⣿⣿⣿⣿⠟⠉⠀⠀⢀⣤⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿",
        "⣿⣿⣿⣿⡿⠙⡇⠀⣼⢫⠚⢿⣿⣿⣿⣿⣿⡿⣏⣥⣷⣿⣻⣿⣿⣿⣿⣼⣿⣿⣧⡿⠟⠋⠀⠀⣀⣴⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿",
        "⣿⣿⣿⣿⣿⠀⣄⣄⡳⣶⣶⣿⣿⣿⡿⢋⠴⢛⠘⣿⣹⡴⣏⠙⠛⠛⠛⢻⣿⣿⣿⠀⢀⣠⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿",
        "⣿⣿⣿⣿⣿⣿⣿⣿⣏⣍⢋⣼⣿⠋⠔⠉⢋⣴⣾⣿⣿⡗⠀⢰⣶⡦⡔⡂⣿⣿⣿⡈⠉⠻⠿⠛⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿",
        "⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣞⢡⢾⠶⣶⣮⣶⣿⣿⠟⠋⠀⠀⠈⠱⢞⣭⠌⣿⣿⣿⣇⣤⣶⣶⡄⣠⣼⡻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿",
        "⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⡬⢿⡿⠿⠛⠁⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣧⣿⣿⣿⣧⢻⣿⣿⡼⣶⣝⡻⠿⠟⠛⠛⠛⠋⠉⠉⠉⠉⠉⠉⠉⢉⣉⣥⣾",
        "⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⠀⠀⠀⡄⠀⠀⠀⠀⠀⠀⠀⠀⢠⣾⣿⣿⣿⣮⡸⣿⣿⣿⣯⢿⣿⣷⣹⣿⣿⠇⠀⣀⣤⣤⣤⣶⣶⠶⢛⣩⣵⣾⣿⣿⣿⣿",
        "⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠁⠀⠀⠰⠀⠀⠀⠀⠀⠀⠀⢰⣿⣿⣿⠿⠿⠿⠷⢹⣿⣿⣿⢺⣿⣿⢇⣿⡏⠀⠀⠘⠿⠛⣋⣥⣴⣾⣿⣿⣿⣿⣿⣿⣿⣿",
        "⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠋⠀⠀⠀⢿⣿⣶⣶⠦⣔⣒⣒⣒⡛⣭⠋⡭⡁⣶⣷⢷⢸⣿⣿⡿⣾⣿⠏⢾⠏⣾⣶⣶⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿",
        "⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠁⠀⠀⠀⠀⠀⠀⢛⣭⣶⣯⣹⣿⠟⣻⣿⢰⢟⣀⣣⣭⣼⣆⢿⡿⢟⣹⢿⣫⣾⠗⢁⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿",
        "⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⡾⢿⣷⣶⣶⠶⠿⢛⣭⡲⢾⣿⣿⣿⣿⣿⣾⡷⠗⠚⠛⠛⠁⢠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿",
        "⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⢀⠁⠀⠀⠀⠀⠀⣠⠟⣵⣿⣆⠉⠙⠛⠛⠛⠉⠀⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿",
        "⣿⣿⣿⣿⣿⣿⣿⣿⣿⡆⠀⣀⠀⠀⠀⠀⢸⠀⠀⠀⢀⣴⣿⢫⣾⣿⣿⣿⣷⣦⣄⣀⣀⠀⠀⠀⠀⢠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿",
        "⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⣿⣿⣶⡆⠀⠈⠀⠀⠀⢸⣿⣷⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠇⣶⡆⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿",
        "⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠀⣿⣿⣿⠇⠀⡘⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⣰⣿⡇⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿",
        "⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣄⣿⣿⣿⠀⢰⠁⠀⠀⢸⣿⣿⣿⣿⣿⡿⣿⣿⣿⣿⣿⣿⡿⢡⣿⣿⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿",
        "⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣸⣿⣿⣿⠀⡈⠀⠀⠀⢸⣿⣿⣿⠟⢋⣼⣿⣿⣿⣿⣿⣿⢣⣿⣿⣿⠀⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿",
        "⣿⣿⣿⣿⣿⣿⣿⣿⣿⣇⣿⣿⣿⡟⠀⡇⠀⠀⠀⠸⠟⠋⢁⣴⣿⣿⣿⣿⣿⣿⣿⣳⣿⣿⣿⡇⠀⣸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿",
        "⣿⣿⣿⣿⣿⣿⣿⣿⣿⢹⣿⣤⣉⠁⠀⡇⠀⠀⠀⢀⣴⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠁⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿",
        "⣿⣿⣿⣿⣿⣿⣿⣿⣿⣸⣿⣟⣁⣀⣀⣇⣀⣀⣀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣇⣀⣀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿"
    )
    foreach ($line in $art) {
        Write-Host $line -ForegroundColor $c
        Start-Sleep -Milliseconds 40
    }
    Write-Host ""
    Start-Sleep -Milliseconds 200
    Write-Host "  ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor $c
    Start-Sleep -Milliseconds 100
    Write-Host ("  ║   V A U L T  ·  S H I N O B I  ·  K O N O H A      v{0,-6}║" -f $VERSION) -ForegroundColor $c
    Start-Sleep -Milliseconds 80
    Write-Host "  ╠══════════════════════════════════════════════════════════════╣" -ForegroundColor $c
    Start-Sleep -Milliseconds 80
    Write-Host "  ║   Code like a Shinobi  ·  Strike Fast  ·  Leave No Trace   ║" -ForegroundColor $c
    Start-Sleep -Milliseconds 80
    Write-Host "  ║   macOS · Linux · Windows                  EN / Français    ║" -ForegroundColor $c
    Start-Sleep -Milliseconds 80
    Write-Host "  ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor $c
    try { [Console]::CursorVisible = $true } catch {}
    Write-Host ""
}

# ════════════════════════════════════════════════════════════════════
# DEPENDENCIES
# ════════════════════════════════════════════════════════════════════
$MISSING_DEPS = @()
$PKG_MGR = if (Get-Command winget -EA SilentlyContinue) { "winget" } elseif (Get-Command choco -EA SilentlyContinue) { "choco" } else { $null }

function Test-Dep($cmd) {
    if (-not (Get-Command $cmd -EA SilentlyContinue)) { $script:MISSING_DEPS += $cmd }
}

function Install-Dep($name, $wingetId, $chocoId) {
    info "Installing $name..."
    if ($script:PKG_MGR -eq "winget") {
        winget install --id $wingetId --silent --accept-package-agreements --accept-source-agreements
    } elseif ($script:PKG_MGR -eq "choco") {
        choco install $chocoId -y
    } else {
        warn "No package manager — install $name manually"
        warn "  winget : winget install $wingetId"
        warn "  choco  : choco install $chocoId"
    }
}

function Check-Dependencies {
    title (T deps_check)
    Test-Dep "vault"
    Test-Dep "caddy"
    Test-Dep "docker"
    Test-Dep "curl"

    if ($script:MISSING_DEPS.Count -eq 0) { ok (T deps_ok); return }

    warn (T deps_missing)
    foreach ($d in $script:MISSING_DEPS) {
        Write-Host "    • $d" -ForegroundColor Yellow
        switch ($d) {
            "vault"  { Write-Host "      winget install Hashicorp.Vault" -ForegroundColor DarkGray }
            "caddy"  { Write-Host "      winget install CaddyServer.Caddy" -ForegroundColor DarkGray }
            "docker" { Write-Host "      winget install Docker.DockerDesktop" -ForegroundColor DarkGray }
            "curl"   { Write-Host "      winget install curl.curl" -ForegroundColor DarkGray }
        }
    }

    $ans = Read-Host "`n  $(T deps_auto_q)"
    if ($ans -match "^[YyOo]?$") {
        foreach ($d in $script:MISSING_DEPS) {
            switch ($d) {
                "vault"  { Install-Dep "Vault"         "Hashicorp.Vault"       "vault" }
                "caddy"  { Install-Dep "Caddy"         "CaddyServer.Caddy"     "caddy" }
                "docker" { Install-Dep "Docker Desktop" "Docker.DockerDesktop" "docker-desktop" }
                "curl"   { Install-Dep "curl"           "curl.curl"            "curl" }
            }
        }
        $script:MISSING_DEPS = @()
        ok (T deps_ok)
    } else {
        err "Install missing dependencies and re-run."
    }
}

# ════════════════════════════════════════════════════════════════════
# MODE + NOTIFICATION
# ════════════════════════════════════════════════════════════════════
$MODE          = "development"
$NOTIFY_CHOICE = "4"
$NOTIFY_EMAIL  = ""

function Select-Mode {
    title (T mode_title)
    Write-Host "    $(T mode_dev)"
    Write-Host "    $(T mode_prod)"
    $m = Read-Host "  > "
    if ($m -eq "2") { $script:MODE = "production" } else { $script:MODE = "development" }
}

function Select-Notification {
    title (T notif_title)
    Write-Host "    $(T notif_1)"
    Write-Host "    $(T notif_2)"
    Write-Host "    $(T notif_3)"
    Write-Host "    $(T notif_4)"
    $n = Read-Host "  > "
    $script:NOTIFY_CHOICE = if ($n) { $n } else { "4" }
    if ($script:NOTIFY_CHOICE -in "2","3") {
        $script:NOTIFY_EMAIL = Read-Host "  $(T email_q)"
        if (-not $script:NOTIFY_EMAIL) { err "Email address required" }
    }
}

# ════════════════════════════════════════════════════════════════════
# DOMAIN
# ════════════════════════════════════════════════════════════════════
function Setup-Domain {
    $d = Read-Host "  $(T domain_q)"
    if ($d) { $script:VAULT_DOMAIN = $d }
    $hosts = Get-Content $HOSTS_FILE -EA SilentlyContinue
    if (-not ($hosts -match [regex]::Escape($script:VAULT_DOMAIN))) {
        Add-Content -Path $HOSTS_FILE -Value "127.0.0.1 $($script:VAULT_DOMAIN)"
        ok "Domain: $($script:VAULT_DOMAIN) → 127.0.0.1"
    }
}

# ════════════════════════════════════════════════════════════════════
# NTFY
# ════════════════════════════════════════════════════════════════════
$NTFY_TOPIC_FILE = "$SECURE_DIR\.ntfy-topic"
$NTFY_TOPIC      = ""

function Setup-Ntfy {
    $localHost = $env:COMPUTERNAME.ToLower()

    if (-not (Test-Path $NTFY_TOPIC_FILE)) {
        $topic = "vault-" + [System.Guid]::NewGuid().ToString("N").Substring(0,16)
        New-Item -Path $SECURE_DIR -ItemType Directory -Force | Out-Null
        $topic | Set-Content $NTFY_TOPIC_FILE
        Write-Host ""
        Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
        Write-Host "  $(T ntfy_first)" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  1. Install ntfy on your phone"
        Write-Host "     iOS     : https://apps.apple.com/app/ntfy/id1625396347"
        Write-Host "     Android : https://play.google.com/store/apps/details?id=io.heckel.ntfy"
        Write-Host ""
        Write-Host "  2. Add server : http://${localHost}:$NTFY_PORT"
        Write-Host "  3. Subscribe  : $topic"
        Write-Host "  4. Re-run this script"
        Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
        Exit 0
    }

    $script:NTFY_TOPIC = Get-Content $NTFY_TOPIC_FILE

    $running = docker ps --filter "name=ntfy-vault" --format "{{.Names}}" 2>$null
    if ($running -notmatch "ntfy-vault") {
        $exists = docker ps -a --filter "name=ntfy-vault" --format "{{.Names}}" 2>$null
        if ($exists -match "ntfy-vault") {
            docker start ntfy-vault | Out-Null
        } else {
            docker run -d --name ntfy-vault --restart=unless-stopped `
                -p "${NTFY_PORT}:80" `
                -e "NTFY_BASE_URL=http://${localHost}:${NTFY_PORT}" `
                binwiederhier/ntfy serve | Out-Null
            Start-Sleep 2
        }
    }
    ok "ntfy → http://${localHost}:$NTFY_PORT"
}

# ════════════════════════════════════════════════════════════════════
# CADDY
# ════════════════════════════════════════════════════════════════════
$SECRET_PASS = ""
$PASS_HASH   = ""
$CADDYFILE   = "$SECURE_DIR\Caddyfile"

function Setup-CaddyConfig {
    $chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    $script:SECRET_PASS = -join ((1..20) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
    $script:PASS_HASH   = (caddy hash-password --plaintext $script:SECRET_PASS 2>&1).Trim()

    New-Item -Path $SECURE_DIR -ItemType Directory -Force | Out-Null

    @"
{
    local_certs
}

$($script:VAULT_DOMAIN):$CADDY_PORT {
    tls internal
    basicauth * {
        vault $($script:PASS_HASH)
    }
    reverse_proxy localhost:$VAULT_PORT
}
"@ | Set-Content $script:CADDYFILE
}

function Start-CaddyServer {
    Get-Process caddy -EA SilentlyContinue | Stop-Process -Force -EA SilentlyContinue
    Start-Sleep 1

    Start-Process caddy -ArgumentList "run --config `"$script:CADDYFILE`"" `
        -RedirectStandardOutput $CADDY_LOG -WindowStyle Hidden
    Start-Sleep 3

    if (-not (Get-Process caddy -EA SilentlyContinue)) {
        Write-Host (Get-Content $CADDY_LOG -Raw -EA SilentlyContinue)
        err "Caddy failed to start"
    }

    # Trust certificate in Windows Certificate Store
    $caddyCA = "$env:APPDATA\Caddy\pki\authorities\local\root.crt"
    if (Test-Path $caddyCA) {
        $cert  = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $caddyCA
        $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root","LocalMachine")
        $store.Open("ReadWrite")
        if (-not ($store.Certificates | Where-Object { $_.Thumbprint -eq $cert.Thumbprint })) {
            $store.Add($cert)
            ok "HTTPS certificate trusted"
        }
        $store.Close()
    }

    ok "$(T caddy_ok) → https://$($script:VAULT_DOMAIN)"
}

# ════════════════════════════════════════════════════════════════════
# VAULT — DEVELOPMENT
# ════════════════════════════════════════════════════════════════════
$ROOT_TOKEN = ""

function Start-VaultDev {
    Get-Process vault -EA SilentlyContinue | Stop-Process -Force -EA SilentlyContinue
    Start-Sleep 1

    Start-Process vault -ArgumentList "server -dev -dev-listen-address=127.0.0.1:$VAULT_PORT" `
        -RedirectStandardOutput $VAULT_LOG -RedirectStandardError "$VAULT_LOG.err" -WindowStyle Hidden

    $w = 0
    while ($w -lt 15) {
        Start-Sleep 1; $w++
        if (Test-Path $VAULT_LOG) {
            $txt = Get-Content $VAULT_LOG -Raw -EA SilentlyContinue
            if ($txt -match "Root Token:\s*(\S+)") { $script:ROOT_TOKEN = $Matches[1]; break }
        }
    }
    if (-not $script:ROOT_TOKEN) { err "Root token not found — check $VAULT_LOG" }
    ok "$(T vault_ok) (dev mode)"
}

# ════════════════════════════════════════════════════════════════════
# VAULT — PRODUCTION
# ════════════════════════════════════════════════════════════════════
$VAULT_DATA_DIR    = "$SECURE_DIR\vault-data"
$VAULT_CONFIG_FILE = "$SECURE_DIR\vault.hcl"
$UNSEAL_KEYS       = @()

function Start-VaultProd {
    New-Item -Path $VAULT_DATA_DIR -ItemType Directory -Force | Out-Null
    $dataPath = $VAULT_DATA_DIR -replace '\\','/'

    @"
storage "file" { path = "$dataPath" }
listener "tcp"  { address = "127.0.0.1:$VAULT_PORT" tls_disable = "true" }
api_addr = "http://127.0.0.1:$VAULT_PORT"
ui = true
"@ | Set-Content $script:VAULT_CONFIG_FILE

    Get-Process vault -EA SilentlyContinue | Stop-Process -Force -EA SilentlyContinue
    Start-Sleep 2

    Start-Process vault -ArgumentList "server -config=`"$($script:VAULT_CONFIG_FILE)`"" `
        -RedirectStandardOutput $VAULT_LOG -WindowStyle Hidden
    Start-Sleep 3

    $env:VAULT_ADDR = "http://127.0.0.1:$VAULT_PORT"
    $keysFile = "$SECURE_DIR\.vault-keys"
    $status = vault status 2>&1 | Out-String

    if ($status -match "Initialized\s+true") {
        if (Test-Path $keysFile) {
            $kc = Get-Content $keysFile -Raw
            $script:UNSEAL_KEYS = [regex]::Matches($kc,"Unseal Key \d+: (\S+)") | ForEach-Object { $_.Groups[1].Value }
            $script:ROOT_TOKEN  = [regex]::Match($kc,"Initial Root Token:\s+(\S+)").Groups[1].Value
            vault operator unseal $script:UNSEAL_KEYS[0] | Out-Null
            vault operator unseal $script:UNSEAL_KEYS[1] | Out-Null
        } else { warn "Vault initialized but keys not found — unseal manually" }
    } else {
        $init = vault operator init -key-shares=3 -key-threshold=2 2>&1 | Out-String
        $init | Set-Content $keysFile
        $script:UNSEAL_KEYS = [regex]::Matches($init,"Unseal Key \d+: (\S+)") | ForEach-Object { $_.Groups[1].Value }
        $script:ROOT_TOKEN  = [regex]::Match($init,"Initial Root Token:\s+(\S+)").Groups[1].Value
        vault operator unseal $script:UNSEAL_KEYS[0] | Out-Null
        vault operator unseal $script:UNSEAL_KEYS[1] | Out-Null
    }

    ok "$(T vault_ok) (production)"
}

# ════════════════════════════════════════════════════════════════════
# SERVICE (Task Scheduler)
# ════════════════════════════════════════════════════════════════════
function Install-VaultService {
    $exe = (Get-Command vault).Source
    $action    = New-ScheduledTaskAction -Execute $exe -Argument "server -config=`"$VAULT_CONFIG_FILE`""
    $trigger   = New-ScheduledTaskTrigger -AtStartup
    $settings  = New-ScheduledTaskSettingsSet -RestartOnFailure -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
    Register-ScheduledTask -TaskName "VaultServer" -Action $action -Trigger $trigger `
        -Settings $settings -Principal $principal -Force | Out-Null
    ok (T svc_done)
}

# ════════════════════════════════════════════════════════════════════
# NOTIFICATIONS
# ════════════════════════════════════════════════════════════════════
function Send-Notification {
    $body = "URL   : https://$($script:VAULT_DOMAIN)`nUser  : vault`nPass  : $($script:SECRET_PASS)`nToken : $($script:ROOT_TOKEN)"

    if ($script:NOTIFY_CHOICE -in "1","3") {
        try {
            Invoke-RestMethod -Uri "http://127.0.0.1:$NTFY_PORT/$($script:NTFY_TOPIC)" `
                -Method POST -Body $body `
                -Headers @{ "Title"="Vault 🔐"; "Priority"="high"; "Tags"="key,lock" } | Out-Null
            ok "ntfy notification sent"
        } catch { warn "ntfy send failed" }
    }

    if ($script:NOTIFY_CHOICE -in "2","3") {
        try {
            $ol   = New-Object -ComObject Outlook.Application -EA Stop
            $mail = $ol.CreateItem(0)
            $mail.To      = $script:NOTIFY_EMAIL
            $mail.Subject = "🔐 Vault — Credentials"
            $mail.Body    = $body
            $mail.Send()
            ok "Email sent → $($script:NOTIFY_EMAIL)"
        } catch { warn "Outlook unavailable — credentials shown on screen only" }
    }
}

# ════════════════════════════════════════════════════════════════════
# SUMMARY
# ════════════════════════════════════════════════════════════════════
function Show-Summary {
    $W = "═" * 66; $w = "─" * 66
    Write-Host ""
    Write-Host "  ╔$W╗" -ForegroundColor Green
    Write-Host "  ║$(("  ✅  VAULT IS RUNNING").PadRight(66))║" -ForegroundColor Green
    Write-Host "  ║$(" " * 66)║" -ForegroundColor Green
    Write-Host "  ╠$w╣" -ForegroundColor Green
    Write-Host "  ║$(" " * 66)║" -ForegroundColor Green

    $url  = "  🌐  URL          https://$($script:VAULT_DOMAIN)"
    $user = "  👤  Username     vault"
    $pass = "  🔑  Password     $($script:SECRET_PASS)"
    $tok  = "  🎫  Token        $($script:ROOT_TOKEN)"

    Write-Host "  ║$(($url).PadRight(66))║" -ForegroundColor Cyan
    Write-Host "  ║$(($user).PadRight(66))║" -ForegroundColor White
    Write-Host "  ║$(($pass).PadRight(66))║" -ForegroundColor Yellow
    Write-Host "  ║$(($tok).PadRight(66))║" -ForegroundColor White
    Write-Host "  ║$(" " * 66)║" -ForegroundColor Green

    if ($script:MODE -eq "production" -and $script:UNSEAL_KEYS.Count -gt 0) {
        Write-Host "  ╠$w╣" -ForegroundColor Green
        Write-Host "  ║  ⚠️  $(T unseal_warn)" -ForegroundColor Yellow
        foreach ($k in $script:UNSEAL_KEYS) {
            Write-Host "  ║$(("     • $k").PadRight(66))║" -ForegroundColor Yellow
        }
        Write-Host "  ║$(" " * 66)║" -ForegroundColor Green
    }

    Write-Host "  ╠$w╣" -ForegroundColor Green
    Write-Host "  ║$(("  📄  Vault log  $VAULT_LOG").PadRight(66))║" -ForegroundColor Cyan
    Write-Host "  ║$(("  📄  Caddy log  $CADDY_LOG").PadRight(66))║" -ForegroundColor Cyan
    Write-Host "  ║$(" " * 66)║" -ForegroundColor Green
    Write-Host "  ║$(("  🗑️   Uninstall  PowerShell -File vault-setup.ps1 -Uninstall").PadRight(66))║" -ForegroundColor White
    Write-Host "  ║$(" " * 66)║" -ForegroundColor Green
    Write-Host "  ╚$W╝" -ForegroundColor Green
    Write-Host ""
}

# ════════════════════════════════════════════════════════════════════
# UNINSTALL
# ════════════════════════════════════════════════════════════════════
function Do-Uninstall {
    Write-Host ""
    warn (T uninstall_w)
    $c = Read-Host "  $(T uninstall_q)"
    if ($c -ne "yes" -and $c -ne "oui") { Write-Host "Cancelled."; Exit 0 }

    Get-Process vault, caddy -EA SilentlyContinue | Stop-Process -Force -EA SilentlyContinue
    docker stop ntfy-vault 2>$null | Out-Null
    docker rm   ntfy-vault 2>$null | Out-Null
    Unregister-ScheduledTask -TaskName "VaultServer" -Confirm:$false -EA SilentlyContinue

    (Get-Content $HOSTS_FILE) -notmatch "vault\.local" | Set-Content $HOSTS_FILE
    if (Test-Path $SECURE_DIR) { Remove-Item $SECURE_DIR -Recurse -Force }

    ok "Vault uninstalled — all data removed"
    if ($PSCommandPath -and (Test-Path $PSCommandPath)) {
        Remove-Item -Force $PSCommandPath -ErrorAction SilentlyContinue
        ok "Script supprimé : $PSCommandPath"
    }
    Exit 0
}

# ════════════════════════════════════════════════════════════════════
# MAIN
# ════════════════════════════════════════════════════════════════════
Select-Language
Show-Banner

if ($Uninstall) { Do-Uninstall }

step (T deps_check);   Check-Dependencies
step (T mode_title);   Select-Mode
step (T notif_title);  Select-Notification
step "Domain";         Setup-Domain

New-Item -Path $SECURE_DIR -ItemType Directory -Force | Out-Null

if ($NOTIFY_CHOICE -in "1","3") { step "ntfy"; Setup-Ntfy }

step "Caddy config";   Setup-CaddyConfig

if ($MODE -eq "development") {
    step "Vault (development)"; Start-VaultDev
} else {
    step "Vault (production)";  Start-VaultProd
    step "System service";      Install-VaultService
}

step "Caddy"; Start-CaddyServer
Send-Notification
Show-Summary
