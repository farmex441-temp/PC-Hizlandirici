# @name: Dosya Gezgini ve Sağ Tık Menüsü
# @category: Görünüm
# @default: true
# @desc: Dosya uzantıları gösterilir, Gezgin "Bu Bilgisayar" ile açılır, son kullanılan dosya geçmişi ve bulut önerileri gizlenir, Windows 11'de klasik (tam) sağ tık menüsü geri getirilir ("Daha fazla seçenek göster" derdi biter), menüden Paylaş / Erişim ver / Cihaza yayınla / Copilot'a sor gibi gereksiz girdiler kaldırılır.

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

# Sağ tık menüsünden gereksiz girdileri kaldır (dosyalara dokunulmaz, sadece menü sadeleşir)
$blocked = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked'
$entries = @{
    '{e2bf9676-5f8f-435c-97eb-11607a5bedf7}' = 'Paylaş'
    '{f81e9010-6ea4-11ce-a7ff-00aa003ca9f6}' = 'Erişim ver'
    '{7AD84985-87B4-4a16-BE58-8B72A5B390F7}' = 'Cihaza yayınla'
    '{CB3B0003-8088-4EDE-8769-8B354AB2FF8C}' = 'Copilot''a sor'
}
foreach ($k in $entries.Keys) { Set-Reg $blocked $k '' String; Say "Menüden kaldırıldı: $($entries[$k])" }
Ok "Sağ tık menüsü sadeleştirildi."
Request-ExplorerRestart
