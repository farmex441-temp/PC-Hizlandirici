# @name: Çekirdek Yalıtımı / VBS Kapat (+%5-10 FPS)
# @category: Gelişmiş (Risk)
# @default: false
# @desc: Bellek Bütünlüğü (HVCI) ve Sanallaştırma Tabanlı Güvenlik (VBS) kapatılır. Özellikle Windows 11'de oyunlarda %5-10 FPS kazandırabilir. RİSK: Kötü amaçlı sürücülere karşı bir güvenlik katmanı kalkar. Valorant/FACEIT gibi bazı anti-cheat sistemleri VBS istemez ama bazıları ileride isteyebilir. Ne yaptığınızı biliyorsanız seçin.

$dg = 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard'
Set-Reg "$dg\Scenarios\HypervisorEnforcedCodeIntegrity" 'Enabled' 0
Set-Reg "$dg\Scenarios\HypervisorEnforcedCodeIntegrity" 'WasEnabledBy' 0
Set-Reg $dg 'EnableVirtualizationBasedSecurity' 0
Set-Reg $dg 'RequirePlatformSecurityFeatures' 0
Ok "Çekirdek yalıtımı / VBS yeniden başlatma sonrası kapalı olacak."
Say "Geri açmak için: Ayarlar > Gizlilik ve güvenlik > Windows Güvenliği > Cihaz güvenliği > Çekirdek yalıtımı."
