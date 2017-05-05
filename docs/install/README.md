# Telepítési útmutató Debian Stretchre

## Nodesource csomaglista hozzáadása

Telepítsük a csomaglista hozzáadásához szükséges csomagokat!

```apt-get install apt-transport-https curl```

A következő paranccsal kitöltjük a csomaglistafájlt:

```
cat << EOF > /etc/apt/sources.list.d/nodesource.list
deb https://deb.nodesource.com/node_6.x jessie main
deb-src https://deb.nodesource.com/node_6.x jessie main
EOF
```

Adjuk hozzá a Nodesource publikus kulcsát az apt kulcstartóhoz, majd frissítsük a csomaglistákat!
```
curl --silent https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -
apt-get update
```


## Szükséges csomagok telepítése
```
apt-get install nodejs postgresql iptables-persistent git ntp
# csak frontend:
apt-get install phantomjs
```

## Tűzfalszabályok beállítása
A beengedett tcp portok:

 + 22: ssh
 + 80: http
 + 443: https
 - 7700: apidoc
 - 7000: backend szerver
 - 4200: frontend szerver

```
iptables -P INPUT ACCEPT
iptables -F INPUT
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT # ssh
iptables -A INPUT -p tcp --dport 80 -j ACCEPT # http
iptables -A INPUT -p tcp --dport 443 -j ACCEPT # https
#iptables -A INPUT -p tcp --dport 7700 -j ACCEPT # apidoc
#iptables -A INPUT -p tcp --dport 7000 -j ACCEPT # backend
#iptables -A INPUT -p tcp --dport 4200 -j ACCEPT # frontend
iptables -P INPUT DROP
iptables-save > /etc/iptables/rules.v4

ip6tables -P INPUT ACCEPT
ip6tables -F INPUT
ip6tables -A INPUT -i lo -j ACCEPT
ip6tables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
ip6tables -A INPUT -p icmpv6 -j ACCEPT
ip6tables -A INPUT -p tcp --dport 22 -j ACCEPT # ssh
ip6tables -A INPUT -p tcp --dport 80 -j ACCEPT # http
ip6tables -A INPUT -p tcp --dport 443 -j ACCEPT # https
#ip6tables -A INPUT -p tcp --dport 7700 -j ACCEPT # apidoc
#ip6tables -A INPUT -p tcp --dport 7000 -j ACCEPT # backend
#ip6tables -A INPUT -p tcp --dport 4200 -j ACCEPT # frontend
ip6tables -P INPUT DROP
ip6tables-save > /etc/iptables/rules.v6
```

## PostgreSQL konfigurálása
A helyi gépről elfogadunk minden csatlakozást. Az internet felé nem is hallgatunk. Létrehozzuk a `laboradmin` adatbázist és a `postgres` usert.
```
cat << EOF > /etc/postgresql/*/main/pg_hba.conf
local all all peer
host all all 127.0.0.1/32 trust
host all all ::1/128 trust
EOF
systemctl restart postgresql@9.6-main
su -c 'psql -c "create database laboradmin"' postgres
su -c 'psql -c "create user postgres"' postgres
```

## Alkalmazások telepítése

### A frontendhez szükséges CLI eszközök

```
npm install -g bower
npm install -g ember-cli
```

### Felhasználók és mappák létrehozása, letöltés
A backendnek egy `backend` nevű felhasználó és csoport, a frontendnek egy `frontend` nevű felhasználó és csoport jön létre. Ezek birtokolják a fájlokat és futtatják a szervereket.
```
mkdir /srv/http
useradd -M -d /srv/http/szglab5-frontend -s /bin/false frontend
useradd -M -d /srv/http/szglab5-backend -s /bin/false backend
cd /srv/http
git clone https://github.com/bme-db-lab/szglab5-frontend.git
git clone https://github.com/bme-db-lab/szglab5-backend.git
```

### Backend konfigurálása
A `dev` branchen van a kód aktuális változata. Ha ez változik, akkor más branchet kell majd checkoutolni.
A `bcrypt` npm csomagot forráskódból kell fordítani. Ehhez szükséges a `make` és a `g++`.

A jelszavak megváltoztatandók.
```
pushd /srv/http/szglab5-backend
git checkout dev
cat << EOF > /srv/http/szglab5-backend/config/config.prod.json
{
  "db": {
    "host": "localhost",
    "port": 5432,
    "database": "laboradmin",
    "username": "postgres",
    "password": "devpass"
  },
  "api": {
    "port": 7000
  },
  "cors": {
    "whitelist": ["http://fecske-dev.db.bme.hu:4200"]
  }
}
EOF

apt install make g++ # <- a bcrypt npm csomag fordítási függőségei
npm install
popd
```

### Frontend konfigurálása
Itt is a `dev` branch a legaktuálisabb változat a dokumentum írásakor. Az `npm install` futtatásához legalább 1 GB RAM szükséges, ugyanis telepítés előtt a RAM-ba cache-eli a csomagokat az npm.

A `node-sass` újraépítése egy bug miatt szükséges workaround, anélkül nem indul az `ember-cli`.

A production.js fájlban a backendUrl értelemszerűen a szerver elérhetőségére szabandó.
```
pushd /srv/http/szglab5-frontend
git checkout dev
cat << EOF > /srv/http/szglab5-frontend/config/production.js
module.exports = function(ENV) {
  // Set variables like:
  // ENV.backendUrl = 'http://localhost:7000';
  ENV.backendUrl = "http://fecske-dev.db.bme.hu:7000";
  return ENV;
};
EOF
chown frontend:frontend -R /srv/http/szglab5-frontend
su -c 'npm install' -s /bin/bash - frontend # <- Legalább 1 GB RAM szükséges a futtatáshoz
su -c 'bower install' -s /bin/bash - frontend
su -c 'npm rebuild node-sass' -s /bin/bash - frontend # <- workaround
popd
```

## Service management
### Pm2 process manager a backendhez
A [pm2](http://pm2.keymetrics.io/) manageli a backend és az apidoc példányokat. Ehhez létre kell hoznunk egy konfigurációs fájlt, ahol leírjuk, hogy mit és hogyan futtasson.

Ezután telepítenünk kell egy systemd service fájlt, aminek segítségével elindul a pm2 a backend user nevében.

```
chown backend:backend -R /srv/http/szglab5-backend

npm install pm2 -g
cat << EOF > /srv/http/szglab5-backend/ecosystem.config.js
module.exports = {
        /**
         * Application configuration section
         * http://pm2.keymetrics.io/docs/usage/application-declaration/
         */
        apps : [
                {
                        name      : 'szglab5-backend',
                        script    : 'server.js',
                        env: {
                                //COMMON_VARIABLE: 'true'
                        },
                        env_prod : {
                                NODE_ENV: 'prod'
                        },
                        env_dev: {
                                NODE_ENV: 'dev'
                        }
                },

                {
                        name      : 'szglab5-apidoc',
                        script    : 'apidoc.server.js'
                }
        ]
};
EOF
chown backend:backend -R /srv/http/szglab5-backend
su -s /bin/bash -c 'pm2 start ecosystem.config.js --env prod' - backend
PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u backend --hp /srv/http/szglab5-backend --env prod
```
### Systemd service a frontendhez
A pm2-ben nincs ember.js támogatás, így arra egy egyszerű systemd service fájlt készítünk, és a systemd-re bízzuk a frontend szerver processz menedzselését.

```
cat << EOF > /etc/systemd/system/szglab5-frontend.service
[Unit]
Description=Szglab5 frontend EmberJS server
After=network.target

[Service]
User=frontend
Group=frontend
WorkingDirectory=/srv/http/szglab5-frontend
ExecStart=/usr/bin/ember serve --environment production
KillMode=process

[Install]
WantedBy=multi-user.target
Alias=szglab5-frontend.service
EOF
systemctl daemon-reload
systemctl start szglab5-frontend
```

## Jenkins telepítése a teszt szerverre (CSAK TESZT SZERVER!)
Az alábbiak futtatása után a 8080-as porton fog hallgatni a jenkins.
```
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list
apt-get update
apt-get install jenkins
```

## Nginx reverse proxy konfigurálása
Ahhoz, hogy mind a frontend, mind a backend elérhető legyen egységes felületen, egy nginx reverse proxyn keresztül szolgáljuk ki a kéréseket. A backend a /api almappán keresztül lesz elérhető.

A production.js konfigfájlba kerülő url-t értelemszerűen a szerver elérhetőségére kell szabni.
```
apt-get install nginx
cat << EOF > /etc/nginx/sites-available/default
server {
	listen 80 default_server;
	listen [::]:80 default_server;

	server_name _;

	location / {
		proxy_pass http://127.0.0.1:4200;
	}

	location ~ /api(/?)(.*)$ {
		proxy_redirect off;
		proxy_set_header Host $host;
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
		proxy_pass      http://127.0.0.1:7000/$2;
	}
}
EOF
cat << EOF > /srv/http/szglab5-frontend/config/production.js
module.exports = function(ENV) {
  // Set variables like:
  // ENV.backendUrl = 'http://localhost:7000';
  ENV.backendUrl = "http://fecske-dev.db.bme.hu/api";
  return ENV;
};
EOF
sed -i 's/:4200//g' /srv/http/szglab5-backend/config/config.prod.json
service nginx reload
systemctl restart szglab5-frontend
su - backend -s /bin/bash -c 'pm2 restart szglab5-backend'
```

