param (
    [string]$websiteName,
    [string]$publishFolder,
    [string]$projectPath,
    [string]$repositoryPath, 
    [string]$branch = "main",
    [string]$configuration = "Release"
)

$initialDirectory = Get-Location

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as an administrator."
    Read-Host "Press Enter to exit..."
    return
}

$ErrorActionPreference = "Stop"

if (!(Test-Path "C:\Logs")) {
    New-Item -ItemType Directory -Path "C:\Logs"
}
$logFile = "C:\Logs\deploy-$websiteName-$(Get-Date -Format 'yyyyMMddHHmm').log"
Start-Transcript -Path $logFile

Write-Host "pulling：$repositoryPath - $branch"
Set-Location -Path $repositoryPath
git pull origin $branch
if (-not $?) {
    Write-Error "Git pull Fall。"
    Read-Host "press Enter To Continue..."
    return
}

Set-Location -Path $initialDirectory

Import-Module WebAdministration

Write-Host "Stopping website: $websiteName"
Stop-Website -Name $websiteName

Start-Sleep -Seconds 3
if ((Get-Website -Name $websiteName).State -ne "Stopped") {
    Write-Error "Failed to stop the website."
    Read-Host "Press Enter to continue despite the error..."
}

function Reset-PublishFolder {
    param (
        [string]$path,
        [int]$maxRetryTimeInSeconds = 5 
    )

    function DeleteFolderRecursive {
        param (
            [string]$folderPath,
            [datetime]$startTime
        )

        if ((Get-Date) - $startTime -gt [timespan]::FromSeconds($maxRetryTimeInSeconds)) {
            Write-Error "Unable to delete the publish folder: $folderPath. Timeout exceeded 5 seconds. Please check if files are in use."
            return
        }

        if (Test-Path $folderPath) {
            Write-Host "Attempting to delete the publish folder: $folderPath"
            Remove-Item $folderPath -Recurse -Force -ErrorAction SilentlyContinue

            Start-Sleep -Milliseconds 500
            DeleteFolderRecursive -folderPath $folderPath -startTime $startTime
        }
    }

    Write-Host "Starting deletion process for publish folder: $path"
    DeleteFolderRecursive -folderPath $path -startTime (Get-Date)

    if (-not (Test-Path $path)) {
        Write-Host "Recreating the publish folder: $path"
        New-Item -ItemType Directory -Path $path | Out-Null
    }
    else {
        Write-Error "Failed to recreate publish folder: $path. Manual intervention may be required."
        Read-Host "Press Enter to continue..."
    }
}

Reset-PublishFolder -path $publishFolder
Write-Host "Publishing the application..."
dotnet publish "$projectPath" -c $configuration -o "$publishFolder" > $null 2>&1

if (-not $?) {
    Write-Error "Publish failed."
    Read-Host "Press Enter to continue despite the error..."
}

Write-Host "Starting website: $websiteName"
Start-Website -Name $websiteName

Start-Sleep -Seconds 3
if ((Get-Website -Name $websiteName).State -ne "Started") {
    Write-Error "Failed to start the website."
    Read-Host "Press Enter to continue despite the error..."
}

Write-Host "Deployment completed successfully."
Stop-Transcript