# @name: Bildirimleri, İpuçlarını ve Reklamları Kapat
# @category: Windows Temizliği
# @default: true
# @desc: TÜM açılır bildirimler kapatılır (uygulamalar, Windows Güvenliği uyarıları ve güncelleme hatırlatmaları dahil; Defender tehditleri yine otomatik engeller, sadece bildirim göstermez). Ayrıca kilit ekranı bildirimleri, Windows ipuçları/önerileri, "cihazınızı kurmayı bitirin" ekranları, Başlat menüsü reklamları, kilit ekranı reklamları ve Microsoft'un sizin yerinize otomatik uygulama (Candy Crush vb.) kurması kapatılır.

# --- Uygulama bildirimleri ---
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications' 'ToastEnabled' 0
Set-Reg 'HKCU:\Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications' 'NoToastApplicationNotification' 1
Set-Reg 'HKCU:\Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications' 'NoToastApplicationNotificationOnLockScreen' 1
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings' 'NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK' 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings' 'NOC_GLOBAL_SETTING_ALLOW_CRITICAL_TOASTS_ABOVE_LOCK' 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.Suggested' 'Enabled' 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowSyncProviderNotifications' 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_AccountNotifications' 0
Ok "Uygulama ve kilit ekranı bildirimleri kapalı."

# --- İpuçları, öneriler, reklamlar, sessiz uygulama kurulumu ---
$cdm = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
foreach ($v in 'ContentDeliveryAllowed', 'FeatureManagementEnabled', 'OemPreInstalledAppsEnabled', 'PreInstalledAppsEnabled',
               'PreInstalledAppsEverEnabled', 'SilentInstalledAppsEnabled', 'SoftLandingEnabled', 'SystemPaneSuggestionsEnabled',
               'RotatingLockScreenEnabled', 'RotatingLockScreenOverlayEnabled',
               'SubscribedContent-310093Enabled', 'SubscribedContent-314563Enabled', 'SubscribedContent-338387Enabled',
               'SubscribedContent-338388Enabled', 'SubscribedContent-338389Enabled', 'SubscribedContent-338393Enabled',
               'SubscribedContent-353694Enabled', 'SubscribedContent-353696Enabled', 'SubscribedContent-353698Enabled',
               'SubscribedContentEnabled') {
    Set-Reg $cdm $v 0
}
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement' 'ScoobeSystemSettingEnabled' 0
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsConsumerFeatures' 1
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableSoftLanding' 1
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableConsumerAccountStateContent' 1
Set-Reg 'HKCU:\Software\Policies\Microsoft\Windows\CloudContent' 'DisableTailoredExperiencesWithDiagnosticData' 1
Set-Reg 'HKCU:\Software\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsSpotlightFeatures' 1
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_IrisRecommendations' 0
Ok "İpuçları, öneriler, reklamlar ve otomatik uygulama kurulumu kapalı."
