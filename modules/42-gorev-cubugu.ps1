# @name: Görev Çubuğunu Temizle
# @category: Görünüm
# @default: true
# @desc: Görev çubuğundaki arama kutusu, Görev Görünümü, Widget, Sohbet, Copilot, Şimdi Toplantı Yap düğmeleri kaldırılır; sabitlenmiş Edge/Mağaza/Gezgin simgeleri çözülür; tüm sistem tepsisi simgeleri gösterilir; sağ tıkta "Görevi sonlandır" seçeneği eklenir (donan oyunları kapatmak için). Hizalama değiştirilmez.

$adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'SearchboxTaskbarMode' 0
Set-Reg $adv 'ShowTaskViewButton' 0
Set-Reg $adv 'TaskbarMn' 0
Set-Reg $adv 'ShowCopilotButton' 0
Set-Reg $adv 'TaskbarSd' 1                         # sağ alt köşe: masaüstünü göster
Set-Reg "$adv\TaskbarDeveloperSettings" 'TaskbarEndTask' 1
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' 'AllowNewsAndInterests' 0
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds' 'EnableFeeds' 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' 'HideSCAMeetNow' 1
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer' 'NoPinningStoreToTaskbar' 1
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer' 'EnableAutoTray' 0
Ok "Görev çubuğu düğmeleri kaldırıldı."

# Sabitlenmiş öğeleri çöz
reg delete 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband' /f 2>&1 | Out-Null
$ql = "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
if (Test-Path $ql) { Get-ChildItem $ql -Filter *.lnk -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue }
Ok "Sabitlenmiş simgeler çözüldü."

# Tüm tepsi simgelerini göster (Windows 11)
Get-ChildItem 'HKCU:\Control Panel\NotifyIconSettings' -ErrorAction SilentlyContinue | ForEach-Object {
    Set-ItemProperty -Path $_.PSPath -Name 'IsPromoted' -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
}
Ok "Tüm sistem tepsisi simgeleri gösteriliyor."

Request-ExplorerRestart
