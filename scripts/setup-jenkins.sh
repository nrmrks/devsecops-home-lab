#!/bin/bash

################################################################################
# Jenkins Container Setup Script
# 
# This script automates the setup of Jenkins in a Docker container for the
# DevSecOps home lab environment.
#
# Usage: ./setup-jenkins.sh
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
JENKINS_IMAGE="jenkins/jenkins:lts"
JENKINS_CONTAINER="jenkins"
JENKINS_PORT="8080"
JENKINS_AGENT_PORT="50000"
JENKINS_VOLUME="jenkins_home"

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

check_docker() {
    print_info "Checking Docker installation..."
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running. Please start Docker."
        exit 1
    fi
    
    print_success "Docker is installed and running"
    docker --version
}

check_existing_jenkins() {
    print_info "Checking for existing Jenkins container..."
    
    if docker ps -a | grep -q "$JENKINS_CONTAINER"; then
        print_warning "Jenkins container already exists"
        read -p "Do you want to remove it and start fresh? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Stopping and removing existing Jenkins container..."
            docker stop "$JENKINS_CONTAINER" 2>/dev/null || true
            docker rm "$JENKINS_CONTAINER" 2>/dev/null || true
            print_success "Existing container removed"
        else
            print_info "Keeping existing container. Exiting."
            exit 0
        fi
    fi
}

check_ports() {
    print_info "Checking if required ports are available..."
    
    if lsof -Pi :$JENKINS_PORT -sTCP:LISTEN -t >/dev/null 2>&1 || \
       ss -ltn | grep -q ":$JENKINS_PORT " 2>/dev/null; then
        print_error "Port $JENKINS_PORT is already in use"
        print_info "Process using port $JENKINS_PORT:"
        lsof -i :$JENKINS_PORT 2>/dev/null || ss -ltnp | grep ":$JENKINS_PORT "
        exit 1
    fi
    
    print_success "Ports are available"
}

pull_jenkins_image() {
    print_info "Pulling Jenkins Docker image..."
    if docker pull "$JENKINS_IMAGE"; then
        print_success "Jenkins image pulled successfully"
    else
        print_error "Failed to pull Jenkins image"
        exit 1
    fi
}

create_jenkins_volume() {
    print_info "Creating Jenkins volume..."
    if docker volume inspect "$JENKINS_VOLUME" &> /dev/null; then
        print_warning "Volume $JENKINS_VOLUME already exists"
    else
        docker volume create "$JENKINS_VOLUME"
        print_success "Volume created: $JENKINS_VOLUME"
    fi
}

start_jenkins_container() {
    print_info "Starting Jenkins container..."
    
    docker run -d \
        --name "$JENKINS_CONTAINER" \
        --restart unless-stopped \
        -p ${JENKINS_PORT}:8080 \
        -p ${JENKINS_AGENT_PORT}:50000 \
        -v ${JENKINS_VOLUME}:/var/jenkins_home \
        -v /var/run/docker.sock:/var/run/docker.sock \
        --user root \
        "$JENKINS_IMAGE"
    
    print_success "Jenkins container started"
}

configure_docker_permissions() {
    print_info "Configuring Docker permissions for Jenkins..."
    
    # Give Jenkins access to Docker socket
    docker exec -u root "$JENKINS_CONTAINER" chmod 666 /var/run/docker.sock || {
        print_warning "Could not set Docker socket permissions directly"
        print_info "You may need to run this manually later:"
        print_info "  docker exec -u root jenkins chmod 666 /var/run/docker.sock"
    }
    
    print_success "Docker permissions configured"
}

wait_for_jenkins() {
    print_info "Waiting for Jenkins to start..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker logs "$JENKINS_CONTAINER" 2>&1 | grep -q "Jenkins is fully up and running"; then
            print_success "Jenkins is ready!"
            return 0
        fi
        
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    echo
    print_warning "Jenkins startup took longer than expected"
    print_info "Check logs with: docker logs $JENKINS_CONTAINER"
    return 1
}

get_initial_password() {
    print_info "Retrieving initial admin password..."
    
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if password=$(docker exec "$JENKINS_CONTAINER" cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null); then
            echo
            echo "════════════════════════════════════════════════════════════════"
            echo -e "${GREEN}Jenkins Initial Admin Password:${NC}"
            echo
            echo -e "${YELLOW}$password${NC}"
            echo
            echo "════════════════════════════════════════════════════════════════"
            return 0
        fi
        
        sleep 2
        attempt=$((attempt + 1))
    done
    
    print_warning "Could not retrieve initial password yet"
    print_info "Try again later with: docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword"
    return 1
}

display_next_steps() {
    echo
    echo "════════════════════════════════════════════════════════════════"
    echo -e "${GREEN}Jenkins Setup Complete! 🚀${NC}"
    echo "════════════════════════════════════════════════════════════════"
    echo
    echo "Next Steps:"
    echo "1. Access Jenkins at: http://localhost:$JENKINS_PORT"
    echo "2. Use the initial admin password shown above"
    echo "3. Complete the setup wizard"
    echo "4. Install suggested plugins"
    echo "5. Create your first admin user"
    echo
    echo "Useful Commands:"
    echo "  View logs:           docker logs -f $JENKINS_CONTAINER"
    echo "  Stop Jenkins:        docker stop $JENKINS_CONTAINER"
    echo "  Start Jenkins:       docker start $JENKINS_CONTAINER"
    echo "  Restart Jenkins:     docker restart $JENKINS_CONTAINER"
    echo "  Remove Jenkins:      docker rm -f $JENKINS_CONTAINER"
    echo
    echo "For more help, see: docs/jenkins-setup.md"
    echo "════════════════════════════════════════════════════════════════"
    echo
}

# Main execution
main() {
    echo
    echo "════════════════════════════════════════════════════════════════"
    echo "  Jenkins Container Setup for DevSecOps Lab"
    echo "════════════════════════════════════════════════════════════════"
    echo
    
    check_docker
    check_existing_jenkins
    check_ports
    pull_jenkins_image
    create_jenkins_volume
    start_jenkins_container
    configure_docker_permissions
    wait_for_jenkins
    get_initial_password
    display_next_steps
}

# Run main function
main
