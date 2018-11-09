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
 
# file "/etc/yum.repos.d/docker.repo" do
#     content "[dockerrepo]
# name=Docker Repository
# baseurl=https://yum.dockerproject.org/repo/main/centos/7/
# enabled=1
# gpgcheck=1
# gpgkey=https://yum.dockerproject.org/gpg"
# end
# 
# package "docker-engine"
# 
# service "docker" do
#     action [:enable, :start]
# end
# 
# # I need to add 'jenkins' as well
# group 'docker' do
#   action :modify
#   members ['vagrant']
#   append true
# end

execute "dos2unix /home/vagrant/load-guest-additions.sh"
execute "dos2unix /home/vagrant/load-vscode.sh"
execute "dos2unix /home/vagrant/runme.sh"

file '/home/vagrant/runme.sh' do
    mode '0674'
end

file '/home/vagrant/load-vscode.sh' do
    mode '0674'
end

file '/home/vagrant/load-guest-additions.sh' do
    mode '0674'
end

# This is experimental from here!!
# execute "yum groupinstall -y 'gnome desktop'"
# execute "yum install -y 'xorg*'"
# execute "yum remove -y initial-setup initial-setup-gui"
# execute "systemctl isolate graphical.target"
# execute "systemctl set-default graphical.target"
