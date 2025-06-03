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
function Create-Env-Files {
    Copy-Item -ErrorAction SilentlyContinue -Force env.d/development/common.dist env.d/development/common
    Copy-Item -ErrorAction SilentlyContinue -Force env.d/development/postgresql.dist env.d/development/postgresql
    Copy-Item -ErrorAction SilentlyContinue -Force env.d/development/kc_postgresql.dist env.d/development/kc_postgresql
    Copy-Item -ErrorAction SilentlyContinue -Force env.d/development/crowdin.dist env.d/development/crowdin
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
        Write-Host "L'URL de téléchargement de Node.js est invalide."
        exit 1
    }
    Write-Host "Téléchargement de Node.js LTS depuis $url..."
    Invoke-WebRequest -Uri $url -OutFile $outputPath
    if (-not (Test-Path $outputPath)) {
        Write-Host "L'installateur de Node.js n'a pas été téléchargé correctement."
        exit 1
    }
    Write-Host "Installation de Node.js..."
    Start-Process msiexec.exe -Wait -ArgumentList @("/i", $outputPath, "/qn", "/norestart")
    Write-Host "Nettoyage de l'installateur..."
    Remove-Item $outputPath -Force
    $nodeVersion = node -v
    $npmVersion = npm -v
    if ($nodeVersion) {
        Write-Host "Node.js installé : $nodeVersion"
    } else {
        Write-Host "Échec de l'installation de Node.js."
        exit 1
    }
    if ($npmVersion) {
        Write-Host "npm installé : $npmVersion"
    } else {
        Write-Host "Échec de l'installation de npm."
        exit 1
    }
}
function Frontend-Development-Install {
    # Si node déjà installé et npm disponible, on ne fait rien
    if (Get-Command node -ErrorAction SilentlyContinue) {
        Write-Host "Node.js est déjà installé."
        $npmVersion = npm -v
        if ($npmVersion) {
            Write-Host "npm est déjà installé : $npmVersion"
        } else {
            Write-Host "npm n'est pas installé, installation de Node.js..."
            Install-NodeJS $nodeUrl $installerPath
        }
    }
    Push-Location ./src/frontend/apps/impress
    yarn
    Pop-Location
}
function Run-Frontend-Development {
    docker compose stop frontend
    Push-Location ./src/frontend/apps/impress
    yarn dev
    Pop-Location
}
function Deploy-Frontend-Local {
    Frontend-Development-Install
    Run-Frontend-Development
}
function Help {
    Write-Host "Commandes disponibles :"
    Write-Host "  bootstrap                   : Prépare le projet (build, install, migrate, demo, etc.)"
    Write-Host "  run                         : Démarre tous les services (backend + frontend)"
    Write-Host "  run-backend                 : Démarre uniquement le backend"
    Write-Host "  frontend-development-install: Installe les dépendances frontend"
    Write-Host "  run-frontend-development    : Lance le frontend en mode développement"
    Write-Host "  deploy-frontend-local       : Installe les dépendances frontend et lance le frontend en mode développement"
    Write-Host "  demo                        : Remplit la base avec des données de démo"
    Write-Host "  superuser                   : Crée un superuser Django"
    Write-Host "  resetdb                     : Réinitialise la base et crée un superuser"
    Write-Host "  help                        : Affiche cette aide"
}

# --- Dispatcher principal ---
if ($args.Count -eq 0) {
    Help
    exit 0
}

switch ($args[0]) {
    "bootstrap"                   { Bootstrap }
    "run"                         { Run }
    "run-backend"                 { Run-Backend }
    "frontend-development-install"{ Frontend-Development-Install }
    "run-frontend-development"    { Run-Frontend-Development }
    "deploy-frontend-local"       { Deploy-Frontend-Local }
    "demo"                        { Demo }
    "superuser"                   { Superuser }
    "resetdb"                     { ResetDb }
    "help"                        { Help }
    default                       { Write-Host "Commande inconnue. Utilisez 'help'."; Help; exit 1 }
}

# Variables d'installation (non utilisées dans les commandes principales mais conservées pour extension)

# Fin du script Makefile.ps1