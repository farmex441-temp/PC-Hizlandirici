# @name: NVIDIA Sürücüsünü Kur / Güncelle
# @category: Ekran Kartı
# @default: true
# @desc: NVIDIA kartınız varsa NVIDIA'nın resmi sunucusundan en güncel Game Ready (WHQL) sürücüsünü bulur. Sürücü hiç yoksa veya eskiyse indirip sessizce kurar (~1 GB, 5-10 dk, kurulum sırasında ekran birkaç kez kararabilir). Zaten güncelse hiçbir şey yapmaz. GTX 10 serisi ve daha eski kartlarda (en yeni sürücüyü desteklemezler) otomatik kurulum yapılmaz. NVIDIA dijital imzası kurulumdan önce doğrulanır. NVIDIA kartı yoksa atlanır.

$gpu = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'NVIDIA' -or $_.AdapterCompatibility -match 'NVIDIA' -or $_.PNPDeviceID -like 'PCI\VEN_10DE*' }
# Sürücü yokken kart "Microsoft Temel Görüntü Bağdaştırıcısı" görünür; PnP kimliğinden yakala
if (-not $gpu) { $gpu = Get-PnpDevice -Class Display -ErrorAction SilentlyContinue | Where-Object { $_.InstanceId -like 'PCI\VEN_10DE*' } }
if (-not $gpu) { Say "NVIDIA ekran kartı bulunamadı, modül atlandı."; return }

# Eski mimariler (Kepler/Maxwell/Pascal/Volta: GTX 600-1000, Titan V; PCI cihaz kimliği < 0x1E00)
# en yeni Game Ready dalını desteklemez. Onlara yanlış sürücü indirmemek için otomatik kurulum yapılmaz.
$pnp = Get-PnpDevice -Class Display -ErrorAction SilentlyContinue | Where-Object { $_.InstanceId -match 'PCI\\VEN_10DE&DEV_([0-9A-F]{4})' } | Select-Object -First 1
if ($pnp -and $pnp.InstanceId -match 'DEV_([0-9A-F]{4})') {
    $devId = [Convert]::ToInt32($Matches[1], 16)
    if ($devId -lt 0x1E00) {
        if (Test-Path "$env:SystemRoot\System32\nvapi64.dll") { Ok "Eski nesil NVIDIA kart (GTX 10 serisi ve öncesi): mevcut sürücü korunuyor." }
        else { Warn "Eski nesil NVIDIA kart: en güncel sürücü bu kartı desteklemez. Kartınıza uygun sürücüyü nvidia.com'dan seçip kurun."; Open-Url 'https://www.nvidia.com/tr-tr/drivers/' }
        return
    }
}

if (-not (Test-Internet)) { Fail "İnternet yok, sürücü kontrol edilemedi."; return }

# Kurulu sürüm (32.0.16.2114 -> 621.14)
$installed = $null
$vc = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -match 'NVIDIA' } | Select-Object -First 1
if ($vc -and $vc.DriverVersion -and (Test-Path "$env:SystemRoot\System32\nvapi64.dll")) {
    $digits = ($vc.DriverVersion -replace '\.', '')
    if ($digits.Length -ge 5) { $d5 = $digits.Substring($digits.Length - 5); $installed = [decimal]($d5.Substring(0, 3) + '.' + $d5.Substring(3)) }
}

# NVIDIA'nın en güncel masaüstü WHQL DCH sürümü
try {
    $api = 'https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php?func=DriverManualLookup&psid=120&pfid=929&osID=57&languageCode=1033&isWHQL=1&dch=1&sort1=0&numberOfResults=1'
    $resp = (Invoke-WebRequest -Uri $api -UseBasicParsing -TimeoutSec 30).Content | ConvertFrom-Json
    $latestStr = [string]$resp.IDS[0].downloadInfo.Version
    $latest = [decimal]$latestStr
} catch { Fail "NVIDIA sürücü sunucusuna ulaşılamadı: $($_.Exception.Message)"; return }

if ($installed) { Say "Kurulu sürücü: $installed  |  En güncel: $latestStr" } else { Say "NVIDIA sürücüsü kurulu değil. En güncel: $latestStr" }
if ($installed -and $installed -ge $latest) { Ok "NVIDIA sürücüsü zaten güncel."; return }

# Dizüstü mü? (UPS bataryası yanıltmasın diye kasa tipi ve GPU adına bakılır)
$chassis = @((Get-CimInstance Win32_SystemEnclosure -ErrorAction SilentlyContinue).ChassisTypes)
$laptopChassis = 8, 9, 10, 11, 12, 14, 18, 21, 30, 31, 32
$isLaptop = ($chassis | Where-Object { $laptopChassis -contains $_ }) -or ((Get-CimInstance Win32_VideoController | Where-Object { $_.Name -match 'NVIDIA' }).Name -match 'Laptop')
$kind = if ($isLaptop) { 'notebook' } else { 'desktop' }
$url = "https://international.download.nvidia.com/Windows/$latestStr/$latestStr-$kind-win10-win11-64bit-international-dch-whql.exe"
$file = Join-Path $script:PCH_WorkDir "nvidia-$latestStr.exe"

Say "İndiriliyor: NVIDIA $latestStr ($kind, ~1 GB). Bu biraz sürebilir..."
if (-not (Get-File $url $file)) { Fail "Sürücü indirilemedi. https://www.nvidia.com/tr-tr/drivers/ adresinden elle kurun."; return }
if (-not (Test-Signed $file 'NVIDIA')) { Remove-Item $file -Force -ErrorAction SilentlyContinue; Fail "Sürücü dosyasının NVIDIA imzası doğrulanamadı, KURULMADI."; return }

Say "Kuruluyor (ekran birkaç kez kararabilir, bu normal)..."
$code = Invoke-Process $file '-s -noreboot -noeula' 1800 -Visible
# Paket açıcı kapansa bile asıl kurulum (setup.exe) sürüyor olabilir; bitmesini bekle
for ($w = 0; $w -lt 240; $w++) {
    $busy = Get-Process -Name setup, NVI2, nvidiaInstaller -ErrorAction SilentlyContinue | Where-Object { $_.Path -like '*NVIDIA*' }
    if (-not $busy) { break }
    if ($w % 12 -eq 0) { Say "Kurulum sürüyor..." }
    Start-Sleep -Seconds 5
}
Remove-Item $file -Force -ErrorAction SilentlyContinue
Remove-Item "$env:SystemDrive\NVIDIA" -Recurse -Force -ErrorAction SilentlyContinue
if ($code -eq 0 -or $code -eq 1) { Ok "NVIDIA $latestStr kuruldu." }
elseif ($code -ge 0) { Warn "NVIDIA kurulum kodu: $code. Yeniden başlattıktan sonra sürümü kontrol edin." }
