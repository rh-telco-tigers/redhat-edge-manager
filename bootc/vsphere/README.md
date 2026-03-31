# Building VMWare Disk Images

This variant builds a similar base image to the latebinding builds. The Containerfile has been updated to install the vSphere agent and ensure that the service is started at boot time. The Containerfile is set up for latebinding, however you can uncomment the last line of the file and include a `config.yaml` file as a part of the image. 

> **NOTE:** by including the config.yaml in 

Files:

- `Containerfile`: bootc image definition without `config.yaml`
- `config.toml`: `bootc-image-builder` optional installer config
- `user-data.yaml`: example cloud-init payload for late binding

## Log into Registry

In order to access the `registry.redhat.io/rhel9/rhel-bootc:9.7` bootc container image you will need to log into the `registry.redhat.io` registry.  See [Red Hat Container Registry Authentication](https://access.redhat.com/articles/RegistryAuthentication) for details on logging in.

```
sudo podman login registry.redhat.io
```

** Test your registry access **

```
sudo podman pull registry.redhat.io/rhel9/bootc-image-builder:latest
```

> **NOTE:** we are using the `sudo` command here as well as later in this document because the image-builder command must also run as root. 

## Build base image

Using the Containerfile in this directory, build a base "bootc" image. This image can be pushed to a registry, or just kept in local storage. The command below will keep the image locall only. The container file contains the required agent for running on ESXi, and can be further customized as needed.

```
sudo podman build . -t localhost/rhel-bootc-vmdk
```

## Create config.toml

The example Containerfile here includes the local user account as well as a SSH key to be automatically added to the image. You can also use a `config.toml` file to add users and set passwords and ssh keys, so this information is not embedded in your image. 

```
[[customizations.user]]
name = "cloud-user"
password = "pass"
key = "ssh-rsa AAA ... user@email.com"
groups = ["wheel"]
```

### Create VMDK from bootc image

The following command will create a VMDK that can be used to deploy a virtual machine in vSphere. 

```
$ mkdir images
$ sudo podman run \
    --rm \
    -it \
    --privileged \
    -v /var/lib/containers/storage:/var/lib/containers/storage \
    -v ./images:/output \
    --security-opt label=type:unconfined_t \
    --pull newer \
    registry.redhat.io/rhel9/bootc-image-builder:latest \
    --type vmdk \
    --config /config.toml \
    localhost/rhel-bootc-vmdk:latest
```

> **NOTE:** if you are not using the `config.toml` file, ommit the second to last line in the above command.

#### Importing VMDK to vSphere

First we need to import the disk into vSphere. To do this we will use the [govc](https://github.com/vmware/govmomi/blob/main/govc/README.md) tool.

> **NOTE:** Due to limitations of the vSphere Web UI, uploading the VMDK from the web UI does not work. You *MUST* use the govc (or similar) tool to upload the disk.

Start by setting up the environment variables required by **govc**

```sh
$ export GOVC_URL=https://<your vsphere URL>
$ export GOVC_DATACENTER=<your Datacenter name>
$ export GOVC_USERNAME=<your username>
$ export GOVC_PASSWORD=<your password>
# If your vcenter server uses a self-signed certificate be sure to set this variable as well
$ export GOVC_INSECURE=1
```

```sh
$ govc import.vmdk -ds=syno2500-ocp-ds1 ./images/vmdk/disk.vmdk <folder-name>
```

With the VMDK imported, we can now create a VM for this disk. 

```sh
$ govc vm.create \
    -net.adapter=vmxnet3 \
    -m=4096 -c=2 -g=rhel9_64Guest \
    -firmware=efi -disk=”/<folder-name>/disk.vmdk” \
    -disk.controller=pvscsi -on=false \
    -ds=syno2500-ocp-ds1 import-bootc
```

At this point you can power on your VM and it will boot, using the base bootc image created. IF you wish to have the VM enroll in Red Hat Edge Manager, **BEFORE** powering on the VM.

### Enabling self enrollment with cloud-init

In order for the vm to self-enrolll (also known as late-binding) you will need to do the following:

1. log into RHEM using the flightctl command
`flightctl login https://<servername>:3443 --web`
2. using the flightctl command create a new enrollment configuration
`flightctl certificate request --signer enrollment --expiration 365d --output embedded > <vmname-config>.yaml`
2. using the file `user-data-template.yaml` add the contents of the `<vmname-config>.yaml` file in the appropriate section
3. Create a BASE64 encoded version of the config file
`USERDATA=$(gzip -c9 <user-data.yaml | { base64 -w0 2>/dev/null || base64; })`
4. Apply the cloud-init data to the VM created in the previous step:
```sh
$ govc vm.change -vm import-bootc \
-e guestinfo.userdata="${USERDATA}" \
-e guestinfo.userdata.encoding="gzip+base64"
```

At this point when you power on the VM it will auto-enrol in the Red Hat Edge Manager service. You will need to approve the enrollement from the UI, or using the `flightctl` command line tool to start managing the VM.

### Enrolling the VM manually

It is also possible to enroll the VM manually after it has booted, however you will need to ensure that you have a SSH key in order to remotely access the machine.

1. using the flightctl command create a new enrollment configuration
`flightctl certificate request --signer enrollment --expiration 365d --output embedded > <vmname-config>.yaml`
2. use `scp` to copy the `<vmname-config>.yaml` file to the new VM
3. run `sudo mv <vmname-config>.yaml /etc/flightctl/config.yaml`
