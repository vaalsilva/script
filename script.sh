#!/bin/bash

sudo su
# Tornar SELinux permissive
sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config

# Criar swap space
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

# Instalar wget
sudo yum install wget -y

# Download dos binários e arquivos de configuração
cd /u01/software/
sudo -u oracle wget https://s3.amazonaws.com/valeria-weblogic-teste/jdk-8u191-linux-x64.tar.gz && sudo -u oracle wget https://s3.amazonaws.com/valeria-weblogic-teste/fmw_12.2.1.0.0_wls.jar && sudo -u oracle wget https://s3.amazonaws.com/valeria-weblogic-teste/shoppingcart.war && sudo -u oracle wget https://s3.amazonaws.com/valeria-weblogic-teste/wls.rsp && sudo -u oracle wget https://s3.amazonaws.com/valeria-weblogic-teste/oraInst.loc && sudo -u oracle wget https://s3.amazonaws.com/valeria-weblogic-teste/domain.py && wget https://s3.amazonaws.com/valeria-weblogic-teste/boot.properties

# Exportar variáveis
sudo su - oracle
export MW_HOME=/u01/app/oracle/middleware && export WLS_HOME=$MW_HOME/wlserver && export WL_HOME=$WLS_HOME && export JAVA_HOME=/u01/app/oracle/jdk1.8.0_191 && export PATH=$JAVA_HOME/bin:$PATH

# Instalar JDK
cd /u01/app/oracle/
tar -xvzf /u01/software/jdk-8u191-linux-x64.tar.gz

# Iniciar instalação via silent mode.
cd $JAVA_HOME
$JAVA_HOME/bin/java -Xmx1024m -jar /u01/software/fmw_12.2.1.0.0_wls.jar -silent -responseFile /u01/software/wls.rsp -invPtrLoc /u01/software/oraInst.loc

# Determinar qual versão do JDK será usada
. $WLS_HOME/server/bin/setWLSEnv.sh

# Criar domínio
cd $MW_HOME/oracle_common/common/bin
./wlst.sh /u01/software/domain.py

# Alterar configuração do java para iniciar weblogic
#sed 's/-Xshare:off -XX:+UnlockCommercialFeatures/-Xshare:off -XX:+UnlockCommercialFeatures -XX:+ResourceManagement/g' /u01/app/oracle/config/domains/mydomain/bin/startWebLogic.sh

# Mover o arquivo boot-properties
mkdir -p /u01/app/oracle/config/domains/mydomain/servers/weblogic/security/
mv /u01/software/boot.properties /u01/app/oracle/config/domains/mydomain/servers/weblogic/security/

# Iniciar WebLogic
cd /u01/app/oracle/config/domains/mydomain/
nohup ./startWebLogic.sh &
