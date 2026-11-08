# @name: Dosya Gezgini ve Sağ Tık Menüsü
# @category: Görünüm
# @default: true
# @desc: Dosya uzantıları gösterilir, Gezgin "Bu Bilgisayar" ile açılır, son kullanılan dosya geçmişi ve bulut önerileri gizlenir, Windows 11'de klasik (tam) sağ tık menüsü geri getirilir ("Daha fazla seçenek göster" derdi biter).

$adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
Set-Reg $adv 'HideFileExt' 0
Set-Reg $adv 'LaunchTo' 1
Set-Reg $adv 'Start_TrackDocs' 0
Set-Reg $adv 'ShowCloudFilesInQuickAccess' 0
Set-Reg $adv 'ShowRecommendations' 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer' 'ShowRecent' 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer' 'ShowFrequent' 0
Ok "Gezgin: uzantılar görünür, Bu Bilgisayar ile açılır, geçmiş gizli."

if (Test-Win11) {
    Set-Reg 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32' '(default)' '' String
    Ok "Klasik sağ tık menüsü geri getirildi."
}
Request-ExplorerRestart
