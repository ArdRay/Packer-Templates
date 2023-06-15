# Packer Templates

## Usage

1. `cd rocky-linux-9`
2. `packer init config.pkr.hcl`
3. `packer validate -var-file='../credentials.pkr.hcl' ./rocky-linux-9-base.pkr.hcl`
4. `packer build -var-file='../credentials.pkr.hcl' ./rocky-linux-9-base.pkr.hcl`

## Variable file structure

### credentials.pkr.hcl

```
proxmox_api_url = "https://pve.internal:8006/api2/json"
proxmox_api_token_id = "root@pam!packer"
proxmox_api_token_secret = "<secret>"
proxmox_node = "prox"
ssh_password = "<secret>"
```