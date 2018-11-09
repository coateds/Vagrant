# Current vagrant boxes:
* jenkins-docker
  * container building jenkins pipeline here
  * highly useful
* PostGres
  * was built for LA course, 
  * `psql postgres://coateds:H0rnyBunny@172.28.128.3:80/sample -c "SELECT count(id) FROM employees;"`
* python-27-gui - This is no longer needed??
  * python 2.7.5 installed
  * gui installed
  * To be used to dev syntax for container pipeline
* PythonDevCen
  * Python 3.6
  * gui
* PythonDevUbu
  * Never really developed
* st2-sandbox
  * StackStorm installed 
  * Python 2.7.5
  * GUI
  * Firefox
    * https://192.168.16.26:3002/  for Runway
    * https://localhost/  for Stackstorm
  * hiflexdev001
  * 192.168.16.25
* runway  ---  Shut this down in deference to the Win10 IntelliJ box??
  * Runway installed
  * No GUI installed
  * python 2.7.5
  * To be used to dev syntax for container pipeline
  * https://[ipaddress]:3002 to see local (dev) instance of runway
  * hiflexdev002
  * 192.168.16.26
* win10-runway-dev
  * My first Vagrant Windows
  * Loaded with IntelliJ/Git/Runway
  * This works! Keep!

# Trying to go a bit futher with chef-solo:  
* https://andrewtarry.com/chef_with_vagrant/
* chef-demo
  * Ubuntu trying to replicate process from Andrew Tarry
* win10-chef-demo
  * migrate from chef demo to Windows
  * Goal is Chocolatey



# Build processes

## vagrant/CentOS74/GUI
Start with the gui OFF
Vagrantfile:
```
Vagrant.configure("2") do |config|

  config.vm.box = "bento/centos-7.4"

  config.vm.network "private_network", type: "dhcp"

  config.vm.provider "virtualbox" do |vb|
    # vb.gui = true  # brings up the vm in gui window
    vb.memory = 2048
    vb.cpus = 2
  end

  config.vm.provision "chef_solo" do |chef|
    chef.add_recipe "[cookbook]"
  end
end
```

cookbooks/[cookbook]/recipes/default.rb
```
# Add/Configure the wandisco repo to get the latest version of Git
remote_file '/etc/pki/rpm-gpg/RPM-GPG-KEY-WANdisco' do
    source 'http://opensource.wandisco.com/RPM-GPG-KEY-WANdisco'
    action :create
end

file "/etc/yum.repos.d/wandisco-git.repo" do
    content "[WANdisco-git]
name=WANdisco Distribution of git
baseurl=http://opensource.wandisco.com/rhel/$releasever/git/$basearch
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-WANdisco"
end

package "git"
package "vim-enhanced"
package "dos2unix"
package "kernel-devel"

file "/etc/yum.repos.d/docker.repo" do
    content "[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/7/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg"
end

package "docker-engine"

service "docker" do
    action [:enable, :start]
end

# This is experimental from here!!
execute "yum groupinstall -y 'gnome desktop'"
execute "yum install -y 'xorg*'"
execute "yum remove -y initial-setup initial-setup-gui"
execute "systemctl isolate graphical.target"
execute "systemctl set-default graphical.target"
```

!! Docker must be installed to install rw & ct

When complete, shutdown and insert a CDRom from the VirtualBox GUI
* load VBoxGuestAdditions_5.2.12.iso
* functionality moved to script
  * `sudo mkdir /mnt/VBoxLinuxAdditions`
  * `sudo mount /dev/cdrom /mnt/VBoxLinuxAdditions`
  * Run the install script - `sudo sh /mnt/VBoxLinuxAdditions/VBoxLinuxAdditions.run`

Also increase video memory to 64

Turn the gui on in the Vagrantfile and start

[install vscode procedure]

## Set up StackStorm
In the Vagrantfile:
`config.vm.provision :file, source: "runme.sh", destination: "/home/vagrant/runme.sh"`

copies the script from the host
* chmod
* dos2unix
* mod the sh script change grep st2 to grep st22
```
  if [[ ! $(rpm -qa | grep st2) ]]; then
    st2="st2 Install_Stackstorm OFF "
  fi
```

Copy examples to st2 content directory
* `sudo cp -r /usr/share/doc/st2/examples/ /opt/stackstorm/packs/`

Login
* `st2 login [admin]`

Run setup
* `st2 run packs.setup_virtualenv packs=examples`

Reload stackstorm context
* `st2ctl reload --register-all`

## Setup IDE (VSCode)
* Put user vagrant in st2packs group
  * `sudo usermod -a -G st2packs vagrant`
* chgrp examples pack (and others as needed)
* chmod g+w as needed

# Setup multiple hosts in one vagrant file
```Ruby

Vagrant.configure("2") do |config|
  # Every Vagrant development environment requires a box.
  config.vm.box = "CentOS7"

  # The url from where the 'config.vm.box' box will be fetched
  config.vm.box_url = "http://cloud.centos.org/centos/7/vagrant/x86_64/images/CentOS-7-x86_64-Vagrant-1805_01.VirtualBox.box"

  # Setup for Host1
  config.vm.define "host1" do |host1|
    host1.vm.hostname = "host1"
    host1.vm.network "private_network", type: "dhcp"
  end

  # Setup for Host2
  config.vm.define "host2" do |host2|
    host2.vm.hostname = "host2"
    host2.vm.network "private_network", type: "dhcp"
  end
end
```

# Syncd folders (bi-drectional Windows Host, Linux Guest)

`sudo yum install cifs-utils -y`

Vagrantfile
```
Vagrant.configure("2") do |config|
  config.vm.box = "bento/centos-7.4"
  config.vm.network "private_network", type: "dhcp"
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 2048
    vb.cpus = 2
    # Weird, this seems to need to be here inside this 'loop'
    config.vm.synced_folder "sync/", "/vagrant", type: "smb"
  end
end
```
