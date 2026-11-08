# @name: Dosya Sistemi ve Bellek
# @category: Performans
# @default: true
# @desc: NTFS son erişim zamanı güncellemesi ve 8.3 kısa ad üretimi kapatılır (gereksiz disk yazması azalır), SSD için TRIM açık tutulur, uzun dosya yolları desteği açılır. SSD'lerde SysMain (Superfetch) kapatılır; HDD'lerde açık bırakılır çünkü orada faydalıdır. 16 GB ve üzeri RAM'de bellek sıkıştırma kapatılır.

fsutil behavior set disablelastaccess 1 2>&1 | Out-Null
Say "NTFS son erişim zamanı güncellemesi kapalı"
fsutil 8dot3name set 1 2>&1 | Out-Null
Say "8.3 kısa dosya adı üretimi kapalı"
fsutil behavior set DisableDeleteNotify 0 2>&1 | Out-Null
Say "TRIM açık"
Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' 'LongPathsEnabled' 1
Say "Uzun dosya yolları açık"

# Sistem diski SSD mi?
$isSSD = $false
try {
    $part = Get-Partition -DriveLetter ($env:SystemDrive.TrimEnd(':')) -ErrorAction Stop
    $pd = Get-PhysicalDisk -ErrorAction Stop | Where-Object { $_.DeviceId -eq [string]$part.DiskNumber }
    if ($pd -and ($pd.MediaType -eq 'SSD' -or $pd.BusType -eq 'NVMe')) { $isSSD = $true }
} catch {}

# 16 GB ve üzeri RAM'de bellek sıkıştırma gereksiz CPU yükü getirir
$ramGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
if ($ramGB -ge 16) {
    try { Disable-MMAgent -MemoryCompression -ErrorAction Stop; Ok "RAM $ramGB GB: bellek sıkıştırma kapatıldı." } catch { Say "Bellek sıkıştırma zaten kapalı." }
    try { Disable-MMAgent -PageCombining -ErrorAction Stop } catch {}
} else {
    Say "RAM $ramGB GB (<16): bellek sıkıştırma açık bırakıldı."
}

if ($isSSD) {
    Set-ServiceStart 'SysMain' 'Disabled'
    Ok "Sistem diski SSD: SysMain kapatıldı."
} else {
    Say "Sistem diski HDD veya tespit edilemedi: SysMain açık bırakıldı."
}

# Çekirdek ve sürücü kodunu RAM'de tut (diske sayfalama yapma)
Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' 'DisablePagingExecutive' 1
Ok "Dosya sistemi ve bellek ayarları uygulandı."
