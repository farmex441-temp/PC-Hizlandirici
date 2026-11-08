# @name: Arka Plan Uygulamalarını Kapat
# @category: Windows Temizliği
# @default: true
# @desc: Mağaza (UWP) uygulamalarının siz kullanmazken arka planda çalışmasını tamamen engeller. RAM ve CPU boşa harcanmaz.

Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy' 'LetAppsRunInBackground' 2
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications' 'GlobalUserDisabled' 1
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'BackgroundAppGlobalToggle' 0
Ok "Arka plan uygulamaları kapatıldı."

# Kapatılan uygulamaları oturum açınca yeniden başlatma
Set-Reg 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' 'RestartApps' 0
# Güncelleme sonrası "kurulumu tamamlamak için oturum bilgimi kullan" kapalı
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'DisableAutomaticRestartSignOn' 1
Ok "Uygulamaların oturum açılışında otomatik yeniden açılması kapatıldı."
