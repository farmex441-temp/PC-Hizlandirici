# @name: Oyun Modu ve Oyun Önceliği
# @category: Performans
# @default: true
# @desc: Oyun Modu açılır, Xbox Game Bar kaydı (Game DVR) kapatılır, Donanım Hızlandırmalı GPU Zamanlaması (HAGS) ve pencereli oyun iyileştirmeleri açılır, oyunlara CPU/GPU önceliği verilir, ağ kısıtlaması kaldırılır, fare ivmesi (işaretçi hassasiyeti) kapatılır, Shift'e 5 kez basınca çıkan Yapışkan Tuşlar uyarısı kapatılır.

# --- Oyun Modu ---
Set-Reg 'HKCU:\Software\Microsoft\GameBar' 'AllowAutoGameMode' 1
Set-Reg 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled' 1
Ok "Oyun Modu açık."

# --- Game DVR / arka plan kaydı kapalı ---
Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AudioCaptureEnabled' 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'HistoricalCaptureEnabled' 0
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' 'AllowGameDVR' 0
Set-Reg 'HKCU:\Software\Microsoft\GameBar' 'UseNexusForGameBarEnabled' 0
Set-Reg 'HKCU:\Software\Microsoft\GameBar' 'ShowStartupPanel' 0
Ok "Game DVR / arka plan kaydı kapalı, Xbox tuşu Game Bar açmaz."

# --- HAGS + pencereli oyun iyileştirmesi ---
Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' 'HwSchMode' 2
$gpuPrefKey = 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences'
$current = (Get-ItemProperty -Path $gpuPrefKey -Name 'DirectXUserGlobalSettings' -ErrorAction SilentlyContinue).DirectXUserGlobalSettings
if (-not $current) { $current = '' }
if ($current -notmatch 'SwapEffectUpgradeEnable=') { $current += 'SwapEffectUpgradeEnable=1;' }
else { $current = $current -replace 'SwapEffectUpgradeEnable=\d', 'SwapEffectUpgradeEnable=1' }
Set-Reg $gpuPrefKey 'DirectXUserGlobalSettings' $current String
Ok "HAGS ve pencereli oyun iyileştirmeleri açık (yeniden başlatma sonrası)."

# --- Multimedya zamanlayıcısı: oyunlara öncelik ---
$mm = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'
Set-Reg $mm 'SystemResponsiveness' 10
Set-Reg $mm 'NetworkThrottlingIndex' 0xffffffff
$games = "$mm\Tasks\Games"
Set-Reg $games 'GPU Priority' 8
Set-Reg $games 'Priority' 6
Set-Reg $games 'Scheduling Category' 'High' String
Set-Reg $games 'SFIO Priority' 'High' String
Set-Reg $games 'Background Only' 'False' String
Set-Reg $games 'Clock Rate' 10000
Set-Reg $games 'Affinity' 0
Ok "Oyun görevlerine yüksek CPU/GPU önceliği verildi, ağ kısıtlaması kaldırıldı."

# --- Ön plan uygulamasına öncelik (Win32PrioritySeparation = 0x26) ---
Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' 'Win32PrioritySeparation' 38
Ok "Ön plandaki oyuna işlemci önceliği verildi."

# --- Zamanlayıcı çözünürlüğü: oyunun istediği hassasiyet küçültülmüşken de korunur (Win11) ---
Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel' 'GlobalTimerResolutionRequests' 1

# --- Fare: işaretçi hassasiyetini artır = KAPALI (1:1 ham giriş) ---
Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseSpeed' '0' String
Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold1' '0' String
Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold2' '0' String
Ok "Fare ivmesi kapalı."

# --- Klavye: en hızlı tekrar ---
Set-Reg 'HKCU:\Control Panel\Keyboard' 'KeyboardDelay' '0' String
Set-Reg 'HKCU:\Control Panel\Keyboard' 'KeyboardSpeed' '31' String

# --- Yapışkan/Geçiş/Filtre tuşları kısayol uyarıları kapalı (oyun ortasında masaüstüne atmasın) ---
Set-Reg 'HKCU:\Control Panel\Accessibility\StickyKeys' 'Flags' '506' String
Set-Reg 'HKCU:\Control Panel\Accessibility\ToggleKeys' 'Flags' '58' String
Set-Reg 'HKCU:\Control Panel\Accessibility\Keyboard Response' 'Flags' '122' String
Ok "Yapışkan tuş uyarıları kapalı."
