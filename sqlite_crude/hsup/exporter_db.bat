echo ".dump export.sqlite3.sql" 
rem echo ".schema essai_respect_vie_privee.db" | sqlite3 > export.sqlite3.essai_respect_vie_privee.schema.sql 
sqlite3 hsup.db .schema > export.sqlite3.hsup.schema.sql 
sqlite3 hsup.db .dump > export.sqlite3.hsup.insert.sql
pause