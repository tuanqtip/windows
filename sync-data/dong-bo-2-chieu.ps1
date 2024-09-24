# Đặt mã hóa đầu ra
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Xóa History Event
Get-EventSubscriber | Unregister-Event

# Đường dẫn thư mục nguồn và đích
$source = Get-Content -Path ".\source.txt"
$destination = Get-Content -Path ".\destination.txt"

# Kiểm tra thư mục nguồn và đích có tồn tại không
if (-Not (Test-Path $source)) {
    Write-Host "Thư mục nguồn không tồn tại: $source"
    exit
}

if (-Not (Test-Path $destination)) {
    Write-Host "Thư mục đích không tồn tại: $destination"
    exit
} else {
    Write-Host "Thư mục đích tồn tại: $destination"
}

# Thiết lập FileSystemWatcher
$watcherSource = New-Object System.IO.FileSystemWatcher
$watcherSource.Path = $source
$watcherSource.IncludeSubdirectories = $true
$watcherSource.EnableRaisingEvents = $true

$watcherDestination = New-Object System.IO.FileSystemWatcher
$watcherDestination.Path = $destination
$watcherDestination.IncludeSubdirectories = $true
$watcherDestination.EnableRaisingEvents = $true

# Cờ để kiểm soát đồng bộ
$syncInProgress = $false

# Hàm đồng bộ
function Sync-Folders {
    if ($syncInProgress) {
        return
    }

    $syncInProgress = $true
    Write-Host "Có thay đổi trong thư mục. Tiến hành đồng bộ..."
    
    # Đồng bộ từ nguồn đến đích
    Robocopy $source $destination /MIR /Z /R:5 /W:5

    # Đồng bộ từ đích về nguồn
    Start-Sleep -Seconds 2
    Robocopy $destination $source /MIR /Z /R:5 /W:5

    $syncInProgress = $false
}

# Đăng ký sự kiện
Register-ObjectEvent $watcherSource "Changed" -Action { Sync-Folders }
Register-ObjectEvent $watcherSource "Created" -Action { Sync-Folders }
Register-ObjectEvent $watcherSource "Deleted" -Action { Sync-Folders }
Register-ObjectEvent $watcherSource "Renamed" -Action { Sync-Folders }

Register-ObjectEvent $watcherDestination "Changed" -Action { Sync-Folders }
Register-ObjectEvent $watcherDestination "Created" -Action { Sync-Folders }
Register-ObjectEvent $watcherDestination "Deleted" -Action { Sync-Folders }
Register-ObjectEvent $watcherDestination "Renamed" -Action { Sync-Folders }

# Để script chạy liên tục
while ($true) {
    Start-Sleep -Seconds 1
}
