#!/bin/bash


# Criar usuário e grupo de administração
groupadd -g 1001 oinstall
useradd -u 1001 -g oinstall oracle

# Criar diretórios onde os arquivos serão instalados
mkdir -p /u01/app/oracle/middleware && mkdir -p /u01/app/oracle/config/domains && mkdir -p /u01/app/oracle/config/applications
chown -R oracle:oinstall /u01
chmod -R 775 /u01/
