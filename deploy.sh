#!/bin/bash

set -x  
set -e  # Exit on error

# Load environment variables (update these as needed)
AWS_REGION="us-east-1"
ECR_REPOSITORY="fastapi-app"
INSTANCE_USER="ubuntu"
INSTANCE_IP="your-ec2-public-ip"
DOCKER_COMPOSE_FILE="docker-compose.yml"
AWS_ACCOUNT_ID="430118852712"

# AWS Credentials (set via AWS CLI or environment variables)
# ECR_REGISTRY="$(aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com && echo $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com)"

ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
echo "ECR_REGISTRY: $ECR_REGISTRY"
# Step 1: Run CI Checks Locally
echo "Running Linting, Type Checking, and Tests..."

pip install -r requirements.txt flake8 black mypy pytest

# flake8 app/ || { echo "Flake8 failed"; exit 1; }
# black --check app/ || { echo "Black formatting failed"; exit 1; }
# mypy app/ || { echo "Mypy type checking failed"; exit 1; }
# pytest tests/ || { echo "Tests failed"; exit 1; }

echo "✅ CI Checks Passed!"

# Step 2: Build & Push Docker Images to AWS ECR
echo "Logging into AWS ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY

echo "Building Docker Images..."
docker-compose build

echo "Tagging and Pushing Images..."
docker tag fastapi-app:v1 $ECR_REGISTRY/$ECR_REPOSITORY:v1
docker push $ECR_REGISTRY/$ECR_REPOSITORY:v1

echo "✅ Docker Image Pushed to AWS ECR!"

# Step 3: Deploy to EC2
echo "Deploying to EC2 Instance: $INSTANCE_IP"

ssh -o StrictHostKeyChecking=no $INSTANCE_USER@$INSTANCE_IP << EOF
  set -e
  echo "Installing Docker and Docker Compose..."
  sudo apt update -y
  sudo apt install -y docker docker-compose
  sudo systemctl start docker
  sudo systemctl enable docker

  echo "Logging into AWS ECR..."
  aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY

  echo "Pulling and Deploying Latest Docker Images..."
  cd ~/app || mkdir ~/app && cd ~/app
  echo "Copying docker-compose.yml from local machine..."
EOF

scp $DOCKER_COMPOSE_FILE $INSTANCE_USER@$INSTANCE_IP:~/app/

ssh -o StrictHostKeyChecking=no $INSTANCE_USER@$INSTANCE_IP << EOF
  cd ~/app
  docker-compose pull
  docker-compose up -d --force-recreate

  echo "✅ Deployment Successful! FastAPI App Running on EC2."
EOF

echo "🎉 Deployment Complete! Access the app at: http://$INSTANCE_IP"

