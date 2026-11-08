# @name: Windows Update Sürücü Güncellemelerini Engelle
# @category: Gelişmiş (Risk)
# @default: false
# @desc: Windows Update'in ekran kartı ve diğer sürücüleri kendi (genelde eski) sürümleriyle değiştirmesi engellenir; NVIDIA/AMD sürücünüzü siz yönetirsiniz. RİSK: Format sonrası eksik sürücüler (Wi-Fi, ses, yonga seti) artık otomatik GELMEZ. Bu yüzden önce tüm sürücüleri kurun, sonra bu seçeneği uygulayın.

$wu = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
Set-Reg $wu 'ExcludeWUDriversInQualityUpdate' 1
Set-Reg 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Update\ExcludeWUDriversInQualityUpdate' 'value' 1
Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching' 'SearchOrderConfig' 0
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata' 'PreventDeviceMetadataFromNetwork' 1
Ok "Windows Update artık sürücü yüklemeyecek."
