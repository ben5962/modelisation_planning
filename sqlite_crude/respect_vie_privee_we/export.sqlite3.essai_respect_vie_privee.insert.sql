PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
CREATE TABLE dimanches (i integer not null primary key, date_dim TEXT, trim_dim INTEGER);
INSERT INTO "dimanches" VALUES(1,'2017-12-31',4);
INSERT INTO "dimanches" VALUES(2,'2017-12-24',4);
INSERT INTO "dimanches" VALUES(3,'2017-12-17',4);
INSERT INTO "dimanches" VALUES(4,'2017-12-10',4);
INSERT INTO "dimanches" VALUES(5,'2017-12-03',4);
INSERT INTO "dimanches" VALUES(6,'2017-11-26',4);
INSERT INTO "dimanches" VALUES(7,'2017-11-19',4);
INSERT INTO "dimanches" VALUES(8,'2017-11-12',4);
INSERT INTO "dimanches" VALUES(9,'2017-11-05',4);
INSERT INTO "dimanches" VALUES(10,'2017-10-29',4);
INSERT INTO "dimanches" VALUES(11,'2017-10-22',4);
INSERT INTO "dimanches" VALUES(12,'2017-10-15',4);
INSERT INTO "dimanches" VALUES(13,'2017-10-08',4);
INSERT INTO "dimanches" VALUES(14,'2017-10-01',4);
INSERT INTO "dimanches" VALUES(15,'2017-09-24',3);
INSERT INTO "dimanches" VALUES(16,'2017-09-17',3);
INSERT INTO "dimanches" VALUES(17,'2017-09-10',3);
INSERT INTO "dimanches" VALUES(18,'2017-09-03',3);
INSERT INTO "dimanches" VALUES(19,'2017-08-27',3);
INSERT INTO "dimanches" VALUES(20,'2017-08-20',3);
INSERT INTO "dimanches" VALUES(21,'2017-08-13',3);
INSERT INTO "dimanches" VALUES(22,'2017-08-06',3);
INSERT INTO "dimanches" VALUES(23,'2017-07-30',3);
INSERT INTO "dimanches" VALUES(24,'2017-07-23',3);
INSERT INTO "dimanches" VALUES(25,'2017-07-16',3);
INSERT INTO "dimanches" VALUES(26,'2017-07-09',3);
INSERT INTO "dimanches" VALUES(27,'2017-07-02',3);
INSERT INTO "dimanches" VALUES(28,'2017-06-25',2);
INSERT INTO "dimanches" VALUES(29,'2017-06-18',2);
INSERT INTO "dimanches" VALUES(30,'2017-06-11',2);
INSERT INTO "dimanches" VALUES(31,'2017-06-04',2);
INSERT INTO "dimanches" VALUES(32,'2017-05-28',2);
INSERT INTO "dimanches" VALUES(33,'2017-05-21',2);
INSERT INTO "dimanches" VALUES(34,'2017-05-14',2);
INSERT INTO "dimanches" VALUES(35,'2017-05-07',2);
INSERT INTO "dimanches" VALUES(36,'2017-04-30',2);
INSERT INTO "dimanches" VALUES(37,'2017-04-23',2);
INSERT INTO "dimanches" VALUES(38,'2017-04-16',2);
INSERT INTO "dimanches" VALUES(39,'2017-04-09',2);
INSERT INTO "dimanches" VALUES(40,'2017-04-02',2);
INSERT INTO "dimanches" VALUES(41,'2017-03-26',1);
INSERT INTO "dimanches" VALUES(42,'2017-03-19',1);
INSERT INTO "dimanches" VALUES(43,'2017-03-12',1);
INSERT INTO "dimanches" VALUES(44,'2017-03-05',1);
INSERT INTO "dimanches" VALUES(45,'2017-02-26',1);
INSERT INTO "dimanches" VALUES(46,'2017-02-19',1);
INSERT INTO "dimanches" VALUES(47,'2017-02-12',1);
INSERT INTO "dimanches" VALUES(48,'2017-02-05',1);
INSERT INTO "dimanches" VALUES(49,'2017-01-29',1);
INSERT INTO "dimanches" VALUES(50,'2017-01-22',1);
INSERT INTO "dimanches" VALUES(51,'2017-01-15',1);
INSERT INTO "dimanches" VALUES(52,'2017-01-08',1);
INSERT INTO "dimanches" VALUES(53,'2017-01-01',1);
CREATE TABLE bornes (d TEXT not null, f TEXT not null);
INSERT INTO "bornes" VALUES('2017-01-01','2017-12-31');
CREATE TRIGGER ajoutedim BEFORE insert on dimanches
   when date(NEW.date_dim) <  ( select date(bornes.f) from bornes )
begin
   insert into dimanches (date_dim, trim_dim) values ( date(NEW.date_dim, '+7 day'),
                                                                                                                round(
                                                                                                         cast(strftime('%m', date(NEW.date_dim, '+7 day'))  as FLOAT)
                                                                                                         / 3
                                                                                                        +0.4
                                                                                                                )
                                               );

end;
COMMIT;
