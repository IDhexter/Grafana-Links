param(
    [string]$ZabbixUrl = "",
    [string]$ZabbixToken = "",
    [string]$GrafanaUrl = "",
    [string]$GrafanaUser = "",
    [string]$GrafanaPassword = "",
    [string]$DashboardUid = "adhdb5q",
    [string]$DashboardTitle = "SGS Links Status - POC",
    [int]$FolderId = 136,
    [string]$FolderUid = "dg154lz3hgflsd"
)

$ErrorActionPreference = "Stop"

# 1. Carregar variáveis do arquivo .env (se existir)
$envPath = Join-Path $PSScriptRoot "..\.env"
if (-not (Test-Path $envPath)) { $envPath = Join-Path $pwd ".env" }
if (Test-Path $envPath) {
    Get-Content $envPath | ForEach-Object {
        if ($_ -match '^\s*([^#=]+)=(.*)$') {
            $k = $matches[1].Trim()
            $v = $matches[2].Trim().Trim('"').Trim("'")
            [Environment]::SetEnvironmentVariable($k, $v, "Process")
        }
    }
}

if (-not $ZabbixUrl)       { $ZabbixUrl       = [Environment]::GetEnvironmentVariable("ZABBIX_URL") }
if (-not $ZabbixToken)     { $ZabbixToken     = [Environment]::GetEnvironmentVariable("ZABBIX_TOKEN") }
if (-not $GrafanaUrl)      { $GrafanaUrl      = [Environment]::GetEnvironmentVariable("GRAFANA_URL") }
if (-not $GrafanaUser)     { $GrafanaUser     = [Environment]::GetEnvironmentVariable("GRAFANA_USER") }
if (-not $GrafanaPassword) { $GrafanaPassword = [Environment]::GetEnvironmentVariable("GRAFANA_PASSWORD") }
if ([Environment]::GetEnvironmentVariable("GRAFANA_DASHBOARD_UID")) {
    $DashboardUid = [Environment]::GetEnvironmentVariable("GRAFANA_DASHBOARD_UID")
}

if (-not $ZabbixUrl -or -not $ZabbixToken -or -not $GrafanaUrl) {
    Write-Error "Configure o arquivo .env (baseado no .env.example) ou informe os parâmetros -ZabbixUrl, -ZabbixToken e -GrafanaUrl."
    exit 1
}

# 2. Lista Padrão de Links do NOC (Edição Fácil N1)
$nocLinksList = @'
<!-- =========================================================================
     📋 PAINEL NOC SGS - LISTA DE LINKS (EDIÇÃO FÁCIL N1)
     =========================================================================
     COMO EDITAR (ADICIONAR, REMOVER OU MUDAR LINKS):
     1. Cada linha abaixo representa 1 Card na tela do NOC.
     2. Formato de cada linha:
        LOCALIDADE - OPERADORA | NOME DO HOST NO ZABBIX | ITEM (Opcional)
     3. Se o 3º campo (ITEM) não for informado, usa automaticamente "ICMP ping".
     4. Para ADICIONAR um novo link: basta adicionar uma nova linha.
     5. Para REMOVER um link: apague a linha (ou coloque # no início da linha).
     6. Para MUDAR o nome ou operadora: edite o texto antes da primeira barra "|".
     ========================================================================= -->
<pre id="sgs-noc-links-config" style="display:none;">
AMERICANA - HUGHESNET         | [SGS] AMERICANA - INTERNET HUGHESNET
ESTEIO - ALGAR                | [SGS] ESTEIO - INTERNET ALGAR
HIDROMARES - VIVO             | [SGS] HIDROMARES - INTERNET VIVO
SÃO LUIS - VIVO               | [SGS] SÃO LUIS - INTERNET VIVO
BARCARENA - VIVO              | [SGS] BARCARENA - INTERNET VIVO
AMERICANA - EMBRATEL          | [SGS] AMERICANA - INTERNET EMBRATEL
FOODLAB - ALGAR               | [SGS] FOOD LAB - INTERNET ALGAR
RIO GRANDE - ALGAR            | [SGS] RIO GRANDE - INTERNET ALGAR
SERRA INDUSTRIAL - ALGAR      | [SGS] SERRA INDUSTRIAL - INTERNET ALGAR
BARCARENA - VEGANET           | [SGS] BARCARENA - INTERNET VEGANET
ARATU - VIVO                  | [SGS] ARATU - INTERNET VIVO
FOODLAB - VIVO                | [SGS] FOOD LAB - INTERNET VIVO
RIO GRANDE - OI               | [SGS] RIO GRANDE - INTERNET OI
SERRA INDUSTRIAL - VIVO       | [SGS] SERRA INDUSTRIAL - INTERNET VIVO
TRIUNFO - VEGANET             | [SGS] TRIUNFO - INTERNET VEGANET
L2L VIVO DC - HO              | [SGS] - Switch DC CORE - ARUBA | Interface 1/47(L2L-VIVO-CRS-500MB): Operational status
ILHA BARNABE - VIPWAY         | [SGS] ILHA BARNABE - INTERNET VIPWAY
RECREIO - VIVO                | [SGS] RECREIO - INTERNET VIVO
SERRA MINERALS - ALGAR        | [SGS] SERRA MINERALS - INTERNET ALGAR
DUQUE-ARLANXEO - VEGANET      | [SGS] DUQUE ARLANXEO - INTERNET VEGANET
CABO - VIVO                   | [SGS] CABO - INTERNET VIVO
LUIS EDUARDO MAGALHÃES - DBT  | [SGS] LUIZ EDUARDO MAGALHÃES - INTERNET DBT
RECREIO - ALGAR               | [SGS] RECREIO - INTERNET ALGAR
SERRA MINERALS - VIVO         | [SGS] SERRA MINERALS - INTERNET VIVO
DUQUE - BRASKEM Q4 - VEGANET  | [SGS] DUQUE BRASKEM Q4 - INTERNET VEGANET
DC VIVO - VIVO 01             | [SGS] DATA CENTER - INTERNET VIVO 01
PORTO AÇU - ACESSO TOTAL      | [SGS] PORTO AÇU - INTERNET VERTV
SANTOS - VIVO                 | [SGS] SANTOS - INTERNET VIVO
RESTINGA SECA - FAP           | [SGS] RESTINGA SECA - INTERNET FAP
DUQUE - BRASKEM PP5 - VEGANET | [SGS] DUQUE PP5 - INTERNET VEGANET
DC VIVO - VIVO 2              | [SGS] DATA CENTER - INTERNET VIVO 02
PARANAGUÁ - VIVO              | [SGS] PARANAGUÁ - INTERNET VIVO
SANTOS - ALGAR                | [SGS] SANTOS - INTERNET ALGAR
VESPASIANO - VIVO             | [SGS] VESPASIANO - INTERNET VIVO
ITAGUAÍ - VEGANET             | [SGS] ITAGUAÍ - INTERNET VEGANET
DC VIVO - ALGAR               | [SGS] DATA CENTER - INTERNET ALGAR
PIRACICABA - ALGAR            | [SGS] PIRACICABA - INTERNET ALGAR
SANTO ANDRÉ - ALHAMBRA        | [SGS] SANTO ANDRE - INTERNET ALHAMBRA
ITAPETININGA - DESKTOP        | [SGS] ITAPETININGA - INTERNET DESKTOP
SÃO JOÃO DA BARRA - VEGANET   | [SGS] SÃO JOÃO DA BARRA - INTERNET VEGANET
ESTEIO - VIVO                 | [SGS] ESTEIO - INTERNET VIVO
PIRACICABA - VIVO             | [SGS] PIRACICABA - INTERNET VIVO
SÃO BERNARDO - ALGAR          | [SGS] SÃO BERNARDO - INTERNET ALGAR
PORTO SUAPE CON - EVOLNET     | [SGS] SUAPE CONTAINER - INTERNET EVOLNET
CAMAÇARI - GT CONECT          | [SGS] CAMAÇARI - INTERNET GT CONECT
HIDROMARES - NET              | [SGS] HIDROMARES - INTERNET NET
SÃO BERNARDO - VIVO 2         | [SGS] SÃO BERNARDO - INTERNET VIVO
PORTO SUAPE LAB - EVOLNET     | [SGS] SUAPE LABORATÓRIO - INTERNET EVOLNET
</pre>
<div id="sgs-noc-wallboard-root"></div>
'@

# 3. Coletar estado inicial do Zabbix para cache instantâneo (Zero-Flash no boot)
$hRes = Invoke-RestMethod -Uri $ZabbixUrl -Method Post -Body ([System.Text.Encoding]::UTF8.GetBytes((@{
    jsonrpc="2.0"; method="host.get"; params=@{
        output=@("hostid","host","name","status");
        search=@{ name="[SGS]" }
    }; auth=$ZabbixToken; id=1
} | ConvertTo-Json -Depth 5))) -ContentType "application/json"

$allZbxHosts = $hRes.result
$hostIds = $allZbxHosts | ForEach-Object { $_.hostid }

$iRes = Invoke-RestMethod -Uri $ZabbixUrl -Method Post -Body ([System.Text.Encoding]::UTF8.GetBytes((@{
    jsonrpc="2.0"; method="item.get"; params=@{
        output=@("itemid","hostid","name","key_","lastvalue");
        hostids=$hostIds;
        search=@{ name=@("ICMP ping","Operational status") };
        searchByAny=$true
    }; auth=$ZabbixToken; id=2
} | ConvertTo-Json -Depth 5))) -ContentType "application/json"

function Normalize-Key($str) {
    if (-not $str) { return "" }
    $norm = $str.Normalize([System.Text.NormalizationForm]::FormD)
    $sb = New-Object System.Text.StringBuilder
    foreach ($c in $norm.ToCharArray()) {
        if ([System.Globalization.CharUnicodeInfo]::GetUnicodeCategory($c) -ne [System.Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$sb.Append($c)
        }
    }
    return $sb.ToString().ToUpperInvariant().Trim()
}

$itemsByHost = @{}
foreach ($it in $iRes.result) {
    if (-not $itemsByHost.ContainsKey($it.hostid)) { $itemsByHost[$it.hostid] = @() }
    $itemsByHost[$it.hostid] += $it
}

$initialCache = @{}
foreach ($h in $allZbxHosts) {
    $hid = $h.hostid
    $its = $itemsByHost[$hid]
    if ($its) {
        $itemMap = @{}
        foreach ($it in $its) {
            $itemMap[$it.name] = @{ itemid = $it.itemid; val = [int]$it.lastvalue }
        }
        $k = Normalize-Key $h.name
        $initialCache[$k] = @{
            hostid = $hid
            name = $h.name
            items = $itemMap
        }
    }
}
$initialCacheJson = $initialCache | ConvertTo-Json -Compress -Depth 6

# 4. Template AfterRender JavaScript (Single-Quoted Here-String para preservar template literals)
$afterRenderTemplate = @'
(function() {
  const ZABBIX_URL = "__ZABBIX_URL__";
  const ZABBIX_TOKEN = "__ZABBIX_TOKEN__";
  const DASHBOARD_UID = "__DASHBOARD_UID__";
  const INITIAL_CACHE = __INITIAL_CACHE__;

  const root = document.getElementById("sgs-noc-wallboard-root");
  const configEl = document.getElementById("sgs-noc-links-config");
  if (!root || !configEl) return;

  let parentEl = root.parentElement;
  for (let d = 0; d < 5 && parentEl && parentEl !== document.body; d++) {
    parentEl.style.height = "100%";
    parentEl.style.display = "flex";
    parentEl.style.flexDirection = "column";
    if (parentEl.classList.contains("panel-content")) {
      parentEl.style.padding = "2px";
      parentEl.style.overflow = "hidden";
      break;
    }
    parentEl = parentEl.parentElement;
  }

  if (window.__sgsNocWallboardTimer) {
    clearInterval(window.__sgsNocWallboardTimer);
    window.__sgsNocWallboardTimer = null;
  }
  if (window.__sgsNocClockTimer) {
    clearInterval(window.__sgsNocClockTimer);
    window.__sgsNocClockTimer = null;
  }

  let styleEl = document.getElementById("sgs-noc-wallboard-styles");
  if (!styleEl) {
    styleEl = document.createElement("style");
    styleEl.id = "sgs-noc-wallboard-styles";
    document.head.appendChild(styleEl);
  }

  styleEl.textContent = `
    #sgs-noc-wallboard-root {
      width: 100%;
      height: 100%;
      flex: 1;
      min-height: 0;
      box-sizing: border-box;
      background: radial-gradient(circle at 50% 0%, #111c2d 0%, #090e17 55%, #06090f 100%);
      border: 1px solid rgba(56, 189, 248, 0.18);
      border-radius: 10px;
      padding: 10px 12px 12px 12px;
      display: flex;
      flex-direction: column;
      gap: 10px;
      font-family: 'Inter', 'Segoe UI', Roboto, Helvetica, sans-serif;
      color: #f8fafc;
      user-select: none;
      overflow: hidden;
      position: relative;
      box-shadow: inset 0 1px 0 rgba(255,255,255,0.06), 0 10px 30px rgba(0,0,0,0.6);
    }
    #sgs-noc-wallboard-root * { box-sizing: border-box; }
    .noc-header {
      display: flex; align-items: center; justify-content: space-between;
      background: linear-gradient(180deg, rgba(19, 29, 46, 0.96) 0%, rgba(11, 17, 28, 0.99) 100%);
      border: 1px solid rgba(148, 163, 184, 0.2);
      border-bottom: 2px solid rgba(56, 189, 248, 0.4);
      border-radius: 8px; padding: 8px 16px; height: 76px; flex-shrink: 0;
      box-shadow: 0 4px 16px rgba(0, 0, 0, 0.45);
    }
    .noc-header.has-down { border-bottom-color: rgba(255, 23, 68, 0.75); }
    .noc-brand { display: flex; align-items: center; gap: 14px; min-width: 0; }
    .noc-logo-box {
      display: flex; align-items: center; background: #141419;
      border: 1px solid rgba(255,255,255,0.12); border-radius: 6px;
      padding: 4px 10px; height: 54px; overflow: hidden; flex-shrink: 0;
    }
    .noc-logo-img { height: 44px; width: auto; object-fit: contain; display: block; }
    .noc-title-block { display: flex; flex-direction: column; gap: 3px; }
    .noc-title-main {
      font-size: 15.5px; font-weight: 900; letter-spacing: 0.7px; color: #ffffff;
      text-transform: uppercase; white-space: nowrap;
    }
    .noc-title-sub { font-size: 11px; font-weight: 600; color: #94a3b8; letter-spacing: 0.3px; white-space: nowrap; }
    .noc-kpi-strip { display: flex; align-items: center; gap: 10px; }
    .noc-kpi-pill {
      display: flex; align-items: center; gap: 10px; padding: 6px 14px;
      border-radius: 7px; background: rgba(15, 23, 42, 0.85);
      border: 1px solid rgba(148, 163, 184, 0.22); height: 54px; min-width: 116px;
    }
    .noc-kpi-pill.kpi-total { border-color: rgba(56, 189, 248, 0.38); background: linear-gradient(135deg, rgba(14, 116, 144, 0.28) 0%, rgba(15, 23, 42, 0.92) 100%); }
    .noc-kpi-pill.kpi-up { border-color: rgba(0, 230, 118, 0.48); background: linear-gradient(135deg, rgba(6, 95, 70, 0.48) 0%, rgba(6, 40, 30, 0.92) 100%); }
    .noc-kpi-pill.kpi-down { border-color: rgba(255, 23, 68, 0.75); background: linear-gradient(135deg, rgba(185, 28, 28, 0.72) 0%, rgba(69, 10, 10, 0.95) 100%); box-shadow: 0 0 16px rgba(255, 23, 68, 0.3); }
    .noc-kpi-pill.kpi-down.zero-down { border-color: rgba(148, 163, 184, 0.2); background: rgba(15, 23, 42, 0.6); box-shadow: none; opacity: 0.65; }
    .noc-kpi-pill.kpi-sla { border-color: rgba(250, 204, 21, 0.42); background: linear-gradient(135deg, rgba(113, 63, 18, 0.32) 0%, rgba(15, 23, 42, 0.92) 100%); }
    .noc-kpi-num { font-size: 26px; font-weight: 900; line-height: 1; font-variant-numeric: tabular-nums; }
    .kpi-total .noc-kpi-num { color: #38bdf8; }
    .kpi-up .noc-kpi-num { color: #00e676; text-shadow: 0 0 10px rgba(0, 230, 118, 0.4); }
    .kpi-down .noc-kpi-num { color: #ff5252; text-shadow: 0 0 12px rgba(255, 23, 68, 0.6); }
    .kpi-down.zero-down .noc-kpi-num { color: #94a3b8; text-shadow: none; }
    .kpi-sla .noc-kpi-num { color: #facc15; font-size: 21px; }
    .noc-kpi-meta { display: flex; flex-direction: column; justify-content: center; }
    .noc-kpi-label { font-size: 10px; font-weight: 800; letter-spacing: 0.7px; text-transform: uppercase; color: #cbd5e1; }
    .noc-kpi-sub { font-size: 9.5px; font-weight: 600; color: #94a3b8; }
    .noc-right-status { display: flex; align-items: center; gap: 12px; }
    .noc-clock-box { display: flex; flex-direction: column; align-items: flex-end; justify-content: center; }
    .noc-clock-time { font-size: 20px; font-weight: 900; color: #f8fafc; letter-spacing: 1px; font-variant-numeric: tabular-nums; line-height: 1.1; }
    .noc-sync-badge { display: flex; align-items: center; gap: 5px; font-size: 10px; font-weight: 700; color: #34d399; letter-spacing: 0.4px; }
    .noc-sync-dot { width: 7px; height: 7px; border-radius: 50%; background: #00e676; box-shadow: 0 0 8px #00e676; }
    .noc-n1-btn {
      background: rgba(30, 41, 59, 0.5); border: 1px solid rgba(148, 163, 184, 0.2);
      color: #94a3b8; border-radius: 6px; padding: 6px 8px; font-size: 11px; font-weight: 700;
      cursor: pointer; opacity: 0.22; transition: all 0.2s ease; display: flex; align-items: center; gap: 4px;
    }
    .noc-n1-btn:hover { opacity: 1; background: rgba(14, 116, 144, 0.6); border-color: #38bdf8; color: #ffffff; }
    .noc-grid {
      flex: 1; min-height: 0; display: grid;
      grid-template-columns: repeat(5, minmax(0, 1fr));
      grid-auto-rows: 1fr; gap: 8px; width: 100%;
    }
    .noc-card {
      position: relative; border-radius: 7px; padding: 6px 11px 6px 15px;
      display: flex; align-items: center; justify-content: space-between; gap: 8px; overflow: hidden;
    }
    .noc-card::before { content: ""; position: absolute; left: 0; top: 0; bottom: 0; width: 5px; }
    .noc-card.is-up {
      background: linear-gradient(135deg, rgba(6, 78, 59, 0.74) 0%, rgba(4, 42, 32, 0.90) 100%);
      border: 1px solid rgba(16, 185, 129, 0.45);
      box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.07), 0 2px 6px rgba(0, 0, 0, 0.35);
    }
    .noc-card.is-up::before { background: #00e676; box-shadow: 0 0 10px #00e676; }
    @keyframes nocDownPulse {
      0%, 100% { box-shadow: inset 0 0 18px rgba(255, 23, 68, 0.35), 0 0 14px rgba(255, 23, 68, 0.45); border-color: #ff5252; }
      50% { box-shadow: inset 0 0 28px rgba(255, 23, 68, 0.65), 0 0 22px rgba(255, 23, 68, 0.85); border-color: #ff8a80; }
    }
    @keyframes nocLedBlink {
      0%, 100% { opacity: 1; transform: scale(1); }
      50% { opacity: 0.35; transform: scale(0.88); }
    }
    .noc-card.is-down {
      background: linear-gradient(135deg, rgba(185, 28, 28, 0.95) 0%, rgba(105, 15, 15, 0.98) 100%);
      border: 1.5px solid #ff5252; animation: nocDownPulse 1.8s infinite ease-in-out;
    }
    .noc-card.is-down::before { background: #ff1744; box-shadow: 0 0 14px #ff1744; width: 6px; }
    .noc-card-left { display: flex; align-items: center; gap: 10px; min-width: 0; flex: 1; }
    .noc-led { width: 11px; height: 11px; border-radius: 50%; flex-shrink: 0; }
    .noc-card.is-up .noc-led { background: radial-gradient(circle at 35% 35%, #b9f6ca, #00e676 60%, #00b248 100%); box-shadow: 0 0 9px #00e676; }
    .noc-card.is-down .noc-led { background: radial-gradient(circle at 35% 35%, #ffffff, #ff5252 55%, #d50000 100%); box-shadow: 0 0 12px #ff1744; animation: nocLedBlink 0.9s infinite ease-in-out; }
    .noc-card-titles { display: flex; flex-direction: column; justify-content: center; min-width: 0; gap: 3px; }
    .noc-site-name {
      font-size: 13px; font-weight: 800; color: #ffffff; letter-spacing: 0.2px; line-height: 1.15;
      white-space: nowrap; overflow: hidden; text-overflow: ellipsis; text-shadow: 0 1px 2px rgba(0, 0, 0, 0.65);
    }
    .noc-isp-row { display: flex; align-items: center; gap: 6px; }
    .noc-isp-badge { font-size: 10.5px; font-weight: 800; letter-spacing: 0.6px; padding: 1px 6px; border-radius: 3px; text-transform: uppercase; white-space: nowrap; }
    .noc-card.is-up .noc-isp-badge { background: rgba(0, 0, 0, 0.32); color: #a7f3d0; border: 1px solid rgba(52, 211, 153, 0.3); }
    .noc-card.is-down .noc-isp-badge { background: rgba(0, 0, 0, 0.4); color: #fecaca; border: 1px solid rgba(252, 165, 165, 0.45); }
    .noc-status-pill { flex-shrink: 0; font-size: 11px; font-weight: 900; letter-spacing: 0.6px; padding: 4px 8px; border-radius: 4px; text-transform: uppercase; text-align: center; min-width: 48px; }
    .noc-card.is-up .noc-status-pill { background: rgba(0, 230, 118, 0.18); border: 1px solid rgba(0, 230, 118, 0.55); color: #69f0ae; text-shadow: 0 0 6px rgba(0, 230, 118, 0.35); }
    .noc-card.is-down .noc-status-pill { background: #ff1744; border: 1px solid #ff8a80; color: #ffffff; box-shadow: 0 0 10px rgba(255, 23, 68, 0.7); }
    .noc-modal-backdrop { position: absolute; inset: 0; background: rgba(5, 9, 16, 0.88); backdrop-filter: blur(6px); z-index: 9999; display: flex; align-items: center; justify-content: center; padding: 20px; }
    .noc-modal { width: 100%; max-width: 920px; max-height: 92%; background: #0f172a; border: 1px solid #38bdf8; border-radius: 10px; display: flex; flex-direction: column; box-shadow: 0 20px 50px rgba(0,0,0,0.85); overflow: hidden; }
    .noc-modal-header { padding: 14px 18px; background: #1e293b; border-bottom: 1px solid rgba(148,163,184,0.2); display: flex; align-items: center; justify-content: space-between; }
    .noc-modal-title { font-size: 15px; font-weight: 800; color: #38bdf8; }
    .noc-modal-body { padding: 16px 18px; overflow-y: auto; display: flex; flex-direction: column; gap: 12px; flex: 1; }
    .noc-modal-help { background: rgba(14, 116, 144, 0.2); border: 1px solid rgba(56, 189, 248, 0.35); border-radius: 6px; padding: 10px 12px; font-size: 12px; color: #e2e8f0; line-height: 1.45; }
    .noc-add-bar { display: grid; grid-template-columns: 1.2fr 1.6fr 1fr auto; gap: 8px; background: rgba(30, 41, 59, 0.7); padding: 10px; border-radius: 6px; border: 1px solid rgba(148,163,184,0.2); }
    .noc-input { background: #090e17; border: 1px solid rgba(148,163,184,0.35); color: #ffffff; border-radius: 5px; padding: 7px 10px; font-size: 12px; width: 100%; }
    .noc-btn { background: #0284c7; color: #ffffff; border: none; border-radius: 5px; padding: 7px 14px; font-size: 12px; font-weight: 700; cursor: pointer; white-space: nowrap; }
    .noc-btn.save { background: #059669; }
    .noc-btn.cancel { background: #475569; }
    .noc-btn.del { background: #dc2626; padding: 4px 8px; font-size: 11px; }
    .noc-links-table { width: 100%; border-collapse: collapse; font-size: 12px; }
    .noc-links-table th, .noc-links-table td { padding: 6px 8px; border-bottom: 1px solid rgba(148,163,184,0.15); text-align: left; }
    .noc-links-table th { color: #94a3b8; font-weight: 700; background: rgba(15, 23, 42, 0.9); position: sticky; top: 0; }
    .noc-modal-footer { padding: 12px 18px; background: #1e293b; border-top: 1px solid rgba(148,163,184,0.2); display: flex; align-items: center; justify-content: space-between; }
  `;

  function normalizeStr(s) {
    if (!s) return "";
    return s.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toUpperCase().trim();
  }

  function parseConfigLinks(rawText) {
    const lines = (rawText || "").split(/\r?\n/);
    const parsed = [];
    for (let line of lines) {
      const t = line.trim();
      if (!t || t.startsWith("#") || t.startsWith("//") || t.startsWith("<!--")) continue;
      const parts = t.split("|").map(x => x.trim());
      const label = parts[0] || "";
      const host = parts[1] || parts[0] || "";
      const item = parts[2] || "ICMP ping";
      if (!label) continue;

      let site = label;
      let isp = "WAN";
      const lastDash = label.lastIndexOf("-");
      if (lastDash > 0) {
        site = label.substring(0, lastDash).trim();
        isp = label.substring(lastDash + 1).trim();
      }

      parsed.push({
        label, site, isp, host, item,
        normHost: normalizeStr(host),
        status: 1
      });
    }
    return parsed;
  }

  let linksList = parseConfigLinks(configEl.textContent);
  let zbxHostMap = Object.assign({}, INITIAL_CACHE);
  let allZbxHostNames = Object.values(INITIAL_CACHE).map(h => h.name).sort();

  function evaluateLinksStatus() {
    for (let lk of linksList) {
      let hEntry = zbxHostMap[lk.normHost];
      if (!hEntry) {
        const cleanTarget = lk.normHost.replace(/^\[SGS\]\s*-?\s*/, "");
        for (let k of Object.keys(zbxHostMap)) {
          const cleanK = k.replace(/^\[SGS\]\s*-?\s*/, "");
          if (cleanK === cleanTarget || k.includes(cleanTarget) || cleanTarget.includes(cleanK)) {
            hEntry = zbxHostMap[k];
            break;
          }
        }
      }
      if (hEntry && hEntry.items) {
        const exactIt = hEntry.items[lk.item];
        if (exactIt !== undefined) {
          lk.status = (Number(exactIt.val) === 1) ? 1 : 0;
        } else {
          const targetItemUpper = (lk.item || "ICMP ping").toUpperCase();
          let matched = null;
          for (let iName of Object.keys(hEntry.items)) {
            if (iName.toUpperCase() === targetItemUpper || iName.toUpperCase().includes(targetItemUpper)) {
              matched = hEntry.items[iName];
              break;
            }
          }
          if (matched !== null) {
            lk.status = (Number(matched.val) === 1) ? 1 : 0;
          }
        }
      }
    }
  }

  function renderWallboard() {
    evaluateLinksStatus();
    const total = linksList.length;
    const upCount = linksList.filter(x => x.status === 1).length;
    const downCount = total - upCount;
    const sla = total > 0 ? ((upCount / total) * 100).toFixed(1) : "100.0";
    const nowStr = new Date().toLocaleTimeString("pt-BR", { hour: "2-digit", minute: "2-digit", second: "2-digit" });

    let cardsHtml = "";
    for (let i = 0; i < linksList.length; i++) {
      const lk = linksList[i];
      const isUp = lk.status === 1;
      const stateClass = isUp ? "is-up" : "is-down";
      const badgeText = isUp ? "UP" : "DOWN";
      cardsHtml += `
        <div class="noc-card ${stateClass}">
          <div class="noc-card-left">
            <div class="noc-led"></div>
            <div class="noc-card-titles">
              <div class="noc-site-name" title="${lk.label}">${lk.site}</div>
              <div class="noc-isp-row">
                <span class="noc-isp-badge">${lk.isp}</span>
              </div>
            </div>
          </div>
          <div class="noc-status-pill">${badgeText}</div>
        </div>
      `;
    }

    const existingModal = document.getElementById("sgs-noc-n1-modal");
    root.innerHTML = `
      <div class="noc-header ${downCount > 0 ? 'has-down' : ''}">
        <div class="noc-brand">
          <div class="noc-logo-box">
            <img class="noc-logo-img" src="/public/img/logos/Network_SGS.png" alt="Grupo Vega | Network | SGS" onerror="this.style.display='none'" />
          </div>
          <div class="noc-title-block">
            <div class="noc-title-main"><span>NOC • MONITORAMENTO DE LINKS WAN</span></div>
            <div class="noc-title-sub">Painel de Disponibilidade em Tempo Real • SGS_LINKS</div>
          </div>
        </div>
        <div class="noc-kpi-strip">
          <div class="noc-kpi-pill kpi-total">
            <div class="noc-kpi-num">${total}</div>
            <div class="noc-kpi-meta"><span class="noc-kpi-label">MONITORADOS</span><span class="noc-kpi-sub">Total Links</span></div>
          </div>
          <div class="noc-kpi-pill kpi-up">
            <div class="noc-kpi-num">${upCount}</div>
            <div class="noc-kpi-meta"><span class="noc-kpi-label">ONLINE</span><span class="noc-kpi-sub">Links UP</span></div>
          </div>
          <div class="noc-kpi-pill kpi-down ${downCount === 0 ? 'zero-down' : ''}">
            <div class="noc-kpi-num">${downCount}</div>
            <div class="noc-kpi-meta"><span class="noc-kpi-label">OFFLINE</span><span class="noc-kpi-sub">Links DOWN</span></div>
          </div>
          <div class="noc-kpi-pill kpi-sla">
            <div class="noc-kpi-num">${sla}%</div>
            <div class="noc-kpi-meta"><span class="noc-kpi-label">SLA ATUAL</span><span class="noc-kpi-sub">Disponibilidade</span></div>
          </div>
        </div>
        <div class="noc-right-status">
          <div class="noc-clock-box">
            <div class="noc-clock-time" id="sgs-noc-live-clock">${nowStr}</div>
            <div class="noc-sync-badge"><span class="noc-sync-dot"></span><span>ZABBIX LIVE (5s)</span></div>
          </div>
          <button class="noc-n1-btn" id="sgs-noc-open-n1" title="Gerenciador de Links N1">⚙ N1</button>
        </div>
      </div>
      <div class="noc-grid">${cardsHtml}</div>
    `;

    if (existingModal) root.appendChild(existingModal);
    const btnN1 = document.getElementById("sgs-noc-open-n1");
    if (btnN1) btnN1.onclick = openN1EditorModal;
  }

  async function pollZabbixStatus() {
    try {
      const [hRespSgs, hRespGrp] = await Promise.all([
        fetch(ZABBIX_URL, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ jsonrpc: "2.0", method: "host.get", params: { output: ["hostid", "name"], search: { name: "[SGS]" } }, auth: ZABBIX_TOKEN, id: 101 })
        }),
        fetch(ZABBIX_URL, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ jsonrpc: "2.0", method: "host.get", params: { output: ["hostid", "name"], groupids: ["38"] }, auth: ZABBIX_TOKEN, id: 103 })
        })
      ]);
      const hDataSgs = await hRespSgs.json();
      const hDataGrp = await hRespGrp.json();
      const mergedMap = {};
      for (let h of (hDataSgs.result || [])) mergedMap[h.hostid] = h;
      for (let h of (hDataGrp.result || [])) mergedMap[h.hostid] = h;
      const hosts = Object.values(mergedMap);
      if (hosts.length === 0) return;

      allZbxHostNames = hosts.map(h => h.name).sort();
      const hostIds = hosts.map(h => h.hostid);

      const iResp = await fetch(ZABBIX_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          jsonrpc: "2.0",
          method: "item.get",
          params: { output: ["itemid", "hostid", "name", "lastvalue"], hostids: hostIds, search: { name: ["ICMP ping", "Operational status"] }, searchByAny: true },
          auth: ZABBIX_TOKEN,
          id: 102
        })
      });
      const iData = await iResp.json();
      const byHost = {};
      for (let it of (iData.result || [])) {
        if (!byHost[it.hostid]) byHost[it.hostid] = {};
        byHost[it.hostid][it.name] = { itemid: it.itemid, val: parseInt(it.lastvalue, 10) };
      }
      const newMap = {};
      for (let h of hosts) {
        if (byHost[h.hostid]) {
          newMap[normalizeStr(h.name)] = { hostid: h.hostid, name: h.name, items: byHost[h.hostid] };
        }
      }
      zbxHostMap = newMap;
      renderWallboard();
    } catch (e) {
      console.warn("[SGS-NOC] Poll error:", e);
    }
  }

  function openN1EditorModal() {
    let existing = document.getElementById("sgs-noc-n1-modal");
    if (existing) existing.remove();
    let draftLinks = linksList.map(x => ({ label: x.label, host: x.host, item: x.item }));
    const modalWrap = document.createElement("div");
    modalWrap.id = "sgs-noc-n1-modal";
    modalWrap.className = "noc-modal-backdrop";

    function renderModalContent() {
      const hostOptionsHtml = allZbxHostNames.map(hn => `<option value="${hn}">`).join("");
      let rowsHtml = "";
      draftLinks.forEach((dl, idx) => {
        rowsHtml += `
          <tr>
            <td style="color:#64748b;font-weight:700;">${idx + 1}</td>
            <td><input class="noc-input row-label" data-idx="${idx}" value="${dl.label.replace(/"/g, '&quot;')}" /></td>
            <td><input class="noc-input row-host" list="sgs-zbx-hosts-datalist" data-idx="${idx}" value="${dl.host.replace(/"/g, '&quot;')}" /></td>
            <td><input class="noc-input row-item" data-idx="${idx}" value="${(dl.item || 'ICMP ping').replace(/"/g, '&quot;')}" /></td>
            <td><button class="noc-btn del row-del" data-idx="${idx}">🗑️ Remover</button></td>
          </tr>
        `;
      });

      modalWrap.innerHTML = `
        <div class="noc-modal">
          <div class="noc-modal-header">
            <span class="noc-modal-title">📋 GERENCIADOR DE LINKS DO NOC (EDIÇÃO FÁCIL N1)</span>
            <button class="noc-btn cancel" id="noc-modal-close">✕ Fechar</button>
          </div>
          <div class="noc-modal-body">
            <div class="noc-modal-help">
              <b>Como editar os links desta tela:</b><br/>
              • <b>Adicionar novo link:</b> Preencha <i>Nome no Card (Ex: CIDADE - OPERADORA)</i>, escolha o <i>Host do Zabbix</i> abaixo e clique em <b>+ Adicionar Link</b>.<br/>
              • <b>Alterar ou Remover:</b> Edite qualquer linha diretamente na tabela abaixo ou clique em <b>🗑️ Remover</b> e depois em <b>💾 Salvar na Dashboard</b>.
            </div>
            <datalist id="sgs-zbx-hosts-datalist">${hostOptionsHtml}</datalist>
            <div class="noc-add-bar">
              <input id="noc-new-label" class="noc-input" placeholder="Nome no Card (Ex: BARCARENA - STARLINK)" />
              <input id="noc-new-host" class="noc-input" list="sgs-zbx-hosts-datalist" placeholder="Host no Zabbix (Ex: [SGS] BARCARENA - INTERNET...)" />
              <input id="noc-new-item" class="noc-input" value="ICMP ping" placeholder="Item (Padrão: ICMP ping)" />
              <button id="noc-btn-add" class="noc-btn">+ Adicionar Link</button>
            </div>
            <div style="max-height:380px;overflow-y:auto;border:1px solid rgba(148,163,184,0.2);border-radius:6px;">
              <table class="noc-links-table">
                <thead>
                  <tr>
                    <th style="width:40px">#</th>
                    <th>Nome Exibido no Card (LOCAL - OPERADORA)</th>
                    <th>Nome do Host no Zabbix</th>
                    <th style="width:180px">Item Monitorado</th>
                    <th style="width:95px">Ação</th>
                  </tr>
                </thead>
                <tbody>${rowsHtml}</tbody>
              </table>
            </div>
          </div>
          <div class="noc-modal-footer">
            <span id="noc-save-status" style="font-size:12px;color:#94a3b8;">Total configurado: <b>${draftLinks.length} links</b></span>
            <div style="display:flex;gap:10px;">
              <button class="noc-btn cancel" id="noc-modal-cancel">Cancelar</button>
              <button class="noc-btn save" id="noc-modal-save">💾 Salvar na Dashboard</button>
            </div>
          </div>
        </div>
      `;

      modalWrap.querySelectorAll(".row-label").forEach(inp => { inp.oninput = (e) => { draftLinks[Number(e.target.dataset.idx)].label = e.target.value; }; });
      modalWrap.querySelectorAll(".row-host").forEach(inp => { inp.oninput = (e) => { draftLinks[Number(e.target.dataset.idx)].host = e.target.value; }; });
      modalWrap.querySelectorAll(".row-item").forEach(inp => { inp.oninput = (e) => { draftLinks[Number(e.target.dataset.idx)].item = e.target.value; }; });
      modalWrap.querySelectorAll(".row-del").forEach(btn => {
        btn.onclick = (e) => {
          draftLinks.splice(Number(e.currentTarget.dataset.idx), 1);
          renderModalContent();
        };
      });

      document.getElementById("noc-btn-add").onclick = () => {
        const lbl = document.getElementById("noc-new-label").value.trim();
        const hst = document.getElementById("noc-new-host").value.trim();
        const itm = document.getElementById("noc-new-item").value.trim() || "ICMP ping";
        if (!lbl || !hst) { alert("Preencha o Nome no Card e o Host no Zabbix!"); return; }
        draftLinks.push({ label: lbl, host: hst, item: itm });
        renderModalContent();
      };

      document.getElementById("noc-modal-close").onclick = () => modalWrap.remove();
      document.getElementById("noc-modal-cancel").onclick = () => modalWrap.remove();
      document.getElementById("noc-modal-save").onclick = async () => {
        const statusEl = document.getElementById("noc-save-status");
        statusEl.textContent = "⏳ Salvando alterações no Grafana...";
        const formattedLines = draftLinks.map(d => {
          const padLabel = d.label.padEnd(30, " ");
          return (!d.item || d.item === "ICMP ping") ? `${padLabel}| ${d.host}` : `${padLabel}| ${d.host} | ${d.item}`;
        }).join("\n");

        const newContentHtml = `<pre id="sgs-noc-links-config" style="display:none;">\n${formattedLines}\n</pre>\n<div id="sgs-noc-wallboard-root"></div>`;
        try {
          const getRes = await fetch(`/api/dashboards/uid/${DASHBOARD_UID}`);
          const dashObj = await getRes.json();
          dashObj.dashboard.panels[0].options.content = newContentHtml;
          const saveRes = await fetch("/api/dashboards/db", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ dashboard: dashObj.dashboard, folderId: dashObj.meta.folderId, overwrite: true, message: "Atualização de links via Gerenciador N1" })
          });
          if (!saveRes.ok) throw new Error("HTTP " + saveRes.status);
          configEl.textContent = formattedLines;
          linksList = parseConfigLinks(formattedLines);
          modalWrap.remove();
          renderWallboard();
        } catch (err) {
          statusEl.textContent = "❌ Erro ao salvar: " + err.message;
        }
      };
    }

    root.appendChild(modalWrap);
    renderModalContent();
  }

  renderWallboard();
  pollZabbixStatus();
  window.__sgsNocWallboardTimer = setInterval(pollZabbixStatus, 5000);
  window.__sgsNocClockTimer = setInterval(() => {
    const clk = document.getElementById("sgs-noc-live-clock");
    if (clk) clk.textContent = new Date().toLocaleTimeString("pt-BR", { hour: "2-digit", minute: "2-digit", second: "2-digit" });
  }, 1000);
})();
'@

$afterRenderJs = $afterRenderTemplate.Replace("__ZABBIX_URL__", $ZabbixUrl).Replace("__ZABBIX_TOKEN__", $ZabbixToken).Replace("__DASHBOARD_UID__", $DashboardUid).Replace("__INITIAL_CACHE__", $initialCacheJson)

$newPanel = @{
    id = 1
    type = "marcusolsson-dynamictext-panel"
    title = ""
    transparent = $true
    gridPos = @{ x = 0; y = 0; w = 20; h = 24 }
    datasource = @{ type = "alexanderzobnin-zabbix-datasource"; uid = "fdzsfqj0b5wqob" }
    targets = @(@{ refId = "A"; queryType = "0"; group = @{ filter = "SGS_LINKS" }; host = @{ filter = "/.*/" }; item = @{ filter = "ICMP ping" } })
    options = @{
        content = $nocLinksList
        afterRender = $afterRenderJs
        defaultContent = ""
        everyRow = $false
        renderMode = "data"
        editors = @("afterRender")
        status = ""
        wrap = $false
    }
}

$dashPayload = @{
    dashboard = @{
        uid = $DashboardUid
        title = $DashboardTitle
        editable = $true
        fiscalYearStartMonth = 0
        graphTooltip = 0
        preload = $false
        refresh = "5s"
        schemaVersion = 42
        time = @{ from = "now-1h"; to = "now" }
        timepicker = @{ hidden = $true }
        timezone = ""
        panels = @($newPanel)
    }
    folderId = $FolderId
    folderUid = $FolderUid
    overwrite = $true
    message = "Deploy Automatizado NOC Wallboard (w=20, h=24)"
}

$payloadJson = $dashPayload | ConvertTo-Json -Depth 20
$base64 = [Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("${GrafanaUser}:${GrafanaPassword}"))
$headers = @{ Authorization = "Basic $base64"; "Content-Type" = "application/json; charset=utf-8" }

$deployRes = Invoke-RestMethod -Uri "$GrafanaUrl/api/dashboards/db" -Method Post -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($payloadJson))
Write-Output "Deploy concluído com sucesso! Status: $($deployRes.status) | Versão: $($deployRes.version) | URL: $($deployRes.url)"
