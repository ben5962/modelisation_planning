begin transaction;
drop table if exists periodes_travaillees;
CREATE TABLE periodes_travaillees ( 
	debut_periode timestamp, 
	fin_periode timestamp CHECK(fin_periode > debut_periode), 
	jour_travaille DATE, 
	CONSTRAINT periode_unique UNIQUE(debut_periode, fin_periode, jour_travaille) 
	);
-- ajout des deux bornes extremes 
insert into periodes_travaillees values ('2017-07-01 06:00:00', '2017-07-01 18:00:00', '2017-07-01');
insert into periodes_travaillees values ('2017-08-01 06:00:00', '2017-08-01 18:00:00', '2017-08-01');
-- ajout d une valeur aléatoire qui n est pas un dimanche
insert into periodes_travaillees values ('2017-07-20 06:00:00', '2017-07-20 18:00:00', '2017-07-20');
-- ajout du 8, un samedi et du 10, un lundi(doit sortir le 9 de la liste des dimanches fournis)
insert into periodes_travaillees values ('2017-07-08 06:00:00', '2017-07-08 18:00:00', '2017-07-08');
insert into periodes_travaillees values ('2017-07-10 06:00:00', '2017-07-10 18:00:00', '2017-07-10');
-- ajout du 23, un dimanche  (doit sortir le 23 de la liste des dimanches fournis)
insert into periodes_travaillees values ('2017-07-23 06:00:00', '2017-07-23 18:00:00', '2017-07-23');




commit;




drop table if exists dimanches ;
CREATE TABLE dimanches (i integer not null primary key, date_dim TEXT, trim_dim INTEGER);
drop table if exists bornes;
CREATE TABLE bornes (d TEXT not null, f TEXT not null);

pragma recursive_triggers = on;
CREATE TRIGGER ajoutedim BEFORE insert on dimanches
   when date(NEW.date_dim) <  ( select date(bornes.f) from bornes )
begin
-- 
-- creation d une serie de dimanches entre deux dates
--       méth : une table contenant un debut et une fin
--              une table contenant le resultat
--              un triggger lance a chaque ajout dans resultat
--                          lancant la crea de resultat suivant en util f() de transition au suiv
--                          ayant pour cas d arret la borne de fin
--  amorcage : set bornes d, f, set 1er ele de dim comme 1er elem de bornes
--  
  insert into dimanches (date_dim, trim_dim) values ( date(NEW.date_dim, '+7 day'),

                                                                                                                round(

                                                                                                         cast(strftime('%m', date(NEW.date_dim, '+7 day'))  as FLOAT)

                                                                                                         / 3

                                                                                                        +0.4

                                                                                                                )

                                               );



end;

-- amorcage de bornes
-- set bornes
-- INSERT INTO "bornes" VALUES('2017-01-01','2017-12-31');
insert into bornes (d,f) select min(date(jour_travaille)), max(date(jour_travaille)) from periodes_travaillees;
-- inset first dim
insert into dimanches (date_dim, trim_dim) select date(bornes.d, 'weekday 0'), round(
		cast(strftime('%m', date(bornes.d, 'weekday 0'))  as FLOAT) -- mois en flottant 
						/ 3											-- afin que div à virgule
						+ (0.5 - 1.0/3.0 + 0.1)						-- ajout de 0,4 
						) 
						from bornes 											-- fin de round
						-- fin de values et du insert juste apres.
		 ;

-- les dates de dimanches dispo sont les dates de dim présents ds intervalles et absents de période cp:
	 
begin transaction;
CREATE TABLE periodes_conges ( 
	debut_periode timestamp, 
	fin_periode timestamp CHECK(fin_periode > debut_periode), 
	jour_conge DATE, 
	CONSTRAINT periode_unique UNIQUE(debut_periode, fin_periode, jour_conge) 
	);

-- ajout du dim 30 comme cp, doit sortir le 30 de la liste des dimanches fournis
insert into periodes_conges values ('2017-07-30 00:00:00', '2017-07-31 00:00:00', '2017-07-30');


commit;

drop view if exists dim_dispo;
create view dim_dispo as select date_dim, trim_dim, periodes_conges.jour_conge from dimanches 
left outer join periodes_conges 
on dimanches.date_dim = periodes_conges.jour_conge
where periodes_conges.jour_conge is NULL;


-- les dates de dimanches fournis sont les dates de dim 
-- non travailles et (ou (jour prec) non travaille ou joursuiv non travaille)
-- et non cp
drop view if exists dim_fournis;
create view dim_fournis as select date_dim, trim_dim, periodes_conges.jour_conge,
periodes_travaillees.jour_travaille, periodes_trav_sam.jour_travaille, periodes_trav_lun.jour_travaille
 from dimanches
left outer join periodes_conges
on dimanches.date_dim = periodes_conges.jour_conge
left outer join periodes_travaillees
on dimanches.date_dim = periodes_travaillees.jour_travaille
left outer join periodes_travaillees as periodes_trav_sam
on date(dimanches.date_dim, '-1 day') = periodes_trav_sam.jour_travaille
left outer join periodes_travaillees as periodes_trav_lun
on date(dimanches.date_dim, '+1 day') = periodes_trav_lun.jour_travaille
where periodes_conges.jour_conge is NULL and periodes_travaillees.jour_travaille is NULL 
and (periodes_trav_sam.jour_travaille is NULL or periodes_trav_lun.jour_travaille is NULL);



-- la vue joignant tout cela , juste avant le décompte:
drop view if exists dim_vie_priv;
create view dim_vie_priv as
select dimanches.date_dim as existant, 
dimanches.trim_dim as num_trimestre,
dim_dispo.date_dim as dim_dispo, 
dim_fournis.date_dim as dim_fournis
from dimanches
left outer join dim_dispo
on dimanches.date_dim = dim_dispo.date_dim
left outer join dim_fournis
on dimanches.date_dim = dim_fournis.date_dim;


-- le décompte 
drop view if exists decompte_dim_vie_priv;
create view decompte_dim_vie_priv as
select count (dim_vie_priv.existant) as ex, count(dim_vie_priv.dim_dispo) as dispo,
count (dim_vie_priv.dim_fournis) as fournis,  round((count(dim_vie_priv.dim_dispo) / 2.0) + 0.49) as dus,
round((count(dim_vie_priv.dim_dispo) / 2.0) + 0.49) - 
from dim_vie_priv
group by dim_vie_priv.num_trimestre;