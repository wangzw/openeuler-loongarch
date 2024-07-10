#!/usr/bin/env bash

set -euxo pipefail

CORE=${CORE-4}
MEMORY=${MEMORY-8}
DISK=${DISK-50}

function create_disk() {
    if [ ! -f /data/openeuler-la64-24.03.raw ]; then
      sudo mkdir -p /data/
      sudo chmod 777 /data/
      qemu-img convert -f qcow2 -O raw /image/openeuler-la64-24.03.qcow2 /data/openeuler-la64-24.03.raw
    fi

    qemu-img resize -f raw /data/openeuler-la64-24.03.raw ${DISK}G
}

function loongarch64() {
    exec qemu-system-loongarch64 \
      -name loongarch64 \
      -bios /firmware/QEMU_EFI_8.1.fd \
      -smp ${CORE} \
      -cpu la464-loongarch-cpu \
      -m ${MEMORY}G \
      -machine type=virt,accel=tcg \
      -device nec-usb-xhci,id=xhci,addr=0x1b \
      -device usb-tablet,id=tablet,bus=xhci.0,port=1 \
      -device usb-kbd,id=keyboard,bus=xhci.0,port=2 \
      -device virtio-gpu \
      -device virtio-net,netdev=user.0 \
      -drive file=/data/openeuler-la64-24.03.raw,if=virtio,cache=writeback,format=raw \
      -netdev user,id=user.0,hostfwd=tcp::3957-:22 \
      -vnc 0.0.0.0:65
}

function start() {
    create_disk
    loongarch64
}

start
