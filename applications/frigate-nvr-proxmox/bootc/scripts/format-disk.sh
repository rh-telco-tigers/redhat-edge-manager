#!/bin/bash
# Exit if the disk is already formatted
if blkid /dev/sdb1; then
    exit 0
fi

# Create a GPT partition table and a partition covering the whole disk
parted -s /dev/sdb mklabel gpt
parted -s /dev/sdb mkpart primary ext4 0% 100%

# Format the partition
mkfs.xfs /dev/sdb1