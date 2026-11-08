# @name: Gereksiz Windows Servislerini Kapat
# @category: Windows Temizliği
# @default: true
# @desc: Oyun bilgisayarında işe yaramayan servisler kapatılır veya "El ile" (gerektiğinde başlar) moduna alınır: perakende demo, faks, uzak kayıt defteri, haritalar, ebeveyn denetimi, Insider, dağıtılmış bağlantı izleme, telefon, program uyumluluk yardımcısı vb. Yazıcı, Bluetooth, ses, arama, Xbox ve güvenlik servislerine DOKUNULMAZ.

$disable = @(
    'DiagTrack',          # Bağlı Kullanıcı Deneyimleri ve Telemetri
    'dmwappushservice',   # WAP Push mesaj yönlendirme (telemetri)
    'RetailDemo',         # Perakende demo
    'MapsBroker',         # İndirilen haritalar yöneticisi
    'Fax',                # Faks
    'RemoteRegistry',     # Uzak kayıt defteri (güvenlik için de kapalı olmalı)
    'WMPNetworkSvc',      # Windows Media Player ağ paylaşımı
    'wisvc',              # Windows Insider
    'WpcMonSvc',          # Ebeveyn denetimi
    'TrkWks',             # Dağıtılmış bağlantı izleme istemcisi
    'diagnosticshub.standardcollector.service' # Tanılama merkezi toplayıcı
)
$manual = @(
    'lfsvc',              # Coğrafi konum (gerekirse başlar)
    'PhoneSvc',           # Telefon
    'PcaSvc',             # Program uyumluluk yardımcısı
    'WerSvc',             # Hata raporlama
    'DPS',                # Tanılama ilkesi
    'WdiServiceHost',     # Tanılama hizmeti ana bilgisayarı
    'WdiSystemHost',      # Tanılama sistemi ana bilgisayarı
    'SEMgrSvc',           # Ödeme ve NFC/SE yöneticisi
    'SCardSvr',           # Akıllı kart
    'ScDeviceEnum',       # Akıllı kart aygıt numaralandırma
    'WbioSrvc',           # Biyometrik (Windows Hello parmak izi/yüz kullananlar için gerektiğinde başlar)
    'icssvc',             # Mobil etkin nokta
    'AJRouter',           # AllJoyn yönlendirici
    'SharedAccess',       # İnternet bağlantısı paylaşımı
    'stisvc'              # Tarayıcı/kamera görüntü alma (gerektiğinde başlar)
)

foreach ($s in $disable) { Set-ServiceStart $s 'Disabled' }
foreach ($s in $manual)  { Set-ServiceStart $s 'Manual' }
Ok "Servis ayarları uygulandı."
