param (
    [string]$websiteName,
    [string]$publishFolder,
    [string]$projectPath,
    [string]$repositoryPath, 
    [string]$branch = "main",
    [string]$configuration = "Release"
)

# 保存當前工作目錄
$initialDirectory = Get-Location

# 檢查是否以管理員身份運行
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as an administrator."
    Read-Host "Press Enter to exit..."
    return
}

# 設定錯誤偏好
$ErrorActionPreference = "Stop"

# 設定日誌文件
if (!(Test-Path "C:\Logs")) {
    New-Item -ItemType Directory -Path "C:\Logs"
}
$logFile = "C:\Logs\deploy-$websiteName-$(Get-Date -Format 'yyyyMMddHHmm').log"
Start-Transcript -Path $logFile

# 執行 Git Pull 更新代碼
Write-Host "pulling：$repositoryPath - $branch"
Set-Location -Path $repositoryPath
git pull origin $branch
if (-not $?) {
    Write-Error "Git pull Fall。"
    Read-Host "press Enter To Continue..."
    return
}

# 返回初始工作目錄
Set-Location -Path $initialDirectory

# 匯入 WebAdministration 模組，用於管理 IIS
Import-Module WebAdministration

try {
	# 停止網站
	Write-Host "Stopping website: $websiteName"
	Stop-Website -Name $websiteName

	# 等待並檢查網站是否成功停止
	Start-Sleep -Seconds 3
	if ((Get-Website -Name $websiteName).State -ne "Stopped") {
		Write-Error "Failed to stop the website."
		Read-Host "Press Enter to continue despite the error..."
	}

	# 用於刪除發佈文件夾並設定最大重試時間的函數
	function Reset-PublishFolder {
        param (
            [string]$path,
            [int]$maxRetryTimeInSeconds = 5
        )

        Write-Host "Starting deletion process for publish folder: $path"

        $startTime = Get-Date
        while (Test-Path $path) {
            try {
                Remove-Item $path -Recurse -Force -ErrorAction Stop
            }
            catch {
                Write-Warning "Unable to delete folder: $_"
            }

            if ((Get-Date) - $startTime -gt [TimeSpan]::FromSeconds($maxRetryTimeInSeconds)) {
                Write-Error "Unable to delete the publish folder: $path. Timeout exceeded $maxRetryTimeInSeconds seconds. Please check if files are in use."
                exit
            }

            Start-Sleep -Milliseconds 500
        }

        Write-Host "Recreating the publish folder: $path"
        New-Item -ItemType Directory -Path $path | Out-Null
    }

	# 執行重建發佈目錄並發佈應用程序
	Reset-PublishFolder -path $publishFolder
	Write-Host "Publishing the application..."
	dotnet publish "$projectPath" -c $configuration -o "$publishFolder" > $null 2>&1

	# 檢查發佈是否成功
	if (-not $?) {
		Write-Error "Publish failed."
		Read-Host "Press Enter to continue despite the error..."
	}

	# 啟動網站
	Write-Host "Starting website: $websiteName"
	Start-Website -Name $websiteName

	# 等待並檢查網站是否成功啟動
	Start-Sleep -Seconds 3
	if ((Get-Website -Name $websiteName).State -ne "Started") {
		Write-Error "Failed to start the website."
		Read-Host "Press Enter to continue despite the error..."
	}

	Write-Host "Deployment completed successfully."
}
catch {
    Write-Error "An unexpected error occurred: $_"
    Read-Host "Press Enter to exit..."
}
finally {
    # 停止日誌記錄
    Stop-Transcript
    # 返回初始目錄
    Set-Location -Path $initialDirectory
}
