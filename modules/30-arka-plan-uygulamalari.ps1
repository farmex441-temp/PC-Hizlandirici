# @name: Arka Plan Uygulamalarını Kapat
# @category: Windows Temizliği
# @default: true
# @desc: Mağaza (UWP) uygulamalarının siz kullanmazken arka planda çalışması kapatılır, RAM ve CPU boşa harcanmaz. Kilitleyen ilke kullanılmaz: belirli bir uygulamaya (ör. Saat/Alarm) izin vermek isterseniz Ayarlar > Uygulamalar'dan açabilirsiniz. Başlat araması etkilenmez.

Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications' 'GlobalUserDisabled' 1
# Önceki sürümlerin yazdığı ve Windows 10'da aramayı bozabilen ayarları temizle
Remove-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'BackgroundAppGlobalToggle'
Remove-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy' 'LetAppsRunInBackground'
Ok "Arka plan uygulamaları kapatıldı."

# Kapatılan uygulamaları oturum açınca yeniden başlatma
Set-Reg 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' 'RestartApps' 0
# Güncelleme sonrası "kurulumu tamamlamak için oturum bilgimi kullan" kapalı
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'DisableAutomaticRestartSignOn' 1
Ok "Uygulamaların oturum açılışında otomatik yeniden açılması kapatıldı."
