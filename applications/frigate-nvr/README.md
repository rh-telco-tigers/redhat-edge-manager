# frigate-nvr

This is an alternative example application deployment. We will be using the same principals that are used in the hello-web application, but we will leverage an existing published application, as well as persistent storage.

The example application we will deploy is an OpenSource NVR application called [Frigate NVR](https://github.com/blakeblackshear/frigate).

> **NOTE:** Frigate is a open source third party application, not a supported Red Hat application. This is for demo purposes only

## Creating our Base Image

Our NVR application will use a bootc image that has been designed for this applciations use. Specifically we are going to create a partition on `/dev/sdb` and then format it with the xfs filesystem. The script and the systemd "oneshot" service are located in the `bootc\scripts` directory. We will embed these files directly into the base bootc image.

In order to ensure we have remote access to the machines, we will need to create a "cloud-user" user and add an ssh key. To ensure that the ssh key is added either create an ssh key in the `bootc` directory with `ssh-keygen -t ed25519 -C "your_email@example.com" -f bootc/demo-authorized-key.pub` or place a copy of an existing ssh key of your choosing in the `bootc/demo-authorized-key.pub` file before continuing.

### Build and Publish our bootc container

```
cd bootc
podman build -t quay.io/markd/fedora-frigate:v1 .
podman login quay.io
podman push quay.io/markd/fedora-frigate:v1
```

## Deploy App and Configuration

We will test this out with a virtual machine. That virtual machine should have a minimum of 2 disks. The primary disk built from a bootc-image-builder command and a blank secondary disk for storing live video feeds.

### Apply the configs

```
flightctl login
flightctl apply -f repository.yaml 
flightctl apply -f resourcesync.yaml
```


### 