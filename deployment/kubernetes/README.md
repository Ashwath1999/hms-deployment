# Hospital Management System (HMS) - Kubernetes Deployment Guide

This guide provides comprehensive instructions for deploying the Hospital Management System microservices architecture on Kubernetes.

## Table of Contents
- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Step-by-Step Deployment](#step-by-step-deployment)
- [Accessing Services](#accessing-services)
- [Monitoring and Troubleshooting](#monitoring-and-troubleshooting)
- [Scaling](#scaling)
- [Common Operations](#common-operations)
- [Troubleshooting Guide](#troubleshooting-guide)

## Architecture Overview

The HMS consists of 7 microservices, each with its own PostgreSQL database:

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Kubernetes Cluster (hms)                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐  │
│  │ Patient Service  │  │ Doctor Service   │  │Appointment Svc   │  │
│  │   Port: 3001     │  │   Port: 3002     │  │   Port: 3003     │  │
│  │   NodePort: 30001│  │   NodePort: 30002│  │   NodePort: 30003│  │
│  │   Replicas: 2    │  │   Replicas: 2    │  │   Replicas: 2    │  │
│  └────────┬─────────┘  └────────┬─────────┘  └────────┬─────────┘  │
│           │                     │                     │             │
│  ┌────────▼─────────┐  ┌────────▼─────────┐  ┌────────▼─────────┐  │
│  │postgres-patient  │  │postgres-doctor   │  │postgres-appt     │  │
│  │   Port: 5432     │  │   Port: 5432     │  │   Port: 5432     │  │
│  │   DB: patients   │  │   DB: doctors    │  │   DB: appts      │  │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘  │
│                                                                       │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐  │
│  │ Billing Service  │  │Prescription Svc  │  │ Payment Service  │  │
│  │   Port: 3004     │  │   Port: 3005     │  │   Port: 3006     │  │
│  │   NodePort: 30004│  │   NodePort: 30005│  │   NodePort: 30006│  │
│  │   Replicas: 2    │  │   Replicas: 2    │  │   Replicas: 2    │  │
│  └────────┬─────────┘  └────────┬─────────┘  └────────┬─────────┘  │
│           │                     │                     │             │
│  ┌────────▼─────────┐  ┌────────▼─────────┐  ┌────────▼─────────┐  │
│  │postgres-billing  │  │postgres-presc    │  │postgres-payment  │  │
│  │   Port: 5432     │  │   Port: 5432     │  │   Port: 5432     │  │
│  │   DB: billing    │  │   DB: presc      │  │   DB: payments   │  │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘  │
│                                                                       │
│  ┌──────────────────┐                                                │
│  │Notification Svc  │                                                │
│  │   Port: 3007     │                                                │
│  │   NodePort: 30007│                                                │
│  │   Replicas: 2    │                                                │
│  └────────┬─────────┘                                                │
│           │                                                          │
│  ┌────────▼─────────┐                                                │
│  │postgres-notif    │                                                │
│  │   Port: 5432     │                                                │
│  │   DB: notify     │                                                │
│  └──────────────────┘                                                │
│                                                                       │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │ ConfigMaps: hms-config                                        │  │
│  │ Secrets: hms-secrets, postgres-*-secret                       │  │
│  │ PVCs: postgres-*-pvc (7 volumes)                              │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

### Service Communication Flow
```
External User/API
      ↓
  NodePort/Ingress
      ↓
┌─────────────────┐
│  Any Service    │ ←→ Other Services (via ClusterIP)
└────────┬────────┘
         ↓
    PostgreSQL DB
```

## Prerequisites

### Required Software
- **Minikube**: v1.30.0 or higher
- **kubectl**: v1.27.0 or higher
- **Docker**: v20.10.0 or higher (as Minikube driver)
- **Git**: For cloning the repository

### System Requirements
- CPU: 4 cores or more
- RAM: 8GB or more
- Disk: 20GB free space

### Installation Instructions

#### macOS
```bash
# Install Minikube
brew install minikube

# Install kubectl
brew install kubectl

# Verify installations
minikube version
kubectl version --client
```

#### Linux
```bash
# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verify installations
minikube version
kubectl version --client
```

#### Windows (PowerShell as Administrator)
```powershell
# Install using Chocolatey
choco install minikube
choco install kubernetes-cli

# Or download installers from:
# https://minikube.sigs.k8s.io/docs/start/
# https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
```

## Quick Start

For experienced users, here's the quick deployment:

```bash
# 1. Start Minikube
minikube start --cpus=4 --memory=8192 --driver=docker

# 2. Build Docker images (ensure you're in the project root)
eval $(minikube docker-env)
# Build your microservice images here

# 3. Navigate to kubernetes directory
cd deployment/kubernetes

# 4. Deploy everything
kubectl apply -f 00-namespace.yaml
kubectl apply -f 01-configmap.yaml
kubectl apply -f 02-secret.yaml
kubectl apply -f 03-pvc.yaml
kubectl apply -f 04-databases.yaml
kubectl apply -f 05-database-services.yaml
kubectl apply -f 06-patient-service.yaml
kubectl apply -f 07-doctor-service.yaml
kubectl apply -f 08-appointment-service.yaml
kubectl apply -f 09-billing-service.yaml
kubectl apply -f 10-prescription-service.yaml
kubectl apply -f 11-payment-service.yaml
kubectl apply -f 12-notification-service.yaml
kubectl apply -f 13-services.yaml
kubectl apply -f 14-ingress.yaml  # Optional

# 5. Verify deployment
kubectl get pods -n hms
kubectl get services -n hms

# 6. Access services
minikube service patient-service-external -n hms
```

## Step-by-Step Deployment

### Step 1: Start Minikube Cluster

```bash
# Start Minikube with sufficient resources
minikube start --cpus=4 --memory=8192 --driver=docker

# Verify cluster is running
kubectl cluster-info
kubectl get nodes

# Expected output:
# NAME       STATUS   ROLES           AGE   VERSION
# minikube   Ready    control-plane   1m    v1.27.x
```

### Step 2: Build Docker Images

Before deploying, you need to build Docker images for all microservices:

```bash
# Configure Docker to use Minikube's Docker daemon
eval $(minikube docker-env)

# Navigate to project root and build images
cd /path/to/your/project

# Build all service images
docker build -t patient-service:latest ./services/patient
docker build -t doctor-service:latest ./services/doctor
docker build -t appointment-service:latest ./services/appointment
docker build -t billing-service:latest ./services/billing
docker build -t prescription-service:latest ./services/prescription
docker build -t payment-service:latest ./services/payment
docker build -t notification-service:latest ./services/notification

# Verify images are built
docker images | grep service

# Expected output should show all 7 service images
```

**Note**: If you have a build script, use it instead:
```bash
./build-all.sh
```

### Step 3: Deploy Namespace and Configuration

```bash
# Navigate to kubernetes directory
cd deployment/kubernetes

# Create namespace
kubectl apply -f 00-namespace.yaml

# Verify namespace
kubectl get namespace hms

# Deploy ConfigMap (contains application configuration)
kubectl apply -f 01-configmap.yaml

# Deploy Secrets (contains passwords and sensitive data)
kubectl apply -f 02-secret.yaml

# Verify ConfigMap and Secrets
kubectl get configmap -n hms
kubectl get secret -n hms
```

### Step 4: Create Persistent Volume Claims

```bash
# Create PVCs for all databases
kubectl apply -f 03-pvc.yaml

# Verify PVCs are created and bound
kubectl get pvc -n hms

# Expected output:
# NAME                        STATUS   VOLUME                                     CAPACITY   ACCESS MODES
# postgres-patient-pvc        Bound    pvc-xxx-xxx-xxx                           1Gi        RWO
# postgres-doctor-pvc         Bound    pvc-xxx-xxx-xxx                           1Gi        RWO
# postgres-appointment-pvc    Bound    pvc-xxx-xxx-xxx                           2Gi        RWO
# ... (7 PVCs total)
```

### Step 5: Deploy Database Layer

```bash
# Deploy all PostgreSQL databases
kubectl apply -f 04-databases.yaml

# Deploy database services
kubectl apply -f 05-database-services.yaml

# Wait for databases to be ready (this may take 2-3 minutes)
kubectl wait --for=condition=ready pod -l tier=database -n hms --timeout=300s

# Verify database deployments
kubectl get pods -n hms -l tier=database

# All pods should show 1/1 READY and STATUS Running
```

### Step 6: Deploy Application Services

```bash
# Deploy all microservices (one by one for better visibility)
kubectl apply -f 06-patient-service.yaml
kubectl apply -f 07-doctor-service.yaml
kubectl apply -f 08-appointment-service.yaml
kubectl apply -f 09-billing-service.yaml
kubectl apply -f 10-prescription-service.yaml
kubectl apply -f 11-payment-service.yaml
kubectl apply -f 12-notification-service.yaml

# Wait for all services to be ready (this may take 3-5 minutes)
kubectl wait --for=condition=ready pod -l tier=backend -n hms --timeout=600s

# Verify application deployments
kubectl get pods -n hms -l tier=backend

# All pods should show 1/1 READY and STATUS Running
```

### Step 7: Deploy Services (Internal and External)

```bash
# Deploy all Kubernetes services
kubectl apply -f 13-services.yaml

# Verify services
kubectl get services -n hms

# You should see both ClusterIP (internal) and NodePort (external) services
```

### Step 8: Deploy Ingress (Optional)

```bash
# Enable ingress addon in Minikube
minikube addons enable ingress

# Wait for ingress controller to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# Deploy ingress
kubectl apply -f 14-ingress.yaml

# Verify ingress
kubectl get ingress -n hms

# Add to /etc/hosts (for local development)
echo "$(minikube ip) hms.local" | sudo tee -a /etc/hosts
```

### Step 9: Verify Complete Deployment

```bash
# Check all resources in hms namespace
kubectl get all -n hms

# Check pod status
kubectl get pods -n hms -o wide

# Check services
kubectl get services -n hms

# Check ingress
kubectl get ingress -n hms

# Check persistent volumes
kubectl get pvc -n hms
```

## Accessing Services

### Method 1: Using NodePort (Recommended for Minikube)

Each service is exposed via NodePort for external access:

```bash
# Get Minikube IP
minikube ip

# Access services using NodePort:
# Patient Service:      http://<minikube-ip>:30001
# Doctor Service:       http://<minikube-ip>:30002
# Appointment Service:  http://<minikube-ip>:30003
# Billing Service:      http://<minikube-ip>:30004
# Prescription Service: http://<minikube-ip>:30005
# Payment Service:      http://<minikube-ip>:30006
# Notification Service: http://<minikube-ip>:30007

# Or use Minikube service command (opens in browser)
minikube service patient-service-external -n hms
minikube service doctor-service-external -n hms
minikube service appointment-service-external -n hms
```

### Method 2: Using Port Forwarding

For direct access without NodePort:

```bash
# Port forward to specific service
kubectl port-forward -n hms service/patient-service 3001:3001

# Access at http://localhost:3001

# For multiple services, use different terminal windows
kubectl port-forward -n hms service/doctor-service 3002:3002
kubectl port-forward -n hms service/appointment-service 3003:3003
```

### Method 3: Using Ingress (If enabled)

```bash
# Access via ingress
# First, get the Minikube IP
minikube ip

# Access services:
# http://hms.local/patient/
# http://hms.local/doctor/
# http://hms.local/appointment/
# http://hms.local/billing/
# http://hms.local/prescription/
# http://hms.local/payment/
# http://hms.local/notification/
```

### Testing Service Endpoints

```bash
# Get Minikube IP
MINIKUBE_IP=$(minikube ip)

# Test Patient Service health endpoints
curl http://$MINIKUBE_IP:30001/live
curl http://$MINIKUBE_IP:30001/ready

# Test creating a patient
curl -X POST http://$MINIKUBE_IP:30001/api/patients \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "+1234567890",
    "dateOfBirth": "1990-01-01",
    "gender": "male",
    "address": "123 Main St"
  }'

# Test getting all patients
curl http://$MINIKUBE_IP:30001/api/patients

# Similar tests for other services...
```

## Monitoring and Troubleshooting

### View Logs

```bash
# View logs for a specific pod
kubectl logs -n hms <pod-name>

# View logs for all pods of a service
kubectl logs -n hms -l app=patient-service

# Follow logs in real-time
kubectl logs -n hms -f <pod-name>

# View logs from previous container instance (if pod crashed)
kubectl logs -n hms <pod-name> --previous

# View logs for database
kubectl logs -n hms -l app=postgres-patient
```

### Check Pod Status

```bash
# Get all pods with details
kubectl get pods -n hms -o wide

# Describe a specific pod (shows events and errors)
kubectl describe pod -n hms <pod-name>

# Get pods with specific labels
kubectl get pods -n hms -l tier=backend
kubectl get pods -n hms -l tier=database

# Watch pods in real-time
kubectl get pods -n hms -w
```

### Check Service Status

```bash
# Get all services
kubectl get services -n hms

# Describe a service
kubectl describe service -n hms patient-service

# Test service connectivity from within cluster
kubectl run -it --rm debug --image=busybox --restart=Never -n hms -- sh
# Inside the pod:
wget -O- http://patient-service:3001/live
```

### Check Resource Usage

```bash
# Get resource usage for pods
kubectl top pods -n hms

# Get resource usage for nodes
kubectl top nodes

# Check if pods are being throttled or OOMKilled
kubectl get pods -n hms -o json | \
  jq '.items[] | select(.status.containerStatuses[].lastState.terminated.reason == "OOMKilled")'
```

### Check Events

```bash
# View recent events in namespace
kubectl get events -n hms --sort-by='.lastTimestamp'

# View events for specific pod
kubectl describe pod -n hms <pod-name> | grep Events: -A 20
```

### Database Troubleshooting

```bash
# Connect to PostgreSQL pod
kubectl exec -it -n hms postgres-patient-xxx -- psql -U postgres -d hms_patients

# Inside PostgreSQL:
# \dt              # List tables
# \l               # List databases
# \d+ patients     # Describe patients table
# SELECT * FROM patients LIMIT 10;

# Check database logs
kubectl logs -n hms postgres-patient-xxx

# Verify database connection
kubectl exec -it -n hms <app-pod-name> -- sh
# Inside pod:
nc -zv postgres-patient 5432
```

## Scaling

### Manual Scaling

```bash
# Scale a specific service
kubectl scale deployment patient-service -n hms --replicas=3

# Scale multiple services
kubectl scale deployment -n hms \
  patient-service \
  doctor-service \
  appointment-service \
  --replicas=3

# Verify scaling
kubectl get deployments -n hms
```

### Auto-Scaling (HPA - Horizontal Pod Autoscaler)

```bash
# Create HPA for a service (scales based on CPU)
kubectl autoscale deployment patient-service -n hms \
  --cpu-percent=70 \
  --min=2 \
  --max=10

# View HPA status
kubectl get hpa -n hms

# Describe HPA
kubectl describe hpa patient-service -n hms

# Delete HPA
kubectl delete hpa patient-service -n hms
```

Example HPA manifest (save as `hpa-patient.yaml`):
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: patient-service-hpa
  namespace: hms
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: patient-service
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

Apply HPA:
```bash
kubectl apply -f hpa-patient.yaml
```

## Common Operations

### Update Application

```bash
# Update image for a service
kubectl set image deployment/patient-service \
  patient-service=patient-service:v2 \
  -n hms

# Check rollout status
kubectl rollout status deployment/patient-service -n hms

# View rollout history
kubectl rollout history deployment/patient-service -n hms

# Rollback to previous version
kubectl rollout undo deployment/patient-service -n hms

# Rollback to specific revision
kubectl rollout undo deployment/patient-service -n hms --to-revision=2
```

### Restart Services

```bash
# Restart a deployment (rolling restart)
kubectl rollout restart deployment/patient-service -n hms

# Delete pods to force restart (not recommended for production)
kubectl delete pods -n hms -l app=patient-service
```

### Update Configuration

```bash
# Edit ConfigMap
kubectl edit configmap hms-config -n hms

# Or update from file
kubectl apply -f 01-configmap.yaml

# Restart services to pick up new config
kubectl rollout restart deployment -n hms --selector=tier=backend
```

### Backup Database

```bash
# Create backup of a database
kubectl exec -n hms postgres-patient-xxx -- \
  pg_dump -U postgres hms_patients > patient_backup.sql

# Restore from backup
kubectl exec -i -n hms postgres-patient-xxx -- \
  psql -U postgres hms_patients < patient_backup.sql
```

### Clean Up

```bash
# Delete specific resources
kubectl delete -f 14-ingress.yaml
kubectl delete -f 13-services.yaml

# Delete all application deployments
kubectl delete -f 06-patient-service.yaml
kubectl delete -f 07-doctor-service.yaml
kubectl delete -f 08-appointment-service.yaml
kubectl delete -f 09-billing-service.yaml
kubectl delete -f 10-prescription-service.yaml
kubectl delete -f 11-payment-service.yaml
kubectl delete -f 12-notification-service.yaml

# Delete databases
kubectl delete -f 05-database-services.yaml
kubectl delete -f 04-databases.yaml

# Delete PVCs (WARNING: This deletes all data)
kubectl delete -f 03-pvc.yaml

# Delete entire namespace (WARNING: Deletes everything)
kubectl delete namespace hms

# Stop Minikube
minikube stop

# Delete Minikube cluster
minikube delete
```

## Troubleshooting Guide

### Common Issues and Solutions

#### Issue 1: Pods stuck in "Pending" state

```bash
# Check events
kubectl describe pod -n hms <pod-name>

# Common causes:
# 1. Insufficient resources
minikube start --cpus=4 --memory=8192

# 2. PVC not bound
kubectl get pvc -n hms

# 3. Image pull issues
# Check if images exist in Minikube's Docker
eval $(minikube docker-env)
docker images
```

#### Issue 2: Pods in "CrashLoopBackOff"

```bash
# View logs
kubectl logs -n hms <pod-name>
kubectl logs -n hms <pod-name> --previous

# Common causes:
# 1. Database connection failure
# Check if database is ready
kubectl get pods -n hms -l tier=database

# 2. Environment variables missing
kubectl describe pod -n hms <pod-name>

# 3. Application errors
# Check application logs for stack traces
```

#### Issue 3: Service not accessible

```bash
# Check if pods are running
kubectl get pods -n hms

# Check if service exists
kubectl get service -n hms

# Check if endpoints are populated
kubectl get endpoints -n hms

# Test service connectivity
kubectl run -it --rm test --image=busybox --restart=Never -n hms -- \
  wget -O- http://patient-service:3001/live

# For NodePort, check Minikube IP
minikube ip
```

#### Issue 4: Database connection errors

```bash
# Verify database is running
kubectl get pods -n hms -l app=postgres-patient

# Check database logs
kubectl logs -n hms <postgres-pod-name>

# Verify service DNS resolution
kubectl exec -n hms <app-pod-name> -- nslookup postgres-patient

# Test database connection
kubectl exec -n hms <postgres-pod-name> -- \
  psql -U postgres -d hms_patients -c "SELECT 1"

# Check environment variables in app pod
kubectl exec -n hms <app-pod-name> -- env | grep DB_
```

#### Issue 5: Out of Memory (OOMKilled)

```bash
# Check pod events
kubectl describe pod -n hms <pod-name>

# Increase memory limits
kubectl edit deployment -n hms <deployment-name>
# Update resources.limits.memory to higher value

# Or update YAML file and reapply
```

#### Issue 6: Disk space issues

```bash
# Check PVC usage
kubectl exec -n hms <postgres-pod-name> -- df -h

# Increase PVC size (requires storage class that supports expansion)
kubectl edit pvc -n hms postgres-patient-pvc
# Update storage size

# Or delete old data
kubectl exec -it -n hms <postgres-pod-name> -- bash
# Run cleanup queries
```

### Health Check Endpoints

Each service provides health check endpoints:

- **Liveness**: `/live` - Indicates if the service is alive
- **Readiness**: `/ready` - Indicates if the service is ready to accept traffic

```bash
# Check health status
MINIKUBE_IP=$(minikube ip)
curl http://$MINIKUBE_IP:30001/live
curl http://$MINIKUBE_IP:30001/ready
```

### Enable Debug Logging

```bash
# Update ConfigMap to set LOG_LEVEL=debug
kubectl edit configmap hms-config -n hms

# Change LOG_LEVEL from "info" to "debug"

# Restart services
kubectl rollout restart deployment -n hms --selector=tier=backend
```

## Best Practices

### Security
- Never commit secrets to version control
- Use Kubernetes Secrets for sensitive data
- Implement RBAC for access control
- Use network policies to restrict traffic

### Resource Management
- Always set resource requests and limits
- Monitor resource usage regularly
- Use HPA for automatic scaling
- Set up resource quotas for namespace

### High Availability
- Run multiple replicas of services
- Use PodDisruptionBudgets
- Implement proper health checks
- Use anti-affinity rules for pod distribution

### Monitoring
- Implement centralized logging (e.g., ELK stack)
- Set up metrics collection (e.g., Prometheus)
- Create dashboards (e.g., Grafana)
- Set up alerts for critical issues

## Additional Resources

- [Kubernetes Official Documentation](https://kubernetes.io/docs/)
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [PostgreSQL on Kubernetes](https://www.postgresql.org/docs/)

## Support

For issues or questions:
1. Check the troubleshooting guide above
2. Review pod logs: `kubectl logs -n hms <pod-name>`
3. Check events: `kubectl get events -n hms`
4. Consult service-specific documentation

## File Structure

```
deployment/kubernetes/
├── 00-namespace.yaml              # HMS namespace
├── 01-configmap.yaml              # Application configuration
├── 02-secret.yaml                 # Secrets (passwords, tokens)
├── 03-pvc.yaml                    # Persistent Volume Claims
├── 04-databases.yaml              # All 7 PostgreSQL databases
├── 05-database-services.yaml      # Database ClusterIP services
├── 06-patient-service.yaml        # Patient service deployment
├── 07-doctor-service.yaml         # Doctor service deployment
├── 08-appointment-service.yaml    # Appointment service deployment
├── 09-billing-service.yaml        # Billing service deployment
├── 10-prescription-service.yaml   # Prescription service deployment
├── 11-payment-service.yaml        # Payment service deployment
├── 12-notification-service.yaml   # Notification service deployment
├── 13-services.yaml               # All service definitions
├── 14-ingress.yaml                # Ingress controller configuration
└── README.md                      # This file
```

## Quick Reference Commands

```bash
# View all resources
kubectl get all -n hms

# Get pods
kubectl get pods -n hms

# Get services
kubectl get services -n hms

# View logs
kubectl logs -n hms <pod-name>

# Describe resource
kubectl describe pod -n hms <pod-name>

# Execute command in pod
kubectl exec -it -n hms <pod-name> -- bash

# Port forward
kubectl port-forward -n hms service/patient-service 3001:3001

# Scale deployment
kubectl scale deployment patient-service -n hms --replicas=3

# Restart deployment
kubectl rollout restart deployment/patient-service -n hms

# Get events
kubectl get events -n hms --sort-by='.lastTimestamp'

# Open service in browser (Minikube)
minikube service patient-service-external -n hms
```

---

**Version**: 1.0.0
**Last Updated**: 2025-10-11
**Kubernetes Version**: v1.27+
**Tested on**: Minikube v1.30.0
