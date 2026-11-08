# @name: Xbox Uygulamasını ve Game Bar'ı Kaldır
# @category: Gelişmiş (Risk)
# @default: false
# @desc: Xbox uygulaması ve Game Bar katmanı kaldırılır. Xbox hesabıyla giriş altyapısı (Minecraft, Forza, Halo vb. için gerekli) KORUNUR. RİSK: Game Pass oyunlarını yüklemek/başlatmak için Xbox uygulaması gerekir; Game Pass kullanıyorsanız seçmeyin. Geri getirmek için Microsoft Store'dan "Xbox" uygulamasını kurmanız yeterli.

Stop-Process -Name GameBar, GameBarFTServer, XboxPcApp -Force -ErrorAction SilentlyContinue
# XboxIdentityProvider, Xbox.TCUI ve GamingServices KORUNUR: Minecraft, Forza, Halo MCC, Sea of Thieves gibi
# Steam oyunları da Xbox hesabıyla giriş için bunlara ihtiyaç duyar.
foreach ($a in 'Microsoft.GamingApp', 'Microsoft.XboxGamingOverlay', 'Microsoft.XboxGameOverlay', 'Microsoft.XboxSpeechToTextOverlay', 'Microsoft.XboxApp') {
    Remove-AppxSafe $a
}
# Game Bar kaldırıldıktan sonra "ms-gamebar" bağlantısı açılmaya çalışınca çıkan uyarıyı engelle
Set-Reg 'HKCU:\Software\Microsoft\GameBar' 'UseNexusForGameBarEnabled' 0
Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0
Ok "Xbox uygulamaları ve Game Bar kaldırıldı."
