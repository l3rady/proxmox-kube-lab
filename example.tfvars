# Environment
########################################################################
## Replace `dev` with your desired environment name.
env_name = "dev"


# Proxmox VE
########################################################################
## Specify Proxmox VE API URL, token details, and Proxmox host where VM will be hosted.
## If you've not created an API token, please refer to this guide: https://registry.terraform.io/providers/Telmate/proxmox/2.9.14/docs
pm_api_url          = "https://192.168.255.254:8006/api2/json"
pm_api_token_id     = "terraform-prov@pve!terraform-prov-api-key"
pm_api_token_secret = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
pm_tls_insecure     = true
pm_host             = "pve"


# Internal Network
########################################################################
## Replace `vmbr1` with your bridge name dedicated to the Kubernetes internal network.
internal_net_name = "vmbr1"
## Replace `10.0.1.0/24` with your internal network address and prefix length.
internal_net_subnet_cidr = "10.0.1.0/24"


# Bastion Host
########################################################################
## Replace `192.168.255.2` with LAN IP/ public IP address of your bastion host.
bastion_ssh_port = 22
bastion_ssh_ip   = "192.168.255.2"
bastion_ssh_user = "ubuntu"


# SSH
########################################################################
## Specify base64 encoding of SSH keys for Kubernetes admin authentication.
ssh_public_keys = "put-base64-encoded-public-keys-here"
ssh_private_key = "put-base64-encoded-private-keys-here"

# VM specifications
########################################################################
# Replace `2` with the maximum cores that your Proxmox VE server can give to a VM.
vm_max_vcpus = 2
# Specify the VM specifications for the Kubernetes control plane.
vm_k8s_control_plane = {
  node_count = 1
  vcpus      = 2
  memory     = 2048
  disk_size  = 20
}
# Specify the VM specifications for the Kubernetes worker nodes.
vm_k8s_worker = {
  node_count = 3
  vcpus      = 2
  memory     = 3072
  disk_size  = 20
}
# Specify the storage pool where OS VM disk is placed.
vm_os_disk_storage = "tank"