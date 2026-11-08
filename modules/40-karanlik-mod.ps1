# @name: Karanlık Mod
# @category: Görünüm
# @default: true
# @desc: Windows ve uygulamalar karanlık temaya geçer, saydamlık kapatılır, vurgu rengi koyu gri yapılır (başlık çubukları ve görev çubuğu siyaha yakın).

$p = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
Set-Reg $p 'AppsUseLightTheme' 0
Set-Reg $p 'SystemUsesLightTheme' 0
Set-Reg $p 'EnableTransparency' 0
Set-Reg $p 'ColorPrevalence' 1
Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'AppsUseLightTheme' 0

$accent = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent'
Set-Reg $accent 'AccentPalette' ([byte[]](0x64,0x64,0x64,0x00,0x6b,0x6b,0x6b,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00)) Binary
Set-Reg $accent 'StartColorMenu' 0
Set-Reg $accent 'AccentColorMenu' 0

$dwm = 'HKCU:\Software\Microsoft\Windows\DWM'
Set-Reg $dwm 'EnableWindowColorization' 1
Set-Reg $dwm 'ColorPrevalence' 1
Set-Reg $dwm 'AccentColor' 0xff191919
Set-Reg $dwm 'ColorizationColor' 0xc4191919
Set-Reg $dwm 'ColorizationAfterglow' 0xc4191919

Ok "Karanlık mod açık."
Request-ExplorerRestart
