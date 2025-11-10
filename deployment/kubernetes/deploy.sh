#!/bin/bash

# HMS Kubernetes Deployment Script
# This script automates the deployment of Hospital Management System to Kubernetes

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================================${NC}\n"
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"

    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    print_success "kubectl is installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"

    # Check minikube
    if ! command -v minikube &> /dev/null; then
        print_error "minikube is not installed. Please install minikube first."
        exit 1
    fi
    print_success "minikube is installed: $(minikube version --short)"

    # Check if minikube is running
    if ! minikube status &> /dev/null; then
        print_warning "Minikube is not running. Starting Minikube..."
        minikube start --cpus=4 --memory=8192 --driver=docker
    else
        print_success "Minikube is running"
    fi

    # Check cluster connection
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    print_success "Connected to Kubernetes cluster"
}

# Deploy namespace and configuration
deploy_config() {
    print_header "Step 1: Deploying Namespace and Configuration"

    print_info "Creating namespace..."
    kubectl apply -f 00-namespace.yaml
    print_success "Namespace created"

    print_info "Deploying ConfigMap..."
    kubectl apply -f 01-configmap.yaml
    print_success "ConfigMap deployed"

    print_info "Deploying Secrets..."
    kubectl apply -f 02-secret.yaml
    print_success "Secrets deployed"

    print_info "Creating Persistent Volume Claims..."
    kubectl apply -f 03-pvc.yaml
    print_success "PVCs created"

    echo ""
    kubectl get namespace hms
    kubectl get configmap -n hms
    kubectl get secret -n hms
    kubectl get pvc -n hms
}

# Deploy databases
deploy_databases() {
    print_header "Step 2: Deploying Databases"

    print_info "Deploying PostgreSQL databases..."
    kubectl apply -f 04-databases.yaml
    print_success "Database deployments created"

    print_info "Deploying database services..."
    kubectl apply -f 05-database-services.yaml
    print_success "Database services created"

    print_info "Waiting for databases to be ready (this may take 2-3 minutes)..."
    kubectl wait --for=condition=ready pod -l tier=database -n hms --timeout=300s || {
        print_warning "Databases taking longer than expected. Check status with: kubectl get pods -n hms -l tier=database"
    }

    echo ""
    kubectl get pods -n hms -l tier=database
    kubectl get services -n hms -l tier=database
}

# Deploy application services
deploy_applications() {
    print_header "Step 3: Deploying Application Services"

    print_info "Deploying Patient Service..."
    kubectl apply -f 06-patient-service.yaml

    print_info "Deploying Doctor Service..."
    kubectl apply -f 07-doctor-service.yaml

    print_info "Deploying Appointment Service..."
    kubectl apply -f 08-appointment-service.yaml

    print_info "Deploying Billing Service..."
    kubectl apply -f 09-billing-service.yaml

    print_info "Deploying Prescription Service..."
    kubectl apply -f 10-prescription-service.yaml

    print_info "Deploying Payment Service..."
    kubectl apply -f 11-payment-service.yaml

    print_info "Deploying Notification Service..."
    kubectl apply -f 12-notification-service.yaml

    print_success "All application deployments created"

    print_info "Waiting for applications to be ready (this may take 3-5 minutes)..."
    kubectl wait --for=condition=ready pod -l tier=backend -n hms --timeout=600s || {
        print_warning "Applications taking longer than expected. Check status with: kubectl get pods -n hms -l tier=backend"
    }

    echo ""
    kubectl get pods -n hms -l tier=backend
}

# Deploy services
deploy_services() {
    print_header "Step 4: Deploying Services"

    print_info "Deploying Kubernetes services..."
    kubectl apply -f 13-services.yaml
    print_success "Services deployed"

    echo ""
    kubectl get services -n hms -l tier=backend
}

# Deploy ingress
deploy_ingress() {
    print_header "Step 5: Deploying Ingress (Optional)"

    read -p "Do you want to deploy Ingress? (y/n): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Enabling ingress addon..."
        minikube addons enable ingress

        print_info "Waiting for ingress controller..."
        kubectl wait --namespace ingress-nginx \
          --for=condition=ready pod \
          --selector=app.kubernetes.io/component=controller \
          --timeout=120s || {
            print_warning "Ingress controller not ready yet. You can check later with: kubectl get pods -n ingress-nginx"
        }

        print_info "Deploying ingress..."
        kubectl apply -f 14-ingress.yaml
        print_success "Ingress deployed"

        echo ""
        kubectl get ingress -n hms

        print_info "Adding hms.local to /etc/hosts..."
        MINIKUBE_IP=$(minikube ip)
        if grep -q "hms.local" /etc/hosts; then
            print_warning "hms.local already exists in /etc/hosts"
        else
            echo "$MINIKUBE_IP hms.local" | sudo tee -a /etc/hosts
            print_success "Added hms.local to /etc/hosts"
        fi
    else
        print_info "Skipping ingress deployment"
    fi
}

# Show deployment summary
show_summary() {
    print_header "Deployment Summary"

    echo ""
    print_info "All Resources in HMS namespace:"
    kubectl get all -n hms

    echo ""
    print_info "Persistent Volume Claims:"
    kubectl get pvc -n hms

    echo ""
    print_info "Ingress:"
    kubectl get ingress -n hms 2>/dev/null || print_info "No ingress configured"

    echo ""
    print_header "Access Information"

    MINIKUBE_IP=$(minikube ip)
    print_success "Minikube IP: $MINIKUBE_IP"

    echo ""
    print_info "Services can be accessed at:"
    echo -e "  ${GREEN}Patient Service:${NC}       http://$MINIKUBE_IP:30001"
    echo -e "  ${GREEN}Doctor Service:${NC}        http://$MINIKUBE_IP:30002"
    echo -e "  ${GREEN}Appointment Service:${NC}   http://$MINIKUBE_IP:30003"
    echo -e "  ${GREEN}Billing Service:${NC}       http://$MINIKUBE_IP:30004"
    echo -e "  ${GREEN}Prescription Service:${NC}  http://$MINIKUBE_IP:30005"
    echo -e "  ${GREEN}Payment Service:${NC}       http://$MINIKUBE_IP:30006"
    echo -e "  ${GREEN}Notification Service:${NC}  http://$MINIKUBE_IP:30007"

    if kubectl get ingress -n hms &>/dev/null; then
        echo ""
        print_info "Or via Ingress at:"
        echo -e "  ${GREEN}http://hms.local/patient/${NC}"
        echo -e "  ${GREEN}http://hms.local/doctor/${NC}"
        echo -e "  ${GREEN}http://hms.local/appointment/${NC}"
        echo -e "  ${GREEN}http://hms.local/billing/${NC}"
        echo -e "  ${GREEN}http://hms.local/prescription/${NC}"
        echo -e "  ${GREEN}http://hms.local/payment/${NC}"
        echo -e "  ${GREEN}http://hms.local/notification/${NC}"
    fi

    echo ""
    print_header "Useful Commands"
    echo "View all pods:           kubectl get pods -n hms"
    echo "View logs:               kubectl logs -n hms <pod-name>"
    echo "Describe pod:            kubectl describe pod -n hms <pod-name>"
    echo "Open service in browser: minikube service <service-name>-external -n hms"
    echo "Port forward:            kubectl port-forward -n hms service/<service-name> <local-port>:<service-port>"
    echo "Scale deployment:        kubectl scale deployment <name> -n hms --replicas=<count>"
    echo "View events:             kubectl get events -n hms --sort-by='.lastTimestamp'"
    echo ""

    print_success "Deployment completed successfully!"
}

# Main deployment flow
main() {
    print_header "HMS Kubernetes Deployment"
    print_info "Starting deployment process..."

    check_prerequisites
    deploy_config
    deploy_databases
    deploy_applications
    deploy_services
    deploy_ingress
    show_summary
}

# Handle script interruption
trap 'print_error "Deployment interrupted!"; exit 1' INT TERM

# Run main function
main
