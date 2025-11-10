#!/bin/bash

# HMS Kubernetes Cleanup Script
# This script removes all HMS resources from Kubernetes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Confirmation prompt
confirm_cleanup() {
    print_header "HMS Kubernetes Cleanup"
    print_warning "This will delete ALL HMS resources from Kubernetes!"
    print_warning "Including:"
    echo "  - All deployments and pods"
    echo "  - All services"
    echo "  - All persistent volumes and data"
    echo "  - All configuration and secrets"
    echo "  - The entire HMS namespace"
    echo ""

    read -p "Are you sure you want to continue? (yes/no): " -r
    echo

    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        print_info "Cleanup cancelled"
        exit 0
    fi

    read -p "Type 'DELETE' to confirm: " -r
    echo

    if [[ $REPLY != "DELETE" ]]; then
        print_info "Cleanup cancelled"
        exit 0
    fi
}

# Delete resources
cleanup_resources() {
    print_header "Cleaning Up Resources"

    # Check if namespace exists
    if ! kubectl get namespace hms &> /dev/null; then
        print_info "HMS namespace does not exist. Nothing to clean up."
        exit 0
    fi

    print_info "Deleting ingress..."
    kubectl delete -f 14-ingress.yaml --ignore-not-found=true
    print_success "Ingress deleted"

    print_info "Deleting services..."
    kubectl delete -f 13-services.yaml --ignore-not-found=true
    print_success "Services deleted"

    print_info "Deleting application deployments..."
    kubectl delete -f 12-notification-service.yaml --ignore-not-found=true
    kubectl delete -f 11-payment-service.yaml --ignore-not-found=true
    kubectl delete -f 10-prescription-service.yaml --ignore-not-found=true
    kubectl delete -f 09-billing-service.yaml --ignore-not-found=true
    kubectl delete -f 08-appointment-service.yaml --ignore-not-found=true
    kubectl delete -f 07-doctor-service.yaml --ignore-not-found=true
    kubectl delete -f 06-patient-service.yaml --ignore-not-found=true
    print_success "Application deployments deleted"

    print_info "Waiting for application pods to terminate..."
    kubectl wait --for=delete pod -l tier=backend -n hms --timeout=120s 2>/dev/null || true

    print_info "Deleting database services..."
    kubectl delete -f 05-database-services.yaml --ignore-not-found=true
    print_success "Database services deleted"

    print_info "Deleting databases..."
    kubectl delete -f 04-databases.yaml --ignore-not-found=true
    print_success "Databases deleted"

    print_info "Waiting for database pods to terminate..."
    kubectl wait --for=delete pod -l tier=database -n hms --timeout=120s 2>/dev/null || true

    print_warning "Deleting Persistent Volume Claims (THIS WILL DELETE ALL DATA)..."
    kubectl delete -f 03-pvc.yaml --ignore-not-found=true
    print_success "PVCs deleted"

    print_info "Deleting secrets..."
    kubectl delete -f 02-secret.yaml --ignore-not-found=true
    print_success "Secrets deleted"

    print_info "Deleting configmap..."
    kubectl delete -f 01-configmap.yaml --ignore-not-found=true
    print_success "ConfigMap deleted"

    print_info "Deleting namespace..."
    kubectl delete -f 00-namespace.yaml --ignore-not-found=true
    print_success "Namespace deleted"

    print_info "Waiting for namespace to be fully deleted..."
    kubectl wait --for=delete namespace/hms --timeout=120s 2>/dev/null || true
}

# Clean up hosts file
cleanup_hosts() {
    print_header "Cleaning /etc/hosts"

    if grep -q "hms.local" /etc/hosts; then
        print_info "Removing hms.local from /etc/hosts..."
        sudo sed -i.bak '/hms.local/d' /etc/hosts
        print_success "Removed hms.local from /etc/hosts"
    else
        print_info "hms.local not found in /etc/hosts"
    fi
}

# Show summary
show_summary() {
    print_header "Cleanup Complete"

    # Verify namespace is gone
    if kubectl get namespace hms &> /dev/null; then
        print_warning "HMS namespace still exists. It may take a few moments to fully delete."
        echo ""
        kubectl get all -n hms 2>/dev/null || true
    else
        print_success "All HMS resources have been deleted successfully!"
    fi

    echo ""
    print_info "Optional: To stop Minikube, run:"
    echo "  minikube stop"
    echo ""
    print_info "Optional: To delete the Minikube cluster completely, run:"
    echo "  minikube delete"
}

# Alternative: Delete entire namespace at once
quick_cleanup() {
    print_header "Quick Cleanup (Delete Namespace)"

    if kubectl get namespace hms &> /dev/null; then
        print_warning "This will delete the entire HMS namespace and all resources in it."
        read -p "Continue? (yes/no): " -r
        echo

        if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
            print_info "Deleting namespace hms..."
            kubectl delete namespace hms
            print_info "Waiting for namespace to be deleted..."
            kubectl wait --for=delete namespace/hms --timeout=300s 2>/dev/null || true
            print_success "Namespace deleted"
            cleanup_hosts
        else
            print_info "Quick cleanup cancelled"
            exit 0
        fi
    else
        print_info "HMS namespace does not exist"
    fi
}

# Main function
main() {
    # Check if quick mode
    if [[ "$1" == "--quick" || "$1" == "-q" ]]; then
        quick_cleanup
        show_summary
        exit 0
    fi

    # Normal cleanup
    confirm_cleanup
    cleanup_resources
    cleanup_hosts
    show_summary
}

# Handle script interruption
trap 'print_error "Cleanup interrupted!"; exit 1' INT TERM

# Show usage
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "HMS Kubernetes Cleanup Script"
    echo ""
    echo "Usage:"
    echo "  ./cleanup.sh          Normal cleanup (step by step)"
    echo "  ./cleanup.sh --quick  Quick cleanup (delete entire namespace)"
    echo "  ./cleanup.sh --help   Show this help message"
    echo ""
    exit 0
fi

# Run main function
main "$@"
