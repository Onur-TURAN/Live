# Yazılımların adlarını bir dizi içinde tanımlayın
$uygulamalar = @(
    "wgtet",
    "AngusJohnson.ResourceHacker",
    "Microsoft.Sysinternals.ProcessExplorer",
    "Microsoft.Sysinternals.ProcessMonitor"
)
# Her yazılımı indirme döngüsü
foreach ($uygulama in $uygulamalar) {
    Write-Host "----------------------------------------"
    Write-Host "İndirilen uygulama: $uygulama"
    # Yazılımı `winget` ile indirme komutunu çalıştır
    $indirmeSonucu = Invoke-Expression "winget install $uygulama"
    # İndirme sonucunu kontrol et
    if ($indirmeSonucu -match "Başarıyla yüklendi") {
        Write-Host "$uygulama başarıyla indirildi ve yüklendi."
    } else {
        Write-Host "Hata oluştu: $indirmeSonucu"
    }
}
Write-Host "----------------------------------------"
Write-Host "İndirme işlemi tamamlandı."
