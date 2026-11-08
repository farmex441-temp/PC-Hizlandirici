# @name: Windows Update'i Oyuncu Dostu Yap
# @category: Windows Temizliği
# @default: true
# @desc: Güncellemeler KAPATILMAZ (güvenlik için gerekli). Sadece: oturum açıkken zorla yeniden başlatma engellenir, "güncellemeleri çıkar çıkmaz al" kapatılır, çalışma saatleri 08:00-02:00 yapılır, güncelleme sonrası tanıtım ekranları kapatılır ve diğer Microsoft ürünleri de güncellenir.

$au = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
Set-Reg $au 'NoAutoRebootWithLoggedOnUsers' 1
Set-Reg 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' 'IsContinuousInnovationOptedIn' 0
Set-Reg 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' 'ActiveHoursStart' 8
Set-Reg 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' 'ActiveHoursEnd' 2
Set-Reg 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' 'SmartActiveHoursState' 0
Set-Reg 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' 'RestartNotificationsAllowed2' 1
Set-Reg 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' 'AllowMUUpdateService' 1
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement' 'ScoobeSystemSettingEnabled' 0
Ok "Windows Update: zorla yeniden başlatma yok, çalışma saatleri 08:00-02:00."
