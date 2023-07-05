Setup a vmbridge to host vms and we will use a bastion host to connect into vms. This is to secure the VM network from the home LAN

Later we can use Ansible to make this configuration change.

Start a new shell session on your Proxmox VE server.

Take a backup of the network configuration file /etc/network/interfaces.

```sh
cp /etc/network/interfaces /etc/network/interfaces.original
```

Open the /etc/network/interfaces file in a text editor and append the below configuration for the new network vmbr1.

```sh
...
...
# Dedicated internal network for Kubernetes cluster
auto vmbr1
iface vmbr1 inet static
    address  10.0.1.1/24
    bridge-ports none
    bridge-stp off
    bridge-fd 0

    post-up   echo 1 > /proc/sys/net/ipv4/ip_forward
    post-up   iptables -t nat -A POSTROUTING -s '10.0.1.0/24' -o vmbr0 -j MASQUERADE
    post-down iptables -t nat -D POSTROUTING -s '10.0.1.0/24' -o vmbr0 -j MASQUERADE
```

The above configuration does the following:

1. Define the new network bridge vmbr1 that should be brought up during system boot.
2. Assign it a fixed IP address 10.0.1.1 with a subnet mask of /24. This presents a network range from 10.0.1.0 to 10.0.1.255.
3. Configure Masquerading (NAT) with iptables that allows any outgoing traffic (internet access) from the Kubernetes VMs can happen through vmbr0.

Execute ifreload command to apply the changes.

```sh
ifreload -a
```

Next we need to create a VM template.

```sh
curl -s https://raw.githubusercontent.com/l3rady/proxmox-kube-lab/main/proxmox-scripts/create-vm-template.sh | bash
```

This will create a vm template with ID 9000.

Now on to creating the bastion host

```sh
qm clone 9000 9001 --name bastion --full true
qm set 9001 --sshkey ~/.ssh/scott.pub
qm set 9001 --net0 virtio,bridge=vmbr0 --ipconfig0 ip=192.168.255.2/24,gw=192.168.255.1
qm set 9001 --net1 virtio,bridge=vmbr1 --ipconfig1 ip=10.0.1.2/24,gw=10.0.1.1
qm start 9001
```

Setup a terraform role, user and API Key

```sh
pveum role add TerraformProv -privs "Datastore.AllocateSpace Datastore.Audit Pool.Allocate Sys.Audit Sys.Console Sys.Modify VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU 
VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.Monitor VM.PowerMgmt"
pveum user add terraform-prov@pve
pveum aclmod / -user terraform-prov@pve -role TerraformProv
pveum user token add terraform-prov@pve terraform-prov-api-key
```

