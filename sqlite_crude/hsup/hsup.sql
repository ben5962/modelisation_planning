drop table if exists tranche_jour_travaille;
create table tranche_jour_travaille ( d TEXT not null, f TEXT not null, j TEXT not null);

delete from tranche_jour_travaille;
-- tests.
--- insertions int�ressantes:
--- le premier est une semaine iso 52 alors que janvier. l annee iso doit donner annee calendaire -1.
--- le preier janvier 2017 est un dimanche.
--- la deuxiee entree v�rifie que le calcul des semaines iso les fait bien commencer un lundi
--- en saisissant une entr�e datant du 2 janvier. doit donner semaine iso de premiere entree + 1.
--- le dernier est une semaine d�bordant sur le mois de septembre. le moisfp doit donner septembre.
--- les autres entrees de annees doivent etre identiques.
--- je suppose les num de sem iso ok.
insert into tranche_jour_travaille (d, f , j) values
('2017-01-01 06:00:00', '2017-01-01 18:00:00', '2017-01-01'),
('2017-01-02 06:00:00', '2017-01-02 18:00:00', '2017-01-02'),
('2017-08-14 18:00:00','2017-08-15 00:00:00','2017-08-14' ),
('2017-08-15 00:00:00','2017-08-15 02:00:00','2017-08-15' ),
('2017-08-15 18:00:00','2017-08-16 00:00:00','2017-08-15' ),
('2017-08-16 00:00:00','2017-08-16 06:00:00','2017-08-16' ),
('2017-08-16 18:00:00','2017-08-17 00:00:00','2017-08-16' ),
('2017-08-17 00:00:00','2017-08-17 06:00:00','2017-08-17' ),
('2017-08-19 18:00:00','2017-08-20 00:00:00','2017-08-19' ),
('2017-08-20 00:00:00','2017-08-20 02:00:00','2017-08-20' ),
('2017-08-20 18:00:00','2017-08-21 00:00:00','2017-08-20' ),
('2017-08-21 00:00:00','2017-08-21 06:00:00','2017-08-21' ),
('2017-08-21 18:00:00','2017-08-22 00:00:00','2017-08-21' ),
('2017-08-22 00:00:00','2017-08-22 06:00:00','2017-08-22' ),
('2017-08-28 06:00:00','2017-08-28 18:00:00','2017-08-28' )
;
---
--- adjonction d annee iso et de semaine iso
--- annee iso par heuristique: si semaine �lev�e ramener vers int�rieur ann�e (retirer des jours � date puis prendre ann�e)
---                            si semaine basse rajouter des jours puis prendre ann�e.
---
drop view if exists tr_jour_avec_iso;
create view tr_jour_avec_iso as
select t.d as d, t.f as f, t.j as j,
date( julianday(t.j) - strftime('%w',date(t.j, '-1 day'))) as first_d_iso_week,
date( julianday(t.j) - strftime('%w',date(t.j, '-1 day')) + 6) as last_d_iso_week,
(strftime('%j', date(t.j, '-3 days', 'weekday 4')) - 1) / 7 + 1 as iso_week,
strftime('%Y',julianday(t.j) + 26 -  julianday((strftime('%j', date(t.j, '-3 days', 'weekday 4')) - 1) / 7 + 1)) as iso_year,
strftime('%m',date( julianday(t.j) - strftime('%w',date(t.j, '-1 day')) + 6)) as monthfp,
strftime('%Y', date( julianday(t.j) - strftime('%w',date(t.j, '-1 day')) + 6)) as yearfp
from tranche_jour_travaille t;


---
--- regroupement par semaine iso

drop view if exists cumul_h_semaine_iso;
create view cumul_h_semaine_iso as
select i.first_d_iso_week as d_sem_iso,
i.last_d_iso_week as f_sem_iso,
round(sum(julianday(i.f) - julianday(i.d)) * 24) as volhebdo,
i.iso_week as isoweek,
i.iso_year as isoyear,
i.monthfp as mfp,
i.yearfp as yfp
from tr_jour_avec_iso i
group by i.iso_week, i.iso_year;

-- en deduire les heures sup dues
drop view if exists hsup_dues_semaine_iso;
create view hsup_dues_semaine_iso as 
select 
c.d_sem_iso as d_sem,
c.f_sem_iso as f_sem,
c.volhebdo as vh,
case
   when c.volhebdo <= 35 then 0
   when c.volhebdo > 35 and c.volhebdo < 43 then c.volhebdo - 35
   when c.volhebdo >= 43 then 43 - 35
end hs25,
case
    when c.volhebdo <= 43 then 0
	when c.volhebdo > 43 then abs(43 - c.volhebdo)
end hs50,
c.isoweek as isoweek,
c.isoyear as isoyear,
c.mfp as mfp,
c.yfp as yfp
from cumul_h_semaine_iso c;
select * from hsup_dues_semaine_iso;

--- rattachement des heures supplementaires dues au mois.
-- 1� methode : on peut regrouper les heures sup par semaines termin�es  sur le mois:
drop view if exists regroupement_fp_hs_dues;
create view regroupement_fp_hs_dues as 
select 
h.yfp as yfp,
h.mfp as mfp,
sum(h.hs25) as hs25,
sum(h.hs50) as hs50
from hsup_dues_semaine_iso as h
group by h.yfp, h.mfp;
select * from regroupement_fp_hs_dues;
-- 2� m�thode : ou mieux proratiser les semaines sur les mois en les explosant en heures par jour. 
-- puis en proratisant au mois
drop view if exists degroupage_fp_proratise;
create view degroupage_fp_proratise as
select h.d_sem, h.hs25/7.0 as hs25, h.hs50/7.0 as hs50,
strftime('%Y', h.d_sem) as yfp,
strftime('%m', h.d_sem) as mfp
from hsup_dues_semaine_iso h
union
select date(h.d_sem, 'weekday 2'), h.hs25/7.0 as hs25, h.hs50/7.0 as hs50,
strftime('%Y', date(h.d_sem, 'weekday 2')) as yfp,
strftime('%m', date(h.d_sem, 'weekday 2')) as mfp
from hsup_dues_semaine_iso h
union
select date(h.d_sem, 'weekday 3'), h.hs25/7.0 as hs25, h.hs50/7.0 as hs50,
strftime('%Y', date(h.d_sem, 'weekday 3')) as yfp,
strftime('%m', date(h.d_sem, 'weekday 3')) as mfp
from hsup_dues_semaine_iso h
union
select date(h.d_sem, 'weekday 4'), h.hs25/7.0 as hs25, h.hs50/7.0 as hs50,
strftime('%Y', date(h.d_sem, 'weekday 4')) as yfp,
strftime('%m', date(h.d_sem, 'weekday 4')) as mfp
from hsup_dues_semaine_iso h
union
select date(h.d_sem, 'weekday 5'), h.hs25/7.0 as hs25, h.hs50/7.0 as hs50,
strftime('%Y', date(h.d_sem, 'weekday 5')) as yfp,
strftime('%m', date(h.d_sem, 'weekday 5')) as mfp
from hsup_dues_semaine_iso h
union
select date(h.d_sem, 'weekday 6'), h.hs25/7.0 as hs25, h.hs50/7.0 as hs50,
strftime('%Y', date(h.d_sem, 'weekday 6')) as yfp,
strftime('%m', date(h.d_sem, 'weekday 6')) as mfp
from hsup_dues_semaine_iso h
union
select date(h.d_sem, 'weekday 6','+1 day'), h.hs25/7.0 as hs25, h.hs50/7.0 as hs50,
strftime('%Y', date(h.d_sem, 'weekday 6','+1 day')) as yfp,
strftime('%m', date(h.d_sem, 'weekday 6','+1 day')) as mfp
from hsup_dues_semaine_iso h;
select * from degroupage_fp_proratise;

drop view if exists regroupement_hs_fp_proratise;
create view regroupement_hs_fp_proratise as
select 
round(sum(d.hs25)) as hs25,
round(sum(d.hs50)) as hs50,
d.yfp,
d.mfp
from degroupage_fp_proratise d
group by d.yfp, d.mfp;
select * from regroupement_hs_fp_proratise;

-- heure supplementairs payees
-- payees 50 ? 0. pb r�gl�. 
--- payees25 ?  voici. 

drop table if exists fpaye;
create table fpaye (
pk INTEGER not null primary key,
m TEXT not null,
a TEXT not null,
aubry_25 FLOAT not null default 17.33,
-- aubry_25_r FLOAT not null default, --from paye_r vue de fpaye et sem_cp_mois
annu_25 FLOAT not null default 0.0,
h_dimjour_nuithorsdim_10 INTEGER not null default 0.0,
h_dimnuit_20 FLOAT not null default 0.0
-- nb_sem_cp FLOAT not null -- fro
);





-- fpaye_r necessite donc une table des semaines completes en 5eme et et 7eme
-- en 7eme pour proratiser les semaines de cp si ttes les semaines st prises par semaines entieres
-- en 5eme s il y a eu des jours pris isol�s (je pense que non grace aux rc)

drop table if exists cp_cinquieme;
create table cp_cinquieme (
date_cp DATE not null,
nb_heures FLOAT default 7.8,
fraction_sem FLOAT default (1.0 / 5.0)
);

drop table if exists cp_septieme;
create table cp_septieme (
date_cp DATE not null,
nb_heures FLOAT default (7.8 * 5.0 / 7.0),
fraction_sem FLOAT default (1.0 / 7.0)
);

drop table if exists cp_semaine_iso;
create table cp_semaine_iso (
semaine_iso TEXT not null,
annee_iso TEXT not null
);
-- on laisse tomber le trigger suivant:
drop trigger if exists ajouter_cp_5_7;
create trigger ajouter_cp_5_7 after insert on cp_semaine_iso
begin
insert into cp_cinquieme (date_cp) values (date( julianday(date(NEW.annee_iso || '-01-04') - strftime('%w',date(NEW.annee_iso || '-01-04', '-1 day'))))); 
end;

delete from cp_cinquieme;
delete from cp_semaine_iso;
insert into cp_semaine_iso (semaine_iso, annee_iso) values ('35','2017'); 
insert into cp_semaine_iso (semaine_iso, annee_iso) values ('36','2017'); 

--  hmmm on laisse tomber et on passe par une vue.
-- utiiaation: on remplit une valeur piur cp_semaine_iso(iso_num_semm, iso_y)
--             on recupere des semaines de 5j et 7j remplies contenant nb heures et fraction semaine pour chaque entree
--             on fait ensuite la requete du d�but � la fin du mois, pour chaque mois pour avoir le nb de fraction de semaines
--             que je multiplie par 4  pour l'oter de aubry_25
--             pour obtenir aubry_25(moi_fp, anneee_fp)

drop view if exists prepa_ajouter_cp_5;
create view prepa_ajouter_cp_5 as select 
date(cp_semaine_iso.annee_iso || '-01-04') as jour_premiere_sem, 
strftime('%w',date(cp_semaine_iso.annee_iso || '-01-04', '-1 day')) as  nb_jours_a_oter_pour_debut_prem_sem_iso,
date(cp_semaine_iso.annee_iso || '-01-04', 'start of day', '-' || strftime('%w',date(cp_semaine_iso.annee_iso || '-01-04', '-1 day')) || ' day' ) as first_day_of_iso_year,
date(cp_semaine_iso.annee_iso || '-01-04', 'start of day', '-' || strftime('%w',date(cp_semaine_iso.annee_iso || '-01-04', '-1 day')) || ' day',
'+' || cast((cp_semaine_iso.semaine_iso - 1 ) * 7 as TEXT)|| ' day' ) as date_cp
from cp_semaine_iso
union select
date(cp_semaine_iso.annee_iso || '-01-04') as jour_premiere_sem, 
strftime('%w',date(cp_semaine_iso.annee_iso || '-01-04', '-1 day')) as  nb_jours_a_oter_pour_debut_prem_sem_iso,
date(cp_semaine_iso.annee_iso || '-01-04', 'start of day', '-' || strftime('%w',date(cp_semaine_iso.annee_iso || '-01-04', '-1 day')) || ' day' ) as first_day_of_iso_year,
date(cp_semaine_iso.annee_iso || '-01-04', 'start of day', '-' || strftime('%w',date(cp_semaine_iso.annee_iso || '-01-04', '-1 day')) || ' day',
'+' || cast((cp_semaine_iso.semaine_iso - 1 ) * 7 as TEXT)|| ' day', 'weekday 2' ) as date_cp
from cp_semaine_iso
union select
date(cp_semaine_iso.annee_iso || '-01-04') as jour_premiere_sem, 
strftime('%w',date(cp_semaine_iso.annee_iso || '-01-04', '-1 day')) as  nb_jours_a_oter_pour_debut_prem_sem_iso,
date(cp_semaine_iso.annee_iso || '-01-04', 'start of day', '-' || strftime('%w',date(cp_semaine_iso.annee_iso || '-01-04', '-1 day')) || ' day' ) as first_day_of_iso_year,
date(cp_semaine_iso.annee_iso || '-01-04', 'start of day', '-' || strftime('%w',date(cp_semaine_iso.annee_iso || '-01-04', '-1 day')) || ' day',
'+' || cast((cp_semaine_iso.semaine_iso - 1 ) * 7 as TEXT)|| ' day', 'weekday 3' ) as date_cp
from cp_semaine_iso
union select
date(cp_semaine_iso.annee_iso || '-01-04') as jour_premiere_sem, 
strftime('%w',date(cp_semaine_iso.annee_iso || '-01-04', '-1 day')) as  nb_jours_a_oter_pour_debut_prem_sem_iso,
date(cp_semaine_iso.annee_iso || '-01-04', 'start of day', '-' || strftime('%w',date(cp_semaine_iso.annee_iso || '-01-04', '-1 day')) || ' day' ) as first_day_of_iso_year,
date(cp_semaine_iso.annee_iso || '-01-04', 'start of day', '-' || strftime('%w',date(cp_semaine_iso.annee_iso || '-01-04', '-1 day')) || ' day',
'+' || cast((cp_semaine_iso.semaine_iso - 1 ) * 7 as TEXT)|| ' day', 'weekday 4' ) as date_cp
from cp_semaine_iso
union select
date(cp_semaine_iso.annee_iso || '-01-04') as jour_premiere_sem, 
strftime('%w',date(cp_semaine_iso.annee_iso || '-01-04', '-1 day')) as  nb_jours_a_oter_pour_debut_prem_sem_iso,
date(cp_semaine_iso.annee_iso || '-01-04', 'start of day', '-' || strftime('%w',date(cp_semaine_iso.annee_iso || '-01-04', '-1 day')) || ' day' ) as first_day_of_iso_year,
date(cp_semaine_iso.annee_iso || '-01-04', 'start of day', '-' || strftime('%w',date(cp_semaine_iso.annee_iso || '-01-04', '-1 day')) || ' day',
'+' || cast((cp_semaine_iso.semaine_iso - 1 ) * 7 as TEXT)|| ' day', 'weekday 5' ) as date_cp
from cp_semaine_iso;


drop view if exists prepa_ajouter_cp_7;
create view prepa_ajouter_cp_7 as select * from prepa_ajouter_cp_5
union select
date(cp_semaine_iso.annee_iso || '-01-04') as jour_premiere_sem, 
strftime('%w',date(cp_semaine_iso.annee_iso || '-01-04', '-1 day')) as  nb_jours_a_oter_pour_debut_prem_sem_iso,
date(cp_semaine_iso.annee_iso || '-01-04', 'start of day', '-' || strftime('%w',date(cp_semaine_iso.annee_iso || '-01-04', '-1 day')) || ' day' ) as first_day_of_iso_year,
date(cp_semaine_iso.annee_iso || '-01-04', 'start of day', '-' || strftime('%w',date(cp_semaine_iso.annee_iso || '-01-04', '-1 day')) || ' day',
'+' || cast((cp_semaine_iso.semaine_iso - 1 ) * 7 as TEXT)|| ' day', 'weekday 6' ) as date_cp
from cp_semaine_iso
union select
date(cp_semaine_iso.annee_iso || '-01-04') as jour_premiere_sem, 
strftime('%w',date(cp_semaine_iso.annee_iso || '-01-04', '-1 day')) as  nb_jours_a_oter_pour_debut_prem_sem_iso,
date(cp_semaine_iso.annee_iso || '-01-04', 'start of day', '-' || strftime('%w',date(cp_semaine_iso.annee_iso || '-01-04', '-1 day')) || ' day' ) as first_day_of_iso_year,
date(cp_semaine_iso.annee_iso || '-01-04', 'start of day', '-' || strftime('%w',date(cp_semaine_iso.annee_iso || '-01-04', '-1 day')) || ' day',
'+' || cast((cp_semaine_iso.semaine_iso - 1 ) * 7 as TEXT)|| ' day', 'weekday 6','+1 day' ) as date_cp
from cp_semaine_iso;



drop view if exists sem_cp_mois;
create view sem_cp_mois as select 
cast(count(prepa_ajouter_cp_7.date_cp) / 7.0 as real) as nb_sem_cp_mois,
cast(count(prepa_ajouter_cp_7.date_cp) / 7.0 as real) * 4 as nb_h_a_oter_aubry_25_mois,
count(prepa_ajouter_cp_7.date_cp)  as nb_jours_cp7_mois,
strftime('%Y',prepa_ajouter_cp_7.date_cp) as anneefp,
strftime('%m', prepa_ajouter_cp_7.date_cp) as moisfp
from prepa_ajouter_cp_7
group by strftime('%Y',prepa_ajouter_cp_7.date_cp), strftime('%m', prepa_ajouter_cp_7.date_cp);

-- utilisation de sem_cp_mois
-- pour obtenir les fpaye_r
-- le 25 pay� correspond � l annu de mai
-- et au paye_25 aubry - le


drop view if exists fpaye_r;
create view fpaye_r as select
fpaye.m as m, fpaye.a as a, 
h_dimjour_nuithorsdim_10,
h_dimnuit_20,
f.aubry_25,
f.annu_25,
s.nb_h_a_oter_aubry_25_mois,
f.aubry_25 + f.annu_25 - s.nb_h_a_oter_aubry_25_mois as paye_25
from fpaye f
join  sem_cp_mois s
on f.m = s.moisfp and f.a = s.anneefp
; 

-- usage: inserer un mois fp, meme sans param aubry. saisir des cp. septembre est un bon candidat pour cela:
insert into fpaye (m, a) values ('9','2017'); -- valeurs par d�faut pour les autres parametres
delete from cp_semaine_iso;
insert into cp_semaine_iso (semaine_iso, annee_iso) values ('36','2017'), ('37','2017');
delete from tranche_jour_travaille;
-- mettre le planning de septembre.
insert into tranche_jour_travaille (d, f , j) values
('2017-01-01 06:00:00', '2017-01-01 18:00:00', '2017-01-01'),
('2017-01-02 06:00:00', '2017-01-02 18:00:00', '2017-01-02'),
('2017-08-14 18:00:00','2017-08-15 00:00:00','2017-08-14' ),
('2017-08-15 00:00:00','2017-08-15 02:00:00','2017-08-15' ),
('2017-08-15 18:00:00','2017-08-16 00:00:00','2017-08-15' ),
('2017-08-16 00:00:00','2017-08-16 06:00:00','2017-08-16' ),
('2017-08-16 18:00:00','2017-08-17 00:00:00','2017-08-16' ),
('2017-08-17 00:00:00','2017-08-17 06:00:00','2017-08-17' ),
('2017-08-19 18:00:00','2017-08-20 00:00:00','2017-08-19' ),
('2017-08-20 00:00:00','2017-08-20 02:00:00','2017-08-20' ),
('2017-08-20 18:00:00','2017-08-21 00:00:00','2017-08-20' ),
('2017-08-21 00:00:00','2017-08-21 06:00:00','2017-08-21' ),
('2017-08-21 18:00:00','2017-08-22 00:00:00','2017-08-21' ),
('2017-08-22 00:00:00','2017-08-22 06:00:00','2017-08-22' ),
('2017-08-28 06:00:00','2017-08-28 18:00:00','2017-08-28' )
;		


-- tentative de prod de planning compact depuis slite :
/* drop table if exists pl_compact;
create table pl_compact(
  jours TEXT not null,
  mois TEXT not null,
  annee TEXT not null
  );

drop table if exists pl;
create table pl(
  jour TEXT not null,
  mois TEXT ,
  annee TEXT
  );

create trigger ajout_machin after insert on pl_compact
begin
WITH RECURSIVE
split(word, str, hascomma) AS (
    values('',NEW.jours,1)
    UNION ALL SELECT
    substr(str, 0, 
        case when instr(str, ',')
        then instr(str, ',')
        else length(str)+1 end),
    ltrim(substr(str, instr(str, ',')), ','),
    instr(str, ',')
    FROM split
    WHERE hascomma
)

insert into pl (jour, mois, annee) 
select trim(split.word), NEW.mois, NEW.annee 
from split 
cross join NEW ;

end;
delete from pl_compact; */
-- insert into pl_compact(jours, mois, annee) values ('1,2,3,4','12','1993');
-- select * from pl;


