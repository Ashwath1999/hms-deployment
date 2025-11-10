#  Deployment Configuration Repository

This repository contains deployment-related code changes for **Docker** and **Kubernetes** environments.

---

## Docker Setup

This section includes configuration files to containerize and run services locally.

### Files

- `docker-compose.yml` — orchestrates multi-container setup.  
- `.env` — contains environment variables for local builds.

### Commands

```bash
# Build the Docker image
docker build -t <service-name>:latest .

# Run using Docker Compose
docker-compose up --build

# Stop all containers
docker-compose down
