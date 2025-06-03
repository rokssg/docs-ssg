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


Install-Nodejs
Install-Yarn
Install-Frontend

Run-Frontend
# rajouter un stop