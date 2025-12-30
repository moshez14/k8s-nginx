# 1. Authenticate ECR
sudo aws ecr get-login-password --region eu-west-1 | sudo docker login --username AWS --password-stdin 297053566157.dkr.ecr.eu-west-1.amazonaws.com

# 2. Build image without cache
sudo docker build --no-cache -t nginx:1.0.3 .

# 3. Tag for ECR
sudo docker tag nginx:1.0.3 297053566157.dkr.ecr.eu-west-1.amazonaws.com/maifocus-rep:nginx-1.0.4

# 4. Push
sudo docker push 297053566157.dkr.ecr.eu-west-1.amazonaws.com/maifocus-rep:nginx-1.0.4

# 5. Apply Kubernetes deployment
#kubectl apply -f nginx-deployment.yaml
#kubectl rollout restart deployment nginx -n maifocus-ns-prod

