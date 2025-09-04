
# 🚀 Dynamic Reusable Kubernetes Cluster with Networking, Apps, and k8sGPT

## ⚡ TL;DR
A one-click, reusable Kubernetes deployment system powered by **Terraform + Kubernetes + GitHub Actions**, 
deploying **Node.js, NGINX, and k8sGPT apps** with built-in **security scans, safe deletions, and modular workflows**.

---

## 📖 Introduction
This repository provides a **production-ready Kubernetes automation framework** that combines 
Infrastructure-as-Code (IaC), container orchestration, and CI/CD pipelines into a single, reusable system.

The motivation behind this project:  
- Manual Kubernetes + cloud deployments are **slow and error-prone**.  
- Developers need **fast, isolated environments** for dev/test.  
- Enterprises demand **security, auditability, and governance**.  

By unifying **Terraform (infra)**, **Kubernetes (apps)**, and **GitHub Actions (automation)**, 
this system delivers a **repeatable, auditable, and secure pipeline** for end-to-end deployments.

---

## 🏗️ Architecture Overview

```text
 ┌───────────────────────────┐        ┌───────────────────────────┐
 │        Developer           │        │       GitHub Actions       │
 │ (Triggers Workflow Inputs) │        │  (CI/CD + Security Scans) │
 └─────────────┬─────────────┘        └──────────────┬────────────┘
               │                                      │
               ▼                                      ▼
      ┌────────────────┐                     ┌──────────────────────┐
      │   Terraform    │--------------------▶│ AWS Cloud Resources  │
      │ (Infra as Code)│   Provisions        │ VPC, EKS, Nodes, LB  │
      └────────────────┘                     └──────────────────────┘
               │                                      │
               ▼                                      ▼
      ┌───────────────────┐               ┌──────────────────────────┐
      │  Kubernetes (EKS) │◀──────────────│   Apps Deployment Layer  │
      │ Cluster + Nodes   │  kubectl/Helm │  Node.js, NGINX, k8sGPT  │
      └───────────────────┘               └──────────────────────────┘
```

---

## ⚙️ Detailed Features

### 🔹 Infrastructure Automation
- Provision AWS VPC, subnets, gateways, EKS cluster, node groups, and security groups.  
- Use environment-specific tfvars for **dev** and **test** clusters.  
- Support Terraform actions: `apply`, `destroy`, `refresh`.  

### 🔹 Application Deployment
- Deploy Node.js web app (custom Docker image).  
- Deploy NGINX server as a baseline service.  
- Deploy **k8sGPT** for cluster diagnostics with **Google** or **OpenAI** as AI backend.  
- All apps exposed via **LoadBalancer services**.  

### 🔹 Security Integration
- **Terraform Validate** checks for infra misconfigurations.  
- **Trivy Scans** container images for vulnerabilities.  
- RBAC applied in Kubernetes for least-privilege access.  
- GitHub Secrets securely store Docker and AWS credentials.  

### 🔹 Workflows
- **deploy-k8s.yml** → Security scan + infra provisioning + app deployments.  
- **delete-k8s-applications.yml** → Controlled deletion with `dry_run` + `confirm`.  
- Parameter-driven design allows infra-only, apps-only, scan-only, or full workflows.  

---

## 🛠️ Technology Stack

- **Terraform** – Infrastructure provisioning (AWS VPC, EKS, Nodes, Networking).  
- **Kubernetes (EKS)** – Container orchestration and workload scheduling.  
- **Docker** – Application containerization (Node.js app image).  
- **GitHub Actions** – CI/CD automation with parameterized workflows.  
- **Trivy** – Vulnerability scanning of container images.  
- **k8sGPT** – AI-powered Kubernetes diagnostics tool.  
- **AWS** – Cloud provider (networking + compute resources).  

---

## 🚦 Example Workflow Use Cases

### Case 1: Security Scan Only
Inputs: `run_security_scan=true`, others false → Runs Terraform validate + Trivy scan.  

### Case 2: Infra Provisioning Only
Inputs: `run_terraform=true`, `action=apply`, others false → Builds VPC + cluster, no apps.  

### Case 3: Apps Deployment Only
Inputs: `run_application_deployment=true`, others false → Deploys Node.js, NGINX, k8sGPT to existing cluster.  

### Case 4: Full Deployment
All flags true, `action=apply` → End-to-end infra + apps deployed in one run.  

### Case 5: Safe Deletion
Inputs: `apps_to_delete=nodejs-app`, `dry_run=false`, `confirm=true` → Deletes only Node.js app safely.  

---

## 👨‍💻 Contribution Guidelines

We welcome contributions to extend and improve this repository:  

- **Add New Applications** → Place Dockerfiles in `apps/` and manifests in `k8s/`.  
- **Enhance Infrastructure** → Add Terraform modules for scaling, monitoring, or networking.  
- **Improve CI/CD** → Extend workflows with caching, approvals, or reusable workflows.  
- **Documentation** → Expand `/Documents/` with guides, diagrams, or tutorials.  

Please fork, branch (`feature/...`), and submit PRs with detailed commit messages.  

---

## 🔮 Roadmap / Future Enhancements
 
- **Helm Support** → Parameterized, versioned app deployments.  
- **AI-Ops Monitoring** → Predictive alerts using AI models.  
- **Cost Monitoring** → Infracost integration in Terraform plans.  
- **Multi-Cloud Expansion** → Extend support to Azure and GCP.  

---

## 📑 Documentation Navigation

- [DOCUMENTATION.md](./Documents/DOCUMENTATION.md) – General overview  
- [DEPLOYMENT.md](./Documents/DEPLOYMENT.md) – Deployment workflows  
- [WORKFLOW_DETAILED.md](./Documents/WORKFLOW_DETAILED.md) – Detailed workflow explanation  
- [TERRAFORM_DETAILED.md](./Documents/TERRAFORM_DETAILED.md) – Terraform provisioning  
- [KUBERNETES_DETAILED.md](./Documents/KUBERNETES_DETAILED.md) – Kubernetes apps  
- [GITHUBACTIONS_DETAILED.md](./Documents/GITHUBACTIONS_DETAILED.md) – GitHub Actions CI/CD  
- [DELETE_WORKFLOW_DETAILED.md](./Documents/DELETE_WORKFLOW_DETAILED.md) – Safe app deletions  
- [BEST_PRACTICES.md](./Documents/BEST_PRACTICES.md) – Security, scalability, governance  
- [HANDBOOK.md](./Documents/HANDBOOK.md) – Combined all-in-one handbook  

Extras:  
- [HANDBOOK.html](./Documents/HANDBOOK.html) – Web version  
- [HANDBOOK_QUICKSTART.pdf](./Documents/HANDBOOK_QUICKSTART.pdf) – Quickstart summary  
- [HANDBOOK_CHEATSHEET.pdf](./Documents/HANDBOOK_CHEATSHEET.pdf) – 1-page cheatsheet  
- [HANDBOOK_CHEATSHEET_GRAPHICAL.pdf](./Documents/HANDBOOK_CHEATSHEET_GRAPHICAL.pdf) – Visual cheatsheet  
- [HANDBOOK_FULL_PRESENTATION.pptx](./Documents/HANDBOOK_FULL_PRESENTATION.pptx) – Technical deck  
- [HANDBOOK_EXECUTIVE_PRESENTATION.pptx](./Documents/HANDBOOK_EXECUTIVE_PRESENTATION.pptx) – Executive deck  

---

