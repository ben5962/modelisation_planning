drop table if exists tranche_jour_travaille;
create table tranche_jour_travaille ( d TEXT not null, f TEXT not null, j TEXT not null);

delete from tranche_jour_travaille;
insert into tranche_jour_travaille (d, f , j) values
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
('2017-08-22 00:00:00','2017-08-22 06:00:00','2017-08-22' )
;

 

--- jusque ici syntaxe correcte
drop view if exists plus_7_j;
create view plus_7_j as select d as d_7, datetime(d,'+7 day') as f_7 from tranche_jour_travaille;


-- d abord chevauchement : t peut deborder de sem glissante
drop view if exists chevauchement;
create view chevauchement as select plus_7_j.d_7 as d7, plus_7_j.f_7 as f7, t.d as d, t.f as f
from plus_7_j
join tranche_jour_travaille t
on ( t.d <= plus_7_j.f_7 and t.f > plus_7_j.d_7 and  t.f < plus_7_j.f_7 )  -- intersec, t tronqué au début
or ( t.d > plus_7_j.d_7 and t.d  <= plus_7_j.f_7  and t.f > plus_7_j.f_7 )  -- intersec, t tronqué à la fin
or ( t.d > plus_7_j.d_7 and t.f < plus_7_j.f_7)                             -- t inclus
;

-- puis je taille les bords dans inter
-- je n oublie pas d ajouter le critere de regroupement d7
-- f7 aussi par lisibilité rapport final
drop view if exists inter;
create view inter as select
chevauchement.d7 as debut_periode,
chevauchement.f7 as fin_periode, 
case when chevauchement.d7 > chevauchement.d then chevauchement.d7 else chevauchement.d end d,
case when chevauchement.f7 < chevauchement.f then chevauchement.f7 else chevauchement.f end f
from chevauchement
;


-- enfin j effectue la somme
drop view if exists semaine48gliss;
create view semaine48gliss as select inter.debut_periode, inter.fin_periode,
round(sum( (julianday(inter.f) - julianday(inter.d)) * 24 ))
from inter
group by debut_periode
;
https://www.youtube.com/watch?v=tKyzkFglx2k repa voiture
