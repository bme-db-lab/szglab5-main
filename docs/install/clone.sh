#!/bin/bash

# Xen clone script - LVM snapshot version
# Szasz Marton <szaszm@sch.bme.hu>
# based on the work of Jozsef Marton <jmarton@omikk.bme.hu>
#

#set -v -x
set -e

#On the host OS, the following directory will be used to hold backup files during the clone procedure
BACKUP_DIR=/tmp

SNAPSHOT_PEFIX=snapshot

VSERVER_PROD=deb
VSERVER_DEV=devdeb

SNAPSHOT_NAME=${SNAPSHOT_PEFIX}_${VSERVER_PROD}
SNAPSHOT_DIR=/tmp/${SNAPSHOT_NAME}

VGNAME=vg0
SNAPSHOT_LVNAME=lvol_${SNAPSHOT_NAME}
PROD_LVNAME=${VSERVER_PROD}
DEV_LVNAME=${VSERVER_DEV}

SNAPSHOT_LVPATH=/dev/${VGNAME}/${SNAPSHOT_LVNAME}
PROD_LVPATH=/dev/${VGNAME}/${PROD_LVNAME}
DEV_LVPATH=/dev/${VGNAME}/${DEV_LVNAME}

FILES_TO_PRESERVE=(
	'/etc/network/interfaces'
)

for (( i = 0; i < ${#FILES_TO_PRESERVE[@]}; i++ ))
do
	#echo -n ${FILES_TO_PRESERVE[$i]}\ -\>\ 
	FILES_TO_PRESERVE[$i]="`echo ${FILES_TO_PRESERVE[$i]}|sed -r 's/^\///'`"
	#echo ${FILES_TO_PRESERVE[$i]}
done


if [ -d $SNAPSHOT_DIR ] ; then
	echo "Snapshot directory $SNAPSHOT_DIR already exists. Exiting."
	echo "Please investigate the case and remove the directory to allow for a snapshot."
	exit 2
fi

mkdir -p $SNAPSHOT_DIR

echo -n "Start cloning $VSERVER_PROD as $VSERVER_DEV... "
date

VSERVER_ETC=/etc/xen

PATH_PROD=${VSERVER_ETC}/${VSERVER_PROD}
PATH_DEV=${VSERVER_ETC}/${VSERVER_DEV}

DEV_HOMEBUPFILENAME=`/bin/mktemp -d -p $BACKUP_DIR`

if [ ! -f $PATH_PROD ] ; then
	echo "PROD VSERVER does not exist"
	exit 1
fi

xl destroy $VSERVER_DEV || :

if [ -e "${DEV_LVPATH}" ]
then
	umount ${DEV_LVPATH} || :

	kpartx -s -a ${DEV_LVPATH}
	mount /dev/mapper/${VGNAME}-${VSERVER_DEV}1 ${SNAPSHOT_DIR} -t auto

	echo Backing up files...
	pushd ${SNAPSHOT_DIR}
	tar cf ${DEV_HOMEBUPFILENAME}/${VSERVER_DEV}_backup.tar --files-from /dev/null
	for item in "${FILES_TO_PRESERVE[@]}"
	do
		tar rf "${DEV_HOMEBUPFILENAME}/${VSERVER_DEV}_backup.tar" "$item"
	done
	popd

	umount ${SNAPSHOT_DIR}
	kpartx -s -d ${DEV_LVPATH}

	echo Removing ${DEV_LVPATH} logical volume
	lvremove -f ${DEV_LVPATH}
fi

xl destroy $VSERVER_PROD
lvcreate -L 1G -s ${PROD_LVPATH} -n ${DEV_LVNAME} || (echo "Error occured during snapshot creation. Aborting, please fix this manually." && exit 3);
xl create $PATH_PROD

kpartx -s -a ${DEV_LVPATH}
mount /dev/mapper/${VGNAME}-${VSERVER_DEV}1 ${SNAPSHOT_DIR} -t auto

echo $VSERVER_DEV > ${SNAPSHOT_DIR}/etc/hostname

echo -n "Removing ssh RSA/DSA host keys. They will be regenerated upon next start of vserver... "
for i in rsa dsa ecdsa ed25519; do
	rm -fv ${SNAPSHOT_DIR}/etc/ssh/ssh_host_${i}_key{,.pub} || :
done
#rm ${SNAPSHOT_DIR}/etc/ssh/ssh_host_rsa_key ${SNAPSHOT_DIR}/etc/ssh/ssh_host_rsa_key.pub ${SNAPSHOT_DIR}/etc/ssh/ssh_host_dsa_key ${SNAPSHOT_DIR}/etc/ssh/ssh_host_dsa_key.pub ${SNAPSHOT_DIR}/etc/ssh/ssh_host_ecdsa_key{,.pub} || :
echo "done."

mkdir -p ${SNAPSHOT_DIR}/etc/runonce.d
mkdir -p ${SNAPSHOT_DIR}/usr/local/lib/runonce
cat << EOF > ${SNAPSHOT_DIR}/usr/local/lib/runonce/runonce.sh
#!/bin/bash
cd /etc/runonce.d
echo
for i in /etc/runonce.d/*
do
	echo Running "\$i"
	"\$i" || :
	rm -fv "\$i"
	echo
done
EOF

chmod +x ${SNAPSHOT_DIR}/usr/local/lib/runonce/runonce.sh

cat << EOF > ${SNAPSHOT_DIR}/etc/systemd/system/runonce.service
[Unit]
Description=Run scripts once at startup
ConditionFileIsExecutable=/usr/local/lib/runonce/runonce.sh
After=network.target sshd.service

[Service]
Type=oneshot
ExecStart=/usr/local/lib/runonce/runonce.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

ln -svf /etc/systemd/system/runonce.service ${SNAPSHOT_DIR}/etc/systemd/system/multi-user.target.wants/runonce.service

cat > ${SNAPSHOT_DIR}/etc/runonce.d/prepare_dev.sh <<HERE
#!/bin/bash
#Disabling user2 crontab
#/bin/bash -c "crontab -u user2 -l | sed -e 's/^\([^#]\)/#\1/' | crontab -u user2 -"
#Enable apache userdir module
#/bin/bash -c "/usr/sbin/a2enmod userdir ; /etc/init.d/apache2 restart"
#Regenerate ssh host keys
dpkg-reconfigure openssh-server
#su - user2 -c 'psql my_app_db' <<EDDIG;
#update users set password=md5('iH%ae8ahpozeoSh5i');
#EDDIG
HERE

chmod +x ${SNAPSHOT_DIR}/etc/runonce.d/prepare_dev.sh

echo Restoring backed up files
pushd ${SNAPSHOT_DIR}
tar xf ${DEV_HOMEBUPFILENAME}/${VSERVER_DEV}_backup.tar
popd

set +e
read -t 5 -p "Press enter in 5 seconds to get a shell in ${DEV_LVNAME}..."
if [ "$?" -eq 0 ]
then
	pushd ${SNAPSHOT_DIR}
	echo
	echo
	echo Type \'exit\' or send EOF to exit shell
	echo
	bash || :
	echo Shell exited, continuing...
	echo
	popd
else
	echo Continuing...
fi
set -e

umount ${SNAPSHOT_DIR}
rmdir ${SNAPSHOT_DIR}
kpartx -d ${DEV_LVPATH}

rm -r ${DEV_HOMEBUPFILENAME}
	

#Comment AllowUsers from sshd_config
#sed --in-place=.bup -e 's/^AllowUsers /#AllowUsers /' $PATH_DEV/etc/ssh/sshd_config


#ionice and nice -19 mysqld
#sed --in-place -e '/Start MySQL/ {N; s=/usr/bin/mysqld_safe=/usr/bin/ionice -c 3 nice -19 /usr/bin/mysqld_safe= } ' $PATH_DEV/etc/init.d/mysql

#Configure rinetd
#sed --in-place=.bup -e '/^##COMMENT-NEXT-IN-DEV-CONFIG##/ {n; s/^/#/ } ' -e 's/^##UNCOMMENT-IN-DEV-CONFIG##//' $PATH_DEV/etc/rinetd.conf

#Configure tomcat7 startup
#sed --in-place=.bup -e '/^##COMMENT-NEXT-IN-DEV-CONFIG##/ {n; s/^/#/ } ' -e 's/^##UNCOMMENT-IN-DEV-CONFIG##//' $PATH_DEV/etc/init.d/tomcat7-user2-instance
#rm $PATH_DEV/etc/init.d/tomcat7-user2-instance.bup

#Configure Apache
#sed --in-place=.bup -e '/^##COMMENT-NEXT-IN-DEV-CONFIG##/ {n; s/^/#/ } ' -e 's/^##UNCOMMENT-IN-DEV-CONFIG##//' $PATH_DEV/etc/apache2/sites-available/default-ssl.conf
#sed --in-place=.bup -e '/^##COMMENT-NEXT-IN-DEV-CONFIG##/ {n; s/^/#/ } ' -e 's/^##UNCOMMENT-IN-DEV-CONFIG##//' $PATH_DEV/etc/apache2/sites-available/000-default.conf

#Configure network config
#sed --in-place=.bup -e '/^##COMMENT-NEXT-IN-DEV-CONFIG##/ {n; s/^/#/ } ' -e 's/^##UNCOMMENT-IN-DEV-CONFIG##//' $PATH_DEV/etc/network/interfaces

#Configure Shibboleth entityID
#sed --in-place=.bup -e 's/'${VSERVER_PROD}'.example.com/'${VSERVER_DEV}'.example.com/' $PATH_DEV/etc/shibboleth/shibboleth2.xml

xl create ${PATH_DEV}

echo -n "Cloning completed at "
date
