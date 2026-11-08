# @name: DirectX, Visual C++ ve .NET Paketlerini Kur
# @category: Bileşenler
# @default: true
# @desc: Oyunların ihtiyaç duyduğu tüm çalışma zamanı paketlerini RESMİ Microsoft sunucularından indirip sessizce kurar: DirectX (Haziran 2010), Visual C++ 2005-2022 (x86 + x64), .NET Framework 3.5, .NET Desktop Runtime 8 ve 10 (x86 + x64), XNA 4.0. Her dosyanın Microsoft dijital imzası kurulumdan önce doğrulanır. İnternet gerekir, toplam ~500 MB indirir ve 5-15 dakika sürebilir.

if (-not (Test-Internet)) { Fail "İnternet bağlantısı yok. Bu modül atlandı."; return }

$dl = Join-Path $script:PCH_WorkDir 'runtimes'
New-Item -ItemType Directory -Force -Path $dl | Out-Null

# Ad, URL, dosya adı, sessiz kurulum argümanları
$packages = @(
    @('Visual C++ 2005 x86',  'https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x86.EXE', 'vc2005_x86.exe', '/Q /C:"msiexec /i vcredist.msi /qn /norestart"'),
    @('Visual C++ 2005 x64',  'https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x64.EXE', 'vc2005_x64.exe', '/Q /C:"msiexec /i vcredist.msi /qn /norestart"'),
    @('Visual C++ 2008 x86',  'https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x86.exe', 'vc2008_x86.exe', '/q'),
    @('Visual C++ 2008 x64',  'https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x64.exe', 'vc2008_x64.exe', '/q'),
    @('Visual C++ 2010 x86',  'https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x86.exe', 'vc2010_x86.exe', '/q /norestart'),
    @('Visual C++ 2010 x64',  'https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x64.exe', 'vc2010_x64.exe', '/q /norestart'),
    @('Visual C++ 2012 x86',  'https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x86.exe', 'vc2012_x86.exe', '/install /quiet /norestart'),
    @('Visual C++ 2012 x64',  'https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x64.exe', 'vc2012_x64.exe', '/install /quiet /norestart'),
    @('Visual C++ 2013 x86',  'https://aka.ms/highdpimfc2013x86enu', 'vc2013_x86.exe', '/install /quiet /norestart'),
    @('Visual C++ 2013 x64',  'https://aka.ms/highdpimfc2013x64enu', 'vc2013_x64.exe', '/install /quiet /norestart'),
    @('Visual C++ 2015-2022 x86', 'https://aka.ms/vs/17/release/vc_redist.x86.exe', 'vc2022_x86.exe', '/install /quiet /norestart'),
    @('Visual C++ 2015-2022 x64', 'https://aka.ms/vs/17/release/vc_redist.x64.exe', 'vc2022_x64.exe', '/install /quiet /norestart'),
    @('.NET Desktop Runtime 8 x64',  'https://aka.ms/dotnet/8.0/windowsdesktop-runtime-win-x64.exe',  'net8_x64.exe',  '/install /quiet /norestart'),
    @('.NET Desktop Runtime 8 x86',  'https://aka.ms/dotnet/8.0/windowsdesktop-runtime-win-x86.exe',  'net8_x86.exe',  '/install /quiet /norestart'),
    @('.NET Desktop Runtime 10 x64', 'https://aka.ms/dotnet/10.0/windowsdesktop-runtime-win-x64.exe', 'net10_x64.exe', '/install /quiet /norestart'),
    @('.NET Desktop Runtime 10 x86', 'https://aka.ms/dotnet/10.0/windowsdesktop-runtime-win-x86.exe', 'net10_x86.exe', '/install /quiet /norestart'),
    @('XNA Framework 4.0', 'https://download.microsoft.com/download/A/C/2/AC2C903B-E6E8-42C2-9FD7-BEBAC362A930/xnafx40_redist.msi', 'xna40.msi', '')
)

# 0 = başarılı, 3010/1641 = yeniden başlatma gerekli, 1638/5100 = daha yeni sürüm zaten kurulu
$okCodes = 0, 1638, 1641, 3010, 5100

foreach ($p in $packages) {
    $name = $p[0]; $url = $p[1]; $file = Join-Path $dl $p[2]; $argList = $p[3]
    Say "İndiriliyor: $name"
    if (-not (Get-File $url $file)) { Fail "$name indirilemedi."; continue }
    if (-not (Test-Signed $file 'Microsoft')) { Fail "$name dosyasının Microsoft imzası doğrulanamadı, KURULMADI."; continue }
    Say "Kuruluyor: $name"
    if ($file.EndsWith('.msi')) {
        $proc = Start-Process msiexec.exe -ArgumentList "/i `"$file`" /qn /norestart" -Wait -PassThru -WindowStyle Hidden
    } else {
        $proc = Start-Process $file -ArgumentList $argList -Wait -PassThru -WindowStyle Hidden
    }
    if ($okCodes -contains $proc.ExitCode) { Ok "$name hazır." } else { Warn "$name kurulum kodu: $($proc.ExitCode)" }
}

# ---------- DirectX (Haziran 2010) ----------
Say "İndiriliyor: DirectX End-User Runtime (Haziran 2010, ~100 MB)"
$dxExe = Join-Path $dl 'directx_redist.exe'
$dxDir = Join-Path $dl 'directx'
if (Get-File 'https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/directx_Jun2010_redist.exe' $dxExe) {
    if (Test-Signed $dxExe 'Microsoft') {
        New-Item -ItemType Directory -Force -Path $dxDir | Out-Null
        Start-Process $dxExe -ArgumentList "/Q /T:`"$dxDir`"" -Wait -WindowStyle Hidden
        $setup = Join-Path $dxDir 'DXSETUP.exe'
        if (Test-Path $setup) {
            Say "Kuruluyor: DirectX"
            $proc = Start-Process $setup -ArgumentList '/silent' -Wait -PassThru -WindowStyle Hidden
            if ($proc.ExitCode -eq 0) { Ok "DirectX hazır." } else { Warn "DirectX kurulum kodu: $($proc.ExitCode)" }
        } else { Fail "DirectX arşivi açılamadı." }
    } else { Fail "DirectX imzası doğrulanamadı, KURULMADI." }
} else { Fail "DirectX indirilemedi." }

# ---------- .NET Framework 3.5 (eski oyunlar/uygulamalar) ----------
Say "Etkinleştiriliyor: .NET Framework 3.5 (Windows Update üzerinden, birkaç dakika sürebilir)"
try {
    $f = Get-WindowsOptionalFeature -Online -FeatureName NetFx3 -ErrorAction Stop
    if ($f.State -eq 'Enabled') { Ok ".NET Framework 3.5 zaten açık." }
    else {
        Enable-WindowsOptionalFeature -Online -FeatureName NetFx3 -All -NoRestart -ErrorAction Stop | Out-Null
        Ok ".NET Framework 3.5 etkinleştirildi."
    }
} catch { Warn ".NET Framework 3.5 etkinleştirilemedi: $($_.Exception.Message)" }

Remove-Item -Recurse -Force $dl -ErrorAction SilentlyContinue
