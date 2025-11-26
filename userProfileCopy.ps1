$ErrorActionPreference = 'Stop'

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole("Administrators")) { 
  Write-Error "管理者でPowershellを再起動して、再度実行してください。`r`nなお、再度以下コマンドを実行する必要があります。`r`n  Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned"
}

Set-Variable -Name regExportPath -Value C:\copyUserProfile
Set-Variable -Name templateUserProfile -Value C:\Users\利用者テンプレート

[string[][]]$regEnrtyDatas = @()

[string[]]$tmpArray = @()
$tmpArray += "def\Software\Microsoft\SystemCertificates"
$tmpArray += "SystemCertificates"
$regEnrtyDatas += ,@($tmpArray)

[string[]]$tmpArray = @()
$tmpArray += "def\Software\Microsoft\Windows\CurrentVersion\DeviceAccess"
$tmpArray += "DeviceAccess"
$regEnrtyDatas += ,@($tmpArray)

[string[]]$tmpArray = @()
$tmpArray += "def\Software\Microsoft\Windows\Roaming\OpenWith"
$tmpArray += "OpenWith"
$regEnrtyDatas += ,@($tmpArray)

[string[]]$tmpArray = @()
$tmpArray += "def\Software\Microsoft\Windows\Shell\Associations"
$tmpArray += "Associations"
$regEnrtyDatas += ,@($tmpArray)

[string[]]$tmpArray = @()
$tmpArray += "def\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts"
$tmpArray += "FileExts"
$regEnrtyDatas += ,@($tmpArray)

[string[]]$tmpArray = @()
$tmpArray += "def\Software\Microsoft\Active Setup\Installed Components\{89820200-ECBD-11cf-8B85-00AA005B4340}"
$tmpArray += "{89820200-ECBD-11cf-8B85-00AA005B4340}"
$regEnrtyDatas += ,@($tmpArray)

Write-Host "テンプレートユーザプロファイルフォルダの確認..."
if (! (Test-Path -Path $templateUserProfile) ) {
  Write-Error "テンプレートユーザプロファイルが見つかりません。"
}

if ( Test-Path("C:\Users\Default") ) {
  if( Test-Path("C:\Users\Default.bk") ) {
    Write-Error "すでにWindows Defaultのユーザプロファイルが退避されています。フォルダの状態を確認して再実行してください。"
  } else {
    Rename-Item -Path "C:\Users\Default" -NewName "Default.bk"
  }
} else {
  Write-Error "Windows Defaultユーザのプロファイルが見つかりません。フォルダの状態を確認して再実行してください。"
}

Write-Host "ユーザープロファイル基本ファイルのコピー..."
Copy-Item -Recurse $templateUserProfile "C:\Users\Default" -ErrorAction SilentlyContinue
Write-Host "ユーザープロファイル基本ファイルのコピーが完了しました。"

# Write-Debug "レジストリバックアップのフォルダ作成"
# if (! (Test-Path -Path $regExportPath) ) {
#   New-Item -ItemType Direory -Path $regExportPath
# }

Write-Host "テンプレートユーザレジストリハイブの展開..."
$processId = Start-Process -FilePath "reg.exe" -ArgumentList "load HKU\def C:\Users\Default\NTUSER.DAT" -PassThru
reg.exe load HKU\def C:\Users\Default\NTUSER.DAT

# Write-Debug "レジストリバックアップ"
# foreach( $item in $regEnrtyDatas ) {
#   [String]$command = "reg.exe export HKU\" + $item[0] + " " + $regExportPath + "\"+ $item[1] + ".reg /y"
#   try {
#     Invoke-Expression $command
#   } catch {
#     Write-Debug $_.Exception
#   }
# }

Write-Host "レジストリ削除..."
# New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS
foreach( $item in $regEnrtyDatas ) {
  [String]$regPath = "HKU:" + $item[0] + "*"

  try {
    # Write-Debug "Remove-Item -Path $($regPath) -Recurse"
    Remove-Item -Path $regPath -Recurse
  } catch {
    Write-Debug "Remove-Item -Path $($regPath) -Recurse\r\n$($_.Exception.Message)"
  }
}

try {
  Stop-Process -Id $processId
} catch {
  Write-Debug $_.Exception
}

Write-Host "レジストリハイブセーブ..."
reg.exe unload HKU\def

Read-Host "処理が完了しました。終了するにはEnterキーを押してください..."