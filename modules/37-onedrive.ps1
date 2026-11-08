# @name: OneDrive'ı Kaldır
# @category: Windows Temizliği
# @default: true
# @desc: OneDrive kaldırılır ve tekrar kurulması engellenir, Dosya Gezgini'ndeki OneDrive girdisi gizlenir. GÜVENLİK: Masaüstü/Belgeler/Resimler klasörleriniz OneDrive'a yedekleniyorsa (klasörler OneDrive içindeyse) dosya kaybı olmaması için bu modül otomatik olarak ATLANIR.

# Bilinen klasörler OneDrive'a yönlendirilmiş mi?
$usf = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' -ErrorAction SilentlyContinue
$redirected = @()
foreach ($n in 'Desktop', 'Personal', 'My Pictures', '{F42EE2D3-909F-4907-8871-4C22FC0BF756}', '{0DDD015D-B06C-45D5-8C4C-F59713854639}') {
    $v = $usf.$n
    if ($v -and $v -match 'OneDrive') { $redirected += $v }
}
if ($redirected.Count -gt 0) {
    Warn "Masaüstü/Belgeler/Resimler OneDrive klasöründe. Dosyalarınızı korumak için OneDrive KALDIRILMADI."
    Say "Önce OneDrive ayarlarından 'Yedeklemeyi yönet' > yedeklemeyi durdurun, sonra bu modülü tekrar çalıştırın."
    return
}

Say "OneDrive kapatılıyor..."
Stop-Process -Name OneDrive, OneDriveSetup, FileCoAuth -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

$setups = @(
    "$env:SystemRoot\System32\OneDriveSetup.exe",
    "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
)
$setups += Get-ChildItem "$env:LOCALAPPDATA\Microsoft\OneDrive\*\OneDriveSetup.exe" -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }
$setups += Get-ChildItem "$env:ProgramFiles\Microsoft OneDrive\*\OneDriveSetup.exe" -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }

$done = $false
foreach ($s in $setups) {
    if (Test-Path $s) {
        Start-Process $s -ArgumentList '/uninstall' -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
        Start-Process $s -ArgumentList '/uninstall /allusers' -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
        $done = $true
    }
}
# winget ile kurulmuş olabilir
if (Get-Command winget -ErrorAction SilentlyContinue) {
    winget uninstall --id Microsoft.OneDrive --silent --accept-source-agreements 2>&1 | Out-Null
}
if ($done) { Ok "OneDrive kaldırıldı." } else { Say "OneDrive kurulu görünmüyor." }

# Tekrar kurulmasını engelle
Remove-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' 'OneDriveSetup'
Remove-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' 'OneDrive'
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive' 'DisableFileSyncNGSC' 1
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive' 'DisableFileSync' 1

# Varsayılan kullanıcı profili için kurulum kısayolunu kaldır (yeni kullanıcılarda gelmesin)
$defHive = "$env:SystemDrive\Users\Default\NTUSER.DAT"
if (Test-Path $defHive) {
    reg load 'HKU\PCH_Default' $defHive 2>&1 | Out-Null
    reg delete 'HKU\PCH_Default\Software\Microsoft\Windows\CurrentVersion\Run' /v OneDriveSetup /f 2>&1 | Out-Null
    [GC]::Collect(); Start-Sleep -Milliseconds 500
    reg unload 'HKU\PCH_Default' 2>&1 | Out-Null
}

# Gezgin gezinti bölmesinden gizle
Set-Reg 'Registry::HKEY_CLASSES_ROOT\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}' 'System.IsPinnedToNameSpaceTree' 0
Set-Reg 'Registry::HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}' 'System.IsPinnedToNameSpaceTree' 0

# Boş kalan OneDrive klasörünü temizle (içinde dosya varsa dokunma)
$od = Join-Path $env:USERPROFILE 'OneDrive'
if ((Test-Path $od) -and -not (Get-ChildItem $od -Recurse -Force -File -ErrorAction SilentlyContinue | Select-Object -First 1)) {
    Remove-Item $od -Recurse -Force -ErrorAction SilentlyContinue
}
Request-ExplorerRestart
