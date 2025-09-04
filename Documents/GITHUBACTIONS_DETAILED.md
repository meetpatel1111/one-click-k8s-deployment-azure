
# ⚙️ GitHub Actions Detailed Guide (Expanded Version)

## 1. Introduction

GitHub Actions is the automation backbone of this repository. It provides the continuous integration and delivery (CI/CD) 
engine that ties together Terraform and Kubernetes into a single, parameter-driven pipeline. Without GitHub Actions, 
developers would need to run Terraform and kubectl commands locally, which is inconsistent and prone to human error.

By embedding automation into workflows, the repository achieves:
- **Reproducibility**: The same workflow runs identically every time.  
- **Auditability**: Every workflow run is logged and linked to the commit that triggered it.  
- **Safety**: Parameters, conditionals, and secrets ensure safe operations.  
- **Flexibility**: A single workflow supports multiple use cases (scan, infra only, apps only, full deploy).  

---

## 2. Anatomy of a GitHub Actions Workflow

A workflow is a YAML file stored in `.github/workflows/`. It consists of:

- **Triggers**: Define when the workflow runs (manual, push, pull request, schedule).  
- **Jobs**: Logical groups of steps that run on virtual machines.  
- **Steps**: Individual commands or reusable actions executed sequentially.  
- **Conditionals**: `if:` expressions that control when jobs or steps run.  
- **Secrets and Variables**: Injected at runtime for authentication or configuration.  

### Example Structure

```yaml
name: Deploy K8s

on:
  workflow_dispatch:
    inputs:
      environment:
        description: "Target environment"
        required: true
        default: "dev"
      action:
        description: "Terraform action (apply/destroy/refresh)"
        required: true
        default: "apply"
      run_security_scan:
        description: "Run security scan?"
        required: true
        default: "false"
```

This snippet shows how the workflow is parameterized with `workflow_dispatch` inputs, enabling manual control.

---

## 3. deploy-k8s.yml Deep Dive

The `deploy-k8s.yml` workflow is the heart of the automation. It is designed to run in different modes depending on user input.

### Workflow Inputs

- **environment**: Chooses environment (dev/test).  
- **action**: Chooses Terraform lifecycle action (apply/destroy/refresh).  
- **provider**: Chooses AI provider for k8sGPT (google/openai).  
- **run_security_scan**: Boolean to run security scans.  
- **run_terraform**: Boolean to enable Terraform provisioning.  
- **run_application_deployment**: Boolean to enable Kubernetes application deployment.  

These inputs allow one workflow to serve many purposes.

---

### Security Scan Job

This job runs only when `run_security_scan=true`. It validates Terraform and scans container images for vulnerabilities.

```yaml
jobs:
  security-scan:
    if: ${{ github.event.inputs.run_security_scan == 'true' }}
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v3

      - name: Terraform Validate
        run: terraform validate

      - name: Container Scan
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: myapp:latest
```

This ensures issues are caught early before infrastructure or apps are deployed.

---

### Terraform Job

The Terraform job is conditional on `run_terraform=true`. It executes `init`, `plan`, and then the action (`apply`, `destroy`, `refresh`).

```yaml
jobs:
  terraform:
    if: ${{ github.event.inputs.run_terraform == 'true' }}
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2

      - name: Terraform Init
        run: terraform init

      - name: Terraform Plan
        run: terraform plan -var-file=environments/${{ github.event.inputs.environment }}.tfvars

      - name: Terraform Apply
        if: ${{ github.event.inputs.action == 'apply' }}
        run: terraform apply -auto-approve -var-file=environments/${{ github.event.inputs.environment }}.tfvars

      - name: Terraform Destroy
        if: ${{ github.event.inputs.action == 'destroy' }}
        run: terraform destroy -auto-approve -var-file=environments/${{ github.event.inputs.environment }}.tfvars

      - name: Terraform Refresh
        if: ${{ github.event.inputs.action == 'refresh' }}
        run: terraform refresh -var-file=environments/${{ github.event.inputs.environment }}.tfvars
```

The job ensures reproducibility and safety by always running `init` and `plan` before applying or destroying.

---

### Application Deployment Job

This job runs when `run_application_deployment=true`. It configures kubectl and applies manifests for the apps.

```yaml
jobs:
  deploy-apps:
    if: ${{ github.event.inputs.run_application_deployment == 'true' }}
    runs-on: ubuntu-latest
    steps:
      - name: Configure kubectl
        run: aws eks update-kubeconfig --name mycluster --region us-east-1

      - name: Deploy Node.js App
        run: kubectl apply -f k8s/nodejs.yaml

      - name: Deploy NGINX
        run: kubectl apply -f k8s/nginx.yaml

      - name: Deploy k8sGPT
        run: kubectl apply -f k8s/k8sgpt-${{ github.event.inputs.provider }}.yaml
```

This step ties everything together by deploying apps after infra is ready.

---

## 4. delete-k8s-applications.yml Deep Dive

The `delete-k8s-applications.yml` workflow is a complementary workflow focused on safe application removal. 
Unlike the deployment workflow, it does not touch infrastructure. Its goal is to delete specific Kubernetes applications on demand.

### Workflow Inputs

- **environment**: Target environment (dev/test).  
- **apps_to_delete**: Comma-separated list of apps (e.g., `nodejs-app,nginx,k8sgpt`).  
- **dry_run**: If true, lists what would be deleted without performing deletion.  
- **confirm**: Must be explicitly set to true to allow deletion.  

### Safety Mechanisms

The workflow requires both `dry_run=false` and `confirm=true` to proceed with deletion. 
This two-step safeguard prevents accidental removal of critical workloads.

### Example Workflow Section

```yaml
jobs:
  delete:
    runs-on: ubuntu-latest
    steps:
      - name: Configure kubectl
        run: aws eks update-kubeconfig --name mycluster --region us-east-1

      - name: Dry Run
        if: ${{ github.event.inputs.dry_run == 'true' }}
        run: echo "Would delete apps: ${{ github.event.inputs.apps_to_delete }}"

      - name: Confirm and Delete
        if: ${{ github.event.inputs.dry_run == 'false' && github.event.inputs.confirm == 'true' }}
        run: |
          for app in $(echo "${{ github.event.inputs.apps_to_delete }}" | tr ',' ' '); do
            kubectl delete deployment $app || true
            kubectl delete service $app || true
          done
```

---

## 5. Secrets Management in GitHub Actions

Secrets are critical to secure workflows. This repository uses GitHub Secrets for:

- **AWS_ACCESS_KEY_ID** and **AWS_SECRET_ACCESS_KEY**: For Terraform and kubectl authentication.  
- **DOCKER_USERNAME** and **DOCKER_PASSWORD**: For pulling/pushing images.  

Secrets are injected into workflow environments at runtime and masked in logs. Example:

```yaml
env:
  AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
  AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

By centralizing secrets in GitHub, they are versioned, auditable, and protected from accidental leaks.

---

## 6. Conditionals and Parameter-Driven Design

A unique feature of these workflows is conditional execution. Jobs run only if their associated flags are set. 
This makes the pipeline flexible and efficient.

### Example Conditional

```yaml
if: ${{ github.event.inputs.run_application_deployment == 'true' }}
```

This ensures the deployment job is skipped unless explicitly requested.

### Benefits of Conditional Design

- Saves compute time and costs.  
- Reduces risk by skipping unnecessary jobs.  
- Allows one workflow to serve multiple purposes.  

---

## 7. Error Handling and Retry Strategies

Workflows fail-fast by default. If Terraform or kubectl encounters an error, the job halts, preventing downstream steps from running.

### Error Handling Practices

- **Terraform**: Errors logged with detailed messages (e.g., invalid tfvars, quota exceeded).  
- **kubectl**: Errors show pod status and events. Developers can re-run with corrected manifests.  
- **Deletion**: Uses `|| true` to avoid breaking if an app is already absent.  

### Retry Strategies

- Rerun failed workflows directly from the GitHub UI.  
- Use `continue-on-error: true` in non-critical steps (e.g., logging).  
- Implement retries with third-party actions if needed.  

---

## 8. Reusability and Optimization

### Reusable Actions

The workflows use both official actions (checkout, setup-terraform) and third-party actions (Trivy scan). 
These can be replaced or extended with custom composite actions.

### Matrix Strategy

Workflows can be extended with matrices to deploy multiple environments in parallel. Example:

```yaml
strategy:
  matrix:
    environment: [dev, test]
```

### Caching

To optimize performance, Terraform plugin directories or Docker layers can be cached between runs. Example:

```yaml
- name: Cache Terraform Plugins
  uses: actions/cache@v3
  with:
    path: ~/.terraform.d/plugin-cache
    key: ${{ runner.os }}-terraform-${{ hashFiles('**/*.tf') }}
```

---

## 9. Best Practices for GitHub Actions

- **Use Environment Protection Rules**: Require approvals before deploying to production.  
- **Limit Secrets Access**: Scope secrets to environments where they are needed.  
- **Pin Action Versions**: Use specific versions (`@v2`) instead of `@master`.  
- **Add Notifications**: Send Slack/Teams messages on workflow success/failure.  
- **Use Artifacts**: Save Terraform plans or kubectl logs for audit purposes.  

---

## 10. Case Studies

### Case: Scan Only
Inputs: `run_security_scan=true`, others false.  
Workflow runs Trivy and Terraform validate, then stops.

### Case: Infra Only
Inputs: `run_terraform=true`, `action=apply`.  
Workflow provisions infra but does not deploy apps.

### Case: Apps Only
Inputs: `run_application_deployment=true`.  
Workflow deploys apps onto an existing cluster.

### Case: Full Deploy
All flags true, `action=apply`.  
Workflow scans, provisions infra, and deploys apps.

---

## 11. Future Enhancements

Potential improvements include:

- **Reusable Workflows**: Split jobs into separate workflows that can be called with `workflow_call`.  
- **Policy Enforcement**: Add Open Policy Agent (OPA) checks for manifests.  
- **Cost Reporting**: Integrate with Infracost to show cost implications of Terraform plans.  
- **Dynamic Previews**: Spin up ephemeral environments for pull requests.  
- **Observability Integration**: Automatically deploy Prometheus and Grafana dashboards.  

---

## 12. Conclusion

GitHub Actions in this repository provides the glue that binds Terraform and Kubernetes into a cohesive pipeline. 
It enables developers to deploy infrastructure, applications, and even run security scans with a single click. 
By using parameter-driven design, the workflows remain flexible and reusable. Safety features like conditionals, dry runs, 
and confirmations protect against mistakes.

With best practices applied—such as secret management, environment protection, and caching—these workflows 
can scale to production-grade environments. Future enhancements like reusable workflows and observability integrations 
can further strengthen the pipeline.

In short, GitHub Actions transforms this repository into a **self-service deployment system** for Kubernetes, 
bringing speed, safety, and simplicity to DevOps teams.

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
