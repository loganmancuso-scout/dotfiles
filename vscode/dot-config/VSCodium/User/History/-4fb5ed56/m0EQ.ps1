using namespace System.Management.Automation
using namespace System.Management.Automation.Language

<#
.SYNOPSIS
  Script to Initialize my custom powershell profile.
.DESCRIPTION
  Confiugure custom function, Starship Prompt+Theme and aliases
.NOTES
  Author: Logan Mancuso
  Date: 07/25/2024
#>

### --- Prompt --- ###
$env:STARSHIP_CONFIG = "$([Environment]::GetFolderPath("MyDocuments"))\PowerShell\work.toml"
if ( Test-Path $env:POSH_THEMES_PATH ) { Invoke-Expression (&starship init powershell) }
### --- Prompt --- ###

### --- Environment Parameters --- ###
Import-Module -Name Terminal-Icons
Import-Module PSWindowsUpdate
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows
### --- Environment Parameters --- ###

### --- Aliases --- ###
Set-Alias -Name python -Value py
Set-Alias -Name python3 -Value py
function touch() {New-Item -f $args[0]}
function xopen() {explorer.exe $args[0]}
# Terraform
function tf() { terraform $args }
function tfa() { terraform apply }
function tfr() { terraform apply -refresh-only }
function tfp() { terraform plan $args }
function tfs() { terraform state $args }
function tfw() { terraform workspace $args }
function tfi() { terraform init --reconfigure --upgrade && terraform workspace list }
function tfc() { 
  Get-ChildItem -Recurse | Where-Object { $_.Attributes -match 'ReparsePoint' } | 
  ForEach-Object { 
    Write-Output "Removing symbolic link: $($_.FullName)"
    Remove-Item $_.FullName 
  }
}
function tffmt() { terraform fmt -recursive }

### --- Hexagon --- ###
function hex-connect { py $env:USERPROFILE\SourceControl\Hexagon\EnterpriseAssetManagement\eam-terraform\scripts\ssmconnect.py }
function hex-link() { py $env:USERPROFILE\SourceControl\Hexagon\EnterpriseAssetManagement\eam-terraform\scripts\makeSymLink.py $args }
function hex-download { py $env:USERPROFILE\SourceControl\Hexagon\EnterpriseAssetManagement\artifact-repository\Scripts\download_artifact.py $args}
function hex-deploy { py $env:USERPROFILE\SourceControl\Hexagon\EnterpriseAssetManagement\artifact-repository\Scripts\deploy_artifact.py $args}
function hex-sso() { py $env:USERPROFILE\SourceControl\Hexagon\MANCUSOLogan\hex-sso\hex-sso.py $args}
function hex-decrypt() { py $env:USERPROFILE\SourceControl\Hexagon\EnterpriseAssetManagement\eam-terraform\scripts\kmsed.py }

### --- Shortcuts --- ###
function delete() {
  $args | ForEach-Object { Get-Item $_; Remove-Item $_ -Recurse -Force }
}

function watch() {
  while(1) { $args; sleep 5 }
}

function idle {
  $wshell = New-Object -ComObject wscript.shell;
  "Press CTRL+C to cancel."
  while ($true) {
    $wshell.Sendkeys('+')
    Start-Sleep -Seconds 60
  }
}

### --- Shortcuts --- ###

### --- Functions --- ###
function Update-Packages() {
  Start-Job -ScriptBlock {
    try {
      if (([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent() `
        ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Output "Updating Chocolatey Packages"
        choco upgrade all -Y
        Write-Output "Updating Winget Packages"
        winget upgrade -h --all
        Write-Output "Updating Windows Packages"
        Start-Job -ScriptBlock { Import-Module PSWindowsUpdate } | Receive-Job -Wait
      } else {
        Write-Error "Run PWSH as Admin to use this command"
        return
      }
    } catch {
      Write-Error $_.Exception
    }
  } | Receive-Job -Wait
}
### --- Functions --- ###

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
### --- Autocomplete --- ###