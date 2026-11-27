# Codex Config — instalacja na nowych maszynach

Gotowy zestaw konfiguracji Codex CLI + aplikacji (Codex/OpenAI), którą możesz
szybko wdrożyć na dowolnym komputerze (Linux / macOS / Windows).

> ⚠️ Repo jest publiczne, ale **nie zawiera żadnych danych osobowych**:
> sekretów, tokenów, kluczy API, adresów e-mail, IP, ścieżek użytkownika ani
> listy Twoich projektów. Wszystko wrażliwe zastąpiono placeholderami — patrz
> `config.toml.example`, `AGENTS.md.example`, `hooks.json.example`.

## Co jest w środku

| Plik | Opis |
|---|---|
| `config.toml.example` | Wzorzec konfiguracji Codex (model, MCP, pluginy, UI) |
| `AGENTS.md.example` | Globalne instrukcje pracy Codex (user-level) |
| `hooks.json.example` | Hooki jakości (impeccable) — wzorzec |
| `install.sh` | Instalator dla Linux / macOS (bash) |
| `install.ps1` | Instalator dla Windows (PowerShell) |

## Wymagania na maszynie docelowej

- **git**, **curl**
- **Node.js + npm** (wymagane do opencodex oraz MCP przez `npx`)
- Instalator **automatycznie zainstaluje** (jeśli ich brak):
  - **Codex CLI** — oficjalny instalator (`https://chatgpt.com/codex/install.sh` / `install.ps1`)
  - **opencodex / ocx** — przez `npm install -g @bitkyc08/opencodex` (proxy do modeli)
  - **ChatGPT App (desktop)** — na Linux (.deb/.rpm z oficjalnego CDN) lub przez
    winget/Microsoft Store na Windows

> Aby pominąć instalację **narzędzi CLI** (tylko konfiguracja), ustaw zmienną
> `INSTALL_TOOLS=0` (Windows: `$env:INSTALL_TOOLS='0'`).
> Aby pominąć instalację **ChatGPT App**, ustaw `INSTALL_APP=0`
> (Windows: `$env:INSTALL_APP='0'`).

## ChatGPT App (desktop) — ważne informacje

Instalator próbuje zainstalować **ChatGPT App** (aplikację desktopową z Codexem)
obok CLI. Detekcja opiera się na **faktycznych pakietach** (`dpkg -s chatgpt`,
`rpm -q chatgpt`, `pacman -Q chatgpt-desktop`) oraz standardowych lokalizacjach
(`/usr/lib/chatgpt/ChatGPT`, `/opt/OpenAI/ChatGPT`) — **nie** na komendzie
`chatgpt` z PATH, bo tam może być niepowiązany pakiet npm o tej samej nazwie.

### Gdy instalator twierdzi, że app „jest”, a jej nie ma
- Sprawdź, czy w PATH nie siedzi niepowiązany pakiet: `which chatgpt`
- Sprawdź pakiet: `dpkg -s chatgpt` / `rpm -q chatgpt`
- Jeśli faktycznie jej brak, uruchom instalator od nowa (już z poprawioną
  detekcją), ewentualnie z `INSTALL_APP=1`.

### Ręczna instalacja (fallback)
Jeśli automatyczna instalacja zawiedzie (brak sudo, brak apt/dnf, nieobsługiwana
architektura), pobierz odpowiedni pakiet ze strony `https://chatgpt.com/download`
lub bezpośrednio z oficjalnego CDN OpenAI:

- Ubuntu/Debian x64 (AMD64): `…/linux/deb/latest/chatgpt_amd64.deb`
- Ubuntu/Debian ARM64: `…/linux/deb/latest/chatgpt_arm64.deb`
- Fedora x64: `…/linux/rpm/latest/chatgpt.x86_64.rpm`
- Fedora ARM64: `…/linux/rpm/latest/chatgpt.aarch64.rpm`

Następnie zainstaluj w standardowy sposób (`sudo apt install ./…deb` /
`sudo dnf install ./…rpm`).

### Windows
Aplikacja instalowana z Microsoft Store przez `winget` (id `OpenAI.Codex`,
fallback `ChatGPT`). Gdy winget zawiedzie — pobierz ze sklepu Microsoft lub
z `https://chatgpt.com/download`.

## Instalacja — Linux / macOS

```bash
# 1) Pobierz i uruchom instalator wprost z GitHub:
bash <(curl -fsSL https://raw.githubusercontent.com/KwanekDev/codex-config/main/install.sh)

# 2) (opcjonalnie) edytuj konfigurację:
nano ~/.codex/config.toml
```

## Instalacja — Windows (PowerShell)

```powershell
# 1) Pobierz i uruchom:
powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/KwanekDev/codex-config/main/install.ps1 | iex"
```

## Co robi instalator

1. Sprawdza wymagania (git, curl, node/npm).
2. **Instaluje brakujące narzędzia**: Codex CLI oraz opencodex/ocx
   (chyba że `INSTALL_TOOLS=0`).
3. Tworzy `~/.codex/` (lub `%USERPROFILE%\.codex\`) jeśli nie istnieje.
4. Kopiuje `config.toml.example` → `config.toml`, podstawiając **domyślne
   placeholdery** (np. `$HOME`/`%USERPROFILE%`) — żadnych Twoich danych.
5. Opcjonalnie: `AGENTS.md` i `hooks.json` (jeśli istnieją wzorce).
6. **Nie dotyka** `auth.json`, kluczy API ani żadnych sekretów.

> ⚠️ **Ważne:** po instalacji skonfiguruj własny provider/klucz API:
> - jeśli używasz **opencodex** (proxy), w `config.toml` zostaw
>   `openai_base_url = "http://127.0.0.1:10100/v1"` i uruchom `ocx start`;
> - w przeciwnym razie **usuń** ten wpis i ustaw swój model/provider
>   (np. `model = "..."` + zmienne środowiskowe z kluczem).

## Przykład szybkiej konfiguracji po instalacji

```bash
codex      # pierwsze uruchomienie — zaloguj się / lub:
codex login
```

## Uwagi

- Konfiguracja jest **parametryzowana**: ścieżki w plikach używają `$HOME` /
  `%USERPROFILE%` zamiast twardych ścieżek.
- MCP `node_repl`, `github`, `playwright`, `vercel`, `context7`, `notion`
  są aktywne w przykładzie — jeśli któregoś nie potrzebujesz, skasuj jego sekcję
  z `config.toml`.
- Hooki jakości (`hooks.json`) są **opcjonalne** — działają tylko gdy masz
  zainstalowane skille `impeccable` (patrz komentarz w pliku).
