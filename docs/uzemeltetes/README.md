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

### Backup visszaállítás
Első lépésben ürítjük az adatbázist (töröljük az alapértelmezett public sémát, majd újra létrehozzuk azt), ezután pedig az üres adatbázison futtatjuk a dump fájlban lévő sql parancsokat, amik aztán újraépítik az adatbázist.
```
(echo 'begin;drop schema public cascade;create schema public;';xz -cd backup.dump.xz ;echo 'commit;') | psql -U postgres laboradmin
```

## szglab5-frontend
A frontend Ember.js-ben készült. Az Ember.js statikus fajlokat general a `/srv/http/szglab5-frontend/dist` mappaba, amelyeket aztan a webszerver tud kiszolgalni. Ahol nincs másképp meghatározva, a parancsokat a frontend user neveben futtassuk.


Build:

```
ember build -prod
```


### Frissítés
Elsőként töltsük le a változtatásokat a git repoból.
```
git pull
```

Ezután aktualizáljuk a telepített függőségeket
```
npm install
```

Miután mindez megvan, epitsuk újra a szolgáltatást
```
ember build -prod
```
Ezutan már a friss frontend fogad minket a weboldalon.
