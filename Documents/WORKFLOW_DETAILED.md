
# 📖 Detailed Workflow Guide (Expanded Version)

## 1. Introduction

Modern software delivery pipelines demand speed, reproducibility, and safety. 
Traditional deployment methods often required manual steps, long runbooks, and human oversight, 
which increased the risk of misconfigurations, downtime, and security breaches. 
This repository exists to solve that problem by providing a **parameter-driven, one-click deployment workflow** 
that integrates Terraform for infrastructure, Kubernetes for application orchestration, and GitHub Actions for automation.

Instead of managing infrastructure provisioning and application deployment as two separate activities, 
this repository treats them as stages of the same workflow. With a single GitHub Action trigger, 
teams can create or destroy environments, deploy or remove applications, and even run security scans without touching any servers manually. 
This workflow reflects the DevSecOps philosophy: embedding security and compliance checks directly into the deployment pipeline 
while still giving teams granular control through parameters.

---

## 2. Repository Structure in Depth

Understanding the repository structure is key to appreciating how the workflow functions. 
Every folder and file has a purpose, and together they form the foundation of the one-click deployment system.

### `.github/workflows/deploy-k8s.yml`
This is the central automation file. It is a GitHub Actions workflow triggered manually via the `workflow_dispatch` event. 
Inside, it defines inputs (parameters), environment variables, and jobs for security scanning, Terraform provisioning, 
and Kubernetes application deployment. Conditional logic (`if:` statements) ensures that jobs only run when explicitly enabled by parameters.

### `.github/workflows/delete-k8s-applications.yml`
This workflow focuses on safe deletion of applications from the cluster. It is intentionally designed not to touch infrastructure. 
It includes a `dry_run` parameter that shows what would be deleted and a `confirm` parameter that ensures no accidental deletion happens.

### `terraform/`
This folder holds the Infrastructure-as-Code (IaC) definitions. It includes `.tf` files and `.tfvars` files that define cloud networking, 
Kubernetes cluster setup, node groups, and load balancers. By modifying tfvars, environments can be customized without changing code.

### `apps/`
This folder contains application source code and Dockerfiles. The included apps are:
- A Node.js web application,
- An NGINX server, and
- k8sGPT, a Kubernetes diagnostics tool that can be configured to use Google or OpenAI as a provider.

Each app is containerized and deployable to Kubernetes via manifests or Helm.

### Documentation Files
- `README.md`: Quick start and overview.  
- `DOCUMENTATION.md`: Reference-style documentation for parameters and workflows.  
- `DEPLOYMENT.md`: Case-based documentation with flowcharts.  
- `WORKFLOW_DETAILED.md`: This file, a book-length explanation of the workflow.  

---

## 3. Workflow Lifecycle Overview

The deployment lifecycle is parameter-driven. A single workflow can behave in multiple ways depending on the values chosen during execution.

1. **Security Scan Phase**  
   If enabled, this runs static analysis and vulnerability scans without touching infrastructure or applications.

2. **Terraform Phase**  
   If enabled, Terraform provisions infrastructure or tears it down depending on the action chosen (`apply`, `destroy`, `refresh`).

3. **Application Deployment Phase**  
   If enabled, Kubernetes manifests are applied to deploy the Node.js app, NGINX, and k8sGPT.

This lifecycle ensures flexibility: teams can run scans only, deploy infra only, deploy apps only, or perform full end-to-end deployment.

---

## 4. Security Scan Phase in Depth

Security scanning is a first-class citizen in this workflow. 
When the `run_security_scan` parameter is set to `true`, the workflow launches a dedicated job to analyze code and containers for risks.

### Why Security Scanning?
Security scans are essential because cloud infrastructure and container workloads are frequent targets of attacks. 
By scanning Terraform IaC files, Docker images, and Kubernetes manifests, the workflow catches misconfigurations or vulnerabilities before they reach production.

### Example of IaC Security Scan
```yaml
jobs:
  security-scan:
    if: ${{ github.event.inputs.run_security_scan == 'true' }}
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Repo
        uses: actions/checkout@v3

      - name: Run Terraform Static Analysis
        run: terraform validate

      - name: Run Container Scan
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: myapp:latest
```

### Example Output
A typical scan might highlight an outdated base image in a Dockerfile or an insecure setting in Terraform, such as an open security group. 
The workflow surfaces these findings directly in the GitHub Actions logs, making them visible to developers before any resources are touched.

### Short-Circuit Behavior
If `run_security_scan=true` and all other flags are false, the workflow terminates after scanning. 
This allows teams to run "scan-only" jobs as part of compliance audits without the risk of accidental deployments.

---

## 5. Terraform Phase in Depth

The Terraform phase is the backbone of infrastructure provisioning. When `run_terraform=true`, the workflow begins 
executing Terraform commands to either create, destroy, or refresh infrastructure depending on the chosen `action` parameter.

### Terraform Initialization

The workflow starts with `terraform init`. This downloads provider plugins (such as AWS), configures backends, 
and ensures the environment is ready for planning and applying.

```yaml
- name: Terraform Init
  run: terraform init
```

### Terraform Planning

If the action is `apply` or `destroy`, a `terraform plan` step is executed to show the changes that will happen. 
This plan acts as a safeguard, giving teams visibility before resources are created or destroyed.

```yaml
- name: Terraform Plan
  run: terraform plan -var-file=environments/${{ github.event.inputs.environment }}.tfvars
```

### Terraform Apply

When the action is `apply`, Terraform provisions the following resources:
- VPC and networking components,
- Subnets and routing tables,
- A managed Kubernetes cluster,
- Node pools,
- Load balancers for services.

```yaml
- name: Terraform Apply
  run: terraform apply -auto-approve -var-file=environments/${{ github.event.inputs.environment }}.tfvars
```

### Terraform Refresh

The `refresh` action updates Terraform state to reflect real-world resources without making changes. 
This is useful for detecting drift between Terraform state and actual infrastructure.

### Terraform Destroy

When `action=destroy`, Terraform tears down all provisioned resources. This ensures that developers can 
easily remove entire environments when they are no longer needed, optimizing costs.

```yaml
- name: Terraform Destroy
  run: terraform destroy -auto-approve -var-file=environments/${{ github.event.inputs.environment }}.tfvars
```

### Secrets and Authentication

Terraform requires cloud credentials. These are passed securely from GitHub Secrets:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

This avoids hardcoding credentials in the repo.

---

## 6. Application Deployment Phase in Depth

When `run_application_deployment=true`, the workflow connects to the cluster and applies Kubernetes manifests.

### Kubernetes Authentication

Terraform outputs a kubeconfig file. The workflow uses this to authenticate kubectl:

```yaml
- name: Configure kubectl
  run: aws eks update-kubeconfig --name mycluster --region us-east-1
```

### Deploying Node.js App

The Node.js application is deployed with a Deployment and Service manifest:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nodejs-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nodejs
  template:
    metadata:
      labels:
        app: nodejs
    spec:
      containers:
      - name: nodejs
        image: mydockerhub/nodejs-app:latest
        ports:
        - containerPort: 3000
---
apiVersion: v1
kind: Service
metadata:
  name: nodejs-service
spec:
  type: LoadBalancer
  selector:
    app: nodejs
  ports:
  - port: 3000
    targetPort: 3000
```

This exposes the Node.js app at `http://<lb-ip>:3000`.

### Deploying NGINX

NGINX is deployed similarly and exposed via a LoadBalancer on port 80. This can serve static content or act as a reverse proxy.

### Deploying k8sGPT

k8sGPT is deployed as a Kubernetes service. The `provider` parameter (google/openai) is passed as an environment variable:

```yaml
env:
- name: PROVIDER
  value: ${{ github.event.inputs.provider }}
```

This allows runtime switching of diagnostic providers.

---

## 7. End-to-End Deployment Case Studies

### Case: Full Deployment
Parameters:
- `environment=dev`
- `action=apply`
- `provider=google`
- `run_security_scan=false`
- `run_terraform=true`
- `run_application_deployment=true`

Flow:
1. Workflow starts, skips security scan.
2. Terraform provisions a dev cluster.
3. kubectl deploys Node.js, NGINX, and k8sGPT with Google provider.
4. Apps accessible via LoadBalancer IPs.

### Case: Scan Only
Parameters:
- `run_security_scan=true`
- all others false

Flow:
1. Workflow scans Terraform, Dockerfiles, and manifests.
2. Stops after reporting vulnerabilities.
3. No infra or apps are deployed.

### Case: Destroy
Parameters:
- `action=destroy`
- `run_terraform=true`

Flow:
1. Terraform tears down all infra.
2. Applications and load balancers are removed automatically.

---

## 8. Error Handling and Safety

Error handling is built in at every step.

- **Terraform Errors**: If tfvars are invalid or cloud quotas are exceeded, Terraform fails. Workflow halts.  
- **kubectl Errors**: If manifests are invalid, kubectl fails. Workflow halts before deploying further apps.  
- **Deletion Workflow Safety**: Requires both `dry_run=false` and `confirm=true` to actually delete apps.  
- **Short-Circuiting**: If a step fails, downstream steps are skipped.  

This ensures safety in production environments.

---

## 9. Security Philosophy

Security is embedded across the pipeline:

- **Shift Left**: Scans run before infra or apps are touched.  
- **Secrets Management**: Credentials stored in GitHub Secrets.  
- **Principle of Least Privilege**: Terraform credentials scoped narrowly.  
- **Safe Deletions**: Double confirmation needed.  

This philosophy ensures compliance with DevSecOps best practices.

---

## 10. Conclusion

The workflow in this repository represents a **modern, flexible, and safe approach** to Kubernetes deployments. 
It unifies infrastructure provisioning, application deployment, and security scanning into a single parameter-driven workflow. 
By leveraging Terraform, Kubernetes, and GitHub Actions together, it ensures reproducibility, auditability, and speed. 
Teams can confidently deploy, update, scan, or destroy environments with a single click, 
while maintaining guardrails against accidental misconfigurations or security oversights.

This document has explained the workflow in detail, from repository structure to case studies. 
In practice, the result is a system that reduces operational overhead, increases developer productivity, 
and strengthens the security posture of any organization using it.

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
