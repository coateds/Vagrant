#!/usr/bin/env bash
# exit 0
set -ex

yum groupinstall -y 'gnome desktop'
yum install -y 'xorg*'
yum remove -y initial-setup initial-setup-gui
systemctl isolate graphical.target
systemctl set-default graphical.target   # to make this persistant
