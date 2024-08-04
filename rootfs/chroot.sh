#!/bin/bash

LANG_TARGET=zh_CN.UTF-8
PASSWORD=5115
NAME=UFI001C
PARTUUID=a7ab80e8-e9d1-e8cd-f157-93f69b1d141e

cat <<EOF > /etc/apt/sources.list
deb http://deb.debian.org/debian/ trixie main contrib non-free non-free-firmware
# deb-src http://deb.debian.org/debian/ trixie main contrib non-free non-free-firmware

deb http://deb.debian.org/debian/ trixie-updates main contrib non-free non-free-firmware
# deb-src http://deb.debian.org/debian/ trixie-updates main contrib non-free non-free-firmware

deb http://deb.debian.org/debian/ trixie-backports main contrib non-free non-free-firmware
# deb-src http://deb.debian.org/debian/ trixie-backports main contrib non-free non-free-firmware

deb http://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
# deb-src http://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
EOF

cat <<EOF > /etc/fstab
PARTUUID=$PARTUUID / ext4 defaults,noatime,commit=600,errors=remount-ro 0 1
tmpfs /tmp tmpfs defaults,nosuid 0 0
EOF

cat <<EOF >/etc/rc.local
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.
nmcli c u USB

exit 0
EOF
chmod +x /etc/rc.local
systemctl enable --now rc-local

apt-get update
apt-get full-upgrade -y
apt-get install -y locales network-manager modemmanager openssh-server chrony fake-hwclock zram-tools rmtfs qrtr-tools sudo
apt-get install -y /tmp/*.deb
apt-get update
sudo apt-get upgrade -y

sed -i -e "s/# $LANG_TARGET UTF-8/$LANG_TARGET UTF-8/" /etc/locale.gen
dpkg-reconfigure --frontend=noninteractive locales
update-locale LANG=$LANG_TARGET LC_ALL=$LANG_TARGET LANGUAGE=$LANG_TARGET
echo -n >/etc/resolv.conf
echo -e "$PASSWORD\n$PASSWORD" | passwd
echo $NAME > /etc/hostname
sed -i "1a 127.0.0.1\t$NAME" /etc/hosts
sed -i "s/::1\t\tlocalhost/::1\t\tlocalhost $NAME/g" /etc/hosts
sed -i 's/^.\?PermitRootLogin.*$/PermitRootLogin yes/g' /etc/ssh/sshd_config
sed -i 's/^.\?ALGO=.*$/ALGO=lzo-rle/g' /etc/default/zramswap
sed -i 's/^.\?PERCENT=.*$/PERCENT=300/g' /etc/default/zramswap

sed -i s/'openstick-failsafe'/UFI001C/g /usr/sbin/openstick-button-monitor.sh
sed -i s/'openstick-failsafe'/UFI001C/g /usr/sbin/openstick-gc-manager.sh
sed -i s/'openstick-failsafe'/UFI001C/g /usr/sbin/openstick-startup-diagnose.sh
sed -i s/'usb-failsafe'/USB/g /usr/sbin/openstick-startup-diagnose.sh

vmlinuz_name=$(basename /boot/vmlinuz-*)
cat <<EOF > /tmp/info.md
- 内核版本: ${vmlinuz_name#*-}
- 默认用户名: root
- 默认密码: $PASSWORD
- WiFi名称: openstick-failsafe
- WiFi密码: 12345678
EOF
rm -rf /etc/ssh/ssh_host_* /var/lib/apt/lists
apt clean
exit
