# 📘 One-Click Kubernetes Deployment Documentation

This repository provides a **parameter-driven, one-click deployment and management system** for Kubernetes clusters and applications using **GitHub Actions** and **Terraform**.

---

## 📂 Repository Structure (Relevant Parts)

- `.github/workflows/deploy-k8s.yml` → Deployment workflow (Terraform + Apps)
- `.github/workflows/delete-k8s-applications.yml` → Controlled deletion workflow
- `terraform/` → Terraform IaC definitions (infrastructure, cluster, apps)
- `apps/` → Application sources (Node.js, NGINX, k8sgpt, etc.)
- `README.md` → Basic usage guide

---

## 🚀 Deployment Workflow (`deploy-k8s.yml`)

This workflow is the **core one-click deployment pipeline**.  
It is **manually triggered** (`workflow_dispatch`) and accepts multiple **parameters** for fine-grained control.

### 🔹 Parameters

1. **`environment`**
   - Target environment for deployment
   - Options: `dev`, `test`
   - Example: `dev` (default)

2. **`action`**
   - Terraform action to perform
   - Options:
     - `apply` → Deploy infrastructure and apps
     - `destroy` → Tear down resources
     - `refresh` → Refresh Terraform state
   - Example: `apply` (default)

3. **`provider`**
   - AI provider for `k8sgpt`
   - Options: `google`, `openai`
   - Example: `google` (default)

4. **`run_security_scan`**
   - Boolean flag to only run security scans
   - Default: `false`
   - Example: `true` → skips infra/app deployment, runs only scans

5. **`run_terraform`**
   - Boolean flag to run Terraform infra provisioning
   - Default: `false`
   - Example: `true` → provisions infra without app deployment

6. **`run_application_deployment`**
   - Boolean flag to deploy Kubernetes applications (Node.js, NGINX, k8sgpt, etc.)
   - Default: `false`
   - Example: `true` → deploys apps if infra already exists

---

### ⚙️ Workflow Jobs

1. **Security Scan** (conditional)  
   - Runs only if `run_security_scan=true`
   - Performs container scanning, IaC security scans

2. **Terraform Deployment** (conditional)  
   - Runs if `run_terraform=true`
   - Executes `terraform init`, `terraform <action>` (apply/destroy/refresh)

3. **Application Deployment** (conditional)  
   - Runs if `run_application_deployment=true`
   - Uses `kubectl` to apply YAML manifests for apps
   - Deploys:
     - Node.js App (via LoadBalancer)
     - NGINX
     - k8sGPT (with selected provider)

---

## 🗑️ Deletion Workflow (`delete-k8s-applications.yml`)

This workflow allows **selective deletion of deployed apps** from the cluster.  
It is **manually triggered** and requires confirmation for safety.

### 🔹 Parameters

1. **`environment`**
   - Target environment (`dev`, `test`)

2. **`dry_run`**
   - Boolean
   - Default: `true`
   - Simulates deletions without applying them

3. **`apps_to_delete`**
   - Comma-separated list of applications
   - Example: `nodejs-app,nginx,k8sgpt-openai`

4. **`confirm`**
   - Must be `true` to actually delete
   - Acts as a safety switch

---

### ⚙️ Workflow Logic

- Reads the `apps_to_delete` input
- If `dry_run=true` → prints what would be deleted
- If `confirm=true` → runs `kubectl delete` commands for the selected apps
- Safeguard ensures **no accidental deletion** unless both conditions are met

---

## ✅ Key Advantages

- **Granular control**: Deploy/destroy/refresh per environment
- **Parameter-driven**: No code changes needed for switching providers/apps
- **Safe deletion**: `dry_run` and `confirm` safeguard
- **Multi-provider AI**: Supports both `Google` and `OpenAI` for `k8sgpt`
- **One-click simplicity**: Entire cluster + apps in a single workflow run


---

## 🔎 Detailed Explanation of Deployment Workflow

### Step-by-Step

1. **Trigger Workflow**
   - Triggered manually via GitHub Actions `workflow_dispatch`
   - User selects environment, action, and flags

2. **Security Scan Step**
   - Runs if `run_security_scan=true`
   - Scans IaC (Terraform), Dockerfiles, container images
   - No infra or app changes applied

3. **Terraform Step**
   - Runs if `run_terraform=true`
   - Commands executed:
     - `terraform init` → Initializes providers and modules
     - `terraform plan` → Shows infra changes
     - `terraform apply -auto-approve` → Provisions infra when action=apply
     - `terraform refresh` → Updates state from cloud
     - `terraform destroy -auto-approve` → Tears down infra

4. **Application Deployment Step**
   - Runs if `run_application_deployment=true`
   - Requires cluster kubeconfig
   - Applies manifests with `kubectl apply`
   - Deploys:
     - Node.js app (Deployment + Service + LoadBalancer)
     - NGINX ingress/web server
     - k8sGPT with selected provider

5. **Completion**
   - Workflow ends
   - Apps accessible via public IPs

---

## 🔧 Variables Explained

### `environment`
- Defines which environment Terraform variables will load (dev/test)
- Maps to specific `.tfvars` files

### `action`
- Controls Terraform lifecycle
- `apply` = Create/update infra
- `destroy` = Delete infra
- `refresh` = Sync Terraform state

### `provider`
- Sets AI provider for k8sGPT
- Injected into manifests as ENV var or Helm value

### `run_security_scan`
- If true, workflow short-circuits after scans

### `run_terraform`
- If true, runs Terraform block

### `run_application_deployment`
- If true, runs Kubernetes manifests deploy

---

## 📑 Documentation Navigation

- [README.md](../README.md) – Root project overview  
- [DOCUMENTATION.md](./DOCUMENTATION.md) – General documentation and explanations  
- [DEPLOYMENT.md](./DEPLOYMENT.md) – Deployment workflow and parameter guide  
- [WORKFLOW_DETAILED.md](./WORKFLOW_DETAILED.md) – Detailed workflow explanation (~400 lines)  
- [TERRAFORM_DETAILED.md](./TERRAFORM_DETAILED.md) – Terraform provisioning deep dive (~400 lines)  
- [KUBERNETES_DETAILED.md](./KUBERNETES_DETAILED.md) – Kubernetes application deployment (~400 lines)  
- [GITHUBACTIONS_DETAILED.md](./GITHUBACTIONS_DETAILED.md) – GitHub Actions automation (~400 lines)  
- [DELETE_WORKFLOW_DETAILED.md](./DELETE_WORKFLOW_DETAILED.md) – Safe deletion workflow (~400 lines)  
- [BEST_PRACTICES.md](./BEST_PRACTICES.md) – Security, scalability, and governance (~400 lines)  
- [HANDBOOK.md](./HANDBOOK.md) – Combined handbook (all docs in one)  

🔗 Extras:  
- [HANDBOOK.html](./HANDBOOK.html) – Web-friendly version  
- [HANDBOOK_QUICKSTART.pdf](./HANDBOOK_QUICKSTART.pdf) – Quickstart summary (2–3 pages)  
- [HANDBOOK_CHEATSHEET.pdf](./HANDBOOK_CHEATSHEET.pdf) – 1-page cheatsheet  
- [HANDBOOK_CHEATSHEET_GRAPHICAL.pdf](./HANDBOOK_CHEATSHEET_GRAPHICAL.pdf) – Visual cheatsheet with diagram  
- [HANDBOOK_FULL_PRESENTATION.pptx](./HANDBOOK_FULL_PRESENTATION.pptx) – Technical slide deck  
- [HANDBOOK_EXECUTIVE_PRESENTATION.pptx](./HANDBOOK_EXECUTIVE_PRESENTATION.pptx) – Executive-friendly deck  

---
