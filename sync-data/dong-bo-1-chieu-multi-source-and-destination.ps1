# Đặt mã hóa đầu ra
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Xóa History Event
Get-EventSubscriber | Unregister-Event

# Đọc các đường dẫn thư mục nguồn và đích từ file
$sources = @(
    "\\192.168.21.13\QTIP\HRA\3. IT\test1",
    "\\192.168.21.13\QTIP\HRA\3. IT\test2"
)

$destinations = @(
    "D:\OneDrive\OneDrive - CÔNG TY TNHH LIÊN DOANH PHÁT TRIỂN QUẢNG TRỊ\USB\test1",
    "D:\OneDrive\OneDrive - CÔNG TY TNHH LIÊN DOANH PHÁT TRIỂN QUẢNG TRỊ\USB\test2"
)

# Kiểm tra số lượng thư mục nguồn và đích
if ($sources.Count -ne $destinations.Count) {
    Write-Host "Số lượng thư mục nguồn và đích không khớp!"
    exit
}

# Kiểm tra thư mục nguồn và đích có tồn tại
for ($i = 0; $i -lt $sources.Count; $i++) {
    if (-Not (Test-Path $sources[$i])) {
        Write-Host "Thư mục nguồn không tồn tại: $($sources[$i])"
        exit
    }
    if (-Not (Test-Path $destinations[$i])) {
        Write-Host "Thư mục đích không tồn tại: $($destinations[$i])"
        exit
    }
}

# Thiết lập các biến tạm
$watchers = @()
$syncInProgress = @()
for ($i = 0; $i -lt $sources.Count; $i++) {
    $syncInProgress += $false

    # Thiết lập FileSystemWatcher để theo dõi thư mục nguồn
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $sources[$i]
    $watcher.IncludeSubdirectories = $true
    $watcher.EnableRaisingEvents = $true
    $watchers += $watcher
}

# Hàm đồng bộ cho thư mục
function Sync-Folders {
    param(
        [int]$index
    )
    if ($syncInProgress[$index]) {
        return
    }

    $syncInProgress[$index] = $true
    Write-Host "Có thay đổi trong thư mục nguồn: $($sources[$index]). Tiến hành đồng bộ..."

    # Đồng bộ từ nguồn đến đích (chỉ 1 chiều)
    Robocopy $sources[$index] $destinations[$index] /MIR /Z /R:5 /W:5

    $syncInProgress[$index] = $false
}

for ($i = 0; $i -lt $sources.Count; $i++) {
    #Đăng ký sự kiện cho thư mục nguồn
    Register-ObjectEvent $watchers[$i] "Changed" -Action { 
        $index = $Event.MessageData.This
        Sync-Folders $index 
    }-MessageData @{This = $i }
    Register-ObjectEvent $watchers[$i] "Created" -Action { 
        $index = $Event.MessageData.This
        Sync-Folders $index 
    }-MessageData @{This = $i }
    Register-ObjectEvent $watchers[$i] "Deleted" -Action { 
        $index = $Event.MessageData.This
        Sync-Folders $index 
    }-MessageData @{This = $i }
    Register-ObjectEvent $watchers[$i] "Renamed" -Action { 
        $index = $Event.MessageData.This
        Sync-Folders $index 
    }-MessageData @{This = $i }
}

# Để script chạy liên tục
while ($true) {
    # Đảm bảo rằng PowerShell có thời gian xử lý các sự kiện
    Start-Sleep -Seconds 1
}
