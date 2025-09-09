# 📖 Detailed Workflow Guide (Expanded Version, Extended to 400+ Lines)

## 1. Introduction

Modern software delivery pipelines demand **speed, reproducibility, and safety**.  
Traditional deployment methods often required **manual steps, long runbooks, and human oversight**, 
which increased the risk of misconfigurations, downtime, and security breaches.  

This repository exists to solve those problems by providing a **parameter-driven, one-click deployment workflow** that integrates:

- **Terraform** for infrastructure provisioning  
- **Kubernetes** for container orchestration  
- **GitHub Actions** for CI/CD automation  

With a **single GitHub Action trigger**, teams can:  
- Create or destroy environments,  
- Deploy or remove applications,  
- Run compliance/security scans,  
- Validate autoscaling behavior.  

This workflow reflects the **DevSecOps philosophy**: embedding security and compliance checks directly into the deployment pipeline 
while still giving teams **granular control** through parameters.

---

## 2. Repository Structure in Depth

A strong workflow begins with a well-structured repository. Below is the breakdown:

### `.github/workflows/deploy-k8s.yml`
- Central automation file.  
- Triggered manually (`workflow_dispatch`).  
- Defines inputs (parameters), environment variables, and jobs.  
- Conditional logic ensures jobs only run when enabled by parameters.  
- Controls **security scan jobs, Terraform provisioning jobs, and Kubernetes app deployments**.

### `.github/workflows/delete-k8s-applications.yml`
- Workflow for **safe deletion of Kubernetes apps**.  
- Uses `dry_run` and `confirm` flags for **safety-first deletion philosophy**.  
- Does not touch infrastructure.  

### `.github/workflows/hpa-fortio-stress-test.yml`
- Workflow for **HPA (Horizontal Pod Autoscaler) validation**.  
- Runs **Fortio-based stress tests** against services.  
- Observes scaling behavior of pods and cluster autoscaler responsiveness.  
- Outputs results in logs for performance analysis.

### `terraform/`
- Holds **Infrastructure-as-Code** (IaC) definitions.  
- Contains `.tf` and `.tfvars` files that define:  
  - Networking (VNets, subnets, security groups)  
  - Managed Kubernetes cluster (AKS)  
  - Node pools and autoscaling configuration  
  - Supporting services (ACR, Log Analytics, Load Balancers)  
- Enables parameterized environments (`dev.tfvars`, `test.tfvars`, etc.).  

### `apps/`
- Contains **application sources and Dockerfiles**.  
- Example applications:  
  - Node.js web application  
  - NGINX server  
  - k8sGPT diagnostic tool (AI-powered)  
- All apps are containerized and deployed with Kubernetes manifests.  
- Easily extensible with new applications.  

### Documentation Files
- `README.md`: Quick start guide.  
- `DOCUMENTATION.md`: General reference.  
- `DEPLOYMENT.md`: Parameter-case mappings + flowcharts.  
- `WORKFLOW_DETAILED.md`: This file, full workflow explanation (~400+ lines).  
- `BEST_PRACTICES.md`: Security, scalability, governance.  
- `HANDBOOK.md`: Combined single reference file.  

---

## 3. Workflow Lifecycle Overview

The one-click workflow can perform multiple roles, depending on **input parameters**:  

1. **Security Scan Phase**  
   - Static analysis of Terraform, Docker images, Kubernetes manifests.  
   - Runs only if `run_security_scan=true`.  
   - Stops early if no infra/app deployment requested.  

2. **Terraform Phase**  
   - Runs if `run_terraform=true`.  
   - Executes lifecycle actions: `apply`, `destroy`, or `refresh`.  
   - Responsible for creating/tearing down AKS, networking, and supporting resources.  

3. **Application Deployment Phase**  
   - Runs if `run_application_deployment=true`.  
   - Uses `kubectl` to deploy:  
     - Node.js app  
     - NGINX  
     - k8sGPT (provider switchable via parameter).  

4. **Optional HPA Stress Test Phase**  
   - Triggered via a separate workflow (`hpa-fortio-stress-test.yml`).  
   - Runs controlled load tests using Fortio.  
   - Observes HPA scaling behavior.  

This structure ensures **maximum flexibility**:  
- Scan-only jobs  
- Infra-only provisioning  
- Apps-only deployment  
- Full deployment (infra + apps)  
- Destruction workflows  
- Stress-testing workflows  

---

## 4. Security Scan Phase in Depth

Security scans ensure vulnerabilities are caught early.

### Why?
- IaC misconfigurations can open **network exposure risks**.  
- Container images may contain **outdated libraries**.  
- Kubernetes manifests may request **privileged pods**.  

### IaC Security Scan
Runs Terraform validation and static checks. Example:

```yaml
jobs:
  security-scan:
    if: ${{ github.event.inputs.run_security_scan == 'true' }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Terraform Static Analysis
        run: terraform validate
```

### Container Image Scan
Uses **Trivy** to detect CVEs:

```yaml
- name: Run Container Scan
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: myapp:latest
```

### Example Findings
- Terraform: “Security group allows 0.0.0.0/0 on port 22.”  
- Trivy: “Critical vulnerability in `openssl` library.”  

### Short-Circuit
If only scans requested → workflow ends here.

---

## 5. Terraform Phase in Depth

Terraform is used to **provision or destroy infrastructure**.

### Initialization
```yaml
- name: Terraform Init
  run: terraform init
```

### Planning
Shows intended actions before execution.

```yaml
- name: Terraform Plan
  run: terraform plan -var-file=environments/${{ github.event.inputs.environment }}.tfvars
```

### Apply
Provisions full stack.

```yaml
- name: Terraform Apply
  run: terraform apply -auto-approve -var-file=environments/${{ github.event.inputs.environment }}.tfvars
```

Creates:
- VNet + subnets  
- AKS cluster  
- Node pools (with autoscaling enabled)  
- ACR for images  
- Load balancers  
- Log Analytics workspace  

### Refresh
```yaml
terraform refresh -var-file=environments/dev.tfvars
```
Synchronizes state with real-world infra.

### Destroy
```yaml
terraform destroy -auto-approve -var-file=environments/dev.tfvars
```
Tears down resources.

### Authentication
Uses Azure Service Principal (`AZURE_CREDENTIALS`) stored in GitHub Secrets.

---

## 6. Application Deployment Phase in Depth

When enabled, apps are deployed using `kubectl`.

### Authentication
```bash
az aks get-credentials --name my-aks --resource-group rg-dev
```

### Deploy Node.js App
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nodejs-app
spec:
  replicas: 2
  template:
    metadata:
      labels: { app: nodejs }
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
  ports:
  - port: 3000
    targetPort: 3000
  selector:
    app: nodejs
```

### Deploy NGINX
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 2
  template:
    metadata:
      labels: { app: nginx }
    spec:
      containers:
      - name: nginx
        image: nginx:1.21.6
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: nginx
```

### Deploy k8sGPT
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: k8sgpt
spec:
  replicas: 1
  template:
    metadata:
      labels: { app: k8sgpt }
    spec:
      containers:
      - name: k8sgpt
        image: mydockerhub/k8sgpt:latest
        env:
        - name: PROVIDER
          value: "google"
        ports:
        - containerPort: 8080
```

Exposed via LoadBalancer service.

---

## 7. HPA Stress Test Workflow

The third workflow validates HPA.

### Trigger
Manual via GitHub UI with inputs like `qps=50`, `duration=120`.

### Steps
1. Azure login  
2. Set kubectl context  
3. Deploy Fortio pod/job  
4. Run load test  
5. Observe HPA scaling  
6. Collect results  
7. Cleanup  

### Benefits
- Validates scaling thresholds  
- Tests cluster autoscaler responsiveness  
- Ensures reliability before production  

---

## 8. Error Handling

- **Terraform Failures** → workflow stops.  
- **kubectl Failures** → manifest errors shown.  
- **Deletion** → requires explicit confirm.  
- **HPA Test Failures** → logs scaling issues.  

---

## 9. Case Studies

- **Scan Only**: `run_security_scan=true`.  
- **Infra Only**: `run_terraform=true, run_application_deployment=false`.  
- **Apps Only**: `run_application_deployment=true`.  
- **Full Deployment**: all enabled, action=apply.  
- **Destroy**: action=destroy.  
- **HPA Test**: third workflow.  

---

## 10. Best Practices Integration

- Use RBAC & network policies.  
- Separate namespaces (`dev`, `test`).  
- Monitor costs with Infracost.  
- Use GitOps with ArgoCD for drift detection.  
- Store secrets in GitHub Secrets.  

---

## 11. Conclusion

This repository provides a **comprehensive DevSecOps pipeline**.  
By combining Terraform, Kubernetes, and GitHub Actions, it delivers:  

- **Reproducible environments**  
- **Granular parameterized control**  
- **Built-in security scanning**  
- **Safe deletion guarantees**  
- **Performance validation workflows**  

This workflow is production-ready and extensible.  
It enables organizations to scale securely, efficiently, and responsibly.

---

## 📑 Documentation Navigation

- [README.md](../README.md) – Root overview  
- [DOCUMENTATION.md](./DOCUMENTATION.md) – General documentation  
- [DEPLOYMENT.md](./DEPLOYMENT.md) – Workflow guide  
- [WORKFLOW_DETAILED.md](./WORKFLOW_DETAILED.md) – This file (~400+ lines)  
- [TERRAFORM_DETAILED.md](./TERRAFORM_DETAILED.md) – Infra details  
- [KUBERNETES_DETAILED.md](./KUBERNETES_DETAILED.md) – App deployment  
- [GITHUBACTIONS_DETAILED.md](./GITHUBACTIONS_DETAILED.md) – Automation  
- [DELETE_WORKFLOW_DETAILED.md](./DELETE_WORKFLOW_DETAILED.md) – Safe deletion  
- [BEST_PRACTICES.md](./BEST_PRACTICES.md) – Best practices  
- [HANDBOOK.md](./HANDBOOK.md) – Combined doc  

---

---

## 11. Advanced Deployment Strategies

Modern Kubernetes workflows often need more than simple rolling updates. This repository can evolve to support advanced release strategies.

### 11.1 Blue/Green Deployments

Blue/Green deployments create two environments (Blue = live, Green = new).  
- Green environment is provisioned alongside Blue.  
- Traffic is switched from Blue to Green when validation passes.  
- Rollback is instant by redirecting traffic back to Blue.  

Example Service YAML using labels:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nodejs-service
spec:
  selector:
    app: nodejs
    track: blue  # or green
  ports:
  - port: 3000
    targetPort: 3000
```

Switching the `track` label shifts traffic instantly without downtime.

### 11.2 Canary Releases

Canary deployments release new versions to a small subset of users before full rollout.  
- Start with 10% traffic → monitor metrics.  
- Gradually increase to 50%, then 100%.  
- Rollback if errors spike.  

This reduces risk in production.

### 11.3 A/B Testing

Traffic splitting can also support A/B tests by routing traffic based on HTTP headers or cookies.  
This allows experimentation without impacting all users.

---

## 12. Multi-Environment Pipelines

This repository already supports `dev` and `test`, but can extend to `prod` with stricter guardrails.

### Example Environments

- **Dev** → ephemeral, spot nodes, minimal quotas.  
- **Test** → stable, used for QA, medium quotas.  
- **Prod** → HA, reserved nodes, environment approvals.  

### GitHub Actions Environment Protection

Use GitHub’s **environment protection rules**:  
- Require approvals before deploying to prod.  
- Restrict secrets (e.g., `AZURE_CREDENTIALS_PROD`) to production environment.  
- Use branch protection (only `main` can deploy to prod).  

---

## 13. Compliance and Policy Automation

Compliance is critical in regulated industries. This repo can integrate **policy as code**.

### Tools

- **OPA (Open Policy Agent)** → enforce manifest rules.  
- **Conftest** → validate Terraform IaC.  
- **Kyverno** → Kubernetes admission policies.  

### Example OPA Policy

```rego
package kubernetes.admission

deny[msg] {
  input.request.kind.kind == "Deployment"
  input.request.object.spec.template.spec.containers[_].image == "latest"
  msg = "Disallow 'latest' tags in production"
}
```

This blocks deploying containers with `:latest` image tags.

---

## 14. Observability and Monitoring

Scaling and troubleshooting require observability. Integrations include:

- **Prometheus + Grafana** → metrics, dashboards.  
- **ELK/EFK Stack** → logs.  
- **OpenTelemetry** → distributed tracing.  
- **Azure Monitor + Log Analytics** → native monitoring.  

### Example: Horizontal Pod Autoscaler Metrics

```bash
kubectl get hpa nodejs-app
NAME          REFERENCE            TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
nodejs-app    Deployment/nodejs    65%/60%   2         10        4          10m
```

Shows autoscaling in action.

---

## 15. CI/CD Integration

GitHub Actions integrates with CI/CD pipelines seamlessly.

### CI Jobs

- Linting (YAML, Terraform, Dockerfiles).  
- Unit tests for apps.  
- Security scans (Trivy, tfsec).  

### CD Jobs

- Terraform apply.  
- Kubernetes manifests apply.  
- Canary/Blue-Green rollout.  

CI ensures correctness, CD ensures safe rollout.

---

## 16. Future Enhancements

- **AI-Ops** → Predict pod failures before they occur.  
- **Predictive Scaling** → Scale based on ML-driven forecasts.  
- **Automated Cost Governance** → Use FinOps tools (Infracost + Azure Cost Management).  
- **GitOps Controllers** → FluxCD/ArgoCD for continuous reconciliation.  
- **Chaos Engineering** → Inject pod/node failures to test resilience.  

---

## 17. Final Thoughts

This expanded workflow demonstrates not only how to deploy infrastructure and applications, but how to:  
- Release safely with Blue/Green and Canary.  
- Enforce compliance with OPA/Kyverno.  
- Scale across environments with guardrails.  
- Monitor, trace, and troubleshoot effectively.  

By combining **Terraform, Kubernetes, GitHub Actions, and modern DevOps practices**, this repository evolves from a basic CI/CD system into a **cloud-native platform** that can serve production-grade workloads with confidence.

---

## 📑 Documentation Navigation

- [README.md](../README.md) – Root project overview  
- [DOCUMENTATION.md](./DOCUMENTATION.md) – General documentation and explanations  
- [DEPLOYMENT.md](./DEPLOYMENT.md) – Deployment workflow and parameter guide  
- [WORKFLOW_DETAILED.md](./WORKFLOW_DETAILED.md) – Detailed workflow explanation  
- [TERRAFORM_DETAILED.md](./TERRAFORM_DETAILED.md) – Terraform provisioning deep dive  
- [KUBERNETES_DETAILED.md](./KUBERNETES_DETAILED.md) – Kubernetes application deployment  
- [GITHUBACTIONS_DETAILED.md](./GITHUBACTIONS_DETAILED.md) – GitHub Actions automation  
- [DELETE_WORKFLOW_DETAILED.md](./DELETE_WORKFLOW_DETAILED.md) – Safe deletion workflow  
- [BEST_PRACTICES.md](./BEST_PRACTICES.md) – Security, scalability, and governance  
- [HANDBOOK.md](./HANDBOOK.md) – Combined handbook (all docs in one)  

🔗 Extras:  
- [HANDBOOK.html](./HANDBOOK.html) – Web-friendly version  
- [HANDBOOK_QUICKSTART.pdf](./HANDBOOK_QUICKSTART.pdf) – Quickstart summary (2–3 pages)  
- [HANDBOOK_CHEATSHEET.pdf](./HANDBOOK_CHEATSHEET.pdf) – 1-page cheatsheet  
- [HANDBOOK_CHEATSHEET_GRAPHICAL.pdf](./HANDBOOK_CHEATSHEET_GRAPHICAL.pdf) – Visual cheatsheet with diagram  
- [HANDBOOK_FULL_PRESENTATION.pptx](./HANDBOOK_FULL_PRESENTATION.pptx) – Technical slide deck  
- [HANDBOOK_EXECUTIVE_PRESENTATION.pptx](./HANDBOOK_EXECUTIVE_PRESENTATION.pptx) – Executive-friendly deck  

---