# ForestPulse Server Architecture

(The basic schema of the ForestPulse project architecture is defined in the image below?). As an initial step of the project development, we will be defining 4 components:

* `internal-file-server`, which has also been renamed as `fp-nfs` on all nodes's `/etc/hosts` file
* `compute-node-1`
* `compute-node-2`
* `compute-node-3`
* `compute-node-4`
* `compute-node-5`

Further modules will be integrated as the project progresses. `compute-node-1` was set up as the primary access point towards all other Virtual Machines

In the same manner, 4 of the 5 defined volumes were set up and connected to `internal-file-server` to be exported as nfs:

* `userInput`: (interim) _defined space: 2.5T_ 
* `input`: workflows, repositories and containers. _defined space: 2.5T_
* `workdir`: to be used for temporal files in the workflows. _defined space: 70T_
* `output`: _defined space: 10T_

> ⚠️ [Additional info on volume maintenance](VolumeCheatsheet.md)

The remaining volume (`FORCE DC`) is already visble inside the environment and can been exported following [these instructions on CODE-DE](https://knowledgebase.code-de.org/en/latest/eodata/How-to-mount-the-FORCE-community-collection-as-an-NFS-share-on-CODE-DE.html)

## Installing Kubernetes

(brief explanation about pods and clusters and why kubernetes may be more useful to orchestrate things for Nextflow)

While Openstack has support for creating and maintaining Kubernetes nodes, it was preferred to use `kubeadm` directly to bind the nodes to the cluster. This means, node configuration will be applied directly.

These instructions apply to all Virtual Machines / Instances

#### To install Kubernetes on a Linux Machine and add repositories/libraries ([source](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)) :
```bash
#curl -L -s https://dl.k8s.io/release/stable.txt => v1.33  
sudo apt-get install curl ca-certificates apt-transport-https  -y  

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg  

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list  

sudo apt update  
sudo apt install kubeadm kubelet kubectl -y  

sudo apt-mark hold kubeadm kubelet kubectl #mark to avoid updates. Let's use this version as it comes
```
```bash
# Check installation via
kubectl version
```

#### To install a container environment over which the Kubernetes pods will work (found in the instructions for [installing `kubeadm`](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/) and [container runtimes](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd))
```bash
# install a container environment, containerd is recommended over docker
sudo apt update && sudo apt install -y containerd

# generate default config.
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
```

Modify the `config.toml` file so that a property named `SystemdCgroup` is set `true`. **cgroup setting is very relevant to assure stability of the nodes and avoid constant pod restarts**

> ⚠️ For this particular edit and future convenience, I installed `nano`
> ```bash
> sudo apt install nano
> sudo nano /etc/containerd/config.toml
> ```


```bash
# finally, restart the service
sudo systemctl restart containerd
```

Additionally, we have to ensure ip forwarding (any `.conf` file name would do, we chose the name for consistency)

```bash
sudo tee /etc/sysctl.d/99-kubernetes-cri.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

# Apply changes immediately
sudo sysctl --system
```
and
```bash
# Load it now
sudo modprobe br_netfilter

# Ensure it loads on boot
echo 'br_netfilter' | sudo tee /etc/modules-load.d/k8s.conf
```
This last part is checked with `lsmod | grep br_netfilter`

A final step to ensure the nodes "see" `internal-file-server` is to add the following line on the `/etc/hosts`file (put the right ip of the file server here, of course)
```
10.0.0.X internal-file-server.codede.internal fp-nfs
```

## Setting up Nodes

Once Kubernetes related modules have been installed on all virtual machines, we can start forming the cluster. It works usign one or more control-planes (i.e. a director). For this case, on `compute-node-1`.

```bash
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
```
This operation will return an instruction that should be applied on the other virtual machines so that they join the cluster.

Additionally, init output will return the following lines to add privileges to the current shell user
```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Install/apply a CNI, which is akin to a "network manager" for the nodes. [Flannel](https://github.com/flannel-io/flannel/) was chosen, under an Apache License 2.0
```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

Remove the "taint" from the control plane so that it can run pods (A _taint_ is a Kubernetes definition for a restriction. By default, a control plane just manages the pods)
```bash
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
# or kubectl taint nodes compute-node-1 node-role.kubernetes.io/control-plane:NoSchedule-
```

And finally, on the other nodes (a.k.a. *worker nodes*):
```bash
sudo kubeadm join <ip>:6443 --token <token> --discovery-token-ca-cert-hash <hash>
```
Whose values were provided in the outputs of the first `kubeadm init` call on the control-plane. New keys can be generated (see Kubernetes docs) if this one expires.

If the token generated by `kubeadm init` has expired, one can be replicated in the control-plane by using:
```
kubeadm token create --print-join-command
```

## Setting up Volumes and Claims

Volumes are representation of the drives and directories to be mounted, while claims are the interfaces/requests that any pod has. (i.e. what and how to mount internally)

- Creating PV and PVC
- hooking up FORCE too
- how this will be reflected in nextflow

## General debug expressions:

Extracted from notes in a [git hub repository](https://github.com/seqeralabs/nf-k8s-best-practices) about best practices for nextflow + kubernetes

```bash
# view all pods
kubectl get pods # either --namespace=<namespace> or -n <namespace> or --all-namespaces

# view all pods, including the node where each pod is running
kubectl get pods -o wide

# look at the yaml config for a pod
kubectl get pod -o yaml <pod-name>

# get information about a pod (similar to previous command)
kubectl describe pod <pod-name>

# get the log output of a pod
kubectl logs [-f] <pod-name>

# get the list of events (useful if a pod was deleted)
kubectl get events
```

```bash
# get a list of nodes
kubectl get nodes -o wide #(for more details)

# an alternate way to check the pods, using containerd
sudo crictl ps
```

## Deploying Projects

A brief list on what is required to integrate processes/algorithms/resources to the main workflow

What do we need?
* A pod or a VM image that provides a stable environment to be run
* Additional files have been already uploaded to the server and are stored in `fp-nfs/input`

## Additional Information

It would be advisable to install `nano` and `tmux` on the control plane. 

* `nano` is a text editor for quick fixes and useful if someone is not familiar with `vim` motions.

* `tmux` is used to create sessions that persist over time, thus eliminating the need to be connected via `ssh` the entire time a process (e.g. a local Nextflow call) is being executed.