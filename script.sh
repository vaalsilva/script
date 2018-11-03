#!/bin/bash


#test aws --profile dev-ongoing --region us-east-1 ec2 run-instances --image-id ami-6871a115 --count 1 --instance-type t2.micro --key-name Valkeyria --subnet-id subnet-930180e5 --associate-public-ip-address --security-group-ids sg-07ae0b66c8bb81119 --query 'Instances[*].InstanceId' --output text
#tag_test aws --profile dev-ongoing --region us-east-1 ec2 create-tags --resources i-0d8dc01dfa7754785 --tags Key=Name,Value="Val-weblogic-teste"
#public_ip_test aws --profile dev-ongoing --region us-east-1 ec2 describe-instances --instance-ids i-0d8dc01dfa7754785 | grep PublicIpAddress | sed 's/                    "PublicIpAddress": "//g' | sed 's/",//g'


# Disable SELinux
sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config

# Creating a swap space
dd if=/dev/zero of=/swapfile bs=1024 count=612536
mkswap /swapfile
chmod 600 /swapfile
swapon /swapfile
echo "/swapfile swap swap defaults 0 0" >> /etc/fstab

# Criar usuário e grupo de administração
groupadd -g 1001 oinstall
useradd -u 1001 -g oinstall oracle

# Criar diretórios onde os arquivos serão instalados
mkdir -p /u01/app/oracle/middleware && mkdir -p /u01/app/oracle/config/domains/mydomain && mkdir -p /u01/app/oracle/config/applications && mkdir -p /u01/software
chown -R oracle:oinstall /u01
chmod -R 775 /u01/

# Install wget
sudo yum install wget -y

# Download dos binários e arquivos de configuração
cd /u01/software/
sudo -u oracle wget https://s3.amazonaws.com/valeria-weblogic-teste/jdk-8u191-linux-x64.tar.gz && sudo -u oracle wget https://s3.amazonaws.com/valeria-weblogic-teste/fmw_12.2.1.0.0_wls.jar && sudo -u oracle wget https://s3.amazonaws.com/valeria-weblogic-teste/shoppingcart.war && sudo -u oracle wget https://s3.amazonaws.com/valeria-weblogic-teste/wls.rsp && sudo -u oracle wget https://s3.amazonaws.com/valeria-weblogic-teste/oraInst.loc && sudo -u oracle wget https://s3.amazonaws.com/valeria-weblogic-teste/domain.py && sudo -u oracle wget https://s3.amazonaws.com/valeria-weblogic-teste/boot.properties

# Exportar variáveis
sudo -u oracle echo "export MW_HOME=/u01/app/oracle/middleware" >> /home/oracle/.bach_profile && echo "export WLS_HOME=/u01/app/oracle/middleware/wlserver" >> /home/oracle/.bach_profile && echo "export WL_HOME=/u01/app/oracle/middleware/wlserver" >> /home/oracle/.bach_profile && echo "export JAVA_HOME=/u01/app/oracle/jdk1.8.0_191" >> /home/oracle/.bach_profile && echo "export PATH=/u01/app/oracle/jdk1.8.0_191/bin:$PATH" >> /home/oracle/.bach_profile

# Install JDK
cd /u01/app/oracle/
sudo -u oracle tar -xvzf /u01/software/jdk-8u191-linux-x64.tar.gz

# Iniciar instalação via silent mode.
cd /u01/app/oracle/jdk1.8.0_191
sudo -u oracle /u01/app/oracle/jdk1.8.0_191/bin/java -Xmx1024m -jar /u01/software/fmw_12.2.1.0.0_wls.jar -silent -responseFile /u01/software/wls.rsp -invPtrLoc /u01/software/oraInst.loc

# Determinar qual versão do JDK será usada
. /u01/app/oracle/middleware/wlserver/server/bin/setWLSEnv.sh

# Criando domínio
cd /u01/app/oracle/middleware/oracle_common/common/bin
./wlst.sh /u01/software/domain.py

# Alterando configuração do java para iniciar weblogic
sed 's/-Xshare:off -XX:+UnlockCommercialFeatures/-Xshare:off -XX:+UnlockCommercialFeatures -XX:+ResourceManagement/g' /u01/app/oracle/config/domains/mydomain/bin/startWebLogic.sh

# Movendo o arquivo boot-properties
mkdir -p /u01/app/oracle/config/domains/mydomain/servers/weblogic/security/
mv /u01/software/boot.properties /u01/app/oracle/config/domains/mydomain/servers/weblogic/security/

# iniciar WebLogic
cd /u01/app/oracle/config/domains/mydomain/
nohup ./startWebLogic.sh &
