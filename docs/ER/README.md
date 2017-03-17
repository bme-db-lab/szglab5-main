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
