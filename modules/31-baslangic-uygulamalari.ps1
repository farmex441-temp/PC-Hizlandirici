# @name: Başlangıç Uygulamalarını Kapat
# @category: Windows Temizliği
# @default: true
# @desc: Windows açılırken otomatik başlayan tüm programları (Görev Yöneticisi > Başlangıç sekmesindekiler) devre dışı bırakır. Windows Güvenliği ve dizüstü touchpad sürücüleri hariç. Açılıştaki başlangıç gecikmesi de kaldırılır. Hiçbir şey silinmez; istediğinizi Görev Yöneticisi'nden tekrar açabilirsiniz. Sonradan kurduğunuz programlar (Discord, Steam vb.) için modülü tekrar çalıştırabilirsiniz.

# Dokunulmayacaklar: Windows Güvenliği ve dizüstü touchpad sürücüleri (kapanırsa hareketler çalışmaz)
$keep = @('SecurityHealth', 'Syn*', 'ETD*', 'Elan*', '*Touchpad*', '*TouchPad*', '*PrecisionTouch*', 'ctfmon')
function Test-Keep ([string]$n) { foreach ($k in $keep) { if ($n -like $k) { return $true } }; return $false }

# Windows'un masaüstü açıldıktan sonra başlangıç uygulamalarını bekletmesini kaldır
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize' 'StartupDelayInMSec' 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize' 'WaitForIdleState' 0
# Görev Yöneticisi'nin kullandığı "devre dışı" değeri: 03 00 00 00 + zaman damgası
$disabled = [byte[]](@(0x03, 0x00, 0x00, 0x00) + [BitConverter]::GetBytes([DateTime]::Now.ToFileTime()))

$sources = @(
    @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Run',               'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run'),
    @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',               'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run'),
    @('HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run',   'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32')
)

$n = 0
foreach ($s in $sources) {
    $props = Get-ItemProperty -Path $s[0] -ErrorAction SilentlyContinue
    if (-not $props) { continue }
    foreach ($p in $props.PSObject.Properties) {
        if ($p.Name -like 'PS*') { continue }
        if (Test-Keep $p.Name) { Say "Korundu: $($p.Name)"; continue }
        Set-Reg $s[1] $p.Name $disabled Binary
        Say "Kapatıldı: $($p.Name)"
        $n++
    }
}

# Başlangıç klasörleri
$folders = @(
    @([Environment]::GetFolderPath('Startup'),       'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder'),
    @([Environment]::GetFolderPath('CommonStartup'), 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder')
)
foreach ($f in $folders) {
    if (-not $f[0] -or -not (Test-Path $f[0])) { continue }
    Get-ChildItem -Path $f[0] -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'desktop.ini' } | ForEach-Object {
        Set-Reg $f[1] $_.Name $disabled Binary
        Say "Kapatıldı: $($_.Name)"
        $n++
    }
}

Ok "$n başlangıç öğesi devre dışı bırakıldı."
