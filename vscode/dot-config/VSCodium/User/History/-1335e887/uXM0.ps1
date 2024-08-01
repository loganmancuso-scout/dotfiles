New-Item -Path ~\SourceControl -ItemType Directory
New-Item -Path ~\SourceControl\Snippets -ItemType Directory

Set-Service -Name ssh-agent -StartupType Automatic
Start-Service -Name ssh-agent
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
choco install git

git clone git@gitlab.com:snippets/2462579.git SourceControl\Snippets\chocolatey-packages
git clone git@gitlab.com:snippets/2351345.git $env:POSH_THEMES_PATH\personal