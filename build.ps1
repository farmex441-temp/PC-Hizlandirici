# =====================================================================
#  PC Hizlandirici - derleme betigi
#  Kullanim:  powershell -ExecutionPolicy Bypass -File build.ps1
#  Cikti:     dist\PCHizlandirici.exe
#  Gereksinim: yok. Her Windows 10/11'de bulunan .NET Framework 4.x
#              derleyicisi (csc.exe) kullanilir; Visual Studio gerekmez.
# =====================================================================
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

$csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path $csc)) { $csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe' }
if (-not (Test-Path $csc)) { throw 'csc.exe bulunamadi (.NET Framework 4.x gerekli).' }

# Modullerde sozdizimi hatasi varsa derlemeyi durdur
$bad = 0
Get-ChildItem (Join-Path $root 'modules') -Filter *.ps1 | ForEach-Object {
    $tokens = $null; $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$tokens, [ref]$errors) | Out-Null
    foreach ($e in $errors) { Write-Host "SOZDIZIMI HATASI $($_.Name):$($e.Extent.StartLineNumber) $($e.Message)" -ForegroundColor Red; $bad++ }
}
if ($bad -gt 0) { throw "$bad sozdizimi hatasi var, derleme durduruldu." }

$dist = Join-Path $root 'dist'
New-Item -ItemType Directory -Force -Path $dist | Out-Null
$out = Join-Path $dist 'PCHizlandirici.exe'

$cscArgs = @(
    '/nologo', '/target:winexe', '/optimize+', '/codepage:65001', '/platform:anycpu',
    "/out:$out",
    "/win32manifest:$(Join-Path $root 'src\app.manifest')",
    '/r:System.dll', '/r:System.Core.dll', '/r:System.Drawing.dll', '/r:System.Windows.Forms.dll'
)
$icon = Join-Path $root 'assets\icon.ico'
if (Test-Path $icon) { $cscArgs += "/win32icon:$icon" }

# Tum moduller exe icine gomulur (modules/<dosya>.ps1 adiyla)
Get-ChildItem (Join-Path $root 'modules') -Filter *.ps1 | Sort-Object Name | ForEach-Object {
    $cscArgs += "/resource:$($_.FullName),modules/$($_.Name)"
}
$cscArgs += (Join-Path $root 'src\Program.cs')

& $csc @cscArgs
if ($LASTEXITCODE -ne 0) { throw "Derleme basarisiz (kod $LASTEXITCODE)." }

$hash = (Get-FileHash $out -Algorithm SHA256).Hash
Write-Host ""
Write-Host "Derlendi: $out" -ForegroundColor Green
Write-Host ("Boyut:    {0:N0} KB" -f ((Get-Item $out).Length / 1KB))
Write-Host "SHA256:   $hash"
