# Laboradmin rendszer üzemeltetési leírás
## szglab5-backend
A backend node.js környezetben fut. A folyamatos futásáért a pm2 daemon felel, ez a `backend` user nevében fut, ezért minden vezérlő parancsot a backend user nevében kell kiadni! Ebben segíthet a backend csoport tagjainak a `/usr/local/bin/backend-shell.sh` script, ami indít egy bash shellt a backend userként.

A pm2 alatt futó szolgáltatások listázása
```
pm2 list
```

A logok megtekintése
```
pm2 logs
```

Egy szolgáltatás megállítása
```
pm2 stop <id|name>
```

Egy szolgáltatás megállítása, és törlése a listából
```
pm2 delete <id|name>
```

### Frissítés
Első lépésben töltsük le a változtatásokat gittel
```
git pull
```

Ezután frissítsük a függőségeit npm-mel
```
npm install
```

Miután mindez megvan, indítsuk újra a szolgáltatást
```
pm2 restart szglab5-backend
```

Ellenőrizzük a logokat, hogy nem történt-e hiba
```
pm2 logs
```

## szglab5-frontend
A frontend Ember.js-ben készült. Az alkalmazásszervert az ember-cli biztosítja. A szolgáltatás futását a systemd menedzseli a `/etc/systemd/system/szglab5-frontend.service` fájlban megadottak szerint. Ahol nincs másképp meghatározva, a parancsokat rootként futtassuk.

Státusz megtekintése
```
systemctl status szglab5-frontend.service
```

Logok megtekintése
```
journalctl -u szglab5-frontend.service
```

A szolgáltatás leállítása
```
systemctl stop szglab5-frontend.service
```

A szolgáltatás indítása:

Az ember cli viszonylag lassan indul, de a systemd service az elindítástól már futóként tartja nyilván. Várjunk kb. fél percet, mielőtt elkönyveljük magunkban, hogy valami nem működik. A parancs:
```
systemctl start szglab5-frontend.service
```

A szolgáltatás újraindítása
```
systemctl restart szglab5-frontend.service
```

### Frissítés
Elsőként töltsük le a változtatásokat a git repoból. Ezt a frontend user nevében tegyük!
```
git pull
```

Ezután, szintén a frontend user nevében aktualizáljuk a telepített függőségeket
```
npm install
```

Miután mindez megvan, indítsuk újra a szolgáltatást, immár rootként futtatva a következőt
```
systemctl restart szglab5-frontend
```
Kb. fél perc várakozás után már a friss frontend fogad minket a weboldalon.