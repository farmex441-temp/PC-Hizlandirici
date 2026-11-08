# @name: AMD Radeon - Performans Ayarları
# @category: Ekran Kartı
# @default: true
# @desc: FR33THY Ultimate'taki AMD ayarları: Radeon Anti-Lag açık, Dikey Senkronizasyon her zaman kapalı, Doku Filtreleme = Performans, Mozaikleme (Tessellation) kapalı, Vari-Bright kapalı, Adrenalin'in tepsi simgesi / oyun içi katman / reklam / bildirimleri / otomatik güncellemesi kapalı. AMD Radeon ekran kartı yoksa atlanır. ÖNCE AMD Adrenalin sürücüsünü kurun.

$amd = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'Radeon|AMD' -or $_.AdapterCompatibility -match 'Advanced Micro Devices|AMD' }
if (-not $amd) { Say "AMD Radeon ekran kartı bulunamadı, modül atlandı."; return }
Say "Bulunan kart: $(($amd | Select-Object -First 1).Name)"

# Sadece AMD bağdaştırıcılarının sürücü anahtarlarına yaz
$classRoot = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
$amdKeys = Get-ChildItem $classRoot -ErrorAction SilentlyContinue | Where-Object {
    $_.PSChildName -match '^\d{4}$' -and
    ((Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).ProviderName -match 'Advanced Micro Devices|AMD|ATI')
}
# Sistemde NVIDIA kart da varsa AMD büyük ihtimalle işlemcinin dahili grafiği (iGPU): sessiz çalış
$hasNvidia = [bool](Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'NVIDIA' })
if ($hasNvidia) { Say "NVIDIA kart da var: AMD dahili grafik olarak kabul edildi, yalnızca kayıt ayarları uygulanacak." }

if (-not $amdKeys) {
    if ($hasNvidia) { Say "AMD dahili grafik sürücüsü yok, atlandı."; return }
    Warn "AMD sürücüsü kurulu değil. Önce Adrenalin sürücüsünü kurup modülü tekrar çalıştırın."
    Open-Url 'https://www.amd.com/en/support/download/drivers.html'
    return
}

# Adrenalin bir kez açılıp kapanırsa kullanıcı ayarları kalıcı olur (FR33THY yöntemi)
$rs = "$env:ProgramFiles\AMD\CNext\CNext\RadeonSoftware.exe"
if ((Test-Path $rs) -and -not $hasNvidia) {
    Say "AMD Software bir kez açılıp kapatılıyor..."
    Start-Process explorer.exe -ArgumentList "`"$rs`""
    Start-Sleep -Seconds 25
    Stop-Process -Name RadeonSoftware -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

foreach ($k in $amdKeys) {
    Set-Reg $k.PSPath 'KMD_DeLagEnabled' 1                         # Radeon Anti-Lag
    $umd = Join-Path $k.PSPath 'UMD'
    if (Test-Path $umd) {
        Set-Reg $umd 'VSyncControl' ([byte[]](0x30, 0x00)) Binary      # V-Sync: her zaman kapalı
        Set-Reg $umd 'TFQ' ([byte[]](0x32, 0x00)) Binary               # Doku filtreleme: performans
        Set-Reg $umd 'Tessellation' ([byte[]](0x31, 0x00)) Binary      # Mozaikleme: uygulamayı geçersiz kıl
        Set-Reg $umd 'Tessellation_OPTION' ([byte[]](0x32, 0x00)) Binary # Maks. seviye: kapalı
    }
    Get-ChildItem $k.PSPath -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -eq 'power_v1' } | ForEach-Object {
        Set-Reg $_.PSPath 'abmlevel' ([byte[]](0, 0, 0, 0)) Binary      # Vari-Bright kapalı
    }
}
Ok "AMD grafik ayarları uygulandı."

$cn = 'HKCU:\Software\AMD\CN'
Set-Reg $cn 'AutoUpdate' 0
Set-Reg $cn 'SystemTray' 'false' String
Set-Reg $cn 'RSXBrowserUnavailable' 'true' String
Set-Reg $cn 'AllowWebContent' 'false' String
Set-Reg $cn 'CN_Hide_Toast_Notification' 'true' String
Set-Reg $cn 'AnimationEffect' 'false' String
Set-Reg $cn 'WizardProfile' 'PROFILE_CUSTOM' String
Set-Reg 'HKCU:\Software\AMD\AIM' 'LaunchBugTool' 0
Set-Reg 'HKCU:\Software\AMD\DVR' 'HotkeysDisabled' 1
Set-Reg 'HKCU:\Software\AMD\DVR' 'ShowRSOverlay' 'false' String
foreach ($n in 'FreeSync', 'OverlayNotification', 'VirtualSuperResolution') { Set-Reg "$cn\$n" 'AlreadyNotified' 1 }
Ok "AMD Software: tepsi, katman, reklam, bildirim ve otomatik güncelleme kapalı."
