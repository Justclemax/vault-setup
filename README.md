# 🔐 vault-setup

> Universal HashiCorp Vault installer — macOS · Linux · bilingual (EN/FR)

One script that installs and configures a secure, local Vault instance with HTTPS (Caddy), mobile push notifications (ntfy), and email delivery of credentials.

---

## Features

- **Cross-platform** — macOS and Linux (Debian/Ubuntu, RHEL/Fedora, Arch)
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
| `openssl` | Password hashing |
| `curl` | Sending ntfy notifications |

> **Windows users** — this script requires WSL (Windows Subsystem for Linux).  
> Open PowerShell as Administrator and run `wsl --install`, then use this script inside Ubuntu.

---

## Quick start

```bash
# Download
curl -O https://raw.githubusercontent.com/YOUR_USERNAME/vault-setup/main/vault-setup.sh
chmod +x vault-setup.sh

# Run
bash vault-setup.sh
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

```bash
bash vault-setup.sh --uninstall
```

Removes:
- Vault process and data (`~/.vault-secure/`)
- Caddy process
- ntfy Docker container
- `/etc/hosts` entries added by this script
- launchd / systemd service

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

| OS | Version |
|----|---------|
| macOS | Sequoia 15, Sonoma 14 |
| Ubuntu | 22.04, 24.04 |
| Debian | 12 |
| Fedora | 39, 40 |

---

## License

MIT
