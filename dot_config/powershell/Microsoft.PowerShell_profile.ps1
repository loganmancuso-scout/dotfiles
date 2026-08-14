# Author: Logan Mancuso | LastEdit: 2025-09-15

using namespace System.Management.Automation
using namespace System.Management.Automation.Language

### --- Prompt --- ###
function Invoke-Starship-TransientFunction { &starship module character }
Invoke-Expression (&starship init powershell)
Enable-TransientPrompt

### --- Prompt --- ###

### --- Environment Parameters --- ###

$env:KUBE_CONFIG_PATH = "$env:USERPROFILE\.kube\config"
$PSStyle.FileInfo.Directory = "" # disable directory highlighting in ls
$LazyLoadProfileRunspace = [RunspaceFactory]::CreateRunspace()
$LazyLoadProfile = [PowerShell]::Create()
$LazyLoadProfile.Runspace = $LazyLoadProfileRunspace
$LazyLoadProfileRunspace.Open()
[void]$LazyLoadProfile.AddScript({
  Set-PSReadLineOption -PredictionSource History
  Set-PSReadLineOption -PredictionViewStyle ListView
  Set-PSReadLineOption -EditMode Windows
  
  Import-Module -Name Terminal-Icons
  Import-Module posh-git -Scope Local
}) # (1)
[void]$LazyLoadProfile.BeginInvoke()
$null = Register-ObjectEvent -InputObject $LazyLoadProfile -EventName InvocationStateChanged -Action {
  Set-PSReadLineOption -PredictionSource History
  Set-PSReadLineOption -PredictionViewStyle ListView
  Set-PSReadLineOption -EditMode Windows 

  Import-Module -Name Terminal-Icons
  Import-Module posh-git -Scope Local 

  $global:GitPromptSettings.DefaultPromptPrefix.Text = 'PS '
  $global:GitPromptSettings.DefaultPromptBeforeSuffix.Text = '`n'
  $LazyLoadProfile.Dispose()
  $LazyLoadProfileRunspace.Close()
  $LazyLoadProfileRunspace.Dispose()
}

### --- Environment Parameters --- ###

### --- Aliases --- ###
function touch() {New-Item -f $args[0]}
function xopen() {explorer.exe $args[0]}

### Terraform ###
function tf() { terraform $args }
function tfi() { terraform init --reconfigure --upgrade && terraform workspace list }
function tfc() { 
  Get-ChildItem -Recurse | Where-Object { $_.Attributes -match 'ReparsePoint' } | 
  ForEach-Object { 
    Write-Output "Removing symbolic link: $($_.FullName)"
    Remove-Item $_.FullName 
  }
}
function tffmt() { terraform fmt -recursive }

# Terraform env for pulling modules from s3 using sso credentials
$env:AWS_SDK_LOAD_CONFIG=$true

### --- Shortcuts --- ###
function lc() {
  Get-ChildItem -Path . | Select-Object -Property Name
}

function delete() {
  $args | ForEach-Object { Get-Item $_; Remove-Item $_ -Recurse -Force }
}

function watch() {
  while($true) { Invoke-Expression ($args -join " "); Start-Sleep -Seconds 15; Clear-Host }
}

function idle {
  $wshell = New-Object -ComObject wscript.shell;
  "Press CTRL+C to cancel."
  while ($true) {
    $wshell.Sendkeys('+')
    Start-Sleep -Seconds 60
  }
}

function stopwatch {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    while ($true) {
        $elapsedTime = $stopwatch.Elapsed.ToString("hh\:mm\:ss\.fff")
        Write-Host -NoNewline "`r$elapsedTime"
        Start-Sleep -Milliseconds 100
    }
}

### --- Functions --- ###
function update() {
  Import-Module PSWindowsUpdate
  Start-Job -ScriptBlock {
    try {
      if (([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent() `
        ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Output "Updating Chocolatey Packages"
        Start-Job -ScriptBlock { choco upgrade all -Y } | Receive-Job -Wait
        Write-Output "Updating Winget Packages"
        Start-Job -ScriptBlock { winget upgrade -h --all } | Receive-Job -Wait
        Write-Output "Updating Windows Packages"
        Start-Job -ScriptBlock { Import-Module PSWindowsUpdate; Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot } | Receive-Job -Wait
      } else {
        Write-Error "Run PWSH as Admin to use this command"
        return
      }
    } catch {
      Write-Error $_.Exception
    }
  } | Receive-Job -Wait
}

### --- Autocomplete --- ###
Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
    param($wordToComplete, $commandAst,$cursorPosition)
        [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()
        $Local:word = $wordToComplete.Replace('"', '""')
        $Local:ast = $commandAst.ToString().Replace('"', '""')
        winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}

# AWS CLI Autocomplete
Register-ArgumentCompleter -Native -CommandName aws -ScriptBlock {
    param($commandName, $wordToComplete, $cursorPosition)
        $env:COMP_LINE=$wordToComplete
        $env:COMP_POINT=$cursorPosition
        aws_completer.exe | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
        Remove-Item Env:\COMP_LINE     
        Remove-Item Env:\COMP_POINT  
}
