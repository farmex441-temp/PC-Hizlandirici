# @name: Ağ ve Donanım Gecikmesini Düşür
# @category: Performans
# @default: true
# @desc: Ağ bağdaştırıcılarında Nagle algoritması kapatılır (oyunlarda daha düşük ping), Enerji Verimli Ethernet ve ağ kartı güç tasarrufu kapatılır, Teslim İyileştirme (P2P güncelleme paylaşımı) kapatılır, tüm aygıtlarda "güç tasarrufu için bu aygıtı kapat" seçeneği kaldırılır. Ağ kartı değişiklikleri yeniden başlatma sonrası etkinleşir, bağlantı kopmaz.

# --- Nagle kapalı (TCP gecikmeli onay yok) ---
$ifRoot = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces'
Get-ChildItem $ifRoot -ErrorAction SilentlyContinue | ForEach-Object {
    Set-Reg $_.PSPath 'TcpAckFrequency' 1
    Set-Reg $_.PSPath 'TCPNoDelay' 1
    Set-Reg $_.PSPath 'TcpDelAckTicks' 0
}
Ok "Nagle algoritması tüm arayüzlerde kapalı."

# --- TCP genel ayarlar (Windows varsayılanı en iyi olanlar) ---
netsh int tcp set global autotuninglevel=normal 2>&1 | Out-Null
netsh int tcp set global rss=enabled 2>&1 | Out-Null
Say "TCP otomatik ayar: normal, RSS: açık"

# --- Teslim İyileştirme (Delivery Optimization) P2P kapalı ---
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization' 'DODownloadMode' 0
Ok "Teslim İyileştirme P2P kapalı (internet bant genişliğiniz başkalarına dağıtılmaz)."

# --- Fiziksel ağ kartlarında güç tasarrufu kapalı ---
$adapters = Get-NetAdapter -Physical -ErrorAction SilentlyContinue
foreach ($a in $adapters) {
    try { Disable-NetAdapterPowerManagement -Name $a.Name -NoRestart -ErrorAction Stop; Say "$($a.Name): güç yönetimi kapalı" } catch {}
    foreach ($kw in '*EEE', 'EEELinkAdvertisement', 'AdvancedEEE', 'EnableGreenEthernet', 'GigaLite', 'PowerSavingMode', 'ULPMode', 'EnablePME', '*SelectiveSuspend') {
        $prop = Get-NetAdapterAdvancedProperty -Name $a.Name -RegistryKeyword $kw -ErrorAction SilentlyContinue
        if ($prop) {
            try { Set-NetAdapterAdvancedProperty -Name $a.Name -RegistryKeyword $kw -RegistryValue 0 -NoRestart -ErrorAction Stop; Say "$($a.Name): $kw = 0" } catch {}
        }
    }
}
Ok "Ağ kartı güç tasarrufları kapatıldı."

# --- Aygıt Yöneticisi: "güç tasarrufu için bu aygıtı kapat" = kapalı (uyandırma ayarlarına dokunulmaz) ---
$count = 0
Get-CimInstance -Namespace root\wmi -ClassName MSPower_DeviceEnable -ErrorAction SilentlyContinue | ForEach-Object {
    if ($_.Enable) {
        try { Set-CimInstance -InputObject $_ -Property @{ Enable = $false } -ErrorAction Stop; $count++ } catch {}
    }
}
Ok "$count aygıtta güç tasarrufu kapatıldı (USB, ağ, giriş aygıtları)."
