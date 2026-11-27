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

- **Codex CLI** — `curl -fsSL https://chatgpt.com/codex/install.sh | sh`
  (lub aplikacja Codex/ChatGPT)
- **git**, **curl**
- **Node.js + npm** (do MCP przez `npx`: github, playwright, context7, notion)
- *(opcjonalnie)* **opencodex / ocx** — jeśli chcesz proxy na `127.0.0.1:10100`

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

1. Sprawdza wymagania (codex, git, curl, node/npm).
2. Tworzy `~/.codex/` (lub `%USERPROFILE%\.codex\`) jeśli nie istnieje.
3. Kopiuje `config.toml.example` → `config.toml`, podstawiając **domyślne
   placeholdery** (np. `$HOME`/`%USERPROFILE%`) — żadnych Twoich danych.
4. Opcjonalnie: `AGENTS.md` i `hooks.json` (jeśli istnieją wzorce).
5. **Nie dotyka** `auth.json`, kluczy API ani żadnych sekretów.

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
