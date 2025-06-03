# /!\ /!\ /!\ /!\ /!\ /!\ /!\ DISCLAIMER /!\ /!\ /!\ /!\ /!\ /!\ /!\ /!\
#
# This Makefile is only meant to be used for DEVELOPMENT purpose as we are
# changing the user id that will run in the container.
#
# PLEASE DO NOT USE IT FOR YOUR CI/PRODUCTION/WHATEVER...
#
# /!\ /!\ /!\ /!\ /!\ /!\ /!\ /!\ /!\ /!\ /!\ /!\ /!\ /!\ /!\ /!\ /!\ /!\
#
# Note to developers:
#
# While editing this file, please respect the following statements:
#
# 1. Every variable should be defined in the ad hoc VARIABLES section with a
#    relevant subsection
# 2. Every new rule should be defined in the ad hoc RULES section with a
#    relevant subsection depending on the targeted service
# 3. Rules should be sorted alphabetically within their section
# 4. When a rule has multiple dependencies, you should:
#    - duplicate the rule name to add the help string (if required)
#    - write one dependency per line to increase readability and diffs
# 5. .PHONY rule statement should be written after the corresponding rule
# ==============================================================================
# VARIABLES

# ==============================================================================

<#
    .SYNOPSIS
    Script PowerShell pour gérer les tâches de développement d'un projet Docker avec Django et Node.js.

    .DESCRIPTION
    Ce script permet de configurer l'environnement de développement, de gérer les migrations de base de données,
    de créer des données de démonstration, de compiler les fichiers de traduction, d'installer et de construire les mails,
    et de lancer les services backend et frontend via Docker Compose.

    .PARAMETER bootstrap
    Prépare le projet (build, install, migrate, demo, etc.).

    .PARAMETER run
    Démarre tous les services (backend + frontend) via Docker Compose.

    .PARAMETER run-backend
    Démarre uniquement les services backend (Celery, fournisseur Y, Nginx) via Docker Compose.

    .PARAMETER frontend-development-install
    Installe les dépendances frontend localement (yarn install dans le dossier approprié).

    .PARAMETER run-frontend-development
    Lance le frontend en mode développement local (yarn dev dans le dossier approprié, stoppe le conteneur frontend Docker).

    .PARAMETER demo
    Réinitialise la base de données et crée des données de démonstration via Django.

    .PARAMETER superuser
    Crée un superutilisateur Django avec les identifiants par défaut (admin@example.com / admin).

    .PARAMETER resetdb
    Réinitialise la base de données et crée un superutilisateur Django.

    .PARAMETER help
    Affiche la liste des commandes disponibles.
#>

# $BOLD := \033[1m
# $RESET := \033[0m
# $GREEN := \033[1;32m

# -- Database
# $DB_HOST            = postgresql
# $DB_PORT            = 5432

# # -- Docker
# # Get the current user ID to use for docker run and docker exec commands
# $DOCKER_UID          = $(shell id -u)
# $DOCKER_GID          = $(shell id -g)
# $DOCKER_USER         = $(DOCKER_UID):$(DOCKER_GID)
# $COMPOSE             = DOCKER_USER=$(DOCKER_USER) docker compose
# $COMPOSE_EXEC        = $(COMPOSE) exec
# $COMPOSE_EXEC_APP    = $(COMPOSE_EXEC) app-dev
# $COMPOSE_RUN         = $(COMPOSE) run --rm
# $COMPOSE_RUN_APP     = $(COMPOSE_RUN) app-dev
# $COMPOSE_RUN_CROWDIN = $(COMPOSE_RUN) crowdin crowdin

# # -- Backend
# $MANAGE              = $(COMPOSE_RUN_APP) python manage.py
# $MAIL_YARN           = $(COMPOSE_RUN) -w /app/src/mail node yarn

# # -- Frontend
# $PATH_FRONT          = ./src/frontend
# $PATH_FRONT_IMPRESS  = $(PATH_FRONT)/apps/impress

# ==============================================================================
# RULES

# Makefile.ps1 - Script PowerShell pour gérer les tâches de développement

# TODO traiter le problème des entrypoint (retours à la ligne Windows vs Linux)
function Bootstrap {
    Data-Media
    Data-Static
    Create-Env-Files
    Build
    Migrate
    Demo
    Back-I18n-Compile
    Mails-Install
    Mails-Build
    Run
}

function Data-Media {
    if (-not (Test-Path "data/media")) { New-Item -ItemType Directory -Path "data/media" | Out-Null }
}
function Data-Static {
    if (-not (Test-Path "data/static")) { New-Item -ItemType Directory -Path "data/static" | Out-Null }
}

function Build {
    docker compose build app-dev --no-cache
    docker compose build y-provider --no-cache
    docker compose build frontend --no-cache
}
function Build-Backend {
    docker compose build app-dev
}
function Build-Frontend {
    docker compose build frontend
}
function Build-Yjs-Provider {
    docker compose build y-provider
}
function Build-K8s-Cluster {
    ./bin/start-kind.sh
}
function Bump-Packages-Version {
    param([string]$versionType = "minor")
    Push-Location ./src/mail
    yarn version --no-git-tag-version --$versionType
    Pop-Location
    Push-Location ./src/frontend
    yarn version --no-git-tag-version --$versionType
    Pop-Location
    Push-Location ./src/frontend/apps/e2e
    yarn version --no-git-tag-version --$versionType
    Pop-Location
    Push-Location ./src/frontend/apps/impress
    yarn version --no-git-tag-version --$versionType
    Pop-Location
    Push-Location ./src/frontend/servers/y-provider
    yarn version --no-git-tag-version --$versionType
    Pop-Location
    Push-Location ./src/frontend/packages/eslint-config-impress
    yarn version --no-git-tag-version --$versionType
    Pop-Location
    Push-Location ./src/frontend/packages/i18n
    yarn version --no-git-tag-version --$versionType
    Pop-Location
}
function Clean {
    git clean -idx
}
function Create-Env-Files {
    Copy-Item -ErrorAction SilentlyContinue -Force env.d/development/common.dist env.d/development/common
    Copy-Item -ErrorAction SilentlyContinue -Force env.d/development/postgresql.dist env.d/development/postgresql
    Copy-Item -ErrorAction SilentlyContinue -Force env.d/development/kc_postgresql.dist env.d/development/kc_postgresql
    Copy-Item -ErrorAction SilentlyContinue -Force env.d/development/crowdin.dist env.d/development/crowdin
}
function Crowdin-Download {
    docker compose run --rm crowdin crowdin download -c crowdin/config.yml
}
function Crowdin-Download-Sources {
    docker compose run --rm crowdin crowdin download sources -c crowdin/config.yml
}
function Crowdin-Upload {
    docker compose run --rm crowdin crowdin upload sources -c crowdin/config.yml
}
function Data-Media {
    if (-not (Test-Path "data/media")) { New-Item -ItemType Directory -Path "data/media" | Out-Null }
}
function Data-Static {
    if (-not (Test-Path "data/static")) { New-Item -ItemType Directory -Path "data/static" | Out-Null }
}
function Dbshell {
    docker compose exec app-dev python manage.py dbshell
}
function Down {
    docker compose down
}
function Env-Development-Common {
    if (-not (Test-Path "env.d/development/common")) {
        Copy-Item env.d/development/common.dist env.d/development/common
    }
}
function Env-Development-Postgresql {
    if (-not (Test-Path "env.d/development/postgresql")) {
        Copy-Item env.d/development/postgresql.dist env.d/development/postgresql
    }
}
function Env-Development-Kc-Postgresql {
    if (-not (Test-Path "env.d/development/kc_postgresql")) {
        Copy-Item env.d/development/kc_postgresql.dist env.d/development/kc_postgresql
    }
}
function Env-Development-Crowdin {
    if (-not (Test-Path "env.d/development/crowdin")) {
        Copy-Item env.d/development/crowdin.dist env.d/development/crowdin
    }
}
function Frontend-I18n-Compile {
    Push-Location ./src/frontend
    yarn i18n:deploy
    Pop-Location
}
function Frontend-I18n-Extract {
    Push-Location ./src/frontend
    yarn i18n:extract
    Pop-Location
}
function Frontend-I18n-Generate {
    Crowdin-Download-Sources
    Frontend-I18n-Extract
}
function Help {
    Write-Host "`nAvailable commands :"
    foreach ($cmd in $commands) {
        Write-Host ("  {0,-30} : {1}" -f $cmd.key, $cmd.desc)
    }
    Write-Host ""
}
function I18n-Compile {
    Back-I18n-Compile
    Frontend-I18n-Compile
}
function I18n-Download-And-Compile {
    Crowdin-Download
    I18n-Compile
}
function I18n-Generate {
    Back-I18n-Generate
    Frontend-I18n-Generate
}
function I18n-Generate-And-Upload {
    I18n-Generate
    Crowdin-Upload
}
function Logs {
    docker compose logs -f app-dev
}
function Mails-Build-Html-To-Plain-Text {
    docker compose run --rm -w /app/src/mail node yarn build-html-to-plain-text
}
function Mails-Build-Mjml-To-Html {
    docker compose run --rm -w /app/src/mail node yarn build-mjml-to-html
}
function Makemigrations {
    docker compose up -d postgresql
    docker compose run --rm app-dev python manage.py makemigrations
}
function Shell {
    docker compose exec app-dev python manage.py shell
}
function Status {
    docker compose ps
}
function Stop {
    docker compose stop
}
function Test {
    Test-Back-Parallel
}
function Test-Back {
    ./bin/pytest
}
function Test-Back-Parallel {
    ./bin/pytest -n auto
}

function Build {
    docker compose build app-dev --no-cache
    docker compose build y-provider --no-cache
    docker compose build frontend --no-cache
}
function Migrate {
    docker compose up -d postgresql
    docker compose run --rm app-dev python manage.py migrate
}
function Demo {
    ResetDb
    docker compose run --rm app-dev python manage.py create_demo
}
function Back-I18n-Compile {
    docker compose run --rm app-dev python manage.py compilemessages --ignore="venv/**/*"
}
function Mails-Install {
    docker compose run --rm -w /app/src/mail node yarn install
}
function Mails-Build {
    docker compose run --rm -w /app/src/mail node yarn build
}
function Run {
    Run-Backend
    docker compose up --force-recreate -d frontend
}
function Run-Backend {
    docker compose up --force-recreate -d celery-dev
    docker compose up --force-recreate -d y-provider
    docker compose up --force-recreate -d nginx
}
function Superuser {
    docker compose run --rm app-dev python manage.py createsuperuser --email admin@example.com --password admin
}
function ResetDb {
    docker compose run --rm app-dev python manage.py flush --no-input
    Superuser
}
$nodeUrl = "https://nodejs.org/dist/v20.11.1/node-v20.11.1-x64.msi"
$installerPath = "$env:TEMP\node-lts.msi"
$yarnDependenciesPath = "./src/frontend/apps/impress"

function Install-NodeJS {
    param (
        [string]$url,
        [string]$outputPath
    )
    if (-not $url) {
        Write-Host "Node.js url is not valid."
        exit 1
    }
    Write-Host "Downloading Node.js from $url..."
    Invoke-WebRequest -Uri $url -OutFile $outputPath
    if (-not (Test-Path $outputPath)) {
        Write-Host "Node.js installer not found at $outputPath."
        exit 1
    }
    Write-Host "Installing Node.js..."
    Start-Process msiexec.exe -Wait -ArgumentList @("/i", $outputPath, "/qn", "/norestart", "/l*v!", "$env:TEMP\node-install.log")
    # Clean up the installer file
    Remove-Item $outputPath -Force
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
    $nodeVersion = node -v
    $npmVersion = npm -v
    if ($nodeVersion) {
        Write-Host "Node.js installed : $nodeVersion"
    } else {
        Write-Host "Node.js not installed."
        exit 1
    }
    if ($npmVersion) {
        Write-Host "npm installed : $npmVersion"
    } else {
        Write-Host "npm not installed."
        exit 1
    }
}
function Frontend-Development-Install {
    # Si node déjà installé et npm disponible, on ne fait rien
    if (Get-Command node -ErrorAction SilentlyContinue) {
        Write-Host "Node.js already installed."
        $nodeVersion = node -v
        if ($nodeVersion) {
            Write-Host "Node.js version : $nodeVersion"
        }
        $npmVersion = npm -v
        if ($npmVersion) {
            Write-Host "npm is already installed : $npmVersion"
        } else {
            Install-NodeJS $nodeUrl $installerPath
        }
    }
    else {
        Install-NodeJS $nodeUrl $installerPath
    }
}

function Install-Frontend {
    param (
        [string]$path = "$PSScriptRoot/$yarnDependenciesPath"
    )

    if (-not (Test-Path $path)) {
        Write-Host "'$path' doesn't exist."
        exit 1
    }

    Write-Host "Moving to Frontend folder : $path"
    Set-Location $path

    if (Get-Command yarn -ErrorAction SilentlyContinue) {
        Write-Host "Installing dependances with Yarn..."
        yarn
    } else {
        Write-Host "Yarn is not installed. First run Install-Yarn."
        exit 1
    }

    Set-Location -Path $PSScriptRoot
}

function Run-Frontend {
    param (
        [string]$frontendPath = "$PSScriptRoot/$yarnDependenciesPath",
        [string]$composeCommand = "docker-compose"
    )

    # 1. Arrêt du conteneur frontend
    Write-Host "Stopping Frontend Docker container..."
    & $composeCommand stop frontend

    # 2. Vérifie si le dossier frontend existe
    if (-not (Test-Path $frontendPath)) {
        Write-Host "The Frontend folder '$frontendPath' is not found."
        exit 1
    }

    # 3. Lance `yarn dev` dans ce dossier
    Write-Host "Launching the Frontend in development mode..."
    Push-Location $frontendPath
    if (Get-Command yarn -ErrorAction SilentlyContinue) {
        yarn dev
    } else {
        Write-Host "Yarn is not installed. Run Install-Yarn first."
        Pop-Location
        exit 1
    }
    Push-Location ./src/frontend/apps/impress
    yarn
    Pop-Location
}
function Run-Frontend-Development {
    $initialLocation = Get-Location
    try {
        docker compose stop frontend
        Set-Location ./src/frontend/apps/impress
        yarn dev
    }
    finally {
        Set-Location $initialLocation
    }
}
function Deploy-Frontend-Local {
    Frontend-Development-Install
    Run-Frontend-Development
}
# === HashMap of commands ===
$commands = @(
    @{ key = "bootstrap"; desc = "Setup the project (build, install, migrate, demo, etc.)"; action = { Bootstrap } }
    @{ key = "run"; desc = "Start all the services (backend + frontend)"; action = { Run } }
    @{ key = "run-backend"; desc = "Start the backend services"; action = { Run-Backend } }
    @{ key = "frontend-development-deploy"; desc = "Install and Launch Frontend"; action = { Frontend-Development-Install ; Run-Frontend-Development } }
    @{ key = "frontend-development-install"; desc = "Install Frontend dependencies (Node, Yarn, etc.)"; action = { Frontend-Development-Install } }
    @{ key = "run-frontend-development"; desc = "Launch the frontend in development mode (yarn dev)"; action = { Run-Frontend-Development } }
    @{ key = "deploy-frontend-local"; desc = "Install frontend dependencies and launch in development mode"; action = { Frontend-Development-Install; Run-Frontend-Development } }
    @{ key = "demo"; desc = "Reset the database and create demo data"; action = { Demo } }
    @{ key = "superuser"; desc = "Create a Django superuser"; action = { Superuser } }
    @{ key = "resetdb"; desc = "Reset the database"; action = { ResetDb } }
    @{ key = "help"; desc = "Display this help message"; action = { Help } }
)

function Help {
    Write-Host "`nAvailable commands :"
    foreach ($cmd in $commands) {
        Write-Host ("  {0,-30} : {1}" -f $cmd.key, $cmd.desc)
    }
    Write-Host ""
}

function Show-Interactive-Menu {
    Clear-Host
    Write-Host "=========== INTERACTIVE MENU ==========="
    for ($i = 0; $i -lt $commands.Count; $i++) {
        Write-Host "$($i+1). $($commands[$i].key) : $($commands[$i].desc)"
    }
    Write-Host "0. Leave"
    Write-Host "======================================="
}

function Stop-Frontend {
    Write-Host "Stopping Frontend container..."
    docker compose stop frontend
}

# === Menu interactif si aucune commande ===
if ($args.Count -eq 0) {
    do {
        Show-Interactive-Menu
        $choice = Read-Host "Enter a command number (or 0 to exit)"

        if ($choice -eq "0") {
            Write-Host "End of the script."
            break
        }

        $index = [int]$choice - 1
        if ($index -ge 0 -and $index -lt $commands.Count) {
            $commands[$index].action.Invoke()
        } else {
            Write-Host "Invalid choice. Please retry."
        }

        Write-Host ""
        Pause

    } while ($true)

    exit 0
}

# === Exécution d'une commande par argument ===
$matchedCommand = $commands | Where-Object { $_.key -eq $args[0] }
if ($null -ne $matchedCommand) {
    & $matchedCommand.action.Invoke()
} else {
    Write-Host "Unknown command. Use 'help'."
    Help
    exit 1
}


# End of Makefile.ps1 script