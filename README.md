# AutoDeploy-IIS-DotNet

## 簡介
本專案提供了一個自動化的 PowerShell 腳本，適用於將 .NET 應用程式發佈到 IIS 網站。腳本實現了以下功能：
- 自動從指定 Git 分支拉取最新代碼。
- 停止並重啟指定的 IIS 網站。
- 清理並重建發佈目錄。
- 使用指定配置（Release 或 Debug）發佈 .NET 應用程式。
- 生成日誌以記錄部署過程。

## 參數
腳本包含以下參數，執行時可以指定：

- **`$websiteName`** (string): 指定網站名稱（IIS 中的站台名稱）。
- **`$publishFolder`** (string): 發佈文件夾的路徑，將應用程式發佈輸出到該文件夾。
- **`$projectPath`** (string): 指定 .NET 專案文件（`.csproj` 文件）的完整路徑。
- **`$repositoryPath`** (string): Git 存儲庫的根目錄路徑。
- **`$branch`** (string, 預設值: `"main"`): 要拉取的 Git 分支名稱。
- **`$configuration`** (string, 預設值: `"Release"`): 指定發佈的配置（例如 Release 或 Debug）。

## 使用說明
### 1. 準備  
   請確保您的環境符合以下要求：
   - 安裝了 .NET SDK 以及 Git。
   - IIS 中配置了相應的站點，並且 PowerShell 可以以管理員身份運行。
   - 執行前已確保正確配置 IIS 站點名稱、Git 存儲庫路徑等必要信息。
### 2. 執行腳本： 
   請確保使用 PowerShell 以管理員身份運行以下命令，根據需求指定參數：
   ```powershell
   .\CICD.ps1 -websiteName "yourwebsiteName" -publishFolder "yourpublishFolder" -projectPath "yourproject.csproj" -repositoryPath "yourrepositoryPath" -branch "yourbranch" -configuration "Release"
   ```
   - `-websiteName`：設定要部署的 IIS 網站名稱。
   - `-publishFolder`：指定發佈文件夾的路徑。
   - `-projectPath`：指定 .NET 專案文件的路徑。
   - `-repositoryPath`：指定 Git 存儲庫的根目錄。
   - `-branch`：指定要拉取的分支。
   - `-configuration`：指定發佈配置。
### 3. 注意事項： 
   - 請確保腳本執行環境符合 .NET SDK 和 Git 的要求。
   - IIS 網站的名稱、Git 存儲庫路徑、發佈目錄等參數必須正確配置。
   - 確保腳本以管理員身份運行，以避免權限問題。
