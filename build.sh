#!/bin/bash

# Variables
cluster_name="finalproject-ivolve-cluster" # If you wanna change the cluster name make sure you change it in the terraform directory variables.tf (name_prefix & environment)
region="eu-central-1"
aws_id="140592727911"
repo_name="finalproject-ivolve-repo" # If you wanna change the repository name make sure you change it in the k8s/app.yml (Image name) 
image_name="$aws_id.dkr.ecr.$region.amazonaws.com/$repo_name:latest"

namespace="ivolve" # you can keep this variable or if you will change it remember to change the namespace in k8 manifests inside k8s directory
# End of Variables


# build the infrastructure
echo "--------------------Creating EKS--------------------"
echo "--------------------Creating ECR--------------------"

cd terraform && \ 
terraform init
terraform apply -auto-approve
cd ..

# update kubeconfig
echo "--------------------Update Kubeconfig--------------------"
aws eks update-kubeconfig --name $cluster_name --region $region

# remove preious docker images
echo "--------------------Remove Previous build--------------------"
docker rmi -f $image_name || true

# build new docker image with new tag
echo "--------------------Build new Image--------------------"
docker build -t $image_name ./App 

#ECR Login
echo "--------------------Login to ECR--------------------"
aws ecr get-login-password --region $region | docker login --username AWS --password-stdin $aws_id.dkr.ecr.$region.amazonaws.com

# push the latest build to dockerhub
echo "--------------------Pushing Docker Image--------------------"
docker push $image_name

# create namespace
echo "--------------------creating Namespace--------------------"
kubectl create ns $namespace || true

# deploy app
echo "--------------------Deploy App--------------------"
cd manifests
cd kubernetes 
kubectl apply -n $namespace -f deployment.yml
kubectl apply -n $namespace -f service.yml

# Wait for application to be deployed
echo "--------------------Wait for all pods to be running--------------------"
sleep 60s

# Get service URL
echo "--------------------service URL--------------------"
kubectl get service 


