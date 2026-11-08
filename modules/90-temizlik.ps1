# @name: Disk Temizliği
# @category: Bakım
# @default: true
# @desc: Geçici dosyalar, Windows Update indirme önbelleği, Teslim İyileştirme önbelleği, hata raporları, küçük resim önbelleği ve Geri Dönüşüm Kutusu temizlenir. Kişisel dosyalarınıza dokunulmaz.

function Clear-Folder ([string]$Path) {
    if (Test-Path $Path) {
        $before = (Get-ChildItem $Path -Recurse -Force -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
        Get-ChildItem $Path -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        $after = (Get-ChildItem $Path -Recurse -Force -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
        return [math]::Max(0, [double]$before - [double]$after)
    }
    return 0
}

$freed = 0
# Kendi çalışma klasörümüzü (bu betiğin bulunduğu yer) silmemek için kullanıcı TEMP'inde onu hariç tut
Get-ChildItem $env:TEMP -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'PCHizlandirici' } | ForEach-Object {
    $sz = 0
    if ($_.PSIsContainer) { $sz = (Get-ChildItem $_.FullName -Recurse -Force -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum } else { $sz = $_.Length }
    Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
    if (-not (Test-Path $_.FullName)) { $freed += [double]$sz }
}
$freed += Clear-Folder "$env:SystemRoot\Temp"
$freed += Clear-Folder "$env:ProgramData\Microsoft\Windows\WER\ReportArchive"
$freed += Clear-Folder "$env:ProgramData\Microsoft\Windows\WER\ReportQueue"

Say "Windows Update önbelleği temizleniyor..."
Stop-Service wuauserv, bits -Force -ErrorAction SilentlyContinue
$freed += Clear-Folder "$env:SystemRoot\SoftwareDistribution\Download"
Start-Service wuauserv, bits -ErrorAction SilentlyContinue

try { Delete-DeliveryOptimizationCache -Force -ErrorAction Stop } catch {}
Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Windows\Explorer" -Filter 'thumbcache_*.db' -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
try { Clear-RecycleBin -Force -ErrorAction Stop } catch {}

Ok ("Temizlik bitti. Yaklaşık {0:N0} MB boşaltıldı." -f ($freed / 1MB))
