# @name: Monitörü En Yüksek Yenileme Hızına Ayarla
# @category: Ekran Kartı
# @default: true
# @desc: Format sonrası Windows çoğu zaman 144/165/240 Hz monitörleri 60 Hz'de bırakır. Bu modül her monitörün mevcut çözünürlüğünde desteklediği en yüksek yenileme hızını bulup ayarlar (önce Windows'a test ettirir). Ekran bir an kararabilir. Ekran kartı sürücüsünün kurulu olması gerekir.

# Tüm iş C# içinde yapılır (PowerShell'in yapı/ref aktarımındaki sorunlardan kaçınmak için)
if (-not ('PCHDisplay' -as [type])) {
Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
public static class PCHDisplay {
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    struct DEVMODE {
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string dmDeviceName;
        public short dmSpecVersion, dmDriverVersion, dmSize, dmDriverExtra;
        public int dmFields, dmPositionX, dmPositionY, dmDisplayOrientation, dmDisplayFixedOutput;
        public short dmColor, dmDuplex, dmYResolution, dmTTOption, dmCollate;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string dmFormName;
        public short dmLogPixels;
        public int dmBitsPerPel, dmPelsWidth, dmPelsHeight, dmDisplayFlags, dmDisplayFrequency;
        public int dmICMMethod, dmICMIntent, dmMediaType, dmDitherType, dmReserved1, dmReserved2, dmPanningWidth, dmPanningHeight;
    }
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    struct DISPLAY_DEVICE {
        public int cb;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string DeviceName;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceString;
        public int StateFlags;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceID;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceKey;
    }
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern bool EnumDisplayDevices(string dev, uint i, ref DISPLAY_DEVICE dd, uint flags);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern bool EnumDisplaySettings(string dev, int mode, ref DEVMODE dm);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int ChangeDisplaySettingsEx(string dev, ref DEVMODE dm, IntPtr hwnd, uint flags, IntPtr lParam);

    static DEVMODE NewMode() { DEVMODE d = new DEVMODE(); d.dmSize = (short)Marshal.SizeOf(typeof(DEVMODE)); return d; }

    // Dönen satırlar: durum|ekran|mevcutHz|enYuksekHz|kod   (durum: max, test, set, fail, info)
    public static List<string> Run(bool apply) {
        List<string> res = new List<string>();
        for (uint i = 0; i < 32; i++) {
            DISPLAY_DEVICE dd = new DISPLAY_DEVICE();
            dd.cb = Marshal.SizeOf(typeof(DISPLAY_DEVICE));
            if (!EnumDisplayDevices(null, i, ref dd, 0)) break;
            if ((dd.StateFlags & 1) == 0) continue;
            DEVMODE cur = NewMode();
            if (!EnumDisplaySettings(dd.DeviceName, -1, ref cur)) continue;
            int best = cur.dmDisplayFrequency;
            DEVMODE m = NewMode();
            for (int j = 0; EnumDisplaySettings(dd.DeviceName, j, ref m); j++) {
                if (m.dmPelsWidth == cur.dmPelsWidth && m.dmPelsHeight == cur.dmPelsHeight &&
                    m.dmBitsPerPel == cur.dmBitsPerPel && (m.dmDisplayFlags & 2) == 0 && m.dmDisplayFrequency > best)
                    best = m.dmDisplayFrequency;
                m = NewMode();
            }
            string label = dd.DeviceString + " (" + cur.dmPelsWidth + "x" + cur.dmPelsHeight + ")";
            string baseLine = label + "|" + cur.dmDisplayFrequency + "|" + best;
            if (best <= cur.dmDisplayFrequency) { res.Add("max|" + baseLine + "|0"); continue; }
            if (!apply) { res.Add("info|" + baseLine + "|0"); continue; }
            cur.dmDisplayFrequency = best;
            cur.dmFields = 0x400000 | 0x80000 | 0x100000 | 0x40000;
            int t = ChangeDisplaySettingsEx(dd.DeviceName, ref cur, IntPtr.Zero, 2, IntPtr.Zero);   // CDS_TEST
            if (t != 0) { res.Add("test|" + baseLine + "|" + t); continue; }
            int r = ChangeDisplaySettingsEx(dd.DeviceName, ref cur, IntPtr.Zero, 1, IntPtr.Zero);   // CDS_UPDATEREGISTRY
            res.Add((r == 0 ? "set|" : "fail|") + baseLine + "|" + r);
        }
        return res;
    }
}
'@
}

# PCH_DISPLAY_READONLY=1 ise yalnızca raporlar (test amaçlı)
$apply = ($env:PCH_DISPLAY_READONLY -ne '1')
$lines = [PCHDisplay]::Run($apply)
if ($lines.Count -eq 0) { Warn "Masaüstüne bağlı monitör bulunamadı."; return }
foreach ($l in $lines) {
    $p = $l.Split('|')
    switch ($p[0]) {
        'max'  { Ok   "$($p[1]) zaten en yüksek hızda: $($p[2]) Hz" }
        'info' { Say  "$($p[1]): $($p[2]) Hz -> $($p[3]) Hz yapılabilir (salt okuma modu)" }
        'set'  { Ok   "$($p[1]): $($p[2]) Hz -> $($p[3]) Hz yapıldı." }
        'test' { Warn "$($p[1]): $($p[3]) Hz Windows testini geçemedi, değiştirilmedi (kod $($p[4]))." }
        'fail' { Warn "$($p[1]): $($p[3]) Hz ayarlanamadı (kod $($p[4]))." }
    }
}
