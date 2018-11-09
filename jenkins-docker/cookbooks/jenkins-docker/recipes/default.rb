# This line takes a long time and may not be strictly necessary?
# execute "yum -y update"

# this did not really work the way I wanted it to
# it seemed to require a reboot and other servers could not resolve with
# an entry in /etc/hosts
# hostname 'jenkins-docker'

package "java-1.8.0-openjdk"
package "epel-release"
package "vim-enhanced"
package "git"
package "sshpass"

file "/etc/yum.repos.d/jenkins.repo" do
    content "[jenkins]
name=Jenkins-stable
baseurl=http://pkg.jenkins.io/redhat-stable
gpgcheck=1
gpgkey=https://jenkins-ci.org/redhat/jenkins-ci.org.key"
end

package "jenkins-2.121.1"

service "jenkins" do
    action [:enable, :start]
end

file "/etc/yum.repos.d/docker.repo" do
    content "[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/7/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg"
end

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

package "docker-engine"

service "docker" do
    action [:enable, :start]
end

# I need to add 'jenkins' as well
group 'docker' do
  action :modify
  members ['vagrant', 'jenkins']
  append true
end

file "/home/vagrant/my-file.txt" do
    content "This is my file"
end

# execute "yum -y install yum-utils"
# execute "yum -y groupinstall development"
# execute "yum -y install https://centos7.iuscommunity.org/ius-release.rpm"

# package "python36u"
# execute "yum -y install python36u"

# package "python36u-pip"
# package "python36u-devel"

# https://jenkins-ci.org/redhat/jenkins-ci.org.key