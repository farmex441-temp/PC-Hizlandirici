# @name: Görsel Efektleri Performansa Ayarla
# @category: Performans
# @default: true
# @desc: Pencere animasyonları, gölgeler, saydamlık ve menü gecikmeleri kapatılır; yazı yumuşatma ve küçük resim önizlemeleri korunur. Windows çok daha çevik hissettirir.

Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' 'VisualFXSetting' 3
# Animasyonlar kapalı, yazı yumuşatma açık
Set-Reg 'HKCU:\Control Panel\Desktop' 'UserPreferencesMask' ([byte[]](0x90, 0x12, 0x03, 0x80, 0x10, 0x00, 0x00, 0x00)) Binary
Set-Reg 'HKCU:\Control Panel\Desktop' 'FontSmoothing' '2' String
Set-Reg 'HKCU:\Control Panel\Desktop' 'MenuShowDelay' '0' String
Set-Reg 'HKCU:\Control Panel\Desktop' 'DragFullWindows' '1' String
Set-Reg 'HKCU:\Control Panel\Desktop\WindowMetrics' 'MinAnimate' '0' String
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarAnimations' 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ListviewShadow' 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ListviewAlphaSelect' 1
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'IconsOnly' 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\DWM' 'EnableAeroPeek' 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\DWM' 'AlwaysHibernateThumbnails' 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency' 0
Ok "Görsel efektler performans moduna alındı."
Request-ExplorerRestart
