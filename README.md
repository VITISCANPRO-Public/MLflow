---
title: Mlflow37
emoji: 🚀
colorFrom: green
colorTo: pink
sdk: docker
pinned: false
license: apache-2.0
short_description: Vitiscan MLflow tracking server (PostgreSQL + S3)
---

# MLflow Server — Vitiscan

Centralized MLflow tracking server for the Vitiscan MLOps project. Deployed on HuggingFace Spaces as a Docker container. Stores run metadata in PostgreSQL (Neon) and model artifacts in AWS S3.

## Role in the Vitiscan architecture

```
Model-CNN  ──────────────────────────────────────────────────────────┐
  logs metrics, params, model.pth                                    │
                                                                     ▼
Airflow ────────────────────────────────────────► MLflow Server (this repo)
  queries metrics to compare models                  │  PostgreSQL (Neon)
  decides whether to deploy                          │  → run metadata
                                                     │  AWS S3
Diagnostic API  ─────────────────────────────────────┘  → model artifacts (.pth)
  downloads model.pth from S3 via MLflow
```

Every component in the Vitiscan project interacts with this server:
- **Model-CNN** logs every training run (parameters, metrics, `model.pth`)
- **Airflow** queries run metrics to compare the new model against the production model
- **Diagnostic API** downloads the best `model.pth` artifact from S3 via MLflow

## Why PostgreSQL + S3 instead of local MLflow ?

The default MLflow setup stores everything locally (SQLite + local filesystem). This works on a single machine but breaks in a distributed MLOps architecture because:

- **Local files are not shared** — Airflow running on one machine cannot access MLflow data stored on another
- **SQLite does not support concurrent writes** — multiple training runs cannot log simultaneously
- **Local storage is ephemeral** — files are lost when the container restarts

The production-grade solution is the **two-store pattern**:

| Store | Technology | What it holds |
|---|---|---|
| **Backend store** | PostgreSQL (Neon) | Run metadata: parameters, metrics, tags, status |
| **Artifact store** | AWS S3 | Large binary files: `model.pth`, evaluation plots |

PostgreSQL handles concurrent reads/writes from any machine. S3 provides durable, accessible artifact storage. Both are persistent across container restarts.

## File structure

```
mlflow-server/
├── Dockerfile              # Container image (python:3.11-slim, non-root user)
├── entrypoint.sh           # Startup script — optional AWS check + mlflow server
├── requirements.txt        # Minimal dependencies (mlflow, psycopg2, boto3, s3fs)
├── .env.template           # Required environment variables (copy to .env locally)
├── .gitattributes          # Git LFS configuration for binary ML files
├── .gitignore              # Python, secrets, IDE, OS artifacts
├── README.md               # This file
└── .github/
    └── workflows/
        └── deploy.yml      # CD pipeline — auto-deploy to HuggingFace Spaces on push
```

## Environment variables

Copy `.env.template` to `.env` and fill in the values before running locally.

| Variable | Description |
|---|---|
| `MLFLOW_BACKEND_STORE_URI` | PostgreSQL connection string |
| `AWS_ACCESS_KEY_ID` | AWS IAM key with S3 read/write access |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM secret |
| `AWS_DEFAULT_REGION` | AWS region (e.g. `eu-west-3`) |
| `AWS_REGION` | Same region — used by some AWS services |
| `S3_BUCKET_NAME` | S3 bucket name |
| `MLFLOW_ARTIFACT_ROOT` | S3 path for artifacts (e.g. `s3://bucket/mlflow-artifacts`) |
| `PORT` | Server port — must be `7860` on HuggingFace Spaces |
| `MLFLOW_ALLOWED_HOSTS` | Allowed hostnames — use `*` for public deployment |
| `AWS_CHECK`| Set to `yes` to verify AWS credentials on startup |
| `MLFLOW_CORS_ORIGINS` | Allowed CORS origins (comma-separated) — use `*` for public access |`https://mouniat-vitiscanpro-diagno-api.hf.space,https://mouniat-vitiscan-streamlit.hf.space`


> **Note:** `MLFLOW_URI` is not a server variable. It is the public URL that other repositories use to connect to this server after deployment. See [Connecting other repositories](#connecting-other-repositories).

## Deploy to HuggingFace Spaces

### Required GitHub secrets and variables

In the repository settings (`Settings → Secrets and variables → Actions`):

| Type | Name | Value |
|---|---|---|
| Secret | `HF_TOKEN` | Your HuggingFace write token |
| Variable | `HF_USERNAME` | Your HuggingFace username |
| Variable | `HF_SPACE_NAME` | The Space name (e.g. `VITISCANPRO_MLFLOW`) |

### Required HuggingFace Spaces secrets

In the Space settings (`Settings → Variables and secrets`), add all variables from `.env.template` with their real values.

### Deployment

Every push to `main` automatically triggers the deploy workflow, which pushes the code to HuggingFace Spaces. HuggingFace then builds the Docker image and starts the server.

To trigger a manual deployment without pushing code:
```
GitHub → Actions → Deploy to HuggingFace Spaces → Run workflow
```

## Run locally

```bash
# 1. Copy and fill in the environment file
cp .env.template .env

# 2. Build the Docker image
docker build -t vitiscan-mlflow .

# 3. Start the server
docker run --rm -p 7860:7860 --env-file .env vitiscan-mlflow

# 4. Open the MLflow UI
open http://localhost:7860
```

## Connecting other repositories

Once deployed, the server is accessible at `https://your-space-id.hf.space`. Other repositories connect to it by setting the following environment variable:

```bash
MLFLOW_TRACKING_URI="https://your-space-id.hf.space"
```

Repositories that connect to this server:

| Repository | How it connects |
|---|---|
| **Model-CNN** | Logs training runs via `mlflow.set_tracking_uri()` |
| **Airflow** | Queries run metrics via the MLflow REST API to compare models |
| **Diagnostic API** | Downloads `model.pth` artifacts via `mlflow.artifacts.download_artifacts()` |

## CI/CD pipeline

```
push to main
     │
     ▼
.github/workflows/deploy.yml
     │
     └── Push code to HuggingFace Spaces
              │
              ▼
         HuggingFace builds Docker image
              │
              ▼
         Container starts → entrypoint.sh → mlflow server
```

There are no tests in this repository — it contains no business logic to test. The Dockerfile `HEALTHCHECK` validates at runtime that the server is responding correctly on `/health`.

## Requirements

- Python 3.11
- Docker
- PostgreSQL database (Neon recommended)
- AWS S3 bucket with read/write IAM permissions
- HuggingFace account with a Docker Space

## Author

**Mounia Tonazzini** — Agronomist Engineer & Data Scientist and Data Engineer

- HuggingFace: [huggingface.co/MouniaT](https://huggingface.co/MouniaT)
- LinkedIn: [linkedin.com/in/mounia-tonazzini](https://www.linkedin.com/in/mounia-tonazzini)
- GitHub: [github/Mounia-Agronomist-Datascientist](https://github.com/Mounia-Agronomist-Datascientist)
- Email : mounia.tonazzini@gmail.com