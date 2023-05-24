# Documentantion - Packer: https://developer.hashicorp.com/packer/plugins/builders/proxmox

variable "os_image" {
  type    = string
  default = "Rocky-x86_64-dvd.iso"
}

variable "proxmox_api_token_id" {
  type    = string
}

variable "proxmox_api_token_secret" {
  type    = string
  sensitive = true
}

variable "proxmox_api_url" {
  type    = string
}

variable "proxmox_iso_pool" {
  type    = string
  default = "local:iso"
}

variable "proxmox_node" {
  type    = string
}

variable "proxmox_storage_format" {
  type    = string
  default = "raw"
}

variable "proxmox_storage_pool" {
  type    = string
  default = "local-lvm"
}

variable "proxmox_storage_pool_type" {
  type    = string
  default = "lvm-thin"
}

variable "ssh_password" {
  type    = string
  sensitive = true
}

variable "template_description" {
  type    = string
  default = "Rocky Linux 9 Template"
}

variable "template_name" {
  type    = string
  default = "RL9-Template"
}

# source blocks are generated from your builders; a source can be referenced in
# build blocks. A build block runs provisioner and post-processors on a
# source. Read the documentation for source blocks here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/source

source "proxmox" "rocky-linux-9-base" {
  username            = "${var.proxmox_api_token_id}"
  token               = "${var.proxmox_api_token_secret}"
  boot_command        = ["<tab> text inst.ks=https://raw.githubusercontent.com/ArdRay/packer_templates/master/rocky-linux-9/http/rl9-base.ks<enter><wait>"]
  boot_wait           = "4s"
  cores               = "2"
  cpu_type            = "host"
  disks {
    disk_size         = "32G"
    format            = "${var.proxmox_storage_format}"
    storage_pool      = "${var.proxmox_storage_pool}"
    storage_pool_type = "${var.proxmox_storage_pool_type}"
    type              = "scsi"
  }
  http_directory           = "http"
  insecure_skip_tls_verify = false
  iso_file                 = "${var.proxmox_iso_pool}/${var.os_image}"
  memory                   = "4096"
  network_adapters {
    model  = "virtio"  
    bridge = "vmbr0"
    firewall = true
  }
  node                 = "${var.proxmox_node}"
  os                   = "l26"
  proxmox_url          = "${var.proxmox_api_url}"
  scsi_controller      = "virtio-scsi-single"
  ssh_password         = "${var.ssh_password}"
  ssh_port             = 22
  ssh_timeout          = "15m"
  ssh_username         = "root"
  template_description = "${var.template_description}"
  template_name        = "${var.template_name}"
  
  unmount_iso          = true
  
  vm_id                = "140"
  vm_name              = "rocky-linux-9-build"
}

# a build block invokes sources and runs provisioning steps on them. The
# documentation for build blocks can be found here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/build
build {
  sources = ["source.proxmox.rocky-linux-9-base"]

  provisioner "ansible-local" {
    playbook_file = "./ansible/RL9-base.yml"
  }

}
