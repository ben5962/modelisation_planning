import glob
split_debug = False
def splitline(ligne):
	ligne = ligne.rstrip()
	sep = " "
	sep_magique = "}"
	sep_virgule = ","
	is_open = False
	quote = '"'
	mot = ""
	for c in ligne:
		if c in quote:
			is_open = not is_open
		elif c in sep:
			if not is_open:
				c = sep_magique
		mot += c
	if split_debug:
		print(repr(mot))	
	champs = mot.split(sep_magique)
	jours, mois, annee, poste, date_doc, titre_doc, type_doc, remarques = champs
	jrs = jours.split(sep_virgule)
	for j in jrs:
		print("""insert into table docus ( date_doc, titre_doc, type_doc, remarques ) select '{dt}', '{ttr}', '{tp}', '{rq}' WHERE NOT EXISTS (select 1 from docus where date_doc='{dt}' and titre_doc='{ttr}' and type_doc='{tp}' and remarques='{rq}';""".format(dt=date_doc, ttr=titre_doc, tp=type_doc, rq=remarques))
		print("""insert into table planning (j, m, a, p) values ('{j}','{m}','{a}','{p}')""".format(j=j, m=mois, a=annee, p=poste))
if __name__ == '__main__':
	for f in glob.glob("postes*.txt"):
		with open(f) as g:
			for ligne in g:
				splitline(ligne)