Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Starting machine setup..." -ForegroundColor Green
Write-Host "========================================"

# ================================
# LOG FUNCTION
# ================================
function Log-Step($message) {
    Write-Host "[STEP] $message" -ForegroundColor Yellow
}

function Log-Info($message) {
    Write-Host "[INFO] $message" -ForegroundColor Cyan
}

function Log-Success($message) {
    Write-Host "[SUCCESS] $message" -ForegroundColor Green
}

function Log-Error($message) {
    Write-Host "[ERROR] $message" -ForegroundColor Red
}

# ================================
# 1. Install Chocolatey
# ================================
Log-Step "Checking Chocolatey..."

if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Log-Info "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
} else {
    Log-Success "Chocolatey already installed"
}

choco upgrade chocolatey -y

# ================================
# 2. Install packages
# ================================
Log-Step "Installing packages via Chocolatey..."

choco install -y `
    epicgameslauncher `
    vscode `
    docker-cli `
    git `
    claude-code `
    discord `
    powertoys `
    firacode `
    jetbrainsmono `
    uplay `
    obsidian `
    postman

Log-Info "Refreshing environment variables..."
refreshenv

# ================================
# 3. Ensure Git is available
# ================================
Log-Step "Validating Git installation..."

$gitPath = "C:\Program Files\Git\bin\git.exe"

$attempt = 0
while (!(Get-Command git -ErrorAction SilentlyContinue) -and !(Test-Path $gitPath)) {
    if ($attempt -ge 10) {
        Log-Error "Git not found after multiple attempts"
        exit 1
    }

    Log-Info "Waiting for Git to be available... attempt $attempt"
    Start-Sleep -Seconds 2
    refreshenv
    $attempt++
}

# fallback para path direto
if (!(Get-Command git -ErrorAction SilentlyContinue) -and (Test-Path $gitPath)) {
    Log-Info "Using Git from direct path"
    $git = $gitPath
} else {
    $git = "git"
}

Log-Success "Git is ready"

# ================================
# 4. Configure Git
# ================================
Log-Step "Configuring Git..."

& $git config --global user.name "Anderson Andrade"
& $git config --global user.email "anderson_andrade_@outlook.com"

& $git config --global alias.cm "commit -m"
& $git config --global alias.po "push origin"
& $git config --global alias.pom "push origin main"
& $git config --global alias.ch "checkout"
& $git config --global alias.chm "checkout master"
& $git config --global alias.chd "checkout develop"
& $git config --global alias.cha "checkout dev_anderson"
& $git config --global alias.del "branch -D"
& $git config --global alias.rollback "reset --hard"
& $git config --global alias.chb "checkout -b"
& $git config --global alias.s "status -sb"
& $git config --global alias.ad "add ."
& $git config --global alias.upgrade "!git fetch --all && git remote update origin --prune"
& $git config --global alias.upstream "remote add upstream"
& $git config --global alias.sv "remote -v"
& $git config --global alias.fat "fetch --all"
& $git config --global alias.c "commit -m"

& $git config --global alias.l "!git log --graph --abbrev-commit --decorate=no --date=format:'%Y-%m-%d %H:%M:%S' --format=format:'%C(03)%>|(15)%h%C(reset)  %C(04)%ad%C(reset)  %C(green)%<(25,trunc)%an%C(reset)  %C(bold 1)%d%C(reset) %C(bold 0)%>|(1)%s%C(reset)' -n 10"

& $git config --global alias.b "!git branch -r --sort=-committerdate --format='%(color:magenta)%(authorname)%(color:reset)|%(HEAD)%(color:yellow)%(refname:short)|%(color:bold green)%(committerdate:relative)|%(color:blue)%(subject)|' --color=always | column -ts '|'"

Log-Success "Git configured successfully"

# ================================
# 5. Install WSL
# ================================
Log-Step "Installing WSL..."

wsl --install -d Ubuntu-24.04

Log-Success "WSL installation triggered (may require restart)"

# ================================
# FINAL
# ================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setup completed successfully!" -ForegroundColor Green
Write-Host "========================================"