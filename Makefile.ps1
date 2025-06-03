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

function Install-Nodejs{
    $npmVersion = npm -v
    if (Get-Command node -ErrorAction SilentlyContinue) {
        Write-Host "Node.js est déjà installé: $npmVersion"
    } else {
        Write-Host "Node.js n'est pas installé. Début de l'installation..."
        Install-NodeJS -url $nodeUrl -outputPath $installerPath
    }
}

function Install-Yarn{
    if (Get-Command yarn -ErrorAction SilentlyContinue) {
        Write-Host "Yarn est déjà installé : $(yarn --version)"
    } elseif (Get-Command npm -ErrorAction SilentlyContinue) {
        Write-Host "Yarn n'est pas installé. Installation via npm..."
        npm install -g yarn
        if (Get-Command yarn -ErrorAction SilentlyContinue) {
            Write-Host "Yarn installé : $(yarn --version)"
        } else {
            Write-Host "Échec de l'installation de Yarn."
            exit 1
        }
    } else {
        Write-Host "npm n'est pas disponible pour installer Yarn."
        exit 1
    }
}

function Install-Frontend {
    param (
        [string]$path = "$PSScriptRoot/$yarnDependenciesPath"  # Valeur par défaut
    )

    if (-not (Test-Path $path)) {
        Write-Host "Le dossier '$path' n'existe pas."
        exit 1
    }

    Write-Host "Déplacement dans le dossier frontend : $path"
    Set-Location $path

    if (Get-Command yarn -ErrorAction SilentlyContinue) {
        Write-Host "Installation des dépendances avec Yarn..."
        yarn
    } else {
        Write-Host "Yarn n'est pas installé. Exécutez d'abord Install-Yarn."
        exit 1
    }

    # Revenir au dossier initial si tu veux
    Set-Location -Path $PSScriptRoot
}

function Run-Frontend {
    param (
        [string]$frontendPath = "$PSScriptRoot/$yarnDependenciesPath",
        [string]$composeCommand = "docker-compose"
    )

    # 1. Arrêt du conteneur frontend
    Write-Host "Arrêt du conteneur Docker frontend..."
    & $composeCommand stop frontend

    # 2. Vérifie si le dossier frontend existe
    if (-not (Test-Path $frontendPath)) {
        Write-Host "Le dossier frontend '$frontendPath' est introuvable."
        exit 1
    }

    # 3. Lance `yarn dev` dans ce dossier
    Write-Host "Lancement du frontend en mode développement..."
    Push-Location $frontendPath
    if (Get-Command yarn -ErrorAction SilentlyContinue) {
        yarn dev
    } else {
        Write-Host "Yarn n'est pas installé. Exécutez Install-Yarn d'abord."
        Pop-Location
        exit 1
    }
    Pop-Location
}

function Frontend-Development-Install {
    Install-Nodejs
    Install-Yarn
    Install-Frontend
}

function Run-Frontend-Development {
    docker compose stop frontend
    Push-Location ./src/frontend/apps/impress
    yarn dev
    Pop-Location
}
function Help {
    Write-Host "Commandes disponibles :"
    Write-Host "  bootstrap                   : Prépare le projet (build, install, migrate, demo, etc.)"
    Write-Host "  run                         : Démarre tous les services (backend + frontend)"
    Write-Host "  run-backend                 : Démarre uniquement le backend"
    Write-Host "  deploy-frontend-local       : Installe les dépendances frontend et lance le frontend en mode développement"
    Write-Host "  frontend-development-install: Installe les dépendances frontend"
    Write-Host "  run-frontend-development    : Lance le frontend en mode développement"
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
    "deploy-frontend-local" { Frontend-Development-Install; Run-Frontend-Development }
    "frontend-development-install"{ Frontend-Development-Install }
    "run-frontend-development"    { Run-Frontend-Development }
    "demo"                        { Demo }
    "superuser"                   { Superuser }
    "resetdb"                     { ResetDb }
    "help"                        { Help }
    default                       { Write-Host "Commande inconnue. Utilisez 'help'."; Help; exit 1 }
}

# ...existing code...

# Déclaration des variables d'installation
$nodeUrl = "https://nodejs.org/dist/v20.11.1/node-v20.11.1-x64.msi"
$installerPath = "$env:TEMP\node-lts.msi"
$yarnDependenciesPath = "./src/frontend/apps/impress"

function Install-NodeJS {
    param (
        [string]$url,
        [string]$outputPath
    )
    # Vérification de la validité de l'URL
    if (-not $url) {
        Write-Host "L'URL de téléchargement de Node.js est invalide."
        exit 1
    }
    # Téléchargement de l'installateur
    Write-Host "Téléchargement de Node.js LTS depuis $url..."
    Invoke-WebRequest -Uri $url -OutFile $outputPath
    if (-not (Test-Path $outputPath)) {
        Write-Host "L'installateur de Node.js n'a pas été téléchargé correctement."
        exit 1
    }
    # Installation de Node.js
    Write-Host "Installation de Node.js..."
    Start-Process msiexec.exe -Wait -ArgumentList @("/i", $outputPath, "/qn", "/norestart")
    # Nettoyage de l'installateur
    Write-Host "Nettoyage de l'installateur..."
    Remove-Item $outputPath -Force
    # Vérification de l'installation
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



# Fin du script Makefile.ps1