FROM python:3.11-slim

LABEL description="MLflow 3.7.0 Server with S3 and PostgreSQL (Neon) support"

# Variables d'environnement
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Installer les dépendances système nécessaires
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Créer un utilisateur non-root pour la sécurité
RUN useradd -m -u 1000 user

# Basculer vers l'utilisateur non-root
USER user
ENV HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH

# Définir le répertoire de travail
WORKDIR $HOME/app

# Copier le fichier requirements
COPY --chown=user Dockerfile entrypoint.sh requirements.txt ./

# Installer les dépendances Python
RUN pip install --upgrade pip && \
    pip install -r requirements.txt

# Exposer le port MLflow (7860 pour déploiement HFace)
EXPOSE 7860

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

# Use entrypoint instead of CMD
ENTRYPOINT ["bash", "entrypoint.sh"]