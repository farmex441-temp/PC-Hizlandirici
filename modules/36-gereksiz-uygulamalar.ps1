# @name: Gereksiz Uygulamaları Kaldır (Bloatware)
# @category: Windows Temizliği
# @default: true
# @desc: Windows ile gelen gereksiz uygulamalar kaldırılır: Clipchamp, Haberler, Hava Durumu, Başlarken, Yardım Al, Solitaire, Kişiler, Power Automate, To Do, Geri Bildirim Merkezi, Haritalar, Filmler ve TV, Posta/Takvim, Outlook (yeni), Teams, Telefon Bağlantısı, Aile, Dev Home, Skype, Paint 3D, Candy Crush gibi reklam oyunları. Mağaza, Hesap Makinesi, Fotoğraflar, Not Defteri, Paint, Terminal, Ekran Alıntısı Aracı, Medya Oynatıcı ve Xbox uygulamaları KORUNUR.

$apps = @(
    'Clipchamp.Clipchamp',
    'Microsoft.549981C3F5F10',               # Cortana
    'Microsoft.BingNews',
    'Microsoft.BingWeather',
    'Microsoft.BingSearch',
    'Microsoft.BingFinance',
    'Microsoft.BingSports',
    'Microsoft.BingTranslator',
    'Microsoft.GetHelp',
    'Microsoft.Getstarted',
    'Microsoft.Messaging',
    'Microsoft.Microsoft3DViewer',
    'Microsoft.MicrosoftSolitaireCollection',
    'Microsoft.MixedReality.Portal',
    'Microsoft.News',
    'Microsoft.Office.OneNote',
    'Microsoft.OneConnect',
    'Microsoft.OutlookForWindows',
    'Microsoft.People',
    'Microsoft.PowerAutomateDesktop',
    'Microsoft.Print3D',
    'Microsoft.SkypeApp',
    'Microsoft.Todos',
    'Microsoft.Wallet',
    'Microsoft.WindowsFeedbackHub',
    'Microsoft.WindowsMaps',
    'Microsoft.WindowsCommunicationsApps',   # Posta ve Takvim
    'Microsoft.Windows.DevHome',
    'Microsoft.YourPhone',                   # Telefon Bağlantısı
    'Microsoft.ZuneVideo',                   # Filmler ve TV
    'MicrosoftCorporationII.MicrosoftFamily',
    'MicrosoftTeams',
    'MSTeams',
    'Microsoft.MicrosoftJournal',
    'MicrosoftWindows.CrossDevice',
    'Microsoft.MSPaint',                     # Paint 3D (yeni Paint korunur)
    'Microsoft.Microsoft3DViewer',
    '*CandyCrush*',
    '*BubbleWitch*',
    '*king.com*',
    '*HiddenCity*',
    '*MarchofEmpires*',
    '*Royal Revolt*'
)
# Not: Spotify, Netflix, Instagram, TikTok gibi uygulamalar BİLEREK listede yok;
# siz kurduktan sonra programı tekrar çalıştırırsanız silinmesinler diye.
# Windows'un bunları kendiliğinden kurması "Bildirimler" modülünde engellenir.

foreach ($a in $apps) { Remove-AppxSafe $a }
Ok "Gereksiz uygulamalar kaldırıldı."

# Kaldırılan uygulamaların Windows Update ile geri gelmesini azalt
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsConsumerFeatures' 1
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SilentInstalledAppsEnabled' 0

# Yeni Outlook ve Dev Home'un otomatik kurulmasını engelle
foreach ($k in 'OutlookUpdate', 'DevHomeUpdate') {
    Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\$k" -Recurse -Force -ErrorAction SilentlyContinue
}
