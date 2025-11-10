# HMS Kubernetes Deployment - File Index

## Quick Links
- [README.md](README.md) - Complete deployment guide with troubleshooting
- [DEPLOYMENT-SUMMARY.md](DEPLOYMENT-SUMMARY.md) - Summary of all resources
- [deploy.sh](deploy.sh) - Automated deployment script
- [cleanup.sh](cleanup.sh) - Cleanup script

## File Structure

```
deployment/kubernetes/
├── 00-namespace.yaml              # Namespace definition (hms)
├── 01-configmap.yaml              # Application configuration
├── 02-secret.yaml                 # Secrets for all services
├── 03-pvc.yaml                    # Persistent Volume Claims (7 databases)
├── 04-databases.yaml              # PostgreSQL deployments (7 databases)
├── 05-database-services.yaml      # Database services (ClusterIP)
├── 06-patient-service.yaml        # Patient service deployment
├── 07-doctor-service.yaml         # Doctor service deployment
├── 08-appointment-service.yaml    # Appointment service deployment
├── 09-billing-service.yaml        # Billing service deployment
├── 10-prescription-service.yaml   # Prescription service deployment
├── 11-payment-service.yaml        # Payment service deployment
├── 12-notification-service.yaml   # Notification service deployment
├── 13-services.yaml               # All service definitions (ClusterIP + NodePort)
├── 14-ingress.yaml                # Ingress controller configuration
├── deploy.sh                      # Automated deployment script
├── cleanup.sh                     # Cleanup script
├── README.md                      # Complete documentation
├── DEPLOYMENT-SUMMARY.md          # Resource summary
└── INDEX.md                       # This file
```

## Manifest Files (YAML)

### Infrastructure (4 files)

| File | Description | Resources | Size |
|------|-------------|-----------|------|
| `00-namespace.yaml` | Namespace definition | 1 Namespace | 129B |
| `01-configmap.yaml` | Configuration parameters | 1 ConfigMap | 995B |
| `02-secret.yaml` | Secrets for all services | 8 Secrets | 1.6K |
| `03-pvc.yaml` | Storage for databases | 7 PVCs | 1.3K |

### Database Layer (2 files)

| File | Description | Resources | Size |
|------|-------------|-----------|------|
| `04-databases.yaml` | All PostgreSQL databases | 7 Deployments | 14K |
| `05-database-services.yaml` | Database networking | 7 Services | 2.2K |

### Application Services (7 files)

| File | Description | Port | NodePort | Size |
|------|-------------|------|----------|------|
| `06-patient-service.yaml` | Patient management | 3001 | 30001 | 2.7K |
| `07-doctor-service.yaml` | Doctor management | 3002 | 30002 | 3.0K |
| `08-appointment-service.yaml` | Appointment scheduling | 3003 | 30003 | 4.1K |
| `09-billing-service.yaml` | Billing management | 3004 | 30004 | 3.2K |
| `10-prescription-service.yaml` | Prescription management | 3005 | 30005 | 2.9K |
| `11-payment-service.yaml` | Payment processing | 3006 | 30006 | 2.6K |
| `12-notification-service.yaml` | Notification service | 3007 | 30007 | 2.6K |

### Service Exposure (2 files)

| File | Description | Resources | Size |
|------|-------------|-----------|------|
| `13-services.yaml` | Service networking | 14 Services | 4.4K |
| `14-ingress.yaml` | Ingress routing | 1 Ingress | 3.7K |

## Scripts

| File | Description | Purpose | Size |
|------|-------------|---------|------|
| `deploy.sh` | Deployment automation | Automated deployment with checks | 8.6K |
| `cleanup.sh` | Cleanup automation | Remove all resources | 6.3K |

## Documentation

| File | Description | Content | Size |
|------|-------------|---------|------|
| `README.md` | Complete guide | Deployment, troubleshooting, operations | 27K |
| `DEPLOYMENT-SUMMARY.md` | Resource summary | Statistics, specifications, architecture | 11K |
| `INDEX.md` | This file | File index and quick reference | - |

## Total Statistics

- **YAML Files**: 15
- **Scripts**: 2
- **Documentation**: 3
- **Total Files**: 20
- **Total Size**: ~110 KB
- **Total Resources**: 50+ Kubernetes objects

## Deployment Order

Follow this order for manual deployment:

1. **Prerequisites**: Start Minikube, build images
2. **Infrastructure**: 00 → 01 → 02 → 03
3. **Databases**: 04 → 05 (wait for ready)
4. **Applications**: 06 → 07 → 08 → 09 → 10 → 11 → 12 (wait for ready)
5. **Services**: 13
6. **Ingress**: 14 (optional)

## Quick Start Methods

### Method 1: Automated Deployment
```bash
./deploy.sh
```

### Method 2: Manual Step-by-Step
```bash
kubectl apply -f 00-namespace.yaml
kubectl apply -f 01-configmap.yaml
kubectl apply -f 02-secret.yaml
kubectl apply -f 03-pvc.yaml
kubectl apply -f 04-databases.yaml
kubectl apply -f 05-database-services.yaml
kubectl wait --for=condition=ready pod -l tier=database -n hms --timeout=300s
kubectl apply -f 06-patient-service.yaml
kubectl apply -f 07-doctor-service.yaml
kubectl apply -f 08-appointment-service.yaml
kubectl apply -f 09-billing-service.yaml
kubectl apply -f 10-prescription-service.yaml
kubectl apply -f 11-payment-service.yaml
kubectl apply -f 12-notification-service.yaml
kubectl wait --for=condition=ready pod -l tier=backend -n hms --timeout=600s
kubectl apply -f 13-services.yaml
kubectl apply -f 14-ingress.yaml
```

### Method 3: One-Command Deployment
```bash
kubectl apply -f .
```
**Note**: This applies all files at once. May need to run twice for dependencies.

## Cleanup Methods

### Method 1: Automated Cleanup
```bash
./cleanup.sh
```

### Method 2: Quick Cleanup
```bash
./cleanup.sh --quick
```

### Method 3: Manual Cleanup
```bash
kubectl delete namespace hms
```

## Resource Breakdown

### By Type
- **Namespaces**: 1
- **ConfigMaps**: 1
- **Secrets**: 8
- **PersistentVolumeClaims**: 7
- **Deployments**: 14 (7 databases + 7 applications)
- **Services**: 21 (7 database + 7 ClusterIP + 7 NodePort)
- **Ingress**: 1

### By Tier
- **Database Tier**: 7 deployments, 7 services, 7 PVCs
- **Backend Tier**: 7 deployments, 14 services
- **Network Tier**: 1 ingress

### Total Pods (at 2 replicas)
- **Database Pods**: 7 (1 replica each)
- **Application Pods**: 14 (2 replicas each)
- **Total Running Pods**: 21

## Environment Variables

### ConfigMap (hms-config)
- Database configuration
- Service URLs
- Scheduling parameters
- Appointment rules
- Billing configuration

### Secrets (hms-secrets + 7 database secrets)
- Database passwords
- Database users
- Database names

## Health Checks

All services expose:
- **Liveness**: `GET /live` (checks if service is alive)
- **Readiness**: `GET /ready` (checks if service can accept traffic)

## Port Mapping

| Service | Internal | NodePort | Database | DB Port |
|---------|----------|----------|----------|---------|
| Patient | 3001 | 30001 | postgres-patient | 5432 |
| Doctor | 3002 | 30002 | postgres-doctor | 5432 |
| Appointment | 3003 | 30003 | postgres-appointment | 5432 |
| Billing | 3004 | 30004 | postgres-billing | 5432 |
| Prescription | 3005 | 30005 | postgres-prescription | 5432 |
| Payment | 3006 | 30006 | postgres-payment | 5432 |
| Notification | 3007 | 30007 | postgres-notification | 5432 |

## Access Methods

### NodePort (Default)
```bash
MINIKUBE_IP=$(minikube ip)
curl http://$MINIKUBE_IP:30001/live  # Patient service
```

### Port Forward
```bash
kubectl port-forward -n hms service/patient-service 3001:3001
curl http://localhost:3001/live
```

### Ingress (if enabled)
```bash
curl http://hms.local/patient/live
```

### Minikube Service
```bash
minikube service patient-service-external -n hms
```

## Common Commands

```bash
# View everything
kubectl get all -n hms

# Check pods
kubectl get pods -n hms

# View logs
kubectl logs -n hms <pod-name>

# Describe resource
kubectl describe pod -n hms <pod-name>

# Scale service
kubectl scale deployment patient-service -n hms --replicas=3

# Restart service
kubectl rollout restart deployment/patient-service -n hms

# Check events
kubectl get events -n hms --sort-by='.lastTimestamp'
```

## Troubleshooting Quick Reference

### Pods not starting
```bash
kubectl describe pod -n hms <pod-name>
kubectl logs -n hms <pod-name>
```

### Service not accessible
```bash
kubectl get endpoints -n hms
kubectl describe service -n hms <service-name>
```

### Database connection issues
```bash
kubectl logs -n hms <postgres-pod-name>
kubectl exec -n hms <app-pod-name> -- env | grep DB_
```

### Resource issues
```bash
kubectl top pods -n hms
kubectl top nodes
```

## Prerequisites Checklist

- [ ] Minikube installed (v1.30.0+)
- [ ] kubectl installed (v1.27.0+)
- [ ] Docker installed (v20.10.0+)
- [ ] Minimum 4 CPU cores allocated
- [ ] Minimum 8GB RAM allocated
- [ ] 20GB free disk space
- [ ] Docker images built for all 7 services

## Build Images First

Before deployment, build all service images:

```bash
eval $(minikube docker-env)

# Build all images
docker build -t patient-service:latest ./services/patient
docker build -t doctor-service:latest ./services/doctor
docker build -t appointment-service:latest ./services/appointment
docker build -t billing-service:latest ./services/billing
docker build -t prescription-service:latest ./services/prescription
docker build -t payment-service:latest ./services/payment
docker build -t notification-service:latest ./services/notification

# Verify
docker images | grep service
```

## Labels for Filtering

All resources use consistent labels:

```bash
# By tier
kubectl get pods -n hms -l tier=database
kubectl get pods -n hms -l tier=backend

# By app
kubectl get pods -n hms -l app=patient-service

# By version
kubectl get pods -n hms -l version=v1
```

## Monitoring Recommendations

- **Prometheus**: Collect metrics
- **Grafana**: Visualize metrics
- **ELK Stack**: Centralized logging
- **Jaeger**: Distributed tracing

## Production Considerations

For production deployment, additionally configure:

1. **Security**
   - Network Policies
   - Pod Security Policies
   - RBAC
   - Secrets encryption

2. **High Availability**
   - Multi-node cluster
   - Pod Disruption Budgets
   - Anti-affinity rules
   - Multiple AZs

3. **Scalability**
   - Horizontal Pod Autoscaling
   - Cluster Autoscaling
   - Resource quotas
   - Limit ranges

4. **Observability**
   - Centralized logging
   - Metrics collection
   - Distributed tracing
   - Alerting

5. **Data Management**
   - Backup strategy
   - Disaster recovery
   - Data replication
   - Storage classes

## Support Resources

- **Documentation**: See README.md
- **Troubleshooting**: See README.md (Troubleshooting section)
- **Architecture**: See DEPLOYMENT-SUMMARY.md
- **Kubernetes Docs**: https://kubernetes.io/docs/
- **Minikube Docs**: https://minikube.sigs.k8s.io/docs/

## Version Information

- **Kubernetes**: v1.27+
- **PostgreSQL**: 15-alpine
- **Node.js**: (Service-specific)
- **Last Updated**: 2025-10-11
- **Manifest Version**: v1.0.0

---

**Getting Started**: Read [README.md](README.md) for detailed instructions.
**Quick Deploy**: Run `./deploy.sh` to start automated deployment.
**Clean Up**: Run `./cleanup.sh` to remove all resources.
