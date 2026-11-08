# @name: Geri Yükleme Noktası Oluştur
# @category: Güvenlik
# @default: true
# @desc: Hiçbir şeye dokunmadan önce Windows geri yükleme noktası oluşturur. Bir sorun çıkarsa Win+R > rstrui yazarak bu noktaya geri dönebilirsiniz. Kapatmanız önerilmez.

Say "Sistem koruması C: sürücüsü için açılıyor..."
try { Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction Stop } catch { Warn "Sistem koruması açılamadı: $($_.Exception.Message)" }

# Windows normalde 24 saatte bir nokta oluşturmaya izin verir; sınırı geçici olarak kaldır
$key = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore'
Set-Reg $key 'SystemRestorePointCreationFrequency' 0

try {
    Checkpoint-Computer -Description ("PC Hizlandirici oncesi " + (Get-Date -Format 'yyyy-MM-dd HH:mm')) -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
    Ok "Geri yükleme noktası oluşturuldu."
} catch {
    Warn "Geri yükleme noktası oluşturulamadı: $($_.Exception.Message)"
}

Remove-RegValue $key 'SystemRestorePointCreationFrequency'
