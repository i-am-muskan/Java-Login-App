## Kubernetes Monitoring using Prometheus & Grafana (EC2 + kubeadm)

This guide provides a professional, step-by-step walkthrough for implementing a production-standard monitoring stack on a Kubernetes cluster built with `kubeadm`.

---

### 1. Prerequisites

#### Infrastructure

* **EC2 Instances:** A functional `kubeadm` cluster (1 Master, 1+ Worker nodes).
* **Cluster State:** All nodes must be in the `Ready` state.
* **Control:** `kubectl` and `helm` should be configured on the Master node.

**Verify Cluster:**

```bash
kubectl get nodes

```

---

### 2. Why Prometheus + Grafana?

* **Prometheus:** Acts as the time-series database and scraper. It pulls metrics from nodes (CPU/Memory), Pods, and the Kubernetes API.
* **Grafana:** Acts as the visualization layer. It connects to Prometheus as a data source and provides intuitive, real-time dashboards.

---

### 3. Monitoring Architecture

The architecture follows a "Pull" model where Prometheus scrapes data from various exporters.

* **Node Exporter:** Collects hardware and OS metrics from the nodes.
* **Kube-state-metrics:** Listens to the Kubernetes API server and generates metrics about the state of objects (deployments, nodes, pods).
* **Prometheus Server:** Aggregates and stores the data.
* **Grafana:** Queries Prometheus to display data on dashboards.

---

### 4. Install Monitoring using Helm

Helm is the preferred method as it manages complex deployments like the Prometheus stack with a single command.

#### 4.1 Install Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version

```

#### 4.2 Add Prometheus Helm Repository

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

```

---

### 5. Create Monitoring Namespace

Isolating monitoring tools into their own namespace is a best practice for cluster organization.

```bash
kubectl create namespace monitoring

```

---

### 6. Install kube-prometheus-stack

The `kube-prometheus-stack` is an all-in-one solution containing Prometheus, Grafana, Alertmanager, and the necessary exporters.

```bash
helm install prometheus \
  prometheus-community/kube-prometheus-stack \
  -n monitoring

```

**Verify Pods:**
Wait until all pods reach the `Running` state.

```bash
kubectl get pods -n monitoring

```

---

### 7. Verify Services

Check the services created in the `monitoring` namespace to identify ports for UI access.

```bash
kubectl get svc -n monitoring

```

| Service | Purpose |
| --- | --- |
| `prometheus-grafana` | Grafana Dashboard UI |
| `prometheus-kube-prometheus-prometheus` | Prometheus Query UI |
| `prometheus-node-exporter` | Metrics from physical nodes |
| `prometheus-kube-state-metrics` | Metrics from K8s objects |

---

### 8. Access Grafana

#### 8.1 Change Service to NodePort (or use Port-Forward)

By default, the service is `ClusterIP`. To access it via browser, change it to `NodePort`:

```bash
kubectl patch svc prometheus-grafana -n monitoring -p '{"spec": {"type": "NodePort"}}'

```

#### 8.2 Get the NodePort and URL

```bash
kubectl get svc -n monitoring prometheus-grafana

```

Locate the port (e.g., `80:31817/TCP`). Access via: `http://<EC2-PUBLIC-IP>:31817`

#### 8.3 Get Grafana Admin Password

```bash
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

```

* **Username:** `admin`
* **Password:** Output from the command above.

---

### 9. Access Prometheus

#### 9.1 Change Service to NodePort

```bash
kubectl patch svc prometheus-kube-prometheus-prometheus -n monitoring -p '{"spec": {"type": "NodePort"}}'

```

#### 9.2 Get NodePort

```bash
kubectl get svc -n monitoring prometheus-kube-prometheus-prometheus

```

Access via: `http://<EC2-PUBLIC-IP>:<NODEPORT>` (Example: port `32738`).

---

### 10. Verify Metrics Collection

1. Open the **Prometheus UI**.
2. Navigate to **Status** > **Targets**.
3. Ensure all endpoints (`kubelet`, `node-exporter`, `kube-state-metrics`) are **UP**.

---

### 11. Verify Grafana Dashboards

Grafana comes with pre-configured dashboards.

1. Log in to Grafana.
2. Go to **Dashboards** > **Browse**.
3. Check for default folders:
* **Kubernetes / Compute Resources / Node (Pods)**
* **Kubernetes / Compute Resources / Cluster**
* **Kubernetes / API Server**



---

### 12. EC2 Security Group Configuration

To view the UIs in your local browser, the EC2 Security Group must allow traffic on the NodePorts.

| Protocol | Port Range | Source | Purpose |
| --- | --- | --- | --- |
| TCP | `31817` | `0.0.0.0/0` | Grafana Access |
| TCP | `32738` | `0.0.0.0/0` | Prometheus Access |
| TCP | `30000-32767` | `0.0.0.0/0` | General NodePort Range |

---

### 13. Troubleshooting

| Symptom | Probable Cause | Fix |
| --- | --- | --- |
| **Cannot access UI** | Security Group or Firewall | Open specific NodePorts in AWS Console. |
| **Targets are "DOWN"** | Network Partition or Pod Failure | Restart `node-exporter` pods or check Node reachability. |
| **Grafana password error** | Base64 decoding issue | Ensure you use the exact string output without extra spaces. |

---
