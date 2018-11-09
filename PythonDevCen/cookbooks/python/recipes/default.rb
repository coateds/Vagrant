# This line takes a long time and may not be strictly necessary?
# execute "yum -y update"

execute "yum -y install yum-utils"
execute "yum -y groupinstall development"
execute "yum -y install https://centos7.iuscommunity.org/ius-release.rpm"

package "python36u"
# execute "yum -y install python36u"

package "python36u-pip"
package "python36u-devel"

package "vim-enhanced"