-- Comandos para generar Backups 

-- Backup Full
DECLARE @fileName VARCHAR(255);
DECLARE @dateSuffix VARCHAR(20);

SET @dateSuffix = CONVERT(VARCHAR(20), GETDATE() AT TIME ZONE 
                  'UTC' AT TIME ZONE 'Central America Standard Time', 112) + '_' + 
                  REPLACE(CONVERT(VARCHAR(8), GETDATE() AT TIME ZONE 
                  'UTC' AT TIME ZONE 'Central America Standard Time', 108), ':', '');

SET @fileName = '/backup/gestion_biblioteca_FULL_' + @dateSuffix + '.bak';

BACKUP DATABASE gestion_biblioteca 
TO DISK = @fileName 
WITH COMPRESSION, STATS = 10;

-- Backup Diferencial
DECLARE @fileName VARCHAR(255);
DECLARE @dateSuffix VARCHAR(20);

SET @dateSuffix = CONVERT(VARCHAR(20), GETDATE() AT TIME ZONE 
                  'UTC' AT TIME ZONE 'Central America Standard Time', 112) + '_' + 
                  REPLACE(CONVERT(VARCHAR(8), GETDATE() AT TIME ZONE 
                  'UTC' AT TIME ZONE 'Central America Standard Time', 108), ':', '');

SET @fileName = '/backup/gestion_biblioteca_DIFF_' + @dateSuffix + '.bak';

BACKUP DATABASE gestion_biblioteca 
TO DISK = @fileName 
WITH DIFFERENTIAL, COMPRESSION, STATS = 10;

-- Backup Log
DECLARE @fileName VARCHAR(255);
DECLARE @dateSuffix VARCHAR(20);

SET @dateSuffix = CONVERT(VARCHAR(20), GETDATE() AT TIME ZONE 
                  'UTC' AT TIME ZONE 'Central America Standard Time', 112) + '_' + 
                  REPLACE(CONVERT(VARCHAR(8), GETDATE() AT TIME ZONE 
                  'UTC' AT TIME ZONE 'Central America Standard Time', 108), ':', '');

SET @fileName = '/backup/gestion_biblioteca_log_' + @dateSuffix + '.trn';

BACKUP LOG gestion_biblioteca 
TO DISK = @fileName 
WITH COMPRESSION, STATS = 10;

-- Comandos para restaurar 
USE master;
GO

-- Cierra inmediatamente todas las conexiones activas a la base original
ALTER DATABASE gestion_biblioteca SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

-- 1. Restaurar el último FULL
RESTORE DATABASE gestion_biblioteca 
FROM DISK = '/backup/gestion_biblioteca_FULL_20261108_212254.bak' 
WITH NORECOVERY, REPLACE;
GO

-- 2. Restaurar el último DIFERENCIAL
RESTORE DATABASE gestion_biblioteca 
FROM DISK = '/backup/gestion_biblioteca_DIFF_20261109_220000.bak' 
WITH NORECOVERY;
GO

-- 3. Restaurar los LOGS intermedios
RESTORE LOG gestion_biblioteca 
FROM DISK = '/backup/gestion_biblioteca_log_20261109_080000.trn' 
WITH NORECOVERY;
GO

-- 4. Restaurar el ÚLTIMO LOG disponible y poner la BD ONLINE
RESTORE LOG gestion_biblioteca 
FROM DISK = '/backup/gestion_biblioteca_log_20261109_100000.trn' 
WITH RECOVERY;
GO

-- Devuelve la base de datos a modo multiusuario normal
ALTER DATABASE gestion_biblioteca SET MULTI_USER;
GO