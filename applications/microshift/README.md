# Intro

## Requirements

In order for `microshift` to start up, the host needs to have a valid host name. The easiest way to do this is to ensure that a reverse dns record is in place for the machine so that it can resolve its own name.

There are two Containerfile versions available. One uses upstream binaries `Containerfile.centos9` and one uses Red Hat Released binaries `Containerfile.rhel9`


## Buildiing

[markd@rhel9wk25 bootc]$ podman build -t registry.xphyrlab.net/microshift/microshift:v1 -f Containerfile.rhel9 --authfile=/home/markd/pull-secret.json .

## Authorizing

In order for Microshift to start on the node, you need to install your pull-secret.txt to the following location on the node `/etc/crio/openshift-pull-secret`