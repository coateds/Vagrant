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
package "kernel-devel"

# This is experimental from here!!
execute "yum groupinstall -y 'gnome desktop'"
execute "yum install -y 'xorg*'"
execute "yum remove -y initial-setup initial-setup-gui"
execute "systemctl isolate graphical.target"
execute "systemctl set-default graphical.target"

######################
# Turns out all of this good work was a waste of time
# The Centos 7.4 vagrant image I am using already includes
# Python 2.7.5
# Keeping the work for future reference
######################
# package "gcc"
# package "openssl-devel"
# package "bzip2-devel"
# 
# remote_file '/usr/src/Python-2.7.15.tgz' do
#     source 'https://www.python.org/ftp/python/2.7.15/Python-2.7.15.tgz'
#     action :create
# end
# 
# # There seems to be no Chef built in resource to untar something
# # Use execute to extract to /usr/src/Python-2.7.15
# execute 'extract Python-2.7.15' do
#   command 'tar xzf Python-2.7.15.tgz'
#   cwd '/usr/src'
#   not_if { File.exists?("/usr/src/Python-2.7.15/setup.py") }
# end
# 
# # Now execute from /usr/src/Python-2.7.15
# # ./configure --enable-optimizations
# # make altinstall
# 
# # This will create a Makefile - yes
# # idempotence works with this test!!
# execute 'enable optimizations' do
#     command '/usr/src/Python-2.7.15/configure --enable-optimizations'
#     cwd '/usr/src/Python-2.7.15'
#     not_if { File.exists?("/usr/src/Python-2.7.15/Makefile") }
# end
# 
# # This will install python 2.7.15 - yes
# # idempotence works with this test!!
# execute 'make python' do
#     command 'make altinstall'
#     cwd '/usr/src/Python-2.7.15'
#     not_if { File.exists?("/usr/local/bin/python2.7") }
# end

# Stopping here to work on Chad's st2-sandbox