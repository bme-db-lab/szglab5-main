## ER dokumentáció

### Általános információk

Language: egy természetes nyelv, pl. feladatok illetve hallgató kurzusának a nyelve.

Exercise-világrész:

 - ExerciseCategory: pl. Oracle mint rendszer feladat, JDBC feladat, SQL feladat
 - ExerciseType: van nyelve. pl. Videotéka (VIDEO-hu), Hajózási felügyelet (HAJO-hu), Road transportation (ROAD-en)
 - ExerciseSheet: pl. (VIDEO, SOA), (HAJO, JDBC), (HAJO, Oracle)

Egy Event egyed az egy hallgató egy mérésen való részvétele,
azaz pl. Gedeon bácsi a SOA mérésen HAJO-hu feladatot old meg.


User<-isa-Student, User<-isa-Staff: ez valójában csak az ER-en a fogalmi rendszer érzékeltetésére való, miszerint az egyes kapcsolattípusokban Student vagy Staff vesz részt. Implementációban ez várhatóan egyetlen Users tábla lesz.

StudentRegistration (a Student--Semester több:több kapcsolattípus helyett): egy ember a tárgy egy adott félévbeli futására regisztrált a neptunban. Attribútumai: NeptunSubjectCode, NeptunCourseCode


A beugró eredménye is egy deliverable (az általános Deliverable egyede), és pl. a git-es beadandó egy RepositoryDeliverable. Ezért a Deliverables es a DeliverableTemplate az tenyleg kell.
Pl. a SOA mérés EventTemplate-jához felvesszük, hogy tartozik két DeliverableTemplate: 1. beugró, 2. egy git repo. Ez alapján legeneráljuk az adott EVent példányokhoz a Deliverable példányokat.

A beugrókérdések az ExerciseCategory-hoz kötődnek, és a beugró ténye és eredménye egy deliverable. Pillanatnyilag nincs olyan use case, hogy elektronikusan írjanak beugrót.



A szerepeket/jogosultságokat egy általános Grant táblában implementáljuk:

 - GrantType(grant_type_id, grant_name, class_name): megmutatja, hogy egy adott szerep a usert melyik egyedhalmazzal köti össze.
   pl. (1, tárgyfelelős, Semester), (2, demonstrátor, StudentGroup), (3,
 - Grant(grant_id, grant_type_id, user_id, object_id): megmutatja, hogy adott jogosultságot melyik objektumon gyakorolhatja az adott user. Pl. Szilárd demonstrátor (grant_type_id=2) a 7-es csoportban
 - a sárga kapcsolattípusok kerülnek itt implementálásra

### Attribútum lista és leírás
 	
**1. Appointments:** StudentGroup-ot kapcsol egy alkalomhoz (idő és hely).
- Tulajdonságok:
   * id - number
   * date - datetime
   * location - text
 - Idegen kulcsok:
   * eventtype - EventTypes
   * studentgroup - StudentGroups
 
**2. Courses:** A felület álltal kezelt kurzusok.
- Tulajdonságok:
  * id - number
  * name - text
  * codename - text

**3. Deliverables:** Hallgatók álltal beadandó anyagok.
- Tulajdonságok:
  * id - number
  * deadline - datetime
  * submitteddate - datetime
  * grade - number - 1-5
  * comment - text
- Idegen kulcsok:
  * deliverabletype - DeliverableTemplates
  * evaluator - Staffs
  * related - DeliverableTemplates
  
**4. Deliverables/Repositories:** Speciális beadandó anyag, melyet verziókezelő rendszeren át töltenek fel. 
(Jelenleg egyedüli feltöntendő fajta)
- Tulajdonságok:
  * url - text - git url
  * commit - text - chosen final commit
  
**5. DeliverableTemplates:** Leírja a beadandó anyag típusát.
- Tulajdonságok
  * id - number
  * deadline - datetime operator - +7 nap az esemény idejétől
  * description - text - például: report
- Idegen kulcsok:
  * eventtype - EventTemplates
  
**6. Events:** Egy hallgató mérésen való részvételét tárolja.
- Tulajdonságok
  * id - number
  * date - datetime
  * location - text
  * attempt - number - starting number: 1
- Idegen kulcsok
  * related - Events
  * eventtype - EventTypes
  * exercisheet - ExerciseSheets
  * demonstrator - Staffs
  * studentreg - StudentRegistrations
  
**7. EventTemplates:** A lehetséges látogatható óra típusát adja meg.
- Tulajdonságok:
  * id - number
  * title - text
  * number - number
  
**8. ExerciseCategories:** A feladat kategóriája (JDBC, Oracle, SQL stb).
- Tulajdonságok:
  * id - number
  * type - text - SQL, DBMS, SOA, JDBC, XML
- Idegen kulcsok
  * course - Courses
  
**9. ExerciseTypes:** A feladat típusa (AUTO, HAJO) és nyelve (természetes nyelv).
- Tulajdonságok:
  * id - number
  * name - text - for example: Car Rental
  * shortname - text - for example: AUTO
  * exerciseid - number - for example: 22
  * codename - text - generated, for example: 22-AUTO
  * language - text
- Idegen kulcsok
  * exercisecategory - ExerciseCategories
  
**10. ExerciseSheets:** Egy feladatpapír. Összerendel típust és kategóriát. Például: (SQL, AUTO)
- Idegen kulcsok
  * excategory - ExerciseCategories
  * extype - ExerciseTypes
  
**11. StudentRegistrations:** A tárgyat neptun szerint felvevő hallgatókról tárol neptun információt.
- Tulajdonságok:
  * id - number
  * neptunsubjectcode - text
  * neptuncoursecode - text
- Idegen kulcsok
  * student - Students
  * studentgroup - StudentGroups
  * semester - Semesters
  * language - Languages 
  
**12. Semesters:** Egy egyetemi menetrend szerinti félév beli példánya a kurzusnak.
- Tulajdonságok:
  * id - number
  * academicyear - number
  * academicterm - number
  * description - text - generated
- Idegen kulcsok
  * course - Courses
  
**13. StudentGroups:** A hallgatók csoportja. Egy demonstrátor és nagyjából 20 hallgató tartozik hozzá.
- Tulajdonságok:
  * id - number
  * name - text
  * language - text
- Idegen kulcsok
  * demonstrator - Staffs
  * semester - Semesters
  
**14. Users:** A felületet használó felhasználók.
- Tulajdonságok:
  * id - number
  * givenname - text
  * surname - text
  * title - text
  * displayname - text - generated
  * loginname - text, unique
  * eppn - text - Sibboleth
  * email - text, unique
  * sshpublickey - text
  * password - text
  
**15. Users/Students:** Hallgató felhasználó. Órákra jár és beadandókat tölt fel.
- Tulajdonságok:
  * neptun - text
  * university - text
  
**16. Users/Staff:** Oktatói szerepkörhöz szükséges hozzáférésekkel bíró felhasználó. (pl Demonstrátor, Javító, Admin)

**17. Languages:** A kurzus nyelve. Vonatkozik a beadandó dokumentációkra és a beugró kérdésekre is. [Van értelme nem csak stringként tárolni ahol kell?]
- Tulajdonságok:
  * language - text

**18. Questions:** Egy feladat kategóriában felbukkanó kérdések.
- Tulajdonságok:
  * kerdes - text
- Idegen kulcsok
  * language - Languages
  * excategory - ExerciseCategories
  
  
**19. News:** A felületen megjelenő hírek. A flags attributúm tárolja, mely felületeken jelenik meg (főoldal, login oldal stb)
- Tulajdonságok:
  * newstext - text
  * published - datetime
  * from - datetime
  * until - datetime
  * flags - number
- Idegen kulcsok
  * language - Languages
  * author - User/Staff
  

