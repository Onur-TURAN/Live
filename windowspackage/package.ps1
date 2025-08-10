
$applist = @(
    "Docker.DockerDesktop",
    "Git.Git",
    "Logitech.LogiBolt",
    "Logitech.Options",
    "Microsoft.VSTOR",
    "Microsoft.OneDrive",
    "RARLab.Winrar",
    "Neovim.Neovim",
    "Microsoft.VCRedist.2010.x64",
    "OpenVPNTechnologies.OpenVPNConnect",
    "WireGuard.WireGuard",
    "Logitech.OptionsPlus",
    "DEVCOM.Lua",
    "GoLang.Go",
    "WiresharkFoundation.Wireshark",
    "OpenJS.NodeJS",
    "PuTTY.PuTTY",
    "Orwell.Dev-C++",
    "Huawei.HiSuite",
    "Microsoft.Edge",
    "Insecure.Nmap",
    "JetBrains.PyCharm.Community",
    "Microsoft.DotNet.SDK.9",
    "Microsoft.VCRedist.2008.x86",
    "Microsoft.VCRedist.2013.x86",
    "DG0JBJ.HDSDR",
    "Microsoft.VCRedist.2010.x86",
    "Microsoft.VCRedist.2015+.x64",
    "Microsoft.VCRedist.2015+.x86",
    "PortSwigger.BurpSuite.Community",
    "Anaconda.Anaconda3",
    "Postman.Postman",
    "RaspberyPiFoundation.RaspberryPiImager",
    "Rustlang.Rustup",
    "UniversalCtags.Ctags",
    "Zoom.Zoom.EXE",
    "SlackTechnologies.Slack",
    "Microsoft.VisualStudioCode",
    "Microsoft.Teams",
    "Microsoft.UI.Xaml.2.7",
    "Microsoft.UI.Xaml.2.8",
    "Microsoft.VCLibs.Desktop.14",
    "Microsoft.DevHome",
    "Microsoft.WindowsTerminal",
    "Microsoft.WSL",

)

foreach ($app in $applist) {
    Write-Host "----------------------------------------"
    Write-Host "İndirilen uygulama: $app"

    $process = Start-Process -FilePath "winget" -ArgumentList "install $app" -NoNewWindow -Wait -PassThru

    if ($process.ExitCode -eq 0) {
        Write-Host "$app başarıyla indirildi ve yüklendi."
    } else {
        Write-Host "Hata oluştu: Çıkış kodu $($process.ExitCode)"
    }
}
Write-Host "----------------------------------------"
Write-Host "İndirme işlemi tamamlandı."
