# 获取用户输入的最外层目录和系统版本文件夹名称
$driverBasePath = Read-Host "请输入 VirtIO 驱动的最外层目录（例如 C:\Users\wilinz\Downloads\virtio\virtio-win-0.1.248）"
$systemVersion = Read-Host "请输入系统版本文件夹名称（例如 w11\amd64）"

# 定义路径变量
$installWimFile = ".\install.wim"
$bootWimFile = ".\boot.wim"
$mountDir = ".\mnt1"

# 获取指定目录中的所有驱动路径
function Get-DriverPaths {
    param (
        [string]$basePath,
        [string]$systemVersion
    )
    $driverPaths = @()
    $folders = Get-ChildItem -Path $basePath -Directory
    foreach ($folder in $folders) {
        $infPath = "$($folder.FullName)\$systemVersion"
        if (Test-Path $infPath) {
            $infFiles = Get-ChildItem -Path $infPath -Filter *.inf -File
            foreach ($infFile in $infFiles) {
                $driverPaths += $infFile.FullName
            }
        }
    }
    return $driverPaths
}

# 获取 WIM 映像信息
function Get-WimInfo {
    param (
        [string]$wimFile
    )
    $info = dism /get-wiminfo /wimfile:$wimFile
    return $info
}

# 挂载 WIM 映像
function Mount-Wim {
    param (
        [string]$wimFile,
        [int]$index,
        [string]$mountDir
    )
    dism /mount-wim /wimfile:$wimFile /index:$index /mountdir:$mountDir
}

# 添加驱动
function Add-Drivers {
    param (
        [string]$mountDir,
        [array]$drivers
    )
    foreach ($driver in $drivers) {
        dism /image:$mountDir /add-driver /driver:$driver /forceunsigned
    }
}

# 卸载并保存 WIM 映像
function Unmount-Wim {
    param (
        [string]$mountDir
    )
    dism /unmount-wim /mountdir:$mountDir /commit
}

# 主程序
try {
    # 获取所有驱动路径
    $drivers = Get-DriverPaths -basePath $driverBasePath -systemVersion $systemVersion

    # 创建挂载目录
    if (-Not (Test-Path -Path $mountDir)) {
        New-Item -Path $mountDir -ItemType Directory
    }

    # 处理 install.wim
    $installWimInfo = Get-WimInfo -wimFile $installWimFile

    # 调试信息
    Write-Output "Install.wim Info:"
    Write-Output $installWimInfo

    # 提取索引信息并处理每个索引
    $indexes = @()
    foreach ($line in $installWimInfo) {
        if ($line -match "索引: (\d+)") {
            $indexes += [int]$matches[1]
        }
    }

    foreach ($index in $indexes) {
        Write-Output "Processing install.wim index $index"
        Mount-Wim -wimFile $installWimFile -index $index -mountDir $mountDir
        Add-Drivers -mountDir $mountDir -drivers $drivers
        Unmount-Wim -mountDir $mountDir
    }

    # 处理 boot.wim
    $bootWimInfo = Get-WimInfo -wimFile $bootWimFile

    # 调试信息
    Write-Output "Boot.wim Info:"
    Write-Output $bootWimInfo

    # 提取索引信息并处理每个索引
    $indexes = @()
    foreach ($line in $bootWimInfo) {
        if ($line -match "索引: (\d+)") {
            $indexes += [int]$matches[1]
        }
    }

    foreach ($index in $indexes) {
        Write-Output "Processing boot.wim index $index"
        Mount-Wim -wimFile $bootWimFile -index $index -mountDir $mountDir
        Add-Drivers -mountDir $mountDir -drivers $drivers
        Unmount-Wim -mountDir $mountDir
    }

    Write-Output "All drivers have been added successfully."
}
catch {
    Write-Error $_.Exception.Message
}
finally {
    # 清理挂载目录
    if (Test-Path -Path $mountDir) {
        Remove-Item -Path $mountDir -Recurse -Force
    }
}
