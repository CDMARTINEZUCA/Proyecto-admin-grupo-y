USE gestion_biblioteca;
GO

---- B.1 Estado actual de los archivos
       CAST(size AS bigint) * 8 / 1024    AS tamano_mb,
       CASE WHEN is_percent_growth = 1
            THEN CAST(growth AS varchar(10)) + ' %'
            ELSE CAST(CAST(growth AS bigint) * 8 / 1024 AS varchar(10)) + ' MB' END AS crecimiento,
       CASE max_size WHEN -1 THEN 'Sin límite'
            ELSE CAST(CAST(max_size AS bigint) * 8 / 1024 AS varchar(10)) + ' MB' END AS tamano_maximo
FROM sys.database_files;
 
SELECT name, recovery_model_desc
FROM sys.databases
WHERE name = N'gestion_biblioteca';
GO
 
---- B.2 Espacio realmente usado, por tabla
SELECT
    s.name + '.' + t.name                                              AS tabla,
    SUM(CASE WHEN ps.index_id IN (0,1) THEN ps.row_count ELSE 0 END)   AS filas,
    SUM(ps.reserved_page_count) * 8                                    AS reservado_kb,
    SUM(ps.used_page_count) * 8                                        AS usado_kb
FROM sys.dm_db_partition_stats ps
JOIN sys.tables  t ON t.object_id = ps.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
GROUP BY s.name, t.name
ORDER BY reservado_kb DESC;
 
EXEC sp_spaceused;          -- resumen de toda la base
GO
 
/* ---- B.3 Uso del log de transacciones ---- */
SELECT total_log_size_in_bytes / 1048576.0 AS log_total_mb,
       used_log_space_in_bytes / 1048576.0 AS log_usado_mb,
       used_log_space_in_percent           AS log_usado_pct
FROM sys.dm_db_log_space_usage;
GO
 
---- B.4 Configuración propuesta de archivos 
USE master;
GO
 
ALTER DATABASE gestion_biblioteca
MODIFY FILE (NAME = N'gestion_biblioteca',     SIZE = 64MB, FILEGROWTH = 32MB, MAXSIZE = 2GB);
 
ALTER DATABASE gestion_biblioteca
MODIFY FILE (NAME = N'gestion_biblioteca_log', SIZE = 32MB, FILEGROWTH = 16MB, MAXSIZE = 1GB);
GO
 
/* ---- B.5 Tamaño del registro de auditoría en disco ---- */
SELECT name, status_desc, audit_file_size / 1048576.0 AS archivo_actual_mb
FROM sys.dm_server_audit_status
WHERE name = N'Audit_Biblioteca';
GO
 
/* ---- B.6 Monitoreo: alertar cuando el archivo de datos se acerque al tope ---- */
USE gestion_biblioteca;
GO
SELECT name,
       size * 8 / 1024                                   AS tamano_mb,
       FILEPROPERTY(name, 'SpaceUsed') * 8 / 1024        AS usado_mb,
       (size - FILEPROPERTY(name, 'SpaceUsed')) * 8 / 1024 AS libre_mb
FROM sys.database_files;
GO