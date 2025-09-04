
# ☸️ Kubernetes Detailed Guide (Expanded Version)

## 1. Introduction

Kubernetes is the execution environment for all applications in this repository. 
While Terraform provisions the underlying infrastructure, Kubernetes is the layer where workloads run, scale, and self-heal. 
It provides the abstraction that allows containerized applications to be deployed uniformly across environments, regardless of the 
underlying infrastructure.

This repository leverages Kubernetes for three main workloads:
- A Node.js web application,
- An NGINX server, and
- k8sGPT, a diagnostic tool for Kubernetes clusters with AI provider integration.

Each workload is packaged into Kubernetes manifests (Deployments, Services, and supporting resources), making the system flexible, 
scalable, and easily extensible.

---

## 2. Kubernetes Cluster Overview

The cluster is provisioned by Terraform, typically through AWS EKS. Once the control plane and worker nodes are created, 
GitHub Actions connects to the cluster using a kubeconfig file. At this point, Kubernetes becomes the orchestration engine 
for deploying applications.

The cluster architecture includes:
- **Control Plane**: Managed by the cloud provider (EKS).  
- **Worker Nodes**: Provisioned in node groups defined by tfvars.  
- **Networking**: VPC and subnets configured by Terraform.  
- **Load Balancers**: Created dynamically by Kubernetes Services of type `LoadBalancer`.  

This design ensures that applications deployed to the cluster are immediately reachable from outside.

---

## 3. Node.js Application Deployment

The Node.js application demonstrates how a simple containerized workload can be deployed and scaled in Kubernetes. 
It is defined by a Deployment and a Service.

### Node.js Deployment Manifest

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nodejs-app
  labels:
    app: nodejs
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
```

This deployment ensures that two replicas of the Node.js app are always running. 
If one pod crashes, Kubernetes automatically restarts it.

### Node.js Service Manifest

```yaml
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

The `LoadBalancer` service type instructs Kubernetes to create a cloud load balancer. 
As a result, the Node.js application becomes accessible at `http://<load-balancer-ip>:3000`.

### Scaling the Node.js App

Replica count can be increased in the Deployment manifest or via:

```bash
kubectl scale deployment nodejs-app --replicas=5
```

Kubernetes schedules additional pods across nodes, and the service load balances requests automatically.

---

## 4. NGINX Deployment

NGINX serves as both a reverse proxy and a static file server. In this repository, it demonstrates deployment of a widely-used 
production-grade web server.

### NGINX Deployment Manifest

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
```

This ensures high availability for NGINX by running two replicas.

### NGINX Service Manifest

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
```

This service creates a public-facing load balancer, making NGINX accessible at `http://<load-balancer-ip>`.

### Use Cases

- Serving static content such as HTML or images.  
- Acting as a reverse proxy in front of other services.  
- Demonstrating ingress-style routing when extended.  

---

## 5. k8sGPT Deployment

k8sGPT is an AI-powered diagnostic tool for Kubernetes clusters. It inspects cluster state, identifies issues, 
and provides natural language explanations. In this repository, it is deployed as a Kubernetes workload that can be 
configured to use either Google or OpenAI as the provider.

### k8sGPT Deployment Manifest

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: k8sgpt
  labels:
    app: k8sgpt
spec:
  replicas: 1
  selector:
    matchLabels:
      app: k8sgpt
  template:
    metadata:
      labels:
        app: k8sgpt
    spec:
      containers:
      - name: k8sgpt
        image: mydockerhub/k8sgpt:latest
        env:
        - name: PROVIDER
          value: "google" # or "openai"
        ports:
        - containerPort: 8080
```

### k8sGPT Service Manifest

```yaml
apiVersion: v1
kind: Service
metadata:
  name: k8sgpt-service
spec:
  type: LoadBalancer
  selector:
    app: k8sgpt
  ports:
  - port: 80
    targetPort: 8080
```

### Provider Switching

The `provider` parameter in the workflow determines whether Google or OpenAI is injected into the deployment as an environment variable:

```yaml
env:
- name: PROVIDER
  value: ${{ github.event.inputs.provider }}
```

This runtime configuration makes the system flexible without requiring manifest changes.

---

## 6. Service Types Explained

Kubernetes offers multiple service types, each serving a different purpose. 
This repository primarily uses `LoadBalancer` services, but understanding all service types provides context.

- **ClusterIP** (default): Exposes a service within the cluster only. Suitable for internal microservices.  
- **NodePort**: Exposes a service on a static port on each node. Often used for debugging or simple clusters.  
- **LoadBalancer**: Integrates with the cloud provider to create an external load balancer. This is used here to 
  expose Node.js, NGINX, and k8sGPT to the internet.  

By choosing `LoadBalancer`, the applications in this repository are immediately reachable from outside the cluster.

---

## 7. Namespaces and Labeling Strategy

Namespaces allow logical separation of resources. For example, dev and test apps can be deployed into different namespaces. 
In this repository, workloads are grouped under a common namespace per environment, ensuring isolation.

Labels are used extensively to connect Deployments and Services. For instance, both the Node.js Deployment and Service use `app: nodejs`. 
This label ensures the service routes traffic only to the intended pods.

---

## 8. ConfigMaps and Secrets

Applications often require configuration. Kubernetes supports two primitives:

- **ConfigMaps**: Store non-sensitive configuration such as environment variables or file contents.  
- **Secrets**: Store sensitive values such as API keys.  

Example of ConfigMap for Node.js app:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nodejs-config
data:
  APP_ENV: "development"
  LOG_LEVEL: "debug"
```

Example of Secret for k8sGPT:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: k8sgpt-secret
type: Opaque
data:
  API_KEY: bXktc2VjcmV0LWtleQ==  # base64 encoded
```

These are mounted into pods via environment variables or files.

---

## 9. Rolling Updates and Scaling

Kubernetes Deployments support rolling updates by default. 
When a new image is applied, pods are updated gradually, ensuring no downtime. 
If an error occurs, Kubernetes rolls back automatically.

Scaling can be manual (changing replicas) or automated using the Horizontal Pod Autoscaler (HPA). Example:

```bash
kubectl autoscale deployment nodejs-app --cpu-percent=50 --min=2 --max=10
```

This command ensures the Node.js app scales based on CPU usage.

---

## 10. Networking and Ingress

While LoadBalancer services provide external access, larger deployments benefit from ingress controllers. 
An ingress controller routes traffic based on hostnames and paths, enabling multiple apps to share one load balancer.

Example ingress rule:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
spec:
  rules:
  - host: node.dev.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nodejs-service
            port:
              number: 3000
```

Ingress controllers (NGINX Ingress, Traefik, etc.) can be added as future improvements to this repository.

---

## 11. Error Handling and Debugging

Deployments can fail for many reasons. Common issues include:

- **CrashLoopBackOff**: Application container repeatedly crashes due to misconfiguration.  
- **ImagePullBackOff**: Kubernetes cannot pull the container image (e.g., wrong DockerHub credentials).  
- **Pending Pods**: No nodes have enough resources.  

Debugging commands:

```bash
kubectl get pods
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

These reveal events, error messages, and application logs for troubleshooting.

---

## 12. Monitoring and Logging

Monitoring is essential in production environments. While not included by default in this repository, common practices include:

- **Prometheus & Grafana**: For metrics and dashboards.  
- **ELK (Elasticsearch, Logstash, Kibana)**: For centralized logging.  
- **Kubernetes Events**: Checked using `kubectl get events`.  

Integrating these tools can provide visibility into pod health, network traffic, and resource usage.

---

## 13. Case Studies

### Case: Node.js App Only
Parameters: `run_application_deployment=true`, manifests applied only for Node.js.  
Result: Cluster runs Node.js pods, accessible via a load balancer. NGINX and k8sGPT remain absent.

### Case: Full Stack Deployment
All applications deployed. Node.js serves dynamic content, NGINX provides static or reverse proxy capabilities, 
and k8sGPT provides diagnostics.

### Case: Provider Switch
Deploying k8sGPT with `provider=openai` instead of `google`.  
Result: Same diagnostic tool, different backend provider, no manifest changes required.

---

## 14. Security Practices

Security is vital in Kubernetes clusters. Recommendations include:

- **RBAC (Role-Based Access Control)**: Limit permissions for service accounts.  
- **Resource Quotas**: Prevent one app from consuming all resources.  
- **Network Policies**: Restrict pod-to-pod communication.  
- **Admission Controllers**: Enforce policies on pod creation.  
- **Pod Security Standards or OPA Gatekeeper**: Prevent privileged containers.  

By adopting these, the cluster remains secure even as workloads grow.

---

## 15. Conclusion

Kubernetes provides the orchestration needed to run applications reliably and securely. 
In this repository, Node.js, NGINX, and k8sGPT are deployed using straightforward manifests, 
but the principles extend to complex microservices architectures.

By using Deployments, Services, ConfigMaps, Secrets, and LoadBalancers, the repository demonstrates the essentials of Kubernetes. 
Scaling, rolling updates, and provider flexibility make the system robust. With added monitoring, ingress, and RBAC policies, 
the cluster can evolve into a production-grade environment.

This guide has explained Kubernetes in this repository in detail, showing not just *what* is deployed, 
but *how* and *why*. It equips teams to extend the setup, troubleshoot effectively, and adopt best practices.

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
