Add-Type -AssemblyName System.Net.Http

# 1. Carregar configurações do arquivo .env
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

$grafanaUrl = [Environment]::GetEnvironmentVariable("GRAFANA_URL")
if (-not $grafanaUrl) { $grafanaUrl = "http://10.0.0.25:3000" }
$user = [Environment]::GetEnvironmentVariable("GRAFANA_USER")
if (-not $user) { $user = "admin" }
$pass = [Environment]::GetEnvironmentVariable("GRAFANA_PASSWORD")
if (-not $pass) { $pass = "admin" }
$dashboardUid = [Environment]::GetEnvironmentVariable("GRAFANA_DASHBOARD_UID")
if (-not $dashboardUid) { $dashboardUid = "adhdb5q" }
$zabbixToken = [Environment]::GetEnvironmentVariable("ZABBIX_TOKEN")
$zabbixUrl = [Environment]::GetEnvironmentVariable("ZABBIX_URL")

$pair = "${user}:${pass}"
$b64 = [Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))

$c = New-Object System.Net.Http.HttpClient
$c.DefaultRequestHeaders.Authorization = New-Object System.Net.Http.Headers.AuthenticationHeaderValue("Basic", $b64)
$res = $c.GetStringAsync("$grafanaUrl/api/dashboards/uid/$dashboardUid").Result

# Sanitizar credenciais e IPs internos antes de versionar no GitHub
$sanitized = $res
if ($zabbixToken) {
    $sanitized = $sanitized.Replace($zabbixToken, "{{ZABBIX_API_TOKEN}}")
}
if ($zabbixUrl) {
    $sanitized = $sanitized.Replace($zabbixUrl, "http://{{ZABBIX_HOST}}/api_jsonrpc.php")
}

$outPath = Join-Path $PSScriptRoot "..\grafana\dashboards\sgs_links_status_noc.json"
[System.IO.File]::WriteAllText($outPath, $sanitized, (New-Object System.Text.UTF8Encoding($false)))
Write-Output "Dashboard exportada e sanitizada com sucesso em: $outPath ($($sanitized.Length) bytes)"
