param(
    [Parameter(Mandatory=$true)][string]$Python,
    [int]$Port = 8765
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$previewRoot = Join-Path $projectRoot 'tmp/web_preview'
$documentRoot = Join-Path $previewRoot 'build/web'
$serverScript = Join-Path $PSScriptRoot 'serve_preview.py'
$pidFile = Join-Path $previewRoot 'server.pid'
if (-not (Test-Path -LiteralPath (Join-Path $documentRoot 'main.dart.js'))) {
    throw 'Build the browser preview first.'
}
if (Test-Path -LiteralPath $pidFile) {
    $previewPid = [int](Get-Content -LiteralPath $pidFile -Raw)
    $existing = Get-CimInstance Win32_Process -Filter "ProcessId = $previewPid"
    if ($existing) {
        $isOldPreview = $existing.CommandLine.Contains("-m http.server $Port --bind 127.0.0.1")
        $isProjectPreview = $existing.CommandLine.Contains('serve_preview.py') -and $existing.CommandLine.Contains($projectRoot)
        if (-not ($isOldPreview -or $isProjectPreview)) {
            throw 'The recorded process does not belong to this preview. It was not stopped.'
        }
        Stop-Process -Id $previewPid
        Wait-Process -Id $previewPid -ErrorAction SilentlyContinue
    }
}
$arguments = @(('"' + $serverScript + '"'), '--directory', ('"' + $documentRoot + '"'), '--port', "$Port")
$process = Start-Process -FilePath $Python -ArgumentList $arguments -WorkingDirectory $projectRoot -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $previewRoot 'server.log') -RedirectStandardError (Join-Path $previewRoot 'server-error.log')
$process.Id | Set-Content -LiteralPath $pidFile
Write-Output "Local preview process started: $($process.Id)"
