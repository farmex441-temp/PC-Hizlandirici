# @name: Nihai Performans Güç Planı (%100 güç)
# @category: Performans
# @default: true
# @desc: "PC Hızlandırıcı Ultimate" adında bir güç planı oluşturup etkinleştirir: işlemci her zaman %100, çekirdek park etme kapalı, USB/PCIe/disk güç tasarrufu kapalı, uyku ve hazırda bekletme kapalı, hızlı başlatma kapalı, güç kısıtlama (power throttling) kapalı. Ekran yalnızca 10 dk sonra kapanır (monitör koruması). Dizüstünde pil daha hızlı biter.

$PLAN = '77777777-7777-4777-8777-777777777777'
$planName = 'PC Hizlandirici Ultimate'

# Önceki çalıştırmadan kalan planı sil (aktifse önce Dengeli'ye geç)
powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e 2>&1 | Out-Null
powercfg /delete $PLAN 2>&1 | Out-Null

# Nihai Performans -> Yüksek Performans -> Dengeli sırasıyla kaynak planı dene
$created = $false
foreach ($src in 'e9a42b02-d5df-448d-aa00-03f14749eb61', '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c', '381b4222-f694-41f0-9685-ff5bb260df2e') {
    powercfg /duplicatescheme $src $PLAN 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { $created = $true; Say "Kaynak plan: $src"; break }
}
if (-not $created) { Fail "Güç planı oluşturulamadı."; return }

powercfg /changename $PLAN $planName "PC Hizlandirici tarafindan olusturulan %100 performans plani" 2>&1 | Out-Null

# Gizli ayarları görünür yap (Güç Seçenekleri'nde de değiştirilebilsin)
$unhide = @(
    '2a737441-1930-4402-8d77-b2bebba308a3\0853a681-27c8-4100-a2fd-82013e970683',
    '2a737441-1930-4402-8d77-b2bebba308a3\d4e98f31-5ffe-4ce1-be31-1b38b384c009',
    '54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583',
    '54533251-82be-4824-96c1-47b60b740d00\ea062031-0e34-4ff1-9b6d-eb1059334028'
)
foreach ($u in $unhide) { Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\$u" 'Attributes' 2 }

# alt grup, ayar, değer, açıklama
$settings = @(
    @('0012ee47-9041-4b5d-9b77-535fba8b1442', '6738e2c4-e8a5-4a42-b16a-e040e769756e', 0,   'Diski kapatma: asla'),
    @('0d7dbae2-4294-402a-ba8e-26777e8488cd', '309dce9b-bef4-4119-9921-a851fb12f0f4', 1,   'Masaüstü slayt gösterisi: duraklat'),
    @('19cbb8fa-5279-450e-9fac-8a3d5fedd0c1', '12bbebe6-58d6-4636-95bb-3217ef867c1a', 0,   'Kablosuz adaptör: maksimum performans'),
    @('238c9fa8-0aad-41ed-83f4-97be242c8f20', '29f6c1db-86da-48c5-9fdb-f2b67b1f44da', 0,   'Uyku: asla'),
    @('238c9fa8-0aad-41ed-83f4-97be242c8f20', '94ac6d29-73ce-41a6-809f-6363ba21b47e', 0,   'Karma uyku: kapalı'),
    @('238c9fa8-0aad-41ed-83f4-97be242c8f20', '9d7815a6-7ee4-497e-8888-515a05f02364', 0,   'Hazırda bekletme: asla'),
    @('238c9fa8-0aad-41ed-83f4-97be242c8f20', 'bd3b718a-0680-4d9d-8ab2-e1d2b4ac806d', 0,   'Uyandırma zamanlayıcıları: kapalı'),
    @('2a737441-1930-4402-8d77-b2bebba308a3', '0853a681-27c8-4100-a2fd-82013e970683', 0,   'USB hub askıya alma zaman aşımı: 0'),
    @('2a737441-1930-4402-8d77-b2bebba308a3', '48e6b7a6-50f5-4782-a5d4-53bb8f07e226', 0,   'USB seçici askıya alma: kapalı'),
    @('2a737441-1930-4402-8d77-b2bebba308a3', 'd4e98f31-5ffe-4ce1-be31-1b38b384c009', 0,   'USB 3 bağlantı güç yönetimi: kapalı'),
    @('501a4d13-42af-4429-9fd1-a8218c268e20', 'ee12f906-d277-404b-b6da-e5fa1a576df5', 0,   'PCI Express ASPM: kapalı'),
    @('54533251-82be-4824-96c1-47b60b740d00', '893dee8e-2bef-41e0-89c6-b55d0929964c', 100, 'Minimum işlemci durumu: %100'),
    @('54533251-82be-4824-96c1-47b60b740d00', 'bc5038f7-23e0-4960-96da-33abaf5935ec', 100, 'Maksimum işlemci durumu: %100'),
    @('54533251-82be-4824-96c1-47b60b740d00', '94d3a615-a899-4ac5-ae2b-e4d8f634367f', 1,   'Soğutma ilkesi: etkin'),
    @('54533251-82be-4824-96c1-47b60b740d00', '0cc5b647-c1df-4637-891a-dec35c318583', 100, 'Çekirdek park: min %100 (park yok)'),
    @('54533251-82be-4824-96c1-47b60b740d00', 'ea062031-0e34-4ff1-9b6d-eb1059334028', 100, 'Çekirdek park: max %100'),
    @('7516b95f-f776-4464-8c53-06167f40cc99', '3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e', 600, 'Ekranı kapat: 10 dk'),
    @('7516b95f-f776-4464-8c53-06167f40cc99', 'fbd9aa66-9553-4097-ba44-ed6e9d65eab8', 0,   'Uyarlamalı parlaklık: kapalı')
)

foreach ($s in $settings) {
    powercfg /setacvalueindex $PLAN $s[0] $s[1] $s[2] 2>&1 | Out-Null
    powercfg /setdcvalueindex $PLAN $s[0] $s[1] $s[2] 2>&1 | Out-Null
    Say $s[3]
}

powercfg /setactive $PLAN 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) { Ok "Güç planı etkin: $planName" } else { Warn "Güç planı etkinleştirilemedi." }

# Hazırda bekletme + hızlı başlatma kapalı (hiberfil.sys silinir, temiz kapanış)
powercfg /hibernate off 2>&1 | Out-Null
Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' 'HiberbootEnabled' 0
Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' 'HibernateEnabled' 0
Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' 'HibernateEnabledDefault' 0
Ok "Hazırda bekletme ve hızlı başlatma kapatıldı."

# Güç kısıtlamayı (Power Throttling) kapat
Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling' 'PowerThrottlingOff' 1
Ok "Power Throttling kapatıldı."
