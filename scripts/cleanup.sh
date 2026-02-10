#!/bin/bash

################################################################################
# Cleanup Script for DevSecOps Lab
#
# This script helps clean up the DevSecOps lab environment by stopping
# containers, removing images, and resetting the environment.
#
# Usage: ./cleanup.sh [OPTIONS]
#   Options:
#     --all        : Remove everything (containers, images, volumes)
#     --containers : Remove only containers
#     --images     : Remove only images
#     --volumes    : Remove only volumes
#     --help       : Show help message
################################################################################

set -e  # Exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
JENKINS_CONTAINER="jenkins"
APP_CONTAINER="my-test-app"
IMAGE_PREFIX="devsecops"

# Functions
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

show_help() {
    cat << EOF
DevSecOps Lab Cleanup Script

Usage: ./cleanup.sh [OPTIONS]

Options:
  --all         Clean up everything (containers, images, volumes)
  --containers  Stop and remove containers only
  --images      Remove Docker images only
  --volumes     Remove Docker volumes only
  --jenkins     Stop and remove Jenkins container only
  --app         Stop and remove application container only
  --help        Show this help message

Examples:
  ./cleanup.sh --all          # Full cleanup
  ./cleanup.sh --jenkins      # Remove only Jenkins
  ./cleanup.sh --containers   # Remove all containers
  
EOF
}

confirm_action() {
    local message=$1
    read -p "$(echo -e ${YELLOW}[CONFIRM]${NC} $message '(y/N): ')" -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

stop_containers() {
    print_info "Stopping containers..."
    
    local containers=()
    
    # Check for Jenkins container
    if docker ps -q -f name="$JENKINS_CONTAINER" | grep -q .; then
        containers+=("$JENKINS_CONTAINER")
    fi
    
    # Check for app container
    if docker ps -q -f name="$APP_CONTAINER" | grep -q .; then
        containers+=("$APP_CONTAINER")
    fi
    
    # Check for any other devsecops containers
    while IFS= read -r container; do
        if [[ ! " ${containers[@]} " =~ " ${container} " ]]; then
            containers+=("$container")
        fi
    done < <(docker ps --format '{{.Names}}' | grep -i "devsecops\|$IMAGE_PREFIX" || true)
    
    if [ ${#containers[@]} -eq 0 ]; then
        print_warning "No running containers to stop"
        return
    fi
    
    for container in "${containers[@]}"; do
        print_info "Stopping container: $container"
        docker stop "$container" || print_warning "Could not stop $container"
    done
    
    print_success "Containers stopped"
}

remove_containers() {
    print_info "Removing containers..."
    
    # Remove specific containers
    for container in "$JENKINS_CONTAINER" "$APP_CONTAINER"; do
        if docker ps -a -q -f name="$container" | grep -q .; then
            print_info "Removing container: $container"
            docker rm -f "$container" || print_warning "Could not remove $container"
        fi
    done
    
    # Remove any other devsecops-related containers
    while IFS= read -r container; do
        print_info "Removing container: $container"
        docker rm -f "$container" || print_warning "Could not remove $container"
    done < <(docker ps -a --format '{{.Names}}' | grep -i "devsecops\|$IMAGE_PREFIX" || true)
    
    print_success "Containers removed"
}

remove_images() {
    print_info "Removing Docker images..."
    
    # Find and remove images
    local images=$(docker images --format '{{.Repository}}:{{.Tag}}' | grep -i "$IMAGE_PREFIX" || true)
    
    if [ -z "$images" ]; then
        print_warning "No DevSecOps images found to remove"
        return
    fi
    
    echo "$images" | while read -r image; do
        print_info "Removing image: $image"
        docker rmi -f "$image" || print_warning "Could not remove $image"
    done
    
    # Prune dangling images
    print_info "Removing dangling images..."
    docker image prune -f
    
    print_success "Images removed"
}

remove_volumes() {
    print_info "Removing Docker volumes..."
    
    # Remove Jenkins volume
    if docker volume ls -q -f name="jenkins_home" | grep -q .; then
        if confirm_action "Remove Jenkins volume (this will delete all Jenkins data)?"; then
            print_info "Removing jenkins_home volume..."
            docker volume rm jenkins_home || print_warning "Could not remove jenkins_home volume"
        else
            print_info "Keeping jenkins_home volume"
        fi
    fi
    
    # Remove other related volumes
    while IFS= read -r volume; do
        print_info "Found volume: $volume"
        if confirm_action "Remove volume $volume?"; then
            docker volume rm "$volume" || print_warning "Could not remove $volume"
        fi
    done < <(docker volume ls --format '{{.Name}}' | grep -i "devsecops\|prometheus\|grafana" || true)
    
    # Prune unused volumes
    print_info "Pruning unused volumes..."
    docker volume prune -f
    
    print_success "Volumes cleaned up"
}

cleanup_workspace() {
    print_info "Cleaning up workspace..."
    
    # Remove any temporary files in the repo
    if [ -d "tmp" ]; then
        rm -rf tmp
        print_info "Removed tmp directory"
    fi
    
    # Clean npm cache in app directory if it exists
    if [ -d "apps/nodejs-app/node_modules" ]; then
        if confirm_action "Remove node_modules directory?"; then
            rm -rf apps/nodejs-app/node_modules
            print_info "Removed node_modules"
        fi
    fi
    
    print_success "Workspace cleaned"
}

docker_system_cleanup() {
    print_info "Running Docker system cleanup..."
    
    if confirm_action "Run Docker system prune (removes unused data)?"; then
        docker system prune -f
        print_success "Docker system pruned"
    fi
}

show_status() {
    echo
    echo "════════════════════════════════════════════════════════════════"
    echo "  Current Docker Status"
    echo "════════════════════════════════════════════════════════════════"
    
    echo
    echo "Running Containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" || echo "None"
    
    echo
    echo "Docker Images:"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep -E "REPOSITORY|$IMAGE_PREFIX|jenkins" || echo "None"
    
    echo
    echo "Docker Volumes:"
    docker volume ls --format "table {{.Name}}\t{{.Driver}}" | grep -E "NAME|jenkins|devsecops|prometheus|grafana" || echo "None"
    
    echo
    echo "Disk Usage:"
    docker system df
    
    echo "════════════════════════════════════════════════════════════════"
    echo
}

cleanup_jenkins_only() {
    print_info "Cleaning up Jenkins only..."
    
    if docker ps -a -q -f name="$JENKINS_CONTAINER" | grep -q .; then
        print_info "Stopping and removing Jenkins container..."
        docker stop "$JENKINS_CONTAINER" 2>/dev/null || true
        docker rm "$JENKINS_CONTAINER" 2>/dev/null || true
        print_success "Jenkins container removed"
    else
        print_warning "Jenkins container not found"
    fi
}

cleanup_app_only() {
    print_info "Cleaning up application only..."
    
    if docker ps -a -q -f name="$APP_CONTAINER" | grep -q .; then
        print_info "Stopping and removing application container..."
        docker stop "$APP_CONTAINER" 2>/dev/null || true
        docker rm "$APP_CONTAINER" 2>/dev/null || true
        print_success "Application container removed"
    else
        print_warning "Application container not found"
    fi
    
    # Also remove application images
    local app_images=$(docker images --format '{{.Repository}}:{{.Tag}}' | grep "$IMAGE_PREFIX-test" || true)
    if [ -n "$app_images" ]; then
        echo "$app_images" | while read -r image; do
            docker rmi -f "$image" || true
        done
    fi
}

full_cleanup() {
    echo
    echo "════════════════════════════════════════════════════════════════"
    echo "  Full DevSecOps Lab Cleanup"
    echo "════════════════════════════════════════════════════════════════"
    echo
    
    if ! confirm_action "This will remove ALL containers, images, and volumes. Continue?"; then
        print_info "Cleanup cancelled"
        exit 0
    fi
    
    stop_containers
    remove_containers
    remove_images
    remove_volumes
    cleanup_workspace
    docker_system_cleanup
    
    echo
    print_success "Full cleanup completed! 🧹"
    echo
    
    show_status
}

# Main execution
main() {
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi
    
    case "$1" in
        --all)
            full_cleanup
            ;;
        --containers)
            stop_containers
            remove_containers
            show_status
            ;;
        --images)
            remove_images
            show_status
            ;;
        --volumes)
            remove_volumes
            show_status
            ;;
        --jenkins)
            cleanup_jenkins_only
            show_status
            ;;
        --app)
            cleanup_app_only
            show_status
            ;;
        --help|-h)
            show_help
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main
main "$@"
