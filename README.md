### GIT repo

https://github.com/jellycatgill/vbox

### Description
This will install a simple monitoring system comprising of Prometheus, Grafana & Graphite.
You can either install into a Virtualbox or directly into a VM in the cloud.

- Host-A: Ubuntu 16.04 - Hosting Virtualbox (min 2cpu, 4gb RAM)
- Host-B: Ubuntu 16.04 - Either as guest OS in Virtualbox or a cloud VM (min 1cpu, 2gb RAM)

# Installing stack in a VirtualBox - on Host A (optional)

### Clone this repo on Host A

- `# cd /opt`
- `# git clone <this-repo>`
- `# cd vbox`

### VirtualBox installation on Host A (if required)

- `# ./build.sh -i`

End of installaton should display following: 
```Extension Packs: 1
Pack no. 0:   Oracle VM VirtualBox Extension Pack
Version:      6.0.4
Revision:     128413
Edition:      
Description:  USB 2.0 and USB 3.0 Host Controller, Host Webcam, VirtualBox RDP, PXE ROM, Disk Encryption, NVMe.
VRDE Module:  VBoxVRDP
Usable:       true 
```

### Create VM on Host A

- `# mkdir /opt/virtualbox`
- `# ./build.sh -d /opt/virtualbox -p -c vm1`

where:
- -d specifies the VM base directory & download directory for ISO image
- -p downloads the ISO Ubuntu 16.04 image
- -c creates the VM "vm1"

### Check VRDE status on Host A

- `# vboxmanage showvminfo vm1 |grep -i vrde`

```
VRDE:                        enabled (Address 0.0.0.0, Ports 5001, MultiConn: off, ReuseSingleConn: off, Authentication type: null)
VRDE port:                   5001
VRDE property               : TCP/Ports  = "5001"
VRDE property               : TCP/Address = <not set>
VRDE property               : VideoChannel/Enabled = <not set>
VRDE property               : VideoChannel/Quality = <not set>
VRDE property               : VideoChannel/DownscaleProtection = <not set>
VRDE property               : Client/DisableDisplay = <not set>
VRDE property               : Client/DisableInput = <not set>
VRDE property               : Client/DisableAudio = <not set>
VRDE property               : Client/DisableUSB = <not set>
VRDE property               : Client/DisableClipboard = <not set>
VRDE property               : Client/DisableUpstreamAudio = <not set>
VRDE property               : Client/DisableRDPDR = <not set>
VRDE property               : H3DRedirect/Enabled = <not set>
VRDE property               : Security/Method = <not set>
VRDE property               : Security/ServerCertificate = <not set>
VRDE property               : Security/ServerPrivateKey = <not set>
VRDE property               : Security/CACertificate = <not set>
VRDE property               : Audio/RateCorrectionMode = <not set>
VRDE property               : Audio/LogPath = <not set>
VRDE Connection:             not active
```


### After VM is created on Host A

If required, use a remote desktop client, to access <Host-A>:5001 in order to access Host-B (vm1)


# Deploying stack - on Host B

This deploy.sh script will install Graphite in a docker container, and Grafana, Prometheus, and the exporters on Host-B.

### Run deploy.sh on Host-B

- `# cd /opt`
- `# git clone <this-repo>`
- `# cd vbox`
- `# ./deploy.sh`

### URLs for test

- Graphite [http://172.104.187.16:3001] - Login root/root
- Grafana [http://172.104.187.16:3000] - Login admin/admin > Dashboards > "DevOps Test" 
- Prometheus [http://172.104.187.16:9090]
- Node exporter [http://172.104.187.16:9100]
- Graphite exporter [http://172.104.187.16:9108]

### Pending
- Integrating graphite metrics into Graphite Exporter

# Testing stack

### Test script

- `/opt/vbox/test.sh`
```
Testing  prometheus ... PASS
Testing  graphite ...   PASS
Testing  grafana ...    PASS
Testing  graphite_exporter ...  PASS
Testing  node_exporter ...      PASS
Testing datasource creation in Grafana  PASS
Testing dashboard creation in Grafana   PASS
```

### Testing load & effect on dashboard

- CPU
  - `# dd if=/dev/zero of=/dev/null bs=1k`
- Memory
  - `# for index in {1..10000000}; do  value=$(($index * 1024)); eval array$index=\"array[$index]: $value\"; done`
- Disk
  - `# dd if=/dev/zero of=/testfile bs=4k count=10k`

