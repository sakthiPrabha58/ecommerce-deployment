# CloudForge — End-to-End CI/CD Pipeline for Microservices on AWS EKS

A hands-on DevOps project that provisions AWS infrastructure with **Terraform**, configures it with
**Ansible**, and runs a full **Jenkins** pipeline that builds a two-service app with **Docker**, scans it
with **SonarQube**, stores images in **Nexus**, and deploys to **Kubernetes (EKS)** — all tracked in **Git**.

## Architecture

```
Developer → Git push
     │
     ▼
Jenkins (webhook trigger)
     │
     ├─ Unit tests (pytest)
     ├─ SonarQube static analysis + Quality Gate
     ├─ Docker build (frontend + backend images)
     ├─ Push images → Nexus Repository (private registry)
     └─ kubectl/helm deploy → AWS EKS
                                   │
                                   ▼
                     Frontend (nginx) ⇄ Backend (Flask API)
                     (namespace: cloudforge, behind ALB Ingress)
```

Terraform provisions: VPC, subnets, NAT gateway, EKS cluster + node group, and three EC2 instances
(Jenkins, SonarQube, Nexus). Ansible then installs and configures the software on those EC2 boxes.

## Folder structure

```
CloudForge/
├── terraform/          # AWS infra: VPC, EKS, EC2 for Jenkins/Nexus/SonarQube
├── ansible/             # Configures the EC2 tool servers
│   ├── inventory.ini
│   ├── site.yml
│   ├── playbook-jenkins.yml
│   ├── playbook-sonarqube.yml
│   ├── playbook-nexus.yml
│   └── roles/{docker,jenkins,sonarqube,nexus}/tasks/main.yml
├── app/
│   ├── backend/         # Flask API + Dockerfile + pytest tests
│   └── frontend/        # Static site + nginx + Dockerfile
├── k8s/                  # Kubernetes manifests (Deployments, Services, Ingress, HPA)
├── jenkins/
│   └── Jenkinsfile       # The pipeline-as-code
└── sonar-project.properties
```

## Build order (do this once, top to bottom)

1. **Git**: push this whole repo to GitHub/GitLab — Jenkins and your teammates pull from here.
2. **Terraform**: provision the infrastructure.
   ```bash
   cd terraform
   terraform init
   terraform plan
   terraform apply
   ```
   Grab the outputs (`jenkins_public_ip`, `sonarqube_public_ip`, `nexus_public_ip`, `eks_cluster_name`).
3. **Ansible**: configure the three EC2 boxes.
   ```bash
   cd ../ansible
   # replace the placeholder IPs in inventory.ini with the Terraform outputs
   ansible-playbook -i inventory.ini site.yml
   ```
4. **SonarQube** (`http://<sonarqube_public_ip>:9000`, default login admin/admin):
   create a project token, generate a webhook back to Jenkins.
5. **Nexus** (`http://<nexus_public_ip>:8081`): create a `docker-hosted` repository, grab admin
   password from `/nexus-data/admin.password` inside the container.
6. **Jenkins** (`http://<jenkins_public_ip>:8080`):
   - Install plugins: Docker Pipeline, SonarQube Scanner, Kubernetes CLI, AWS Credentials.
   - Add credentials: `nexus-creds` (Nexus username/password), AWS credentials for `aws eks update-kubeconfig`.
   - Configure the SonarQube server under *Manage Jenkins → System* with the name used in the Jenkinsfile.
   - Create a Pipeline job pointing at this repo's `jenkins/Jenkinsfile`.
   - Update the placeholders in `Jenkinsfile` (`<NEXUS_PUBLIC_IP>`, git URL) with your real values.
7. Push a code change → Jenkins webhook fires → pipeline runs end-to-end → app is live on EKS behind the ALB.

## What each tool is doing (quick reference)

| Tool | Role in this project |
|---|---|
| **Git** | Source of truth for app code + all IaC |
| **Terraform** | Provisions VPC, EKS cluster/nodes, EC2 hosts for Jenkins/Nexus/SonarQube |
| **Ansible** | Installs Docker, Jenkins, and runs SonarQube/Nexus as containers on those EC2 hosts |
| **Jenkins** | Orchestrates the pipeline: test → scan → build → push → deploy |
| **SonarQube** | Static analysis + Quality Gate that can block bad code from deploying |
| **Docker** | Packages frontend and backend into images |
| **Nexus** | Private Docker registry storing versioned images |
| **Kubernetes (EKS)** | Runs the deployed app: Deployments, Services, Ingress, HPA |
| **AWS** | The cloud platform underpinning everything (EKS, EC2, VPC, IAM, ALB) |

## Local testing (before touching AWS)

```bash
# Backend
cd app/backend
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt pytest
pytest

docker build -t cloudforge-backend .
docker run -p 5000:5000 cloudforge-backend

# Frontend
cd ../frontend
docker build -t cloudforge-frontend .
docker run -p 8080:80 cloudforge-frontend
```

## Next steps / stretch goals

- Add **Prometheus + Grafana** for cluster and app monitoring.
- Swap the manual `kubectl apply` stage for **ArgoCD** (GitOps).
- Add **Trivy** image scanning before the push-to-Nexus stage.
- Add Slack/email notification steps in the Jenkinsfile `post` block.
- Split Terraform into modules (`modules/vpc`, `modules/eks`, `modules/ec2`) as the project grows.

## Notes

- All placeholder values (`<NEXUS_PUBLIC_IP>`, `<your-username>`, key pair name, S3 bucket name for
  Terraform backend) need to be replaced with your actual values before running anything.
- Default SonarQube/Nexus/Jenkins credentials should be changed immediately after first login.
