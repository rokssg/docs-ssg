# Déclaration des variables d'installation
$nodeUrl = "https://nodejs.org/dist/v20.11.1/node-v20.11.1-x64.msi"
$installerPath = "$env:TEMP\node-lts.msi"

# Write-Host “Hello World!”

# Téléchargement de Node.js
Write-Host "Téléchargement de Node.js LTS depuis $nodeUrl..."
Invoke-WebRequest -Uri $nodeUrl -OutFile $installerPath

# Installation de Node.js
Write-Host "Installation de Node.js (npm inclus)..."
Start-Process msiexec.exe -Wait -ArgumentList @("/i", $installerPath, "/qn", "/norestart")

# Nettoyage de l'installateur
Remove-Item $installerPath -Force

# Vérification des installations
Write-Host "Vérification des installations..."
$nodeVersion = node -v
$npmVersion = npm -v
Write-Host "✔️ Node.js installé : $nodeVersion"
Write-Host "✔️ npm installé : $npmVersion"