FROM python:3.11-slim

# Met à jour les paquets système Debian (corrige les CVE déjà patchées en amont)
RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*

# Définir le répertoire de travail dans le conteneur
WORKDIR /app

# Étape 1 : copier UNIQUEMENT le fichier de dépendances
# Cette couche sera mise en cache tant que requirements.txt ne change pas
COPY requirements.txt .

# Met à jour les outils de build pip/setuptools/wheel
# (corrige les CVE Python sur wheel et jaraco.context tirées par setuptools)
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# Étape 2 : installer les dépendances applicatives (couche mise en cache)
RUN pip install --no-cache-dir -r requirements.txt

# Étape 3 : copier le code source (invalidé à chaque modification du code)
COPY src/ ./src/
COPY tests/ ./tests/

# Documenter le port utilisé par l'application
EXPOSE 8000

# Commande de démarrage du serveur Uvicorn
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]