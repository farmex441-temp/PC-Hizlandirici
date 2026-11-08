# @name: Copilot, Widget'lar ve Recall'u Kapat
# @category: Windows Temizliği
# @default: true
# @desc: Windows Copilot, Haber ve İlgi Alanları / Widget paneli, Recall (ekran görüntüsü kaydı), Click to Do ve Paint/Not Defteri'ndeki AI özellikleri kapatılır. Arka planda RAM ve CPU kullanan bu özellikler oyun bilgisayarında gereksizdir.

# --- Copilot ---
Set-Reg 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 1
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 1
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowCopilotButton' 0
Remove-AppxSafe 'Microsoft.Copilot'
Remove-AppxSafe 'Microsoft.Windows.Ai.Copilot.Provider'
Remove-AppxSafe 'Microsoft.MicrosoftOfficeHub'
Ok "Copilot kapalı."

# --- Widget'lar / Haber ve İlgi Alanları ---
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' 'AllowNewsAndInterests' 0
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds' 'EnableFeeds' 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds' 'ShellFeedsTaskbarViewMode' 2
Stop-Process -Name Widgets, WidgetService -Force -ErrorAction SilentlyContinue
Ok "Widget paneli kapalı."

# --- Recall / Click to Do / Windows AI ---
foreach ($root in 'HKLM:', 'HKCU:') {
    Set-Reg "$root\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" 'DisableAIDataAnalysis' 1
    Set-Reg "$root\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" 'DisableClickToDo' 1
}
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' 'AllowRecallEnablement' 0
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' 'TurnOffSavingSnapshots' 1
try {
    $recall = Get-WindowsOptionalFeature -Online -FeatureName Recall -ErrorAction Stop
    if ($recall.State -eq 'Enabled') { Disable-WindowsOptionalFeature -Online -FeatureName Recall -NoRestart -ErrorAction Stop | Out-Null; Say "Recall özelliği kaldırıldı" }
} catch {}
# Paint ve Not Defteri AI özellikleri
Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Paint' 'DisableCocreator' 1
Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Paint' 'DisableGenerativeFill' 1
Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Paint' 'DisableImageCreator' 1
Set-Reg 'HKLM:\SOFTWARE\Policies\WindowsNotepad' 'DisableAIFeatures' 1
Ok "Recall ve Windows AI özellikleri kapalı."

Request-ExplorerRestart
