# @name: Kilit Ekranını Atla
# @category: Görünüm
# @default: true
# @desc: Açılışta ve Win+L sonrası önce gelen resimli kilit ekranı (saat/hava durumu perdesi) atlanır, doğrudan şifre/PIN ekranı gelir. Şifreniz kaldırılmaz, güvenlik değişmez; sadece bir tık ve birkaç saniye kazanırsınız.

Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization' 'NoLockScreen' 1
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'DisableLogonBackgroundImage' 0
Ok "Kilit ekranı atlanacak, doğrudan oturum açma ekranı gelecek."
