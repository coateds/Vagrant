#!/bin/bash

# Get any passed in param options, this is mainly for vagrant builds
if [[ $1 ]]; then
  if [[ $(echo $1 | grep st2) ]]; then
    st2="st2"
  fi
  if [[ $(echo $1 | grep st2) ]]; then
    st2="kitchen"
  fi
  if [[ $(echo $1 | grep st2) ]]; then
    st2="ct"
  fi
  if [[ $(echo $1 | grep st2) ]]; then
    st2="rw"
  fi
fi

# set the default st2 user, password and version
st2user="st2admin"
st2passwd="Ch@ngeMe"
st2release="stable"
st2version="2.6.1"

# Get the local user who is doing the work/install
user=$(who | awk '{print $1}' | uniq)
group=$(getent passwd ${user} | awk -F ':' '{print $4}')
domain=$(hostname -d)

# Where is this launched from, starting directory
startdir=$(pwd)

# Determine the fqdn of the stash server
if [[ ${domain} == "karmalab.net" ]]; then
  stash="stash.karmalab.net"
elif [[ ${domain} == "idxlab.expedmz.net" ]]; then
  stash="stash.karmalab.net"
elif [[ ${domain} == "sea.corp.expecn.com" ]]; then
  stash="stash.sea.corp.expecn.com"
elif [[ ${domain} == "idxcorp.expedmz.com" ]]; then
  stash="stash.sea.corp.expecn.com"
else
  stash="stash.sea.corp.expecn.com"
fi

if [[ ! -d /opt ]]; then
  mkdir /opt
fi

#start of the UI for choosing install options

# THis loop is to ensure the person launching this is in evacadmins
#if [[ ! $(getent group evacadmins | grep ${user}) ]];then
#  echo "I am sorry, but your no in the SG evacadmins and can't continue."
#  exit
#fi

# IF no passed in params, determine what has already been installed
if [[ $# == 0 ]]; then
  if [[ ! $(rpm -qa | grep st2-2.6.1) ]]; then
    st2="st2 Install_Stackstorm OFF "
  fi

  if [[ ! $(rpm -qa | grep chefdk) ]]; then
    kitchen="kitchen Install_ChefDK_and_Test_Kitchen OFF "
  fi

  if [[ ! -d /opt/runway ]]; then
    rw="rw Install_Runway OFF "
  fi

  if [[ ! -d /opt/controltower ]]; then
    ct="ct Install_ControlTower OFF "
  fi
fi

# If no passed in params, launch the initial whiptail to ask what you want installed
# Choices will be stored in a file called choices in the start directory
if [[ $# == 0 ]]; then
  content="${st2} ${kitchen} ${rw} ${ct}"
  whiptail --title "What do you want to install?" --checklist \
    "Choose what you want installed" 20 78 5 \
    "packs" "Chose_what_Stackstorm_packs_to_install" OFF \
    "renew_vault" "Only use this to update vault token" OFF \
    ${content} 2>${startdir}/choices
else
  echo $1 | awk -F '=' '{print $2}' >${startdir}/choices
fi

# Install EPEL
if [[ $(grep 'st2\|ct\|rw\|kitchen' ${startdir}/choices) ]]; then
  if [[ ! -f /etc/yum.repos.d/epel.repo ]]; then
    echo "*** Installing EPEL ***"
    yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
  fi
  if [[ ! -f /etc/pki/ca-trust/source/anchors/Expedia\ Internal\ 1C.crt ]]; then
    echo "*** Installing internal Expedia certs"
    curl -ks  https://${stash}/projects/SCSC/repos/scs_ca_certificates/raw/files/default/Expedia%20Internal%201C.pem?at=refs%2Fheads%2Fmaster > /etc/pki/ca-trust/source/anchors/Expedia\ Internal\ 1C.crt
  fi
  if [[ ! -f /etc/pki/ca-trust/source/anchors/Expedia\ MS\ Root\ CA\ \(2048\).crt ]]; then
    curl -ks https://${stash}/projects/SCSC/repos/scs_ca_certificates/raw/files/default/Expedia%20MS%20Root%20CA%20\(2048\).pem?at=refs%2Fheads%2Fmaster > /etc/pki/ca-trust/source/anchors/Expedia\ MS\ Root\ CA\ \(2048\).crt
  fi
  if [[ ! -f /etc/pki/ca-trust/source/anchors/ExpediaRoot2015.crt ]]; then
    curl -ks https://stash.sea.corp.expecn.com/projects/SCSC/repos/scs_ca_certificates/raw/files/default/ExpediaRoot2015.pem?at=refs%2Fheads%2Fmaster > /etc/pki/ca-trust/source/anchors/ExpediaRoot2015.crt
  fi
  if [[ ! -f /etc/pki/ca-trust/source/anchors/Internal2015C1.crt ]]; then
    curl -ks https://stash.sea.corp.expecn.com/projects/SCSC/repos/scs_ca_certificates/raw/files/default/Internal2015C1.pem?at=refs%2Fheads%2Fmaster > /etc/pki/ca-trust/source/anchors/Internal2015C1.crt
  fi
  update-ca-trust extract
  update-ca-trust force-enable
fi


# Parse the choices file to start the installs
# Install Stackstorm
if [[ $(grep st2 ${startdir}/choices) ]]; then
  # Select between recent stable (e.g. 1.4) or recent unstable (e.g. 1.5dev)
  if [[ $# > 2 ]]; then
    if [[ ${st2release} == "stable" ]] || [[ ${st2release} == "unstable" ]]
    then
      RELEASE_FLAG="--${st2release}"
    else
      echo -e "Use 'stable' for recent stable release, or 'unstable' to live on the edge."
      exit 2
    fi
  fi

  echo "*** Let's install some net tools ***"

  RHTEST=`cat /etc/redhat-release 2> /dev/null | sed -e "s~\(.*\)release.*~\1~g"`

  if [[ -n "$RHTEST" ]]; then
    echo "*** Detected Distro is ${RHTEST} ***"
    hash curl 2>/dev/null || { sudo yum install -y curl; sudo yum install -y nss; }
    sudo yum update -y curl nss
  else
    echo "Unknown Operating System."
    echo "See list of supported OSes: https://github.com/StackStorm/st2vagrant/blob/master/README.md."
    exit 2
  fi

  RHMAJVER=`cat /etc/redhat-release | sed 's/[^0-9.]*\([0-9.]\).*/\1/'`

  echo "*** Let's install some dev tools ***"

  if [[ -n "$RHTEST" ]]; then
    if [[ "$RHMAJVER" == '6' ]]; then
      sudo yum install -y centos-release-SCL
      sudo yum install -y python27
      echo "LD_LIBRARY_PATH=/opt/rh/python27/root/usr/lib64:$LD_LIBRARY_PATH" | sudo tee -a /etc/environment
      sudo ln -s /opt/rh/python27/root/usr/bin/python /usr/local/bin/python
      sudo ln -s /opt/rh/python27/root/usr/bin/pip /usr/local/bin/pip
      source /etc/environment
    elif [[ "$RHMAJVER" == '7' ]]; then
      sudo yum install -y python
    fi
    sudo yum install -y python-pip git jq python2-pip
  fi
  echo "*** Let's install some python tools ***"
  sudo -H pip install --upgrade pip
  sudo -H pip install virtualenv
  sudo -H pip install python-editor
  sudo -H pip install prompt_toolkit
  sudo -H pip install argcomplete
  sudo -H pip install st2client
  echo "*** Let's install StackStorm  ***"
  curl -sSL https://stackstorm.com/packages/install.sh | bash -s -- --user=${st2user} --password=${st2passwd} --version=${st2version} ${st2release}
  echo "*** Disable logging passwords to log ***"
  sed -i 's/LOG.info/#LOG.info/g' /opt/stackstorm/st2/lib/python2.7/site-packages/st2common/util/jinja.py

fi

# Install chefdk and kitchen
if [[ $(grep kitchen ${startdir}/choices) ]]; then
  echo "*** Let's install ChefDK ***"
  yum install -y https://packages.chef.io/files/stable/chefdk/2.4.17/el/7/chefdk-2.4.17-1.el7.x86_64.rpm
  echo "*** Let's install Docker ***"
  yum install -y docker
fi


# Get Chef environment file.  MUST be on vpn or inside network.
if [[ ! -f ${startdir}/env.json ]]; then
  curl -s -k https://${stash}/projects/EFSC/repos/chef_environments-lab/raw/stackstorm-idxlab-ch.json?at=refs%2Fheads%2Fmaster > ${startdir}/env.json
fi

# Install st2 packs, only works IF stackstorm is installed already
if [[ $(grep packs ${startdir}/choices) ]]; then
  if [[ ! $(rpm -qa | grep st2) ]]; then
    echo "You must install stackstorm first"
    exit
  fi
  echo "*** Let's get some stackstorm packs in place, this will take some time ***"
  if [[ ! -f /bin/tidy ]]; then
    yum install -y tidy
  fi
  count=$(curl -s https://${stash}/projects/EFSC | tidy -q --show-warnings no --show-errors 0 | grep data-repo | grep st2-pack |awk -F '>' '{print $2}' | sed s'/<\/a//g' | wc -l)
  list=$(curl -s https://${stash}/projects/EFSC | tidy -q --show-warnings no --show-errors 0  | grep data-repo | grep st2-pack |awk -F '>' '{print $2}' | sed s'/<\/a//g')
  height=$((${count} + 10))
  content=$(for d in ${list};do  echo -ne "${d} ${d} off "; done)
  whiptail --checklist "choose your packs" ${height} 60 ${count} ${content} 2>${startdir}/out

  for i in $(cat out);
  do
    i=$(echo ${i} | sed s/\"//g)
    if [[ ! -d /opt/stackstorm/packs/$(echo $i | sed s/st2-pack-//) ]]; then
      if [[ $(who | awk '{print $1}' | uniq) == "vagrant" ]]; then
        st2 pack install https://${stash}/scm/efsc/${i}.git
      else
        st2 pack install https://${user}@${stash}/scm/efsc/${i}.git
      fi
      # get the registered config files for each pack.
      shortname=$(echo $i | sed 's/st2-pack-//')
      config=$(cat ${startdir}/env.json | jq -j ".default_attributes.environment.st2packs.${shortname}.config_file")
      if [[ ${config} != "null" ]]; then
        ln -s /opt/stackstorm/packs/${shortname}/${config} /opt/stackstorm/configs/${shortname}.yaml
      fi
    fi
  done

  # change perms so anyone can git pull
  # This is probably something that needs more work
  cd /opt/stackstorm/packs/
  for i in $(cat ${startdir}/out)
  do
    i=$(echo ${i} | sed s/\"//g | sed s/st2-pack-//)
    sudo chmod -R 777 ${i}/.git;
  done
  chown -R ${user} /opt/stackstorm/packs/
  chown -R ${user} /opt/stackstorm/configs

  # fixing sudoers
  echo "st2    ALL=(ALL)    NOPASSWD: SETENV: ALL" > /etc/sudoers.d/st2
  echo "root   ALL=(ALL)    ALL" >> /etc/sudoers.d/st2
  echo "Defaults !requiretty" >> /etc/sudoers.d/st2

  # setup the aliases that make life easier
  if [[ ! $(grep st2reload /home/${user}/.bash_profile) ]]; then
    echo "alias st2reload=\"st2ctl reload --register-actions && st2ctl reload --register-configs\""  >> /home/$user/.bash_profile
    echo "PATH=/opt/rh/rh-ruby23/root/usr/local/bin:/opt/rh/rh-ruby23/root/usr/bin:/usr/lib64/qt-3.3/bin:/sbin:/bin:/usr/sbin:/usr/bin:$HOME/.chefdk/gem/ruby/2.4.0/bin" >> /home/$user/.bash_profile
    echo "export PATH" >> /home/$user/.bash_profile
  fi

  for i in $(cat ${startdir}/out)
  do
    i=$(echo ${i} | sed s/\"//g | sed s/st2-pack-//)
    if [[ -d /opt/stackstorm/packs/${i} ]]; then
      echo "alias ${i}=\"cd /opt/stackstorm/packs/${i} && git pull\"" >> /home/$user/.bash_profile
      echo "alias ${i}.action=\"cd /opt/stackstorm/packs/${i}/actions && git pull\"" >> /home/$user/.bash_profile
      echo "alias ${i}.chain=\"cd /opt/stackstorm/packs/${i}/actions/chains && git pull\"" >> /home/$user/.bash_profile
    fi
  done
fi

# Install kitchen extra bits
if [[ $(grep kitchen ${startdir}/choices) ]]; then
/bin/cat <<EOF>/etc/profile.d/enablerh_ruby23.sh
#!/bin/bash
source scl_source enable rh-ruby23
EOF

  echo "*** Let's create a test kitchen instance ***"
  cd /home/${user}/
  if [[ ! -d kitchen/first_kitchen ]]; then
    mkdir -p kitchen/first_kitchen
    cd kitchen/first_kitchen
    kitchen init
    cat ${startdir}/kitchen.yml > /home/${user}/kitchen/first_kitchen/.kitchen.yml
    chown -R ${user}:${group} /home/${user}
  fi


  echo "*** Setting up ruby2.3 ***"
  sudo yum -y install centos-release-scl
  sudo yum -y install rh-ruby23 rh-ruby23-ruby-devel gcc
  source scl_source enable rh-ruby23
  gem install kitchen-docker

  sudo yum-config-manager  --add-repo  https://download.docker.com/linux/centos/docker-ce.repo
  sudo yum-config-manager --enable docker-ce-edge
  sudo yum-config-manager --enable docker-ce-test
  sudo systemctl start docker
  sudo groupadd docker
  sudo usermod -aG docker ${user}
  sudo systemctl enable docker
fi

# Install Runway and all of it's deps
if [[ $(grep rw ${startdir}/choices) ]]; then
  echo "*** Let's setup a Runway dev area ***"
  yum install -y moreutils python-devel openldap-devel python-ldap nginx python2-pip gcc git
  cd /opt
  git config --global http.sslVerify false
  git clone https://stash/scm/evac/runway.git
  git config --global http.sslVerify true
  cd /opt/runway
  chmod 775 runway.py
  sed -i 's/app.logger.info/#app.logger.info/g' run.py
  pip install --upgrade pip
  pip install -r requirements.txt
  pip install hvac
  pip install flask_profiler
  cd /opt
  chown -R ${user} runway
fi

# Install ControlTower and all of it's deps
if [[ $(grep ct ${startdir}/choices) ]]; then
  echo "*** Let's setup a ControlTower dev area ***"
  yum install -y moreutils python-devel openldap-devel python-ldap nginx python2-pip gcc git
  cd /opt
  git config --global http.sslVerify false
  git clone https://stash/scm/evac/controltower.git
  git config --global http.sslVerify true
  cd /opt/controltower
  pip install --upgrade pip
  pip install -r requirements.txt
  cd /opt
  chown -R ${user} controltower
fi

# Download the vault client
if [[ $(grep 'rw\|ct' ${startdir}/choices) ]]; then
  ## downloading vault
  if [[ ! -f /bin/vault ]]; then
    yum install -y unzip
    cd /tmp/
    curl -s -O https://releases.hashicorp.com/vault/0.9.6/vault_0.9.6_linux_amd64.zip
    cd /bin
    unzip /tmp/vault_0.9.6_linux_amd64.zip
  fi
  if [[ ! -f /etc/nginx/cert.crt ]]; then
    echo "*** setup nginx cert for proxy passthru 8080 -> 3002 and 3001 ***"
    openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -subj '/C=US/ST=WA/L=Bellevue/O=Expedia' -keyout /etc/nginx/cert.key -out /etc/nginx/cert.crt
  fi
fi

# Get the right IP address to put into the nginx config files.
if [[ $(grep 'rw\|ct' ${startdir}/choices) ]]; then
  ipaddr=$(hostname -I)
  if [[ $(echo ${ipaddr} | grep "192.168") ]]; then
    ipaddr=$(ifdata -pa enp0s8)
  else
    ipaddr=$(ifdata -pa eth0)
  fi
fi

# Create a port 8080 nginx proxy, this is need in some cases if you working on VPN.
if [[ $(grep rw ${startdir}/choices) ]]; then
  #nginx config for runway
cat<<EOF>/etc/nginx/conf.d/runway.conf
server {
  listen 8080 ssl;
  server_name $(hostname -f);
  ssl_certificate           /etc/nginx/cert.crt;
  ssl_certificate_key       /etc/nginx/cert.key;
  ssl on;
  ssl_session_cache  builtin:1000  shared:SSL:10m;
  ssl_protocols  TLSv1 TLSv1.1 TLSv1.2;
  ssl_ciphers HIGH:!aNULL:!eNULL:!EXPORT:!CAMELLIA:!DES:!MD5:!PSK:!RC4;
  ssl_prefer_server_ciphers on;
  access_log            /var/log/nginx/runway.access.log;
  location / {
    proxy_pass          https://${ipaddr}:3002;
  }
}
EOF
fi

# Create a port 8000 nginx proxy, this is need in some cases if you working on VPN.
if [[ $(grep ct ${startdir}/choices) ]]; then
  #nginx config for control tower
cat<<EOF>/etc/nginx/conf.d/controltower.conf
server {
  listen 8000 ssl;
  server_name $(hostname -f);
  ssl_certificate           /etc/nginx/cert.crt;
  ssl_certificate_key       /etc/nginx/cert.key;
  ssl on;
  ssl_session_cache  builtin:1000  shared:SSL:10m;
  ssl_protocols  TLSv1 TLSv1.1 TLSv1.2;
  ssl_ciphers HIGH:!aNULL:!eNULL:!EXPORT:!CAMELLIA:!DES:!MD5:!PSK:!RC4;
  ssl_prefer_server_ciphers on;
  access_log            /var/log/nginx/controltower.access.log;
  location / {
    proxy_pass          https://${ipaddr}:3001;
  }
}
EOF
fi

# Setup the vault client for either Runway OR ControlTower.  This is not something you can do
# from the vagrant install mainly because it passes a password.  The valut app will
# nativily do this.  I don't want to even try for vagrant for this.  Just run this script manually.
if [[ $(grep 'rw\|ct\|renew_vault' ${startdir}/choices) ]]; then
  echo "*** let's setup the Vault client now. ***"
  # Dialog box for vault variable input
  while [[ "$uservar" == "" ]]
  do
    uservar=$(whiptail --nocancel --title "Setting up Vault: User Name input" --inputbox "What is your SEA user name? You have to be in the evacadmins security group." 10 60  3>&1 1>&2 2>&3)
  done

  while [[ "$dcvar" == "" ]]
  do
    dcvar=$(whiptail --nocancel --title "Setting up Vault: Datacenter" --radiolist "Choose datacenter location." 15 60 4 "ch" "Chandler" OFF "ph" "Phoenix" OFF 3>&1 1>&2 2>&3)
  done
  dcvar=$(echo ${dcvar} | sed 's/"//g')

  while [[ "$passwd" == "" ]]
  do
    passwd=$(whiptail --nocancel --passwordbox "Setting up Vault: Enter password." 10 30 3>&1 1>&2 2>&3)
  done
  token=$(vault login -address=https://vault.${dcvar}.lab.stockyard.io:8200 -method=ldap username=${uservar} password=${passwd} | grep "token " | grep -v 'Success\|helper' | awk '{print $2}')

  echo "*** Thanks $uservar, these environment variables will be added to your profile ***"
  echo "export VAULT_URL=https://vault.${dcvar}.lab.stockyard.io:8200"
  echo "export ENV=dev"
  echo "export DC=${dcvar}"
  echo "export LOGLEVEL=info"
  echo "export SECRET_VAULT=${token}"
  if [[ $(who | awk '{print $1}' | uniq) == "vagrant" ]]; then
    uservar="vagrant"
  fi
fi

# Creating a systemd service for Runway
if [[ $(grep 'rw\|ct\|renew_vault' ${startdir}/choices) ]]; then
  echo "*** Creating a systemd service for Runway ***"
cat <<EOF> /etc/systemd/system/runway.service
[Unit]
Description=Runway dev instance
After=syslog.target

[Service]
ExecStart=/bin/bash -c "export VAULT_URL=https://vault.${dcvar}.lab.stockyard.io:8200 && export ENV=dev && export DC=${dcvar} && export LOGLEVEL=info && export SECRET_VAULT=${token} && cd /opt/runway &&
./run.py"
User=root
WorkingDirectory=/opt/runway
Type=simple

[Install]
WantedBy=multi-user.target
EOF

  systemctl enable runway
  systemctl daemon-reload
  systemctl restart runway
  systemctl restart nginx
fi

# Creating a systemd service for ControlTower
if [[ $(grep 'ct\|rw\|renew_vault' ${startdir}/choices) ]]; then
  echo "*** Creating a systemd service for ControlTower ***"
cat <<EOF> /etc/systemd/system/controltower.service
[Unit]
Description=ControlTower dev instance
After=syslog.target

[Service]
ExecStart=/bin/bash -c "export VAULT_URL=https://vault.${dcvar}.lab.stockyard.io:8200 && export ENV=dev && export DC=${dcvar} && export LOGLEVEL=info && export SECRET_VAULT=${token} && cd /opt/controltower/api && ./controltower.py"
User=root
WorkingDirectory=/opt/controltower
Type=simple

[Install]
WantedBy=multi-user.target
EOF

  systemctl enable controltower
  systemctl daemon-reload
  systemctl restart controltower
  systemctl restart nginx
fi

# The end
echo "********************************************************************"
echo "********************************************************************"
if [[ $(grep ct ${startdir}/choices) ]]; then
  echo "*** controltower should be reachable on ports 3001 and 8000"
elif [[ $(grep rt ${startdir}/choices) ]]; then
  echo "*** runway should be reachable on ports 3002 and 8080"
elif [[ $(grep st2 ${startdir}/choices) ]]; then
  echo "*** Stackstorm really needs a reboot after installing"
elif [[ $(grep kitchen ${startdir}/choices) ]]; then
  echo "*** Chef kitchen and Docker really need a reboot after installing"
  echo "*** Note, user=st2admin, password=Ch@ngeMe"
fi
echo "${user} your setup is now complete, to make changes rerun runme.sh  "
echo "********************************************************************"
echo "********************************************************************"