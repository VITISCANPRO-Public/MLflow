FROM python:3.11-slim

LABEL description="MLflow 3.7.0 Server with S3 artifact store and PostgreSQL (Neon) backend"

# Disable output buffering, .pyc generation and pip cache for a cleaner image
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system dependencies
# - curl : required by the HEALTHCHECK
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user for security
RUN useradd -m -u 1000 user

# Switch to non-root user
USER user
ENV HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH

# Set working directory
WORKDIR $HOME/app

# Copy application files
COPY --chown=user entrypoint.sh requirements.txt ./

# Install Python dependencies
RUN pip install --upgrade pip && \
    pip install -r requirements.txt

# Expose MLflow port (7860 for HuggingFace Spaces)
EXPOSE 7860

# Health check — verifies the server is running and accepting connections
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:7860/health || exit 1

ENTRYPOINT ["bash", "entrypoint.sh"]