# esufmg-tcc
This is a repo for create and describe TCC files

## [DevContianer](https://code.visualstudio.com/docs/remote/containers)
### GITHUB Access
- [ ] Personal Access Token
    - Scope:
        - [ ] repository
        - [ ] write:package
- [ ] Package GHCR
    - `echo "<PAT>" | docker login ghcr.io --username "GITHUB_USER" --passowrd-stdin`
    - Command: docker pull ghcr.io/felipefrocha/action-docker-build-latex:main

## Kubernetes 
---

### **Pre requirements**

Operational System:
 - This workbook is valid to be used with Ubuntu 20.04.4 LTS from Canonical.

Latest Kubernetes Version tested :
  - 1.24.1
  - Check compatibility with ContainerD and CRI

Container Runtime:
- Containerd (considering that Dockershin is now officially deprecated)

---

### **Access with [kubectl](https://kubernetes.io/pt-br/docs/reference/kubectl/_print/) through `ssh`**

To gain access to this configuration you can choose 2 paths:
1. SSH to a master node and do you commands there;
2. Fowarding port to k8s master nodes:
    ```bash
    #!/bin/bash
    
    set -e

    # Auth to communitate with master trougth bastion
    ssh -L 6443:k8s-haproxy:6443 bastion -Nf && sed -E "s|^(127.0.0.1 localhost)|\1 k8s-haproxy|g" -i /etc/hosts
    
    scp -i ufmg-master01:/etc/kubernetes/admin.conf $HOME/.kube/config && sudo chown $(id -u):$(id -g) $HOME/.kube/config
    ```

### Load Balancer (ExternalIP)
```bash 
kubectl edit configmap -n kube-system kube-proxy
## Find and edit this configuration
# apiVersion: kubeproxy.config.k8s.io/v1alpha1
# kind: KubeProxyConfiguration
# mode: "ipvs"
# ipvs:
#   strictARP: true

# see what changes would be made, returns nonzero returncode if different
kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e "s/strictARP: false/strictARP: true/" | sed -e "s/mode: .*/mode: \"ipvs\"/" | \
kubectl diff -f - -n kube-system || exit 1

# actually apply the changes, returns nonzero returncode on errors only
kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e "s/strictARP: false/strictARP: true/" | sed -e "s/mode: .*/mode: \"ipvs\"/" | \
kubectl apply -f - -n kube-system

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml

kubectl apply -f - <<EOF
---
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 150.164.10.5
      - 150.164.10.7-150.164.10.11
      - 150.164.10.16-150.164.10.17
      - 150.164.10.19
EOF

```

## Ingress (Nginx)

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.2.0/deploy/static/provider/baremetal/deploy.yaml
kubectl describe service/ingress-nginx-controller -n ingress-nginx
```

Change HAProxy config to contemplate that


### Dashboard
To deploy a UI dashboard first apply a recommended configuration descrives
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.5.0/aio/deploy/recommended.yaml

kubectl proxy --address='0.0.0.0' --accept-hosts='^*$'

kubectl apply -f - <<EOF
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard

EOF

# Get token to access it
kubectl -n kubernetes-dashboard create token admin-user

```

### NFS
To apply NFS CSI configs we used
```bash 
kubectl apply -f -<<EOF
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-grafana
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  mountOptions:
    - nfsvers=4.1
  csi:
    driver: nfs.csi.k8s.io
    readOnly: false
    volumeHandle: unique-volumeid  # make sure it's a unique id in the cluster
    volumeAttributes:
      server: k8s-haproxy
      share: /export/volumes
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: pvc-nginx
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  volumeName: pv-nginx
  storageClassName: ""
---
apiVersion: v1
kind: Pod
metadata:
  name: nginx-nfs-example
spec:
  containers:
    - image: nginx
      name: nginx
      ports:
        - containerPort: 80
          protocol: TCP
      volumeMounts:
        - mountPath: /var/www
          name: pvc-nginx
  volumes:
    - name: pvc-nginx
      persistentVolumeClaim:
        claimName: pvc-nginx
EOF

### Monitoring
1. Grafana 

To apply grafana configurations we used the following instructions:
```bash
cd cluster/helm/grafana 
bash grafana.sh
```




