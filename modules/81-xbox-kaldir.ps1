# @name: Xbox Uygulamalarını ve Game Bar'ı Kaldır
# @category: Gelişmiş (Risk)
# @default: false
# @desc: Xbox uygulaması, Game Bar, Xbox kimlik sağlayıcısı ve Gaming Services tamamen kaldırılır. RİSK: Xbox Game Pass / PC Game Pass oyunları ve Microsoft Store oyunları ÇALIŞMAZ. Bu oyunları oynamıyorsanız seçin. Geri getirmek için Microsoft Store'dan "Xbox" uygulamasını kurmanız yeterli.

Stop-Process -Name GameBar, GameBarFTServer, XboxPcApp, gamingservices, gamingservicesnet -Force -ErrorAction SilentlyContinue
foreach ($a in 'Microsoft.GamingApp', 'Microsoft.XboxGamingOverlay', 'Microsoft.XboxGameOverlay', 'Microsoft.XboxSpeechToTextOverlay',
              'Microsoft.XboxIdentityProvider', 'Microsoft.Xbox.TCUI', 'Microsoft.XboxApp', 'Microsoft.GamingServices') {
    Remove-AppxSafe $a
}
foreach ($s in 'XblAuthManager', 'XblGameSave', 'XboxGipSvc', 'XboxNetApiSvc') { Set-ServiceStart $s 'Manual' }
# Game Bar kaldırıldıktan sonra "ms-gamebar" bağlantısı açılmaya çalışınca çıkan uyarıyı engelle
Set-Reg 'HKCU:\Software\Microsoft\GameBar' 'UseNexusForGameBarEnabled' 0
Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0
Ok "Xbox uygulamaları ve Game Bar kaldırıldı."
