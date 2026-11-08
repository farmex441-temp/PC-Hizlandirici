// =====================================================================
//  PC Hizlandirici - Windows oyun optimizasyon araci
//  Arayuz + modul calistirici. Modullerin kendisi modules\*.ps1 icindedir.
//  Derleme: build.ps1  (C# 5 / .NET Framework 4.8, ek kurulum gerektirmez)
// =====================================================================
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Security.Principal;
using System.Text;
using System.Threading;
using System.Windows.Forms;

[assembly: AssemblyTitle("PC Hızlandırıcı")]
[assembly: AssemblyDescription("Format sonrası Windows oyun optimizasyonu")]
[assembly: AssemblyProduct("PC Hızlandırıcı")]
[assembly: AssemblyCopyright("MIT Lisansı - FR33THY/Ultimate tabanlı")]
[assembly: AssemblyVersion("1.0.0.0")]
[assembly: AssemblyFileVersion("1.0.0.0")]

namespace PCHizlandirici
{
    // ------------------------------------------------------------------
    //  Modul modeli
    // ------------------------------------------------------------------
    class Module
    {
        public string FileName;
        public string Name;
        public string Category;
        public bool Default;
        public string Description;
        public string Content;
    }

    static class Modules
    {
        public const string ResourcePrefix = "modules/";
        public static string Lib = "";
        public static string SourceInfo = "";
        public static string LocalDir
        {
            get { return Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "modules"); }
        }

        static readonly Encoding Utf8Bom = new UTF8Encoding(true);

        // modules klasoru exe'nin yanindaysa onu kullan (duzenlenebilir mod), yoksa exe icindekileri kullan
        public static List<Module> Load()
        {
            var files = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            if (Directory.Exists(LocalDir) && File.Exists(Path.Combine(LocalDir, "_lib.ps1")))
            {
                foreach (var f in Directory.GetFiles(LocalDir, "*.ps1"))
                    files[Path.GetFileName(f)] = File.ReadAllText(f, Encoding.UTF8);
                SourceInfo = "Modüller: " + LocalDir + " (düzenlenebilir mod)";
            }
            else
            {
                foreach (var kv in ReadEmbedded()) files[kv.Key] = kv.Value;
                SourceInfo = "Modüller: program içine gömülü";
            }

            string lib;
            Lib = files.TryGetValue("_lib.ps1", out lib) ? lib : "";

            var list = new List<Module>();
            foreach (var name in files.Keys.OrderBy(k => k, StringComparer.Ordinal))
            {
                if (name.StartsWith("_")) continue;
                list.Add(Parse(name, files[name]));
            }
            return list;
        }

        static Dictionary<string, string> ReadEmbedded()
        {
            var result = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            var asm = Assembly.GetExecutingAssembly();
            foreach (var res in asm.GetManifestResourceNames())
            {
                if (!res.StartsWith(ResourcePrefix)) continue;
                using (var s = asm.GetManifestResourceStream(res))
                using (var r = new StreamReader(s, Encoding.UTF8, true))
                    result[res.Substring(ResourcePrefix.Length)] = r.ReadToEnd();
            }
            return result;
        }

        static Module Parse(string fileName, string content)
        {
            var m = new Module
            {
                FileName = fileName,
                Name = Path.GetFileNameWithoutExtension(fileName),
                Category = "Diğer",
                Default = false,
                Description = "",
                Content = content
            };
            foreach (var raw in content.Split('\n'))
            {
                var line = raw.Trim();
                if (line.Length == 0) continue;
                if (!line.StartsWith("#")) break;
                if (!line.StartsWith("# @")) continue;
                int colon = line.IndexOf(':');
                if (colon < 0) continue;
                var key = line.Substring(3, colon - 3).Trim().ToLowerInvariant();
                var val = line.Substring(colon + 1).Trim();
                if (key == "name") m.Name = val;
                else if (key == "category") m.Category = val;
                else if (key == "default") m.Default = val.Equals("true", StringComparison.OrdinalIgnoreCase) || val.Equals("evet", StringComparison.OrdinalIgnoreCase);
                else if (key == "desc") m.Description = val;
            }
            return m;
        }

        // Gomulu modulleri exe yanina "modules" klasorune cikarir (duzenleme icin)
        public static int Export()
        {
            Directory.CreateDirectory(LocalDir);
            int n = 0;
            foreach (var kv in ReadEmbedded())
            {
                var target = Path.Combine(LocalDir, kv.Key);
                if (File.Exists(target)) continue;
                File.WriteAllText(target, kv.Value, Utf8Bom);
                n++;
            }
            return n;
        }

        // Modulu calistirir. Donus: 0 basarili, 2 uyarili, diger hata
        public static int Run(Module m, Action<string> onLine, ref bool explorerRestart, Func<bool> cancelled, out Process started)
        {
            started = null;
            var dir = Path.Combine(Path.GetTempPath(), "PCHizlandirici", "run");
            Directory.CreateDirectory(dir);
            var script = Path.Combine(dir, m.FileName);
            var sb = new StringBuilder();
            sb.AppendLine(Lib);
            sb.AppendLine("# ===== MODUL: " + m.FileName + " =====");
            sb.AppendLine("& {");
            sb.AppendLine(m.Content);
            sb.AppendLine("}");
            sb.AppendLine("if ($script:PCH_Warnings -gt 0) { exit 2 }");
            sb.AppendLine("exit 0");
            File.WriteAllText(script, sb.ToString(), Utf8Bom);

            var psi = new ProcessStartInfo
            {
                FileName = Path.Combine(Environment.SystemDirectory, @"WindowsPowerShell\v1.0\powershell.exe"),
                Arguments = "-NoProfile -NonInteractive -ExecutionPolicy Bypass -File \"" + script + "\"",
                UseShellExecute = false,
                CreateNoWindow = true,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                StandardOutputEncoding = Encoding.UTF8,
                StandardErrorEncoding = Encoding.UTF8,
                WorkingDirectory = dir
            };

            bool restart = false;
            using (var p = new Process { StartInfo = psi })
            {
                DataReceivedEventHandler handler = (s, e) =>
                {
                    if (e.Data == null) return;
                    if (e.Data.Trim() == "##EXPLORER##") { restart = true; return; }
                    onLine(e.Data);
                };
                DataReceivedEventHandler errHandler = (s, e) =>
                {
                    if (e.Data == null || e.Data.Trim().Length == 0) return;
                    onLine("[x] " + e.Data);
                };
                p.OutputDataReceived += handler;
                p.ErrorDataReceived += errHandler;
                p.Start();
                started = p;
                p.BeginOutputReadLine();
                p.BeginErrorReadLine();
                while (!p.WaitForExit(250))
                {
                    if (cancelled())
                    {
                        try { p.Kill(); } catch { }
                        break;
                    }
                }
                p.WaitForExit();
                started = null;
                try { File.Delete(script); } catch { }
                if (restart) explorerRestart = true;
                return p.HasExited ? p.ExitCode : -1;
            }
        }
    }

    // ------------------------------------------------------------------
    //  Tema
    // ------------------------------------------------------------------
    static class Theme
    {
        public static readonly Color Back = Color.FromArgb(16, 17, 20);
        public static readonly Color Panel = Color.FromArgb(24, 26, 31);
        public static readonly Color Panel2 = Color.FromArgb(32, 35, 42);
        public static readonly Color Border = Color.FromArgb(48, 52, 62);
        public static readonly Color Text = Color.FromArgb(230, 232, 236);
        public static readonly Color Muted = Color.FromArgb(150, 156, 168);
        public static readonly Color Accent = Color.FromArgb(118, 185, 0);
        public static readonly Color AccentHover = Color.FromArgb(138, 205, 20);
        public static readonly Color Warn = Color.FromArgb(245, 180, 60);
        public static readonly Color Error = Color.FromArgb(240, 90, 90);
        public static readonly Color Ok = Color.FromArgb(120, 210, 120);
    }

    class FlatBtn : Button
    {
        public FlatBtn(string text, bool primary)
        {
            Text = text;
            FlatStyle = FlatStyle.Flat;
            FlatAppearance.BorderSize = primary ? 0 : 1;
            FlatAppearance.BorderColor = Theme.Border;
            BackColor = primary ? Theme.Accent : Theme.Panel2;
            ForeColor = primary ? Color.Black : Theme.Text;
            FlatAppearance.MouseOverBackColor = primary ? Theme.AccentHover : Theme.Border;
            Font = new Font("Segoe UI", primary ? 11f : 9.5f, primary ? FontStyle.Bold : FontStyle.Regular);
            Cursor = Cursors.Hand;
            AutoSize = false;
            Height = primary ? 42 : 34;
            Margin = new Padding(0, 0, 8, 0);
            UseVisualStyleBackColor = false;
        }
    }

    // ------------------------------------------------------------------
    //  Ana pencere
    // ------------------------------------------------------------------
    class MainForm : Form
    {
        [DllImport("kernel32.dll")]
        static extern uint SetThreadExecutionState(uint esFlags);
        const uint ES_CONTINUOUS = 0x80000000, ES_SYSTEM_REQUIRED = 0x00000001;

        readonly bool autoMode, autoReboot;
        List<Module> modules;
        TreeView tree;
        Label descTitle, descText, statusLabel, sourceLabel;
        RichTextBox log;
        ProgressBar progress;
        FlatBtn runBtn, btnDefaults, btnAll, btnNone, btnEdit;
        volatile bool running, cancel;
        readonly StringBuilder logText = new StringBuilder();

        public MainForm(bool auto, bool reboot)
        {
            autoMode = auto;
            autoReboot = reboot;
            SuspendLayout();
            AutoScaleDimensions = new SizeF(96F, 96F);
            AutoScaleMode = AutoScaleMode.Dpi;
            Text = "PC Hızlandırıcı v1.0";
            Font = new Font("Segoe UI", 9.5f);
            BackColor = Theme.Back;
            ForeColor = Theme.Text;
            Size = new Size(1120, 760);
            MinimumSize = new Size(900, 600);
            StartPosition = FormStartPosition.CenterScreen;
            try { Icon = Icon.ExtractAssociatedIcon(Application.ExecutablePath); } catch { }

            BuildUi();
            ResumeLayout(true);
            LoadModules();

            FormClosing += OnClosingForm;
            Shown += (s, e) =>
            {
                if (!IsAdmin())
                    AppendLog("[!] Yönetici olarak çalışmıyor: modüller uygulanamaz (yalnızca önizleme).", Theme.Warn);
                if (autoMode) StartRun(true);
            };
        }

        // ---------------- arayuz ----------------
        void BuildUi()
        {
            // Ust baslik
            var header = new Panel { Dock = DockStyle.Top, Height = 78, BackColor = Theme.Panel, Padding = new Padding(22, 12, 22, 10) };
            var title = new Label { Text = "⚡ PC Hızlandırıcı", Font = new Font("Segoe UI", 19f, FontStyle.Bold), ForeColor = Theme.Text, AutoSize = true, Location = new Point(20, 10) };
            var sub = new Label { Text = "Format sonrası tek tıkla tam oyun performansı  •  FR33THY Ultimate tabanlı", ForeColor = Theme.Muted, AutoSize = true, Location = new Point(24, 48) };
            sourceLabel = new Label { ForeColor = Theme.Muted, AutoSize = false, Dock = DockStyle.Right, Width = 460, TextAlign = ContentAlignment.BottomRight, Font = new Font("Segoe UI", 8.5f), AutoEllipsis = true };
            header.Controls.Add(sourceLabel);
            header.Controls.Add(title);
            header.Controls.Add(sub);
            var headerLine = new Panel { Dock = DockStyle.Top, Height = 2, BackColor = Theme.Accent };

            // Alt cubuk
            var bottom = new Panel { Dock = DockStyle.Bottom, Height = 72, BackColor = Theme.Panel, Padding = new Padding(18, 14, 18, 14) };
            var leftButtons = new FlowLayoutPanel { Dock = DockStyle.Left, Width = 640, FlowDirection = FlowDirection.LeftToRight, WrapContents = false, BackColor = Theme.Panel, Padding = new Padding(0, 4, 0, 0) };
            btnDefaults = new FlatBtn("Önerilenleri Seç", false) { Width = 140 };
            btnAll = new FlatBtn("Tümünü Seç", false) { Width = 110 };
            btnNone = new FlatBtn("Hiçbiri", false) { Width = 80 };
            btnEdit = new FlatBtn("Modülleri Düzenle…", false) { Width = 150 };
            btnDefaults.Click += (s, e) => SelectWhere(m => m.Default);
            btnAll.Click += (s, e) => SelectWhere(m => true);
            btnNone.Click += (s, e) => SelectWhere(m => false);
            btnEdit.Click += (s, e) => EditModules();
            leftButtons.Controls.AddRange(new Control[] { btnDefaults, btnAll, btnNone, btnEdit });
            runBtn = new FlatBtn("OPTİMİZE ET", true) { Dock = DockStyle.Right, Width = 220 };
            runBtn.Click += (s, e) => { if (running) AskCancel(); else StartRun(false); };
            bottom.Controls.Add(leftButtons);
            bottom.Controls.Add(runBtn);

            var statusBar = new Panel { Dock = DockStyle.Bottom, Height = 30, BackColor = Theme.Back, Padding = new Padding(20, 6, 20, 4) };
            statusLabel = new Label { Dock = DockStyle.Fill, ForeColor = Theme.Muted, Text = "Hazır." };
            progress = new ProgressBar { Dock = DockStyle.Right, Width = 300, Height = 14, Style = ProgressBarStyle.Continuous };
            statusBar.Controls.Add(statusLabel);
            statusBar.Controls.Add(progress);

            // Orta alan
            var split = new SplitContainer
            {
                Dock = DockStyle.Fill,
                BackColor = Theme.Back,
                SplitterWidth = 10,
                FixedPanel = FixedPanel.Panel1,
                Panel1MinSize = 300
            };
            split.Panel1.Padding = new Padding(16, 14, 0, 8);
            split.Panel2.Padding = new Padding(0, 14, 16, 8);

            var treeHeader = new Label { Text = "MODÜLLER", Dock = DockStyle.Top, Height = 24, ForeColor = Theme.Muted, Font = new Font("Segoe UI", 8.5f, FontStyle.Bold) };
            var treeWrap = new Panel { Dock = DockStyle.Fill, BackColor = Theme.Panel, Padding = new Padding(8) };
            tree = new TreeView
            {
                Dock = DockStyle.Fill,
                CheckBoxes = true,
                BackColor = Theme.Panel,
                ForeColor = Theme.Text,
                BorderStyle = BorderStyle.None,
                ShowLines = false,
                ShowPlusMinus = false,
                FullRowSelect = true,
                HideSelection = false,
                ItemHeight = 26,
                Font = new Font("Segoe UI", 10f)
            };
            tree.DrawMode = TreeViewDrawMode.OwnerDrawText;
            tree.DrawNode += (s, e) =>
            {
                if (e.Bounds.IsEmpty) return;
                bool sel = (e.State & TreeNodeStates.Selected) != 0;
                var font = e.Node.NodeFont ?? tree.Font;
                var color = e.Node.ForeColor.IsEmpty ? tree.ForeColor : e.Node.ForeColor;
                if (!tree.Enabled && e.Node.Tag != null) color = Theme.Muted;
                var r = new Rectangle(e.Bounds.X, e.Bounds.Y, Math.Max(0, tree.ClientSize.Width - e.Bounds.X), e.Bounds.Height);
                using (var b = new SolidBrush(sel ? Theme.Panel2 : tree.BackColor)) e.Graphics.FillRectangle(b, r);
                TextRenderer.DrawText(e.Graphics, e.Node.Text, font, r, color, TextFormatFlags.VerticalCenter | TextFormatFlags.Left | TextFormatFlags.NoPrefix);
            };
            tree.AfterCheck += OnAfterCheck;
            tree.AfterSelect += (s, e) => ShowDescription(e.Node);
            tree.BeforeCollapse += (s, e) => e.Cancel = true;
            treeWrap.Controls.Add(tree);
            split.Panel1.Controls.Add(treeWrap);
            split.Panel1.Controls.Add(treeHeader);

            var descPanel = new Panel { Dock = DockStyle.Top, Height = 138, BackColor = Theme.Panel, Padding = new Padding(16, 12, 16, 12) };
            descTitle = new Label { Dock = DockStyle.Top, Height = 28, Font = new Font("Segoe UI", 12f, FontStyle.Bold), ForeColor = Theme.Text, Text = "Bir modül seçin" };
            descText = new Label { Dock = DockStyle.Fill, ForeColor = Theme.Muted, Text = "Soldaki listeden bir modüle tıklayarak ne yaptığını görebilirsiniz. Önerilen ayarlar zaten seçili; doğrudan OPTİMİZE ET'e basabilirsiniz." };
            descPanel.Controls.Add(descText);
            descPanel.Controls.Add(descTitle);
            var gap = new Panel { Dock = DockStyle.Top, Height = 12, BackColor = Theme.Back };
            var logHeader = new Label { Text = "İŞLEM KAYDI", Dock = DockStyle.Top, Height = 24, ForeColor = Theme.Muted, Font = new Font("Segoe UI", 8.5f, FontStyle.Bold) };
            var logWrap = new Panel { Dock = DockStyle.Fill, BackColor = Color.FromArgb(10, 11, 13), Padding = new Padding(10) };
            log = new RichTextBox
            {
                Dock = DockStyle.Fill,
                ReadOnly = true,
                BackColor = Color.FromArgb(10, 11, 13),
                ForeColor = Theme.Muted,
                BorderStyle = BorderStyle.None,
                Font = new Font("Consolas", 9.5f),
                DetectUrls = false,
                WordWrap = true
            };
            logWrap.Controls.Add(log);
            split.Panel2.Controls.Add(logWrap);
            split.Panel2.Controls.Add(logHeader);
            split.Panel2.Controls.Add(gap);
            split.Panel2.Controls.Add(descPanel);

            Controls.Add(split);
            Controls.Add(statusBar);
            Controls.Add(bottom);
            Controls.Add(headerLine);
            Controls.Add(header);
            Load += (s, e) => { try { split.SplitterDistance = (int)(470 * DeviceDpi / 96.0); } catch { } };
            tree.HandleCreated += (s, e) => DarkScrollbars(tree);
            log.HandleCreated += (s, e) => DarkScrollbars(log);
        }

        [DllImport("uxtheme.dll", CharSet = CharSet.Unicode)]
        static extern int SetWindowTheme(IntPtr hWnd, string pszSubAppName, string pszSubIdList);
        [DllImport("dwmapi.dll")]
        static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);

        static void DarkScrollbars(Control c)
        {
            try { SetWindowTheme(c.Handle, "DarkMode_Explorer", null); } catch { }
        }

        protected override void OnHandleCreated(EventArgs e)
        {
            base.OnHandleCreated(e);
            // Koyu baslik cubugu (Windows 10 20H1+ / 11)
            try { int on = 1; if (DwmSetWindowAttribute(Handle, 20, ref on, 4) != 0) DwmSetWindowAttribute(Handle, 19, ref on, 4); } catch { }
        }

        void LoadModules()
        {
            modules = Modules.Load();
            sourceLabel.Text = Modules.SourceInfo;
            tree.BeginUpdate();
            tree.Nodes.Clear();
            var bold = new Font("Segoe UI", 9f, FontStyle.Bold);
            foreach (var group in modules.GroupBy(m => m.Category))
            {
                var cat = new TreeNode(group.Key.ToUpperInvariant()) { NodeFont = bold, ForeColor = group.Key.Contains("Risk") ? Theme.Warn : Theme.Accent };
                foreach (var m in group)
                {
                    var n = new TreeNode(m.Name) { Tag = m, Checked = m.Default };
                    if (m.Category.Contains("Risk")) n.ForeColor = Theme.Warn;
                    cat.Nodes.Add(n);
                }
                cat.Checked = cat.Nodes.Cast<TreeNode>().All(x => x.Checked);
                tree.Nodes.Add(cat);
            }
            tree.ExpandAll();
            tree.EndUpdate();
            if (tree.Nodes.Count > 0 && tree.Nodes[0].Nodes.Count > 0)
            {
                tree.SelectedNode = tree.Nodes[0].Nodes[0];
                tree.Nodes[0].EnsureVisible();
            }
            UpdateStatus();
        }

        void OnAfterCheck(object sender, TreeViewEventArgs e)
        {
            if (e.Action == TreeViewAction.Unknown) return;
            if (running) { return; }
            if (e.Node.Tag == null)
                foreach (TreeNode c in e.Node.Nodes) c.Checked = e.Node.Checked;
            else if (e.Node.Parent != null)
                e.Node.Parent.Checked = e.Node.Parent.Nodes.Cast<TreeNode>().All(x => x.Checked);
            UpdateStatus();
        }

        void SelectWhere(Func<Module, bool> pred)
        {
            foreach (TreeNode cat in tree.Nodes)
            {
                foreach (TreeNode n in cat.Nodes) n.Checked = pred((Module)n.Tag);
                cat.Checked = cat.Nodes.Cast<TreeNode>().All(x => x.Checked);
            }
            UpdateStatus();
        }

        List<Module> Selected()
        {
            var list = new List<Module>();
            foreach (TreeNode cat in tree.Nodes)
                foreach (TreeNode n in cat.Nodes)
                    if (n.Checked) list.Add((Module)n.Tag);
            return list.OrderBy(m => m.FileName, StringComparer.Ordinal).ToList();
        }

        void UpdateStatus()
        {
            if (!running) statusLabel.Text = Selected().Count + " / " + modules.Count + " modül seçili.";
        }

        void ShowDescription(TreeNode node)
        {
            var m = node.Tag as Module;
            if (m == null)
            {
                descTitle.Text = node.Text;
                descText.Text = node.Nodes.Count + " modül. Kategori kutusunu işaretleyerek hepsini seçebilirsiniz.";
                return;
            }
            descTitle.Text = m.Name;
            descText.Text = m.Description + "\n\nDosya: " + m.FileName;
        }

        void EditModules()
        {
            try
            {
                int n = Modules.Export();
                Process.Start("explorer.exe", "\"" + Modules.LocalDir + "\"");
                AppendLog("[+] Modül klasörü: " + Modules.LocalDir + (n > 0 ? " (" + n + " dosya çıkarıldı)" : ""), Theme.Ok);
                AppendLog("    .ps1 dosyalarını düzenleyin veya yeni modül ekleyin; program her açılışta bu klasörü kullanır.", Theme.Muted);
                LoadModules();
            }
            catch (Exception ex) { AppendLog("[x] " + ex.Message, Theme.Error); }
        }

        // ---------------- calistirma ----------------
        void StartRun(bool unattended)
        {
            if (running) return;
            if (!IsAdmin())
            {
                MessageBox.Show(this, "Modülleri uygulamak için program yönetici olarak çalışmalı.", "PC Hızlandırıcı", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }
            var list = unattended ? modules.Where(m => m.Default).ToList() : Selected();
            if (list.Count == 0)
            {
                MessageBox.Show(this, "Hiç modül seçilmedi.", "PC Hızlandırıcı", MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }
            if (!unattended)
            {
                var risky = list.Where(m => m.Category.Contains("Risk")).Select(m => "  • " + m.Name).ToList();
                var msg = list.Count + " modül uygulanacak. İşlem sırasında ekran birkaç kez yanıp sönebilir, bu normaldir.\n" +
                          "İşlem bitince bilgisayarı yeniden başlatmanız gerekir.";
                if (risky.Count > 0) msg += "\n\nDİKKAT - risk içeren seçenekler:\n" + string.Join("\n", risky);
                msg += "\n\nDevam edilsin mi?";
                if (MessageBox.Show(this, msg, "PC Hızlandırıcı", MessageBoxButtons.YesNo, risky.Count > 0 ? MessageBoxIcon.Warning : MessageBoxIcon.Question) != DialogResult.Yes)
                    return;
            }

            running = true;
            cancel = false;
            SetUiEnabled(false);
            log.Clear();
            logText.Clear();
            progress.Maximum = list.Count;
            progress.Value = 0;
            AppendLog("PC Hızlandırıcı v1.0  —  " + DateTime.Now.ToString("dd.MM.yyyy HH:mm"), Theme.Accent);
            AppendLog(Environment.OSVersion.VersionString + "  •  " + Environment.MachineName, Theme.Muted);

            var t = new Thread(() => RunAll(list)) { IsBackground = true };
            t.Start();
        }

        void RunAll(List<Module> list)
        {
            SetThreadExecutionState(ES_CONTINUOUS | ES_SYSTEM_REQUIRED);
            int ok = 0, warn = 0, fail = 0;
            bool explorer = false;
            var sw = Stopwatch.StartNew();
            for (int i = 0; i < list.Count; i++)
            {
                if (cancel) break;
                var m = list[i];
                int idx = i;
                Ui(() => { statusLabel.Text = "[" + (idx + 1) + "/" + list.Count + "] " + m.Name + "…"; HighlightNode(m); });
                AppendLog("", Theme.Muted);
                AppendLog("━━ [" + (i + 1) + "/" + list.Count + "] " + m.Name, Theme.Accent);
                int code;
                try
                {
                    Process p;
                    code = Modules.Run(m, line => AppendLog(line, ColorFor(line)), ref explorer, () => cancel, out p);
                }
                catch (Exception ex)
                {
                    AppendLog("[x] " + ex.Message, Theme.Error);
                    code = -1;
                }
                if (code == 0) { ok++; AppendLog("✔ Tamamlandı", Theme.Ok); }
                else if (code == 2) { warn++; AppendLog("✔ Uyarılarla tamamlandı", Theme.Warn); }
                else { fail++; AppendLog("✖ Hata (çıkış kodu " + code + ")", Theme.Error); }
                Ui(() => progress.Value = idx + 1);
            }

            if (explorer && !cancel)
            {
                AppendLog("", Theme.Muted);
                AppendLog("Gezgin (Explorer) yeniden başlatılıyor…", Theme.Muted);
                RestartExplorer();
            }

            sw.Stop();
            AppendLog("", Theme.Muted);
            AppendLog(string.Format("BİTTİ: {0} başarılı, {1} uyarılı, {2} hatalı  •  süre {3:mm\\:ss}", ok, warn, fail, sw.Elapsed), fail > 0 ? Theme.Warn : Theme.Ok);
            var logFile = SaveLog();
            if (logFile != null) AppendLog("Kayıt dosyası: " + logFile, Theme.Muted);
            SetThreadExecutionState(ES_CONTINUOUS);

            Ui(() =>
            {
                running = false;
                SetUiEnabled(true);
                statusLabel.Text = cancel ? "İptal edildi." : "Tamamlandı. Değişikliklerin tamamı için yeniden başlatın.";
                if (cancel) return;
                if (autoReboot) { Reboot(); return; }
                if (MessageBox.Show(this, "Optimizasyon tamamlandı.\n\n" + ok + " başarılı, " + warn + " uyarılı, " + fail + " hatalı.\n\n" +
                    "Tüm ayarların geçerli olması için bilgisayar yeniden başlatılmalı. Şimdi yeniden başlatılsın mı?",
                    "PC Hızlandırıcı", MessageBoxButtons.YesNo, MessageBoxIcon.Information) == DialogResult.Yes)
                    Reboot();
            });
        }

        void HighlightNode(Module m)
        {
            foreach (TreeNode cat in tree.Nodes)
                foreach (TreeNode n in cat.Nodes)
                    if (n.Tag == m) { tree.SelectedNode = n; n.EnsureVisible(); }
        }

        static void RestartExplorer()
        {
            foreach (var p in Process.GetProcessesByName("explorer"))
                try { p.Kill(); } catch { }
            // Windows, Explorer'i normalde kendisi yeniden baslatir (AutoRestartShell)
            for (int i = 0; i < 20; i++)
            {
                Thread.Sleep(500);
                if (Process.GetProcessesByName("explorer").Length > 0) return;
            }
            try { Process.Start("explorer.exe"); } catch { }
        }

        static void Reboot()
        {
            try { Process.Start(new ProcessStartInfo("shutdown.exe", "/r /t 5 /c \"PC Hizlandirici: optimizasyon tamamlandi, yeniden baslatiliyor.\"") { CreateNoWindow = true, UseShellExecute = false }); } catch { }
        }

        string SaveLog()
        {
            try
            {
                var dir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData), "PCHizlandirici", "logs");
                Directory.CreateDirectory(dir);
                var file = Path.Combine(dir, "log_" + DateTime.Now.ToString("yyyyMMdd_HHmmss") + ".txt");
                lock (logText) File.WriteAllText(file, logText.ToString(), new UTF8Encoding(true));
                return file;
            }
            catch { return null; }
        }

        static Color ColorFor(string line)
        {
            if (line.StartsWith("[+]")) return Theme.Ok;
            if (line.StartsWith("[!]")) return Theme.Warn;
            if (line.StartsWith("[x]")) return Theme.Error;
            return Theme.Muted;
        }

        void AppendLog(string text, Color color)
        {
            lock (logText) logText.AppendLine(text);
            Ui(() =>
            {
                log.SelectionStart = log.TextLength;
                log.SelectionLength = 0;
                log.SelectionColor = color;
                log.AppendText(text + "\n");
                log.ScrollToCaret();
            });
        }

        void Ui(Action a)
        {
            if (IsDisposed) return;
            if (InvokeRequired) { try { BeginInvoke(a); } catch { } }
            else a();
        }

        void SetUiEnabled(bool enabled)
        {
            btnDefaults.Enabled = btnAll.Enabled = btnNone.Enabled = btnEdit.Enabled = enabled;
            tree.Enabled = enabled;
            runBtn.Text = enabled ? "OPTİMİZE ET" : "DURDUR";
            runBtn.BackColor = enabled ? Theme.Accent : Theme.Error;
        }

        void AskCancel()
        {
            if (MessageBox.Show(this, "Çalışan modül yarıda kesilecek. Durdurulsun mu?", "PC Hızlandırıcı", MessageBoxButtons.YesNo, MessageBoxIcon.Warning) == DialogResult.Yes)
                cancel = true;
        }

        void OnClosingForm(object sender, FormClosingEventArgs e)
        {
            if (!running) return;
            if (MessageBox.Show(this, "Optimizasyon devam ediyor. Kapatırsanız çalışan modül yarıda kalır. Yine de kapatılsın mı?", "PC Hızlandırıcı", MessageBoxButtons.YesNo, MessageBoxIcon.Warning) != DialogResult.Yes)
                e.Cancel = true;
            else
                cancel = true;
        }

        public static bool IsAdmin()
        {
            return new WindowsPrincipal(WindowsIdentity.GetCurrent()).IsInRole(WindowsBuiltInRole.Administrator);
        }
    }

    // ------------------------------------------------------------------
    //  Giris noktasi
    // ------------------------------------------------------------------
    static class Program
    {
        [STAThread]
        static int Main(string[] args)
        {
            var a = new HashSet<string>(args.Select(x => x.ToLowerInvariant()));

            // /list <dosya> : modul listesini dosyaya yazar (yonetici gerekmez)
            int li = Array.FindIndex(args, x => x.Equals("/list", StringComparison.OrdinalIgnoreCase));
            if (li >= 0)
            {
                var sb = new StringBuilder();
                foreach (var m in Modules.Load())
                    sb.AppendLine(m.FileName + " | " + m.Category + " | " + (m.Default ? "varsayilan" : "istege bagli") + " | " + m.Name);
                sb.AppendLine("lib bytes: " + Modules.Lib.Length);
                var target = li + 1 < args.Length ? args[li + 1] : Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "modules.txt");
                File.WriteAllText(target, sb.ToString(), new UTF8Encoding(true));
                return 0;
            }

            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            // /screenshot <dosya> : arayuzun goruntusunu kaydeder (README icin)
            int si = Array.FindIndex(args, x => x.Equals("/screenshot", StringComparison.OrdinalIgnoreCase));
            if (si >= 0 && si + 1 < args.Length)
            {
                var form = new MainForm(false, false) { StartPosition = FormStartPosition.Manual, Location = new Point(-4000, -4000), ShowInTaskbar = false };
                var timer = new System.Windows.Forms.Timer { Interval = 1200 };
                timer.Tick += (s, e) =>
                {
                    timer.Stop();
                    using (var bmp = new Bitmap(form.Width, form.Height))
                    {
                        form.DrawToBitmap(bmp, new Rectangle(0, 0, form.Width, form.Height));
                        bmp.Save(args[si + 1], System.Drawing.Imaging.ImageFormat.Png);
                    }
                    form.Close();
                };
                form.Shown += (s, e) => timer.Start();
                Application.Run(form);
                return 0;
            }

            if (!MainForm.IsAdmin() && !a.Contains("/noadmin"))
            {
                try
                {
                    Process.Start(new ProcessStartInfo
                    {
                        FileName = Application.ExecutablePath,
                        Arguments = string.Join(" ", args.Select(x => "\"" + x + "\"")),
                        Verb = "runas",
                        UseShellExecute = true
                    });
                }
                catch (Win32Exception)
                {
                    MessageBox.Show("PC Hızlandırıcı yönetici izni olmadan sistem ayarlarını değiştiremez.", "PC Hızlandırıcı", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                }
                return 0;
            }

            Application.Run(new MainForm(a.Contains("/auto"), a.Contains("/reboot")));
            return 0;
        }
    }
}
