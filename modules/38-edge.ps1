# @name: Microsoft Edge'i Sadeleştir
# @category: Windows Temizliği
# @default: true
# @desc: Edge'in Windows açılışında arka planda başlaması (Startup Boost) ve kapatıldıktan sonra arka planda çalışması engellenir; kenar çubuğu, Copilot, alışveriş asistanı, Rewards, öneriler, yeni sekme haberleri ve telemetri kapatılır. Not: Edge ayarlarında "Kuruluşunuz tarafından yönetiliyor" yazısı görünür, bu normaldir.

$e = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
$policies = @{
    'StartupBoostEnabled'                              = 0
    'BackgroundModeEnabled'                            = 0
    'HubsSidebarEnabled'                               = 0
    'CopilotPageContext'                               = 0
    'CopilotCDPPageContext'                            = 0
    'EdgeShoppingAssistantEnabled'                     = 0
    'ShowMicrosoftRewards'                             = 0
    'ShowRecommendationsEnabled'                       = 0
    'SpotlightExperiencesAndRecommendationsEnabled'    = 0
    'PersonalizationReportingEnabled'                  = 0
    'DiagnosticData'                                   = 0
    'HideFirstRunExperience'                           = 1
    'NewTabPageContentEnabled'                         = 0
    'NewTabPageHideDefaultTopSites'                    = 1
    'NewTabPageAllowedBackgroundTypes'                 = 3
    'ConfigureDoNotTrack'                              = 1
    'AlternateErrorPagesEnabled'                       = 0
    'UserFeedbackAllowed'                              = 0
    'EdgeFollowEnabled'                                = 0
    'WebWidgetAllowed'                                 = 0
    'MicrosoftEdgeInsiderPromotionEnabled'             = 0
    'PromotionalTabsEnabled'                           = 0
    'ShowAcrobatSubscriptionButton'                    = 0
    'EdgeCollectionsEnabled'                           = 0
    'StandaloneHubsSidebarEnabled'                     = 0
}
Set-RegMany $e $policies
Ok "Edge sadeleştirildi (arka planda çalışmaz, reklam/öneri yok)."

# Edge'in görev çubuğuna/masaüstüne tekrar kısayol eklemesini engelle
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate' 'CreateDesktopShortcutDefault' 0
Remove-Item "$env:PUBLIC\Desktop\Microsoft Edge.lnk", "$env:USERPROFILE\Desktop\Microsoft Edge.lnk" -Force -ErrorAction SilentlyContinue
