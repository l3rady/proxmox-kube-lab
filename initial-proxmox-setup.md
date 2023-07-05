Setup a vmbridge to host vms and we will use a bastion host to connect into vms. This is to secure the VM network from the home LAN

Later we can use Ansible to make this configuration change.

Start a new shell session on your Proxmox VE server.

Take a backup of the network configuration file /etc/network/interfaces.

```sh
cp /etc/network/interfaces /etc/network/interfaces.original
``

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
