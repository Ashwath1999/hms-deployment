# Docker Deployment - Hospital Management System

This directory contains Docker and Docker Compose configurations for deploying the complete Hospital Management System locally.

## Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- At least 8GB RAM available
- At least 10GB disk space

## Architecture

The system consists of:
- **7 Microservices**: Patient, Doctor, Appointment, Billing, Prescription, Payment, Notification
- **7 PostgreSQL Databases**: One per service (database-per-service pattern)
- **1 Shared Network**: All services communicate via `hms-network`

## Quick Start

### 1. Build and Start All Services

```bash
# From the deployment/docker directory
docker-compose up -d --build
```

This will:
- Build Docker images for all 7 microservices
- Create 7 PostgreSQL databases
- Start all services with proper dependencies
- Create a shared network for inter-service communication

### 2. Check Service Status

```bash
# View all running containers
docker-compose ps

# View logs from all services
docker-compose logs -f

# View logs from specific service
docker-compose logs -f patient-service
```

### 3. Verify Health

```bash
# Check all services are healthy
curl http://localhost:3001/health  # Patient Service
curl http://localhost:3002/health  # Doctor Service
curl http://localhost:3003/health  # Appointment Service
curl http://localhost:3004/health  # Billing Service
curl http://localhost:3005/health  # Prescription Service
curl http://localhost:3006/health  # Payment Service
curl http://localhost:3007/health  # Notification Service
```

### 4. Access API Documentation

Each service has Swagger UI available:

- Patient Service: http://localhost:3001/api-docs
- Doctor Service: http://localhost:3002/api-docs
- Appointment Service: http://localhost:3003/api-docs
- Billing Service: http://localhost:3004/api-docs
- Prescription Service: http://localhost:3005/api-docs
- Payment Service: http://localhost:3006/api-docs
- Notification Service: http://localhost:3007/api-docs

## Service Ports

| Service | Port | Database Port |
|---------|------|---------------|
| Patient | 3001 | 5432 |
| Doctor | 3002 | 5433 |
| Appointment | 3003 | 5434 |
| Billing | 3004 | 5435 |
| Prescription | 3005 | 5436 |
| Payment | 3006 | 5437 |
| Notification | 3007 | 5438 |

## Loading Seed Data

After services are running, load the seed data:

```bash
# Load patient data
docker exec -it hms-patient-service node src/scripts/loadSeedData.js

# Load doctor data
docker exec -it hms-doctor-service node src/scripts/loadSeedData.js

# Load appointment data
docker exec -it hms-appointment-service node src/scripts/loadSeedData.js

# Load other services...
```

## Common Operations

### Stop All Services
```bash
docker-compose down
```

### Stop and Remove Volumes (Clean Slate)
```bash
docker-compose down -v
```

### Restart Specific Service
```bash
docker-compose restart patient-service
```

### View Service Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f appointment-service

# Last 100 lines
docker-compose logs --tail=100 billing-service
```

### Rebuild After Code Changes
```bash
# Rebuild all services
docker-compose up -d --build

# Rebuild specific service
docker-compose up -d --build patient-service
```

### Execute Commands in Container
```bash
docker exec -it hms-patient-service sh
```

### View Metrics
```bash
# Prometheus metrics for each service
curl http://localhost:3001/metrics
curl http://localhost:3002/metrics
# ... etc
```

## Database Access

Connect to databases using:

```bash
# Patient database
docker exec -it hms-postgres-patient psql -U postgres -d hms_patients

# Doctor database
docker exec -it hms-postgres-doctor psql -U postgres -d hms_doctors

# List all tables
\dt

# View table structure
\d patients

# Query data
SELECT * FROM patients LIMIT 10;
```

## Inter-Service Communication

Services communicate via the `hms-network`:

**Example Flow:**
1. Book Appointment:
   - `appointment-service` → `patient-service` (validate patient)
   - `appointment-service` → `doctor-service` (check availability)
   - `appointment-service` → `notification-service` (send confirmation)

2. Complete Appointment:
   - `appointment-service` → `billing-service` (generate bill)
   - `billing-service` → `notification-service` (bill generated)

3. Process Payment:
   - `payment-service` → `billing-service` (update bill)
   - `payment-service` → `notification-service` (payment received)

## Troubleshooting

### Service Won't Start
```bash
# Check logs
docker-compose logs service-name

# Check if database is ready
docker exec -it hms-postgres-patient pg_isready -U postgres

# Restart service
docker-compose restart service-name
```

### Database Connection Issues
```bash
# Check database is running
docker-compose ps | grep postgres

# Check network
docker network inspect hms-network

# Test connectivity from service to database
docker exec -it hms-patient-service ping postgres-patient
```

### Port Already in Use
```bash
# Find process using port
lsof -i :3001

# Kill process or change port in docker-compose.yml
```

### Clean Everything and Start Fresh
```bash
# Stop everything
docker-compose down -v

# Remove all HMS containers
docker ps -a | grep hms | awk '{print $1}' | xargs docker rm -f

# Remove all HMS images
docker images | grep hms | awk '{print $3}' | xargs docker rmi -f

# Remove volumes
docker volume ls | grep hms | awk '{print $2}' | xargs docker volume rm

# Start fresh
docker-compose up -d --build
```

## Resource Monitoring

```bash
# View resource usage
docker stats

# View specific service
docker stats hms-patient-service
```

## Production Considerations

For production deployment, consider:

1. **Use production-grade PostgreSQL** with proper backup/replication
2. **Add RabbitMQ/Kafka** for async messaging
3. **Add API Gateway** (Nginx, Kong) for routing
4. **Add Service Mesh** (Istio, Linkerd) for advanced networking
5. **Use secrets management** (Vault, AWS Secrets Manager)
6. **Add monitoring** (Prometheus + Grafana stack)
7. **Add log aggregation** (ELK stack)
8. **Use environment-specific configs**
9. **Add backup/restore procedures**
10. **Implement CI/CD pipeline**

## Network Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     hms-network                         │
│                                                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐            │
│  │ Patient  │  │ Doctor   │  │Appointment│            │
│  │ Service  │  │ Service  │  │ Service  │            │
│  │  :3001   │  │  :3002   │  │  :3003   │            │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘            │
│       │             │             │                    │
│  ┌────▼─────┐  ┌───▼──────┐  ┌───▼──────┐            │
│  │PostgreSQL│  │PostgreSQL│  │PostgreSQL│            │
│  │  :5432   │  │  :5433   │  │  :5434   │            │
│  └──────────┘  └──────────┘  └──────────┘            │
│                                                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐            │
│  │ Billing  │  │Prescription│ │ Payment  │            │
│  │ Service  │  │ Service  │  │ Service  │            │
│  │  :3004   │  │  :3005   │  │  :3006   │            │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘            │
│       │             │             │                    │
│  ┌────▼─────┐  ┌───▼──────┐  ┌───▼──────┐            │
│  │PostgreSQL│  │PostgreSQL│  │PostgreSQL│            │
│  │  :5435   │  │  :5436   │  │  :5437   │            │
│  └──────────┘  └──────────┘  └──────────┘            │
│                                                         │
│  ┌──────────┐                                          │
│  │Notification                                         │
│  │ Service  │                                          │
│  │  :3007   │                                          │
│  └────┬─────┘                                          │
│       │                                                 │
│  ┌────▼─────┐                                          │
│  │PostgreSQL│                                          │
│  │  :5438   │                                          │
│  └──────────┘                                          │
└─────────────────────────────────────────────────────────┘
```

## License

MIT
