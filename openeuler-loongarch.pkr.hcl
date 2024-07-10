packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
  }
}

source "qemu" "loongarch64" {
  iso_url          = "https://mirror.sjtu.edu.cn/openeuler/openEuler-24.03-LTS/ISO/loongarch64/openEuler-24.03-LTS-loongarch64-dvd.iso"
  iso_checksum     = "sha256:cd4afcbb2fe9d3e833ebf5a6087356b31737592225256c399f431c9a3d780c4f"
  iso_target_path  = "download/openEuler-24.03-LTS-loongarch64-dvd.iso"
  output_directory = "output"
  vm_name          = "loongarch64"
  shutdown_command = "shutdown -P now"
  disk_size        = "10G"
  format           = "raw"
  accelerator      = "tcg"
  firmware         = "files/QEMU_EFI_8.1.fd"
  disk_interface   = "virtio"
  cdrom_interface  = "virtio"
  headless         = false
  disk_image       = false
  machine_type     = "virt"
  memory           = 4096
  cpus             = 4
  net_device       = "virtio-net"
  vnc_port_min     = 5966
  vnc_port_max     = 5966
  qemuargs = [
    ["-drive", "file=output/loongarch64,if=virtio,cache=writeback,discard=ignore,format=raw"],
    [
      "-drive",
      "file=download/openEuler-24.03-LTS-loongarch64-dvd.iso,if=virtio,index=1,id=cdrom0,media=cdrom"
    ],
    ["-device", "virtio-net,netdev=user.0"],
    ["-device", "virtio-gpu"],
    ["-device", "nec-usb-xhci,id=xhci,addr=0x1b"],
    ["-device", "usb-tablet,id=tablet,bus=xhci.0,port=1"],
    ["-device", "usb-kbd,id=keyboard,bus=xhci.0,port=2"],
  ]
  qemu_binary         = "qemu-system-loongarch64"
  cpu_model           = "la464-loongarch-cpu"
  use_default_display = true
  http_directory      = "files"
  communicator        = "ssh"
  ssh_username        = "root"
  ssh_password        = "vagrant"
  ssh_timeout         = "200m"
  boot_wait           = "10s"
  boot_steps = [
    ["<up>e", "Edit boot command"],
    ["<down><down><down><left>", "Move to end of boot command line"],
    [" net.ifnames=0 inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/loongarch64-ks.cfg", "Edit boot command line"],
    ["<leftCtrlOn>x<rightCtrlOff>", "Start installation"]
  ]
}

build {
  sources = ["source.qemu.loongarch64"]

  provisioner "file" {
    source      = "files/everything-2203.repo"
    destination = "/etc/yum.repos.d/everything-2203.repo"
  }

  provisioner "shell" {
    inline = [
      "set -x",
      "yum-config-manager --disable debuginfo source update update-source everything EPOL",
      "yum install -y cloud-init cloud-init-help cloud-utils-growpart",
      "systemctl enable cloud-init",
      "echo 'policy: enabled'>/etc/cloud/ds-identify.cfg",
      "yum clean all",
      "rm -rf /var/cache/yum",
      "dd if=/dev/zero of=/EMPTY bs=1M || :",
      "/usr/bin/rm -f /EMPTY"
    ]
  }

  provisioner "file" {
    source      = "files/cloud.cfg"
    destination = "/etc/cloud/cloud.cfg"
  }

  post-processor "shell-local" {
    inline = [
      "qemu-img convert -c -f raw -O qcow2 output/loongarch64 output/openeuler-la64-24.03.qcow2"
    ]
  }
}
