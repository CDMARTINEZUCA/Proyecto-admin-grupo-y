create database prueba;
go

drop database prueba;
go

use master;
go

restore filelistonly from disk='/backup/gestion_biblioteca_FULL_20261108_212254.bak';

-- Respaldo Full 

RESTORE DATABASE prueba
FROM DISK = '/backup/gestion_biblioteca_FULL_20261108_212254.bak' 
with 
   move 'gestion_biblioteca' to '/var/opt/mssql/data/prueba.mdf',
   move 'gestion_biblioteca_log' to '/var/opt/mssql/data/prueba_log.ldf',
norecovery, replace, stats=10;


-- 2. RESPALDO DIFERENCIAL (DIFF)

RESTORE DATABASE prueba
FROM DISK = '/backup/gestion_biblioteca_DIFF_20261112_111655.bak'
WITH NORECOVERY;
GO

-- 3. RESPALDO DE REGISTRO DE TRANSACCIONES (LOG)

RESTORE LOG prueba
FROM DISK = '/backup/gestion_biblioteca_log_20261112_112241.trn'
WITH NORECOVERY;
GO

RESTORE LOG prueba
FROM DISK = '/backup/gestion_biblioteca_log_20261112_112319.trn'
WITH RECOVERY;
GO