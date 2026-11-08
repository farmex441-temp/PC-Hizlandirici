# @name: Windows Lisansını Kontrol Et / Etkinleştir (yasal)
# @category: Güvenlik
# @default: true
# @desc: Windows'un etkin olup olmadığını kontrol eder. Etkin değilse: anakarta (BIOS/UEFI) gömülü orijinal ürün anahtarı varsa onu kurup etkinleştirir; bu PC daha önce etkinleştirildiyse dijital lisansla yeniden etkinleştirmeyi tetikler. Hiçbir lisans atlatma/korsan yöntem KULLANILMAZ. Etkinleşmezse Ayarlar > Etkinleştirme sayfasını açar.

function Get-WinLicense {
    Get-CimInstance SoftwareLicensingProduct -Filter "ApplicationID='55c92734-d682-4d71-983e-d6ec3f16059f' AND PartialProductKey IS NOT NULL" -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like 'Windows*' } | Select-Object -First 1
}
$status = @{ 0 = 'Lisanssız'; 1 = 'Etkin'; 2 = 'Ek süre'; 3 = 'Ek süre'; 4 = 'Orijinal olmayan'; 5 = 'Bildirim modu'; 6 = 'Uzatılmış ek süre' }

$lic = Get-WinLicense
if ($lic -and $lic.LicenseStatus -eq 1) { Ok "Windows etkin ($($lic.Name))."; return }
if ($lic) { Say "Durum: $($status[[int]$lic.LicenseStatus]) ($($lic.Name))" } else { Say "Windows ürün anahtarı bulunamadı." }

$slmgr = "$env:SystemRoot\System32\slmgr.vbs"
$cscript = "$env:SystemRoot\System32\cscript.exe"

# Anakarttaki OEM anahtarı (OA3) - üreticinin bu cihaz için verdiği yasal anahtar
$oem = (Get-CimInstance SoftwareLicensingService -ErrorAction SilentlyContinue).OA3xOriginalProductKey
if ($oem) {
    Say "Anakartta orijinal Windows anahtarı bulundu, kuruluyor..."
    $null = Invoke-Process $cscript "//nologo `"$slmgr`" /ipk $oem" 120
}

if (Test-Internet) {
    Say "Microsoft etkinleştirme sunucusuna bağlanılıyor..."
    $null = Invoke-Process $cscript "//nologo `"$slmgr`" /ato" 180
} else {
    Warn "İnternet yok: etkinleştirme internete bağlanınca Windows tarafından otomatik yapılır."
}

$lic = Get-WinLicense
if ($lic -and $lic.LicenseStatus -eq 1) { Ok "Windows etkinleştirildi." }
else {
    Warn "Windows etkinleştirilemedi. Ayarlar > Etkinleştirme sayfasından kendi ürün anahtarınızı girebilir veya 'Sorun gider' ile Microsoft hesabınızdaki dijital lisansı bağlayabilirsiniz."
    Open-Url 'ms-settings:activation'
}
Say "Office: office.com'a Microsoft hesabınızla girip 'Uygulamaları yükle' deyin; satın aldığınız lisans otomatik tanınır."
