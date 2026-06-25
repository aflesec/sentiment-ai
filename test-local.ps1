# test-local.ps1
# Valide l'infra Terraform en local AVANT de pousser dans le pipeline.
# A lancer depuis la racine du repo. Necessite terraform installe + Docker Desktop demarre.

$ErrorActionPreference = "Stop"

function Check($label) {
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ECHEC] $label" -ForegroundColor Red
        exit 1
    }
    Write-Host "[OK] $label`n" -ForegroundColor Green
}

Write-Host "=== Test local Terraform ===`n" -ForegroundColor Cyan

terraform -chdir=infra fmt -check
Check "Formatage (fmt)"

terraform -chdir=infra init -backend=false -input=false
Check "Init sans backend"

terraform -chdir=infra validate
Check "Validation syntaxe"

terraform -chdir=infra init -upgrade -input=false
Check "Init complet (providers)"

terraform -chdir=infra plan -var="image_tag=test"
Check "Plan (apercu, ne cree rien)"

Write-Host "=== Tout est vert. Infra prete a etre poussee. ===" -ForegroundColor Green