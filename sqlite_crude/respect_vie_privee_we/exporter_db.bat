echo ".dump export.sqlite3.sql" 
rem echo ".schema essai_respect_vie_privee.db" | sqlite3 > export.sqlite3.essai_respect_vie_privee.schema.sql 
sqlite3 essai_respect_vie_privee.db .schema > export.sqlite3.essai_respect_vie_privee.schema.sql 
sqlite3 essai_respect_vie_privee.db .dump > export.sqlite3.essai_respect_vie_privee.insert.sql
pause