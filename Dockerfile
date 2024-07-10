FROM ghcr.io/wangzw/qemu:8.2.2

ADD files/QEMU_EFI_8.1.fd /firmware/QEMU_EFI_8.1.fd
ADD download/openeuler-la64-24.03.qcow2 /image/openeuler-la64-24.03.qcow2

ADD files/start.sh /usr/bin/start.sh
CMD ["/usr/bin/start.sh"]
