# Documentation - Rocky CIS: https://www.tenable.com/audits/CIS_Rocky_Linux_9_v1.0.0_L2_Server
# Documentation - RHEL Kickstart: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/installation_guide/sect-kickstart-syntax

# Sets up the authentication options for the system
authselect minimal

# Causes the installer to ignore the specified disks.
ignoredisk --only-use=sda

# Removes partitions from the system, prior to creation of new partitions.
clearpart --none --initlabel

# Install from the first optical drive on the system. 
cdrom

# Perform the kickstart installation in text mode.
text

# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'

# System language
lang en_US.UTF-8

# Network information
network  --bootproto=dhcp --ipv6=auto --activate --onboot=yes
repo --name="AppStream" --baseurl=https://dl.rockylinux.org/pub/rocky/9.2/AppStream/x86_64/ --install
repo --name="EPEL" --baseurl=https://dl.fedoraproject.org/pub/epel/9/Everything/x86_64/ --install

# Root password
rootpw --iscrypted $6$eof03f$Vg.Du8K94G23m7tQz9Op2l3g85ncPCmcZmSTg1dR770kFsdtswMrI9o2/6YNAuRtW4w3VkkTmcveAkEvbrzdk1

# Determine whether the firstboot starts the first time the system is booted.
firstboot --disabled

# If present, X is not configured on the installed system. 
skipx

# System services
services --disabled="kdump" --enabled="sshd,rsyslog,chronyd"

# System timezone
timezone Europe/Zurich

# Disk partitioning information
# part / --fstype="xfs" --grow --size=6144
# part swap --fstype="swap" --size=512

part /dev/shm                                                                                               # xccdf_org.ssgproject.content_rule_partition_for_dev_shm
part /boot --size 512 --asprimary --fstype=ext4 --ondrive=sda --label=boot
part pv.1 --size 1 --grow --fstype=ext4 --ondrive=sda

volgroup system --pesize=1024 pv.1

logvol / --fstype ext4 --vgname system --size=8192 --name=root
logvol /var --fstype ext4 --vgname system --size=2048 --name=var --fsoptions="nodev"                        # xccdf_org.ssgproject.content_rule_partition_for_var
logvol /home --fstype ext4 --vgname system --size=1024 --name=home --fsoptions="nodev"                      # xccdf_org.ssgproject.content_rule_partition_for_home
logvol /tmp --fstype ext4 --vgname system --size=1024 --name=tmp --fsoptions="nodev,noexec,nosuid"          # xccdf_org.ssgproject.content_rule_partition_for_tmp
logvol swap --vgname system --size=2048 --name=swap
logvol /var/log --fstype ext4 --vgname system --size=2048 --name=var_log --fsoptions="nodev"                # xccdf_org.ssgproject.content_rule_partition_for_var_log
logvol /var/tmp --fstype ext4 --vgname system --size=1024 --name=var_tmp --fsoptions="nodev,nosuid,noexec"  # xccdf_org.ssgproject.content_rule_partition_for_var_tmp
logvol /var/log/audit --fstype=ext4 --vgname=system --size=512 --name=var_log_audit --fsoptions="nodev"
reboot

%packages
@^minimal-environment
openssh-server
openssh-clients
epel-release
curl

# Ansible
python3
python3-libselinux
ansible

# unnecessary firmware
-aic94xx-firmware
-atmel-firmware
-b43-openfwwf
-bfa-firmware
-ipw2100-firmware
-ipw2200-firmware
-ivtv-firmware
-iwl100-firmware
-iwl1000-firmware
-iwl3945-firmware
-iwl4965-firmware
-iwl5000-firmware
-iwl5150-firmware
-iwl6000-firmware
-iwl6000g2a-firmware
-iwl6050-firmware
-libertas-usb8388-firmware
-ql2100-firmware
-ql2200-firmware
-ql23xx-firmware
-ql2400-firmware
-ql2500-firmware
-rt61pci-firmware
-rt73usb-firmware
-xorg-x11-drv-ati-firmware
-zd1211-firmware

# CIS compliance
-gdm
-xorg-x11-server-common
%end

%addon com_redhat_kdump --disable
%end

%post

# this is installed by default but we don't need it in virt
# echo "Removing linux-firmware package."
# yum -C -y remove linux-firmware

# Remove firewalld; it is required to be present for install/image building.
# echo "Removing firewalld."
# yum -C -y remove firewalld --setopt="clean_requirements_on_remove=1"

# remove avahi and networkmanager
# echo "Removing avahi/zeroconf and NetworkManager"
# yum -C -y remove avahi\* 

# echo -n "Getty fixes"
# although we want console output going to the serial console, we don't
# actually have the opportunity to login there. FIX.
# we don't really need to auto-spawn _any_ gettys.
# sed -i '/^#NAutoVTs=.*/ a\
# NAutoVTs=0' /etc/systemd/logind.conf

# set virtual-guest as default profile for tuned
# echo "virtual-guest" > /etc/tuned/active_profile

# Because memory is scarce resource in most cloud/virt environments,
# and because this impedes forensics, we are differing from the Fedora
# default of having /tmp on tmpfs.
# echo "Disabling tmpfs for /tmp."
# systemctl mask tmp.mount

# cat <<EOL > /etc/sysconfig/kernel
# UPDATEDEFAULT specifies if new-kernel-pkg should make
# new kernels the default
# UPDATEDEFAULT=yes

# DEFAULTKERNEL specifies the default kernel package type
# DEFAULTKERNEL=kernel
# EOL

# make sure firstboot doesn't start
# echo "RUN_FIRSTBOOT=NO" > /etc/sysconfig/firstboot

# echo "Fixing SELinux contexts."
# touch /var/log/cron
# touch /var/log/boot.log
# mkdir -p /var/cache/yum
# /usr/sbin/fixfiles -R -a restore

# reorder console entries
# sed -i 's/console=tty0/console=tty0 console=ttyS0,115200n8/' /boot/grub2/grub.cfg

#echo "Zeroing out empty space."
# This forces the filesystem to reclaim space from deleted files
# dd bs=1M if=/dev/zero of=/var/tmp/zeros || :
# rm -f /var/tmp/zeros
# echo "(Don't worry -- that out-of-space error was expected.)"

# dnf update -y

# sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers

# Temporarily - For provisioning
echo "PermitRootLogin yes" > /etc/ssh/sshd_config.d/allow-root-ssh.conf

dnf clean all
%end

