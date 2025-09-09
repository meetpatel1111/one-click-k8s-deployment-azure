# 🗑️ Delete Workflow Detailed Guide (Expanded Version)

## 1. Introduction

In most deployment systems, deletion is either an afterthought or tied directly to infrastructure teardown. 
However, this repository deliberately separates application deletion from infrastructure destruction. 
The reason is simple: **safe, controlled, and auditable deletions**.

Applications deployed into Kubernetes may need to be removed independently of the cluster itself. 
For example, a development team may want to test removing the Node.js app while keeping NGINX and k8sGPT running. 
Or a security team may require removing k8sGPT temporarily without impacting other workloads. 
By creating a dedicated workflow for deletions, this repository ensures fine-grained control over application lifecycles.

---

## 2. Philosophy of Safety-First Deletion

Deletion is one of the most dangerous operations in DevOps. A single wrong command can take down production workloads, 
delete customer-facing apps, or break dependencies. This workflow applies the philosophy of **safety-first deletion** 
using three layers of protection:

1. **Explicit Environment Selection**: Users must specify which environment (dev, test) is targeted.  
2. **Dry Run Mode**: Users can simulate deletions to see what *would* happen without actually removing apps.  
3. **Confirmation Requirement**: Even if `dry_run=false`, the workflow does nothing unless `confirm=true`.  

This design ensures that accidental deletions are virtually impossible. 
Only when the user deliberately sets both flags (`dry_run=false` and `confirm=true`) will actual deletions occur.

---

## 3. Anatomy of the Workflow

The `delete-k8s-applications.yml` workflow is stored in `.github/workflows/`. 
It defines inputs, runs on a manual trigger, and executes deletion commands with conditional checks.

### Workflow Inputs

```yaml
on:
  workflow_dispatch:
    inputs:
      environment:
        description: "Target environment (dev/test)"
        required: true
      apps_to_delete:
        description: "Comma-separated list of apps to delete"
        required: true
      dry_run:
        description: "Simulate deletions without performing them"
        default: "true"
      confirm:
        description: "Must be set to true to actually delete apps"
        default: "false"
```

This input design emphasizes clarity: no deletions can occur unless a developer provides all required information.

### Workflow Jobs

The workflow consists of a single job with multiple steps:

1. **Azure Login**: Authenticate with `AZURE_CREDENTIALS`.  
2. **Set kubectl context**: Connect to the AKS cluster for the specified environment using `az aks get-credentials`.  
3. **Dry Run Step**: If `dry_run=true`, prints which apps *would* be deleted.  
4. **Confirm Step**: If `confirm=false`, aborts with a safety message.  
5. **Deletion Step**: If both conditions are met, executes `kubectl delete`.  

This sequence ensures transparency and control.

---

## 4. Parameters in Detail

### `environment`
Defines which AKS cluster context is used. By separating dev and test environments, the workflow prevents accidental cross-environment deletions. 
For example, removing apps from dev does not affect test.

### `apps_to_delete`
Accepts a comma-separated list of apps. Example:  
```text
nodejs-app,nginx,k8sgpt
```
This flexibility allows partial deletions. A developer may delete only the Node.js app while leaving the others untouched.

### `dry_run`
A boolean-like input (true/false). When set to true, the workflow simulates deletions by printing the app names instead of deleting them. 
This mode is essential for audits and planning.

### `confirm`
The final safeguard. Even if dry_run=false, no deletions happen unless `confirm=true`. This requires explicit intent from the user.

---

## 5. Command Breakdown

The deletion commands are simple but effective:

```yaml
- name: Azure Login
  uses: azure/login@v1
  with:
    creds: ${{ secrets.AZURE_CREDENTIALS }}

- name: Set kubectl context
  run: az aks get-credentials --resource-group aks-cluster-${{ github.event.inputs.environment }}-rg --name aks-cluster-${{ github.event.inputs.environment }} --overwrite-existing

- name: Confirm and Delete
  if: ${{ github.event.inputs.dry_run == 'false' && github.event.inputs.confirm == 'true' }}
  run: |
    for app in $(echo "${{ github.event.inputs.apps_to_delete }}" | tr ',' ' '); do
      kubectl delete deployment $app || true
      kubectl delete service $app || true
    done
```

### Explanation

- `azure/login` authenticates with Azure using `AZURE_CREDENTIALS`.  
- `az aks get-credentials` sets the kubectl context for the right cluster.  
- The `for app in ...` loop iterates over each app provided.  
- `kubectl delete deployment $app` removes the app’s deployment.  
- `kubectl delete service $app` removes the associated service.  
- The `|| true` ensures the workflow does not fail if a resource does not exist.  

### Example Run

If `apps_to_delete=nodejs-app,nginx` and both conditions are met, the workflow executes:

```bash
kubectl delete deployment nodejs-app
kubectl delete service nodejs-app
kubectl delete deployment nginx
kubectl delete service nginx
```

This results in Node.js and NGINX being safely removed from the AKS cluster.

---

## 6. Error Handling in Deletions

Deletion operations may encounter errors. Common scenarios include:

- **Non-Existent Applications**: If a developer specifies an app name that does not exist in the cluster, `kubectl delete` 
  returns an error. The `|| true` ensures the workflow logs the issue but continues execution.  
- **Partial Deletions**: Sometimes, the Deployment may exist while the Service does not (or vice versa). The loop handles each 
  independently, ensuring partial resources are removed.  
- **Cluster Connection Errors**: If kubeconfig is not configured correctly, the workflow fails fast at the connection step.  
- **Permissions Issues**: If RBAC prevents deletion, the workflow surfaces a "forbidden" error, highlighting insufficient rights.  

These errors are not silent; they are visible in the GitHub Actions logs, allowing developers to take corrective action.

---

## 7. Rollback Considerations

Sometimes deletions are triggered by mistake, or an app must be restored quickly. Rollback is achieved by simply re-deploying 
the application manifests.

### Example: Re-Deploy Node.js

```bash
kubectl apply -f k8s/nodejs.yaml
```

Since manifests are version-controlled in the repository, rollback is deterministic and auditable. 
This aligns with GitOps principles, where the repository is the source of truth.

For future enhancements, the workflow can be extended to **archive manifests** before deletion. 
Archived manifests could then be re-applied automatically if rollback is required.

---

## 8. Case Studies

### Case: Dry Run Only
Inputs:  
- `apps_to_delete=nodejs-app,nginx`  
- `dry_run=true`  
- `confirm=false`  

Result: Workflow outputs:  
```
Would delete apps: nodejs-app nginx
```
No resources are removed.

---

### Case: Confirm Missing
Inputs:  
- `apps_to_delete=nodejs-app`  
- `dry_run=false`  
- `confirm=false`  

Result: Workflow halts with a safety message. Nothing is deleted. This prevents accidental deletions.  

---

### Case: Confirmed Delete
Inputs:  
- `apps_to_delete=k8sgpt`  
- `dry_run=false`  
- `confirm=true`  

Result: Workflow executes `kubectl delete` commands, removing k8sGPT’s Deployment and Service.  

---

## 9. Security Practices

Security is fundamental to the deletion workflow. Recommended practices include:

- **RBAC Restrictions**: Limit the service account used by GitHub Actions to only allow deleting specific namespaces.  
- **Audit Logs**: Enable AKS audit logging and forward logs to **Azure Monitor / Log Analytics** for traceability.  
- **Namespace Isolation**: Deploy apps into separate namespaces (dev, test) to avoid cross-environment risks.  
- **Scoped Access**: Avoid giving GitHub Actions cluster-admin rights. Use the principle of least privilege.  
- **Confirmation Culture**: Reinforce the requirement that destructive operations require explicit intent.  

Together, these ensure deletions are safe, controlled, and traceable.

---

## 10. Future Improvements

While the deletion workflow is already safe, future enhancements could make it more powerful:

- **Archiving Manifests**: Automatically back up manifests before deletion.  
- **GitOps Pruning**: Use GitOps controllers like ArgoCD to prune workloads instead of direct kubectl deletes.  
- **Notifications**: Send Slack or email alerts when deletions occur.  
- **Approval Gates**: Require team lead approval for deletions in shared environments.  
- **Selective Resource Deletion**: Allow finer granularity, e.g., delete only Services but not Deployments.  

These features would make the workflow even more robust in production contexts.

---

## 11. Conclusion

The deletion workflow in this repository demonstrates how **safety and flexibility can coexist**. 
By separating deletion from deployment, providing dry runs, and requiring explicit confirmation, the workflow 
ensures that destructive actions are intentional, auditable, and recoverable.

Errors are surfaced clearly, rollbacks are straightforward through manifest re-application, and security 
practices like RBAC, Azure Monitor, and audit logs provide guardrails. Case studies highlight how the workflow behaves in 
different scenarios, reinforcing its reliability.

Ultimately, this workflow embodies DevOps maturity: empowering developers to remove applications when needed, 
without sacrificing control or risking accidental production outages. With planned improvements like archiving 
and notifications, it can evolve into a gold-standard approach for Kubernetes app lifecycle management.

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
