# =====================================================================
#  PC Hizlandirici - ortak fonksiyon kutuphanesi
#  Bu dosya her modulun basina otomatik eklenir. Modul degildir,
#  arayuzde gorunmez. Yeni modul yazarken bu fonksiyonlari kullanin.
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}
try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}

$script:PCH_Warnings = 0
$script:PCH_WorkDir  = Join-Path $env:TEMP 'PCHizlandirici'
New-Item -ItemType Directory -Force -Path $script:PCH_WorkDir -ErrorAction SilentlyContinue | Out-Null

# ---------------- cikti ----------------
function Say  ([string]$Text) { Write-Host "    $Text" }
function Ok   ([string]$Text) { Write-Host "[+] $Text" }
function Warn ([string]$Text) { $script:PCH_Warnings++; Write-Host "[!] $Text" }
function Fail ([string]$Text) { $script:PCH_Warnings++; Write-Host "[x] $Text" }

# Explorer'in islem sonunda yeniden baslatilmasini ister (arayuz tek sefer yapar)
function Request-ExplorerRestart { Write-Host '##EXPLORER##' }

# ---------------- sistem bilgisi ----------------
function Get-WinBuild { [int](Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').CurrentBuildNumber }
function Test-Win11   { (Get-WinBuild) -ge 22000 }

function Test-Internet {
    foreach ($h in 'www.microsoft.com', 'github.com') {
        try {
            $r = [Net.WebRequest]::Create("https://$h")
            $r.Method = 'HEAD'; $r.Timeout = 8000
            $resp = $r.GetResponse(); $resp.Close(); return $true
        } catch {}
    }
    return $false
}

# ---------------- kayit defteri ----------------
# Ornek: Set-Reg 'HKCU:\Software\X' 'Deger' 1
#        Set-Reg 'HKCU:\Software\X' 'Yazi' 'abc' String
function Set-Reg {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][AllowEmptyString()][AllowNull()]$Value,
        [ValidateSet('DWord', 'QWord', 'String', 'ExpandString', 'Binary', 'MultiString')]
        [string]$Type = 'DWord'
    )
    try {
        if (-not (Test-Path -LiteralPath $Path)) { New-Item -Path $Path -Force -ErrorAction Stop | Out-Null }
        New-ItemProperty -LiteralPath $Path -Name $Name -Value $Value -PropertyType $Type -Force -ErrorAction Stop | Out-Null
    } catch {
        Warn "Kayit yazilamadi: $Path\$Name ($($_.Exception.Message))"
    }
}

function Remove-RegValue ([string]$Path, [string]$Name) {
    if (Test-Path -LiteralPath $Path) {
        Remove-ItemProperty -LiteralPath $Path -Name $Name -Force -ErrorAction SilentlyContinue
    }
}

# Ayni ayari birden fazla kayda yazar: Set-RegMany 'HKCU:\...' @{ A = 0; B = 1 }
function Set-RegMany ([string]$Path, [hashtable]$Values, [string]$Type = 'DWord') {
    foreach ($k in $Values.Keys) { Set-Reg -Path $Path -Name $k -Value $Values[$k] -Type $Type }
}

# ---------------- servis / gorev ----------------
# StartType: Disabled | Manual | Automatic
function Set-ServiceStart ([string]$Name, [string]$StartType) {
    $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
    if (-not $svc) { return }
    $map = @{ Automatic = 2; Manual = 3; Disabled = 4 }
    try {
        Set-Service -Name $Name -StartupType $StartType -ErrorAction Stop
    } catch {
        # korumali servislerde kayit defteri ile dene
        Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\$Name" 'Start' $map[$StartType]
    }
    if ($StartType -eq 'Disabled') { Stop-Service -Name $Name -Force -ErrorAction SilentlyContinue }
    Say "$Name -> $StartType"
}

function Disable-Task ([string]$TaskPath, [string]$TaskName) {
    $t = Get-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($t) {
        $t | Disable-ScheduledTask -ErrorAction SilentlyContinue | Out-Null
        Say "Gorev kapatildi: $TaskPath$TaskName"
    }
}

# ---------------- indirme ----------------
function Get-File ([string]$Url, [string]$OutFile, [int]$Retry = 3) {
    for ($i = 1; $i -le $Retry; $i++) {
        try {
            $wc = New-Object Net.WebClient
            $wc.Headers.Add('User-Agent', 'PCHizlandirici')
            $wc.DownloadFile($Url, $OutFile)
            if ((Test-Path $OutFile) -and (Get-Item $OutFile).Length -gt 0) { return $true }
        } catch {
            Say "Indirme denemesi $i basarisiz: $($_.Exception.Message)"
            Start-Sleep -Seconds (2 * $i)
        }
    }
    return $false
}

# Indirilen dosyanin gecerli bir Microsoft (veya verilen yayinci) imzasi tasidigini dogrular
function Test-Signed ([string]$File, [string]$Publisher = 'Microsoft') {
    $sig = Get-AuthenticodeSignature -FilePath $File -ErrorAction SilentlyContinue
    return ($sig -and $sig.Status -eq 'Valid' -and $sig.SignerCertificate.Subject -match $Publisher)
}

# ---------------- uygulama paketleri ----------------
function Remove-AppxSafe ([string]$Pattern) {
    $found = $false
    Get-AppxPackage -AllUsers -Name $Pattern -ErrorAction SilentlyContinue | ForEach-Object {
        $found = $true
        try {
            Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction Stop
            Say "Kaldirildi: $($_.Name)"
        } catch {
            try { Remove-AppxPackage -Package $_.PackageFullName -ErrorAction Stop; Say "Kaldirildi: $($_.Name)" } catch {}
        }
    }
    Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like $Pattern } | ForEach-Object {
        Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue | Out-Null
    }
}
