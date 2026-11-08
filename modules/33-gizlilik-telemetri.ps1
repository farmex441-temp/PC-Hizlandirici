# @name: Telemetri, Takip ve Web Aramasını Kapat
# @category: Windows Temizliği
# @default: true
# @desc: Microsoft'a veri gönderen telemetri servisleri ve zamanlanmış görevleri, reklam kimliği, etkinlik geçmişi, geri bildirim istekleri, yazma/mürekkep verisi toplama, hata raporlama ve Başlat menüsündeki Bing web araması kapatılır. Başlat araması yalnızca bilgisayarınızda arar ve çok daha hızlı olur.

# --- Telemetri ---
$dc = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'
Set-Reg $dc 'AllowTelemetry' 0
Set-Reg $dc 'DoNotShowFeedbackNotifications' 1
Set-Reg $dc 'AllowDeviceNameInTelemetry' 0
Set-Reg $dc 'LimitDiagnosticLogCollection' 1
Set-Reg $dc 'DisableOneSettingsDownloads' 1
Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection' 'AllowTelemetry' 0
Set-ServiceStart 'DiagTrack' 'Disabled'
Set-ServiceStart 'dmwappushservice' 'Disabled'
Ok "Telemetri kapalı."

# --- Reklam kimliği, kişiselleştirilmiş deneyimler, geri bildirim ---
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo' 'DisabledByGroupPolicy' 1
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy' 'TailoredExperiencesWithDiagnosticDataEnabled' 0
Set-Reg 'HKCU:\Software\Microsoft\Siuf\Rules' 'NumberOfSIUFInPeriod' 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_TrackProgs' 0
Set-Reg 'HKCU:\Control Panel\International\User Profile' 'HttpAcceptLanguageOptOut' 1
Ok "Reklam kimliği ve geri bildirim istekleri kapalı."

# --- Etkinlik geçmişi ---
$sys = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'
Set-Reg $sys 'EnableActivityFeed' 0
Set-Reg $sys 'PublishUserActivities' 0
Set-Reg $sys 'UploadUserActivities' 0
Ok "Etkinlik geçmişi kapalı."

# --- Yazma / mürekkep verisi toplama ---
Set-Reg 'HKCU:\Software\Microsoft\InputPersonalization' 'RestrictImplicitInkCollection' 1
Set-Reg 'HKCU:\Software\Microsoft\InputPersonalization' 'RestrictImplicitTextCollection' 1
Set-Reg 'HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore' 'HarvestContacts' 0
Set-Reg 'HKCU:\Software\Microsoft\Personalization\Settings' 'AcceptedPrivacyPolicy' 0
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization' 'AllowInputPersonalization' 0

# --- Hata raporlama ---
Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting' 'Disabled' 1
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting' 'Disabled' 1
Set-ServiceStart 'WerSvc' 'Manual'
Ok "Hata raporlama kapalı."

# --- Başlat menüsünde Bing / web araması ---
Set-Reg 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' 'DisableSearchBoxSuggestions' 1
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'BingSearchEnabled' 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'CortanaConsent' 0
$ws = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'
Set-Reg $ws 'AllowCortana' 0
Set-Reg $ws 'AllowCloudSearch' 0
Set-Reg $ws 'ConnectedSearchUseWeb' 0
Set-Reg $ws 'DisableWebSearch' 1
Set-Reg $ws 'EnableDynamicContentInWSB' 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings' 'IsDynamicSearchBoxEnabled' 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings' 'IsDeviceSearchHistoryEnabled' 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings' 'IsMSACloudSearchEnabled' 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings' 'IsAADCloudSearchEnabled' 0
Ok "Başlat menüsü web araması kapalı."

# --- Telemetri zamanlanmış görevleri ---
$tasks = @(
    @('\Microsoft\Windows\Application Experience\', 'Microsoft Compatibility Appraiser'),
    @('\Microsoft\Windows\Application Experience\', 'Microsoft Compatibility Appraiser Exp'),
    @('\Microsoft\Windows\Application Experience\', 'ProgramDataUpdater'),
    @('\Microsoft\Windows\Application Experience\', 'StartupAppTask'),
    @('\Microsoft\Windows\Application Experience\', 'MareBackup'),
    @('\Microsoft\Windows\Application Experience\', 'PcaPatchDbTask'),
    @('\Microsoft\Windows\Autochk\', 'Proxy'),
    @('\Microsoft\Windows\Customer Experience Improvement Program\', 'Consolidator'),
    @('\Microsoft\Windows\Customer Experience Improvement Program\', 'UsbCeip'),
    @('\Microsoft\Windows\DiskDiagnostic\', 'Microsoft-Windows-DiskDiagnosticDataCollector'),
    @('\Microsoft\Windows\Feedback\Siuf\', 'DmClient'),
    @('\Microsoft\Windows\Feedback\Siuf\', 'DmClientOnScenarioDownload'),
    @('\Microsoft\Windows\Windows Error Reporting\', 'QueueReporting'),
    @('\Microsoft\Windows\Maps\', 'MapsUpdateTask'),
    @('\Microsoft\Windows\Maps\', 'MapsToastTask'),
    @('\Microsoft\Windows\CloudExperienceHost\', 'CreateObjectTask'),
    @('\Microsoft\Windows\Flighting\FeatureConfig\', 'UsageDataReporting'),
    @('\Microsoft\Windows\Flighting\OneSettings\', 'RefreshCache')
)
foreach ($t in $tasks) { Disable-Task $t[0] $t[1] }
Ok "Telemetri görevleri kapatıldı."
