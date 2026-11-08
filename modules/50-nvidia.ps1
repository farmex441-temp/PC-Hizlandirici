# @name: NVIDIA Ekran Kartı - %100 Performans Profili
# @category: Ekran Kartı
# @default: true
# @desc: FR33THY Ultimate'taki NVIDIA ayarlarının aynısı: NVIDIA Profile Inspector (resmi GitHub sürümü) indirilir ve genel profile şu ayarlar uygulanır: Güç Yönetimi = Maksimum Performans, Düşük Gecikme = Ultra, Önceden işlenmiş kare = 1, Doku Filtreleme = Yüksek Performans, Dikey Senkronizasyon = Kapalı, G-SYNC = Kapalı, Gölgelendirici Önbelleği = Sınırsız, İş Parçacıklı İyileştirme = Açık, Tercih Edilen Yenileme Hızı = En Yüksek. Ayrıca PhysX GPU'ya alınır, MSI kesme modu açılır, NVIDIA telemetrisi kapatılır. NVIDIA kartı yoksa otomatik atlanır. ÖNCE NVIDIA sürücüsünü kurun.

$gpu = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'NVIDIA' -or $_.AdapterCompatibility -match 'NVIDIA' }
if (-not $gpu) { Say "NVIDIA ekran kartı bulunamadı, modül atlandı."; return }
Say "Bulunan kart: $(($gpu | Select-Object -First 1).Name)"

$driverOk = Test-Path "$env:SystemRoot\System32\nvapi64.dll"
if (-not $driverOk) {
    Warn "NVIDIA sürücüsü kurulu değil! Profil ayarları için önce sürücüyü kurun, sonra bu modülü tekrar çalıştırın."
    Open-Url 'https://www.nvidia.com/tr-tr/drivers/'
}

# --- Kayıt defteri ayarları ---
$nvt = 'HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm\Parameters\Global\NVTweak'
Set-Reg $nvt 'NvCplPhysxAuto' 0                 # PhysX: ekran kartı
Set-Reg $nvt 'NvDevToolsVisible' 1              # geliştirici ayarları menüsü
Set-Reg $nvt 'RmProfilingAdminOnly' 0           # GPU performans sayaçları tüm kullanıcılara
Set-Reg 'HKCU:\Software\NVIDIA Corporation\NvTray' 'StartOnLogin' 0
foreach ($k in 'HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm\FTS', 'HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm\Parameters\FTS') {
    Set-Reg $k 'EnableGR535' 0                  # eski (daha hafif) keskinleştirme filtresi
}
Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}' -ErrorAction SilentlyContinue |
    Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { Set-Reg $_.PSPath 'RmProfilingAdminOnly' 0 }
Ok "NVIDIA kayıt defteri ayarları uygulandı."

# --- NVIDIA telemetrisi ---
Set-Reg 'HKLM:\SOFTWARE\NVIDIA Corporation\NvControlPanel2\Client' 'OptInOrOutPreference' 0
Set-Reg 'HKLM:\SOFTWARE\NVIDIA Corporation\Global\FTS' 'EnableRID44231' 0
Set-Reg 'HKLM:\SOFTWARE\NVIDIA Corporation\Global\FTS' 'EnableRID64640' 0
Set-Reg 'HKLM:\SOFTWARE\NVIDIA Corporation\Global\FTS' 'EnableRID66610' 0
Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -match '^NvTm|NvProfileUpdater|NvDriverUpdateCheck' } |
    Disable-ScheduledTask -ErrorAction SilentlyContinue | Out-Null
Ok "NVIDIA telemetrisi kapatıldı."

# --- MSI (Message Signaled Interrupts) modu: daha düşük DPC gecikmesi ---
Get-PnpDevice -Class Display -PresentOnly -ErrorAction SilentlyContinue | Where-Object { $_.InstanceId -like 'PCI\VEN_10DE*' } | ForEach-Object {
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Enum\$($_.InstanceId)\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" 'MSISupported' 1
    Say "MSI modu açık: $($_.FriendlyName)"
}

if (-not $driverOk) { return }

# --- NVIDIA Profile Inspector ---
if (-not (Test-Internet)) { Fail "İnternet yok, Profile Inspector indirilemedi."; return }
$dir = "${env:ProgramFiles}\NVIDIA Profile Inspector"
$exe = Join-Path $dir 'nvidiaProfileInspector.exe'
$zip = Join-Path $script:PCH_WorkDir 'npi.zip'
Say "NVIDIA Profile Inspector indiriliyor (github.com/Orbmu2k/nvidiaProfileInspector)..."
if (-not (Get-File 'https://github.com/Orbmu2k/nvidiaProfileInspector/releases/latest/download/nvidiaProfileInspector.zip' $zip)) {
    Fail "Profile Inspector indirilemedi."; return
}
New-Item -ItemType Directory -Force -Path $dir | Out-Null
try { Expand-Archive -Path $zip -DestinationPath $dir -Force -ErrorAction Stop } catch { Fail "Arşiv açılamadı: $($_.Exception.Message)"; return }
Remove-Item $zip -Force -ErrorAction SilentlyContinue
if (-not (Test-Path $exe)) {
    $found = Get-ChildItem $dir -Recurse -Filter 'nvidiaProfileInspector.exe' | Select-Object -First 1
    if ($found) { $exe = $found.FullName } else { Fail "nvidiaProfileInspector.exe bulunamadı."; return }
}
Get-ChildItem $dir -Recurse | Unblock-File -ErrorAction SilentlyContinue
Get-ChildItem "$env:ProgramData\NVIDIA Corporation\Drs" -Recurse -ErrorAction SilentlyContinue | Unblock-File -ErrorAction SilentlyContinue

# Başlat menüsü kısayolu
try {
    $ws = New-Object -ComObject WScript.Shell
    $lnk = $ws.CreateShortcut("$env:ProgramData\Microsoft\Windows\Start Menu\Programs\NVIDIA Profile Inspector.lnk")
    $lnk.TargetPath = $exe; $lnk.WorkingDirectory = Split-Path $exe; $lnk.Save()
} catch {}

# Profil (FR33THY/Ultimate "NVIDIA Settings: On" ile aynı ayarlar)
$nip = @'
<?xml version="1.0" encoding="utf-16"?>
<ArrayOfProfile>
  <Profile>
    <ProfileName>Base Profile</ProfileName>
    <Executables/>
    <Settings>
      <ProfileSetting><SettingNameInfo>Frame Rate Limiter V3</SettingNameInfo><SettingID>277041154</SettingID><SettingValue>0</SettingValue><ValueType>Dword</ValueType></ProfileSetting>
      <ProfileSetting><SettingNameInfo>GSYNC - Application Mode</SettingNameInfo><SettingID>294973784</SettingID><SettingValue>0</SettingValue><ValueType>Dword</ValueType></ProfileSetting>
      <ProfileSetting><SettingNameInfo>GSYNC - Application State</SettingNameInfo><SettingID>279476687</SettingID><SettingValue>4</SettingValue><ValueType>Dword</ValueType></ProfileSetting>
      <ProfileSetting><SettingNameInfo>GSYNC - Global Feature</SettingNameInfo><SettingID>278196567</SettingID><SettingValue>0</SettingValue><ValueType>Dword</ValueType></ProfileSetting>
      <ProfileSetting><SettingNameInfo>GSYNC - Global Mode</SettingNameInfo><SettingID>278196727</SettingID><SettingValue>0</SettingValue><ValueType>Dword</ValueType></ProfileSetting>
      <ProfileSetting><SettingNameInfo>GSYNC - Indicator Overlay</SettingNameInfo><SettingID>268604728</SettingID><SettingValue>0</SettingValue><ValueType>Dword</ValueType></ProfileSetting>
      <ProfileSetting><SettingNameInfo>Maximum Pre-Rendered Frames</SettingNameInfo><SettingID>8102046</SettingID><SettingValue>1</SettingValue><ValueType>Dword</ValueType></ProfileSetting>
      <ProfileSetting><SettingNameInfo>Preferred Refresh Rate</SettingNameInfo><SettingID>6600001</SettingID><SettingValue>1</SettingValue><ValueType>Dword</ValueType></ProfileSetting>
      <ProfileSetting><SettingNameInfo>Ultra Low Latency - CPL State</SettingNameInfo><SettingID>390467</SettingID><SettingValue>2</SettingValue><ValueType>Dword</ValueType></ProfileSetting>
      <ProfileSetting><SettingNameInfo>Ultra Low Latency - Enabled</SettingNameInfo><SettingID>277041152</SettingID><SettingValue>1</SettingValue><ValueType>Dword</ValueType></ProfileSetting>
      <ProfileSetting><SettingNameInfo>Vertical Sync</SettingNameInfo><SettingID>11041231</SettingID><SettingValue>138504007</SettingValue><ValueType>Dword</ValueType></ProfileSetting>
      <ProfileSetting><SettingNameInfo>Vertical Sync - Smooth AFR Behavior</SettingNameInfo><SettingID>270198627</SettingID><SettingValue>0</SettingValue><ValueType>Dword</ValueType></ProfileSetting>
      <ProfileSetting><SettingNameInfo>Vertical Sync - Tear Control</SettingNameInfo><SettingID>5912412</SettingID><SettingValue>2525368439</SettingValue><ValueType>Dword</ValueType></ProfileSetting>
      <ProfileSetting><SettingNameInfo>Vulkan/OpenGL Present Method</SettingNameInfo><SettingID>550932728</SettingID><SettingValue>0</SettingValue><ValueType>Dword</ValueType></ProfileSetting>
      <ProfileSetting><SettingNameInfo>Antialiasing - Gamma Correction</SettingNameInfo><SettingID>276652957</SettingID><SettingValue>0</SettingValue><ValueType>Dword</ValueType></ProfileSetting>
      <ProfileSetting><SettingNameInfo>Antialiasing - Mode</SettingNameInfo><SettingID>276757595</SettingID><SettingValue>1</SettingValue><ValueType>Dword</ValueType></ProfileSetting>
      <ProfileSetting><SettingNameInfo>Antialiasing - Setting</SettingNameInfo><SettingID>282555346</SettingID><SettingValue>0</SettingValue><ValueType>Dword</ValueType></ProfileSetting>
      <ProfileSetting><SettingNameInfo>Anisotropic Filter - Optimization</SettingNameInfo><SettingID>8703344</SettingID><SettingValue>1</SettingValue><ValueType>Dword</ValueType></ProfileSetting>
      <ProfileSetting><SettingNameInfo>Anisotropic Filter - Sample Optimization</SettingNameInfo><SettingID>15151633</SettingID><SettingValue>1</SettingValue><ValueType>Dword</ValueType></ProfileSetting>
      <ProfileSetting><SettingNameInfo>Anisotropic Filtering - Mode</SettingNameInfo><SettingID>282245910</SettingID><SettingValue>1</SettingValue><ValueType>Dword</ValueType></ProfileSetting>
      <ProfileSetting><SettingNameInfo>Anisotropic Filtering - Setting</SettingNameInfo><SettingID>270426537</SettingID><SettingValue>1</SettingValue><ValueType>Dword</ValueType></ProfileSetting>
      <ProfileSetting><SettingNameInfo>Texture Filtering - Negative LOD Bias</SettingNameInfo><SettingID>1686376</SettingID><SettingValue>0</SettingValue><ValueType>Dword</ValueType></ProfileSetting>
      <ProfileSetting><SettingNameInfo>Texture Filtering - Quality</SettingNameInfo><SettingID>13510289</SettingID><SettingValue>20</SettingValue><ValueType>Dword</ValueType></ProfileSetting>
      <ProfileSetting><SettingNameInfo>Texture Filtering - Trilinear Optimization</SettingNameInfo><SettingID>3066610</SettingID><SettingValue>0</SettingValue><ValueType>Dword</ValueType></ProfileSetting>
      <ProfileSetting><SettingNameInfo>CUDA - Force P2 State</SettingNameInfo><SettingID>1343646814</SettingID><SettingValue>0</SettingValue><ValueType>Dword</ValueType></ProfileSetting>
      <ProfileSetting><SettingNameInfo>CUDA - Sysmem Fallback Policy</SettingNameInfo><SettingID>283962569</SettingID><SettingValue>1</SettingValue><ValueType>Dword</ValueType></ProfileSetting>
      <ProfileSetting><SettingNameInfo>Power Management - Mode</SettingNameInfo><SettingID>274197361</SettingID><SettingValue>1</SettingValue><ValueType>Dword</ValueType></ProfileSetting>
      <ProfileSetting><SettingNameInfo>Shader Cache - Cache Size</SettingNameInfo><SettingID>11306135</SettingID><SettingValue>4294967295</SettingValue><ValueType>Dword</ValueType></ProfileSetting>
      <ProfileSetting><SettingNameInfo>Threaded Optimization</SettingNameInfo><SettingID>549528094</SettingID><SettingValue>1</SettingValue><ValueType>Dword</ValueType></ProfileSetting>
      <ProfileSetting><SettingNameInfo>OpenGL GDI Compatibility</SettingNameInfo><SettingID>544392611</SettingID><SettingValue>0</SettingValue><ValueType>Dword</ValueType></ProfileSetting>
    </Settings>
  </Profile>
</ArrayOfProfile>
'@
$nipFile = Join-Path $script:PCH_WorkDir 'pc-hizlandirici.nip'
Set-Content -Path $nipFile -Value $nip -Encoding Unicode -Force
Copy-Item $nipFile (Join-Path $dir 'pc-hizlandirici.nip') -Force -ErrorAction SilentlyContinue

Say "Profil içe aktarılıyor..."
$code = Invoke-Process $exe "-silentImport `"$nipFile`"" 180
if ($code -eq 0) { Ok "NVIDIA %100 performans profili uygulandı." }
else { Warn "Profile Inspector çıkış kodu: $code. Ayarları elle uygulamak için Başlat > NVIDIA Profile Inspector'ı açıp $dir\pc-hizlandirici.nip dosyasını içe aktarın." }
