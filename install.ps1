<#
  Installer konfiguracji Codex — Windows (PowerShell)
  Źródło: https://github.com/KwanekDev/codex-config
  Użycie:
    powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/KwanekDev/codex-config/main/install.ps1 | iex"
#>
$ErrorActionPreference = 'Stop'

$repoUrl = 'https://raw.githubusercontent.com/KwanekDev/codex-config/main'
$codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE '.codex' }

Write-Host '==> Codex config installer (Windows)'
Write-Host "    CODEX_HOME=$codexHome"

# --- Wymagania ---
Write-Host '==> Sprawdzam wymagania...'
foreach ($cmd in @('curl','git')) {
  if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
    Write-Host "  [BŁĄD] brak narzędzia: $cmd"; exit 1
  } else { Write-Host "  [OK] $cmd" }
}
if (-not (Get-Command node -ErrorAction SilentlyContinue) -or -not (Get-Command npx -ErrorAction SilentlyContinue)) {
  Write-Host '  [UWAGA] brak Node.js/npm — MCP (github, playwright, context7, notion) nie będą działać.'
}

# --- Instalacja Codex CLI (jeśli brak) ---
if (-not (Get-Command codex -ErrorAction SilentlyContinue)) {
  if ($env:INSTALL_TOOLS -ne '0') {
    Write-Host '==> Brak codex CLI — instaluję (oficjalny instalator)...'
    try {
      Invoke-Expression (Invoke-RestMethod 'https://chatgpt.com/codex/install.ps1')
    } catch {
      Write-Host '  [UWAGA] instalacja codex przez PowerShell nie powiodła się — spróbuj: curl -fsSL https://chatgpt.com/codex/install.sh | sh'
    }
  } else {
    Write-Host '  [UWAGA] brak codex CLI — pomijam (INSTALL_TOOLS=0).'
  }
} else {
  Write-Host "  [OK] codex: $((Get-Command codex).Source)"
}

# --- Instalacja opencodex / ocx (jeśli brak) ---
if (-not (Get-Command ocx -ErrorAction SilentlyContinue)) {
  if ($env:INSTALL_TOOLS -ne '0') {
    Write-Host '==> Brak opencodex (ocx) — instaluję przez npm...'
    try { npm install -g @bitkyc08/opencodex } catch { Write-Host '  [UWAGA] instalacja opencodex nie powiodła się.' }
  } else {
    Write-Host '  [UWAGA] brak opencodex — pomijam (INSTALL_TOOLS=0).'
  }
} else {
  Write-Host "  [OK] ocx: $((Get-Command ocx).Source)"
}

# --- Instalacja ChatGPT App (desktop) — jeśl brak ---
function Test-ChatGptAppInstalled {
  if (-not (Get-Command Get-AppxPackage -ErrorAction SilentlyContinue)) { return $false }
  $appx = Get-AppxPackage -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'OpenAI\.Codex|ChatGPT' } | Select-Object -First 1
  if ($appx) { return $true }
  return $false
}
if (-not (Test-ChatGptAppInstalled)) {
  if ($env:INSTALL_APP -ne '0') {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
      Write-Host '==> Brak ChatGPT App — instaluję przez winget (Microsoft Store)...'
      winget install -e --id OpenAI.Codex -s msstore --accept-package-agreements --accept-source-agreements 2>$null
      if ($LASTEXITCODE -ne 0) {
        Write-Host '  [INFO] próbuję alternatywnego ID (ChatGPT)...'
        winget install -e --id ChatGPT -s msstore --accept-package-agreements --accept-source-agreements 2>$null
      }
      if (-not (Test-ChatGptAppInstalled)) {
        Write-Host '  [UWAGA] instalacja przez winget nie powiodła się — zainstaluj ręcznie: https://chatgpt.com/download'
      }
    } else {
      Write-Host '  [UWAGA] brak winget — zainstaluj ChatGPT App ręcznie: https://chatgpt.com/download'
    }
  } else {
    Write-Host '  [UWAGA] brak ChatGPT App — pomijam (INSTALL_APP=0).'
  }
} else {
  Write-Host '  [OK] ChatGPT App (zainstalowana)'
}

# --- Pobierz wzorce ---
Write-Host '==> Pobieram wzorce z GitHub...'
$tmp = Join-Path $env:TEMP ("codex-config-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
  foreach ($f in @('config.toml.example','AGENTS.md.example','hooks.json.example')) {
    Invoke-WebRequest -UseBasicParsing -Uri "$repoUrl/$f" -OutFile (Join-Path $tmp $f)
  }

  # --- Katalog docelowy ---
  New-Item -ItemType Directory -Path $codexHome -Force | Out-Null

  # --- config.toml ---
  Write-Host '==> Instaluję config.toml...'
  $cfg = Join-Path $codexHome 'config.toml'
  Copy-Item (Join-Path $tmp 'config.toml.example') $cfg -Force
  $content = Get-Content -Raw $cfg
  $content = $content.Replace('<CODEX_HOME>', $codexHome.Replace('\','/'))

  # Wykryj node_repl (typowe lokalizacje)
  $nodeReplBin = $null
  $searchRoots = @()
  if ($env:LOCALAPPDATA) { $searchRoots += (Join-Path $env:LOCALAPPDATA 'OpenAI\Codex') }
  $searchRoots += 'C:\Program Files\WindowsApps'
  foreach ($root in $searchRoots) {
    if (Test-Path $root) {
      $hit = Get-ChildItem -Path $root -Recurse -Filter 'node_repl*' -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'node_repl' } | Select-Object -First 1
      if ($hit) { $nodeReplBin = $hit.FullName; break }
    }
  }
  if ($nodeReplBin) {
    Write-Host "  [OK] znaleziono node_repl: $nodeReplBin"
    $nodeDir = Split-Path (Split-Path $nodeReplBin)
    $content = $content.Replace('<NODE_REPL_BIN>', $nodeReplBin.Replace('\','/'))
    $content = $content.Replace('<NODE_REPL_NODE>', (Join-Path $nodeDir 'node').Replace('\','/'))
    $content = $content.Replace('<NODE_REPL_MODULES>', (Join-Path $nodeDir 'lib\node_modules').Replace('\','/'))
  } else {
    Write-Host '  [INFO] brak node_repl — usuwam sekcję MCP node_repl'
    $content = [regex]::Replace($content, '(?ms)\[mcp_servers\.node_repl\].*?(?=\[mcp_servers\.|$)', '')
  }

  $codexCli = Get-Command codex -ErrorAction SilentlyContinue
  $codexCliPath = 'codex'
  if ($codexCli) { $codexCliPath = $codexCli.Source.Replace('\','/') }
  $content = $content.Replace('<CODEX_CLI_PATH>', $codexCliPath)
  Set-Content -Path $cfg -Value $content -Encoding UTF8
  Write-Host "  [OK] zapisano $cfg"

  # --- AGENTS.md ---
  $agentsPath = Join-Path $codexHome 'AGENTS.md'
  if (-not (Test-Path $agentsPath)) {
    Write-Host '==> Instaluję AGENTS.md (wzorzec)...'
    Copy-Item (Join-Path $tmp 'AGENTS.md.example') $agentsPath
  } else { Write-Host '==> AGENTS.md już istnieje — pomijam.' }

  # --- hooks.json ---
  $impeccable = Join-Path $env:USERPROFILE '.agents\skills\impeccable\scripts\impeccable.cmd'
  $hooksPath = Join-Path $codexHome 'hooks.json'
  if ((Test-Path $impeccable) -and -not (Test-Path $hooksPath)) {
    Write-Host '==> Instaluję hooks.json (impeccable)...'
    $hk = Get-Content -Raw (Join-Path $tmp 'hooks.json.example')
    $hk = $hk.Replace('<IMPECCABLE_BASH>', '"' + $impeccable.Replace('\','/') + '"')
    Set-Content -Path $hooksPath -Value $hk -Encoding UTF8
  } elseif (-not (Test-Path $hooksPath)) {
    Write-Host '==> hooks.json: brak impeccable — pomijam.'
  }

  Write-Host ''
  Write-Host '==> Gotowe! Zweryfikuj: codex doctor'
  Write-Host "    cat $cfg"
  Write-Host 'Uwaga: skonfiguruj własny provider/klucz API (patrz README).'
}
finally {
  Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}
