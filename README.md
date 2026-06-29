# 🔐 vault-setup

> Universal HashiCorp Vault installer — macOS · Linux · Windows · bilingual (EN/FR)

One script that installs and configures a secure, local Vault instance with HTTPS (Caddy), mobile push notifications (ntfy), and email delivery of credentials.

---

## Features

- **Cross-platform** — macOS, Linux (Debian/Ubuntu, RHEL/Fedora, Arch) and Windows
- **Bilingual** — English and French, chosen at startup
- **Two modes** — Development (quick) or Production (persistent data, auto-start service)
- **Auto-dependency check** — detects missing tools and installs them automatically
- **HTTPS out of the box** — Caddy reverse proxy with a local TLS certificate
- **Rotating password** — a new random password is generated on every run
- **Notification choice** — ntfy mobile app, email (Apple Mail / sendmail), both, or screen only
- **Stable local address** — uses Bonjour `.local` hostname instead of a changing DHCP IP
- **Clean uninstall** — one flag removes everything

---

## Requirements

The script checks for these and offers to install them automatically:

| Tool | Purpose |
|------|---------|
| `vault` | HashiCorp Vault |
| `caddy` | HTTPS reverse proxy |
| `docker` | Runs the ntfy notification server |
| `openssl` | Password hashing (macOS/Linux only) |
| `curl` | Sending ntfy notifications |

> **Windows** — uses `winget` (built-in on Windows 10/11) or Chocolatey. No WSL needed.

---

## Quick start

**macOS / Linux**
```bash
curl -O https://raw.githubusercontent.com/Justclemax/vault-setup/main/vault-setup.sh
chmod +x vault-setup.sh
bash vault-setup.sh
```

**Windows** — open PowerShell as Administrator:
```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Justclemax/vault-setup/main/vault-setup.ps1" -OutFile vault-setup.ps1
PowerShell -ExecutionPolicy Bypass -File vault-setup.ps1
```

The script will ask you:
1. **Language** — English or Français
2. **Mode** — Development or Production
3. **Notifications** — ntfy / Email / Both / None
4. **Domain** — local domain for Vault (default: `vault.local`)
5. **Email** — only if you chose email notification

At the end, your credentials are displayed on screen (and sent to your phone/email if configured):

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✅  VAULT IS RUNNING

  URL      : https://vault.local
  Username : vault
  Password : Xk9mP2...   ← rotates every run
  Token    : hvs.XXXXX
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Modes

### Development
- Uses `vault server -dev` — fastest way to get started
- Data is **lost** when Vault stops or the machine restarts
- Good for: local testing, demos, development

### Production
- Persistent file storage in `~/.vault-secure/vault-data/`
- Vault is initialized with **3 unseal keys** (threshold: 2)
- Installed as a system service (**launchd** on macOS, **systemd** on Linux)
- Vault starts automatically at boot and unseals itself using the saved keys
- Good for: real usage, self-hosted secrets management

> ⚠️ **Save your unseal keys.** They are stored in `~/.vault-secure/.vault-keys`.  
> Without 2 of the 3 keys, Vault cannot be unsealed after a restart.

---

## ntfy — mobile notifications

ntfy is a self-hosted push notification service. Your credentials are sent to your phone the moment Vault starts.

### First-time setup (one time only)

1. Install the **ntfy** app on your phone  
   - iOS: [App Store](https://apps.apple.com/app/ntfy/id1625396347)  
   - Android: [Play Store](https://play.google.com/store/apps/details?id=io.heckel.ntfy)

2. In the app → **Settings → Manage accounts → Add account**  
   Server URL: `http://YourMacName.local:2586`  
   *(your Mac name is shown when the script first runs)*

3. Subscribe to your personal topic (generated once and saved locally)

4. Re-run the script — credentials will now arrive on your phone automatically

> The server URL uses your Mac's Bonjour name (e.g. `MacBook-Pro.local`) which never changes even if your IP address changes.  
> **Requirement:** your phone and Mac must be on the same Wi-Fi network.

---

## Email notifications

When you select email notification, the script sends via:
- **macOS** — Apple Mail (uses your existing configured account, no password needed)
- **Linux** — `sendmail` (must be installed and configured)

---

## Uninstall

**macOS / Linux** — sans télécharger le fichier au préalable :
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Justclemax/vault-setup/main/vault-setup.sh) --uninstall
```

Ou si le fichier est déjà présent :
```bash
bash vault-setup.sh --uninstall
```

**Windows** — sans télécharger le fichier au préalable (PowerShell en admin) :
```powershell
$f="$env:TEMP\vs.ps1"; irm https://raw.githubusercontent.com/Justclemax/vault-setup/main/vault-setup.ps1 -OutFile $f; & $f -Uninstall; Remove-Item $f
```

Ou si le fichier est déjà présent :
```powershell
PowerShell -ExecutionPolicy Bypass -File vault-setup.ps1 -Uninstall
```

Removes:
- Vault process and data (`~/.vault-secure/` or `%USERPROFILE%\.vault-secure\`)
- Caddy process
- ntfy Docker container
- `/etc/hosts` (or `C:\Windows\System32\drivers\etc\hosts`) entries
- launchd / systemd service (macOS/Linux) or Scheduled Task (Windows)
- Le script lui-même — aucune trace laissée sur l'ordinateur

---

## File structure

```
~/.vault-secure/
├── Caddyfile          # Caddy reverse proxy config (regenerated each run)
├── vault.hcl          # Vault server config (production only)
├── vault-data/        # Vault persistent storage (production only)
├── .ntfy-topic        # Your private ntfy topic name
└── .vault-keys        # Vault unseal keys + root token (production only)
```

Logs:
```
/tmp/vault-setup.log   # Vault output
/tmp/caddy-setup.log   # Caddy output
/tmp/ntfy-setup.log    # ntfy Docker output
```

---

## Security notes

- Vault listens only on `127.0.0.1` — never exposed directly to the network
- Caddy handles TLS termination and HTTP Basic Auth (password rotates each run)
- The local TLS certificate is trusted in your macOS Keychain automatically
- All secrets are stored in `~/.vault-secure/` with `700` permissions
- ntfy runs locally in Docker — notifications never leave your network

---

## Tested on

| OS | Version | Script |
|----|---------|--------|
| macOS | Sequoia 15, Sonoma 14 | `vault-setup.sh` |
| Ubuntu | 22.04, 24.04 | `vault-setup.sh` |
| Debian | 12 | `vault-setup.sh` |
| Fedora | 39, 40 | `vault-setup.sh` |
| Windows | 10, 11 | `vault-setup.ps1` |

---

## Known issues fixed

| # | Symptom | Cause | Fix |
|---|---------|-------|-----|
| 1 | Summary box déborde sur certains terminaux | Les emoji (4 bytes UTF-8) faussent le comptage de `printf` | Widths ajustés pour chaque ligne |
| 2 | Mode production s'exécutait en dev sans avertissement | Aucun feedback après la sélection du mode | `✅ Mode: production` affiché immédiatement après choix |
| 3 | Mauvais domaine utilisé (hostname à la place de `vault.local`) | Aucune confirmation visible après la saisie | `✅ Domain: vault.local` affiché immédiatement après saisie |
| 4 | `--uninstall` supprimait le script dans un dépôt git cloné | Pas de vérification git avant `rm -f "$0"` | Vérification `git rev-parse` — script conservé si dans un repo |


