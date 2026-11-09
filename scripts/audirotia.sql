/* ---- A.1 Server Audit: define DÓNDE se guardan los eventos ---- */
USE master;
GO
 
IF NOT EXISTS (SELECT 1 FROM sys.server_audits WHERE name = N'Audit_Biblioteca')
BEGIN
    CREATE SERVER AUDIT Audit_Biblioteca
    TO FILE
    (
        FILEPATH = N'/var/opt/mssql/audit/',
        MAXSIZE = 50 MB,              -- tamaño máximo de cada archivo
        MAX_ROLLOVER_FILES = 10,      -- 10 archivos x 50 MB = tope de 500 MB
        RESERVE_DISK_SPACE = OFF
    )
    WITH
    (
        QUEUE_DELAY = 1000,           -- escritura casi inmediata (1 s)
        ON_FAILURE = CONTINUE         -- si falla la auditoría, la BD sigue operando
    );
END
GO
 
/* ---- A.2 Especificación de auditoría a nivel de SERVIDOR ---- */
IF NOT EXISTS (SELECT 1 FROM sys.server_audit_specifications WHERE name = N'Audit_Biblioteca_Servidor')
BEGIN
    CREATE SERVER AUDIT SPECIFICATION Audit_Biblioteca_Servidor
    FOR SERVER AUDIT Audit_Biblioteca
        ADD (FAILED_LOGIN_GROUP),               -- logins fallidos a nivel servidor
        ADD (SERVER_PRINCIPAL_CHANGE_GROUP),    -- crear/alterar/borrar logins
        ADD (SERVER_ROLE_MEMBER_CHANGE_GROUP),  -- cambios en roles de servidor
        ADD (SERVER_PERMISSION_CHANGE_GROUP),   -- GRANT/DENY/REVOKE de servidor
        ADD (BACKUP_RESTORE_GROUP),             -- BACKUP y RESTORE
        ADD (AUDIT_CHANGE_GROUP)                -- cambios sobre la propia auditoría
    WITH (STATE = ON);
END
GO
 
ALTER SERVER AUDIT Audit_Biblioteca WITH (STATE = ON);
GO
 
/* ---- A.3 Especificación de auditoría a nivel de BASE DE DATOS ---- */
USE gestion_biblioteca;
GO
 
IF NOT EXISTS (SELECT 1 FROM sys.database_audit_specifications WHERE name = N'Audit_Biblioteca_BD')
BEGIN
    CREATE DATABASE AUDIT SPECIFICATION Audit_Biblioteca_BD
    FOR SERVER AUDIT Audit_Biblioteca
 
        ADD (FAILED_DATABASE_AUTHENTICATION_GROUP),
        ADD (DATABASE_PRINCIPAL_CHANGE_GROUP),
        ADD (DATABASE_ROLE_MEMBER_CHANGE_GROUP),
        ADD (DATABASE_PERMISSION_CHANGE_GROUP),
        ADD (SCHEMA_OBJECT_PERMISSION_CHANGE_GROUP),
 
        -- Cambios de estructura (DDL)
        ADD (SCHEMA_OBJECT_CHANGE_GROUP),
        ADD (DATABASE_OBJECT_CHANGE_GROUP),
 
        -- Datos sensibles y financieros (DML)
        ADD (INSERT, UPDATE, DELETE ON Personas.Empleado BY public),
        ADD (UPDATE, DELETE         ON Personas.Socio    BY public),
        ADD (UPDATE, DELETE         ON Operaciones.Multa BY public),
        ADD (UPDATE, DELETE         ON Operaciones.Prestamo BY public),
        ADD (DELETE                 ON SCHEMA::Catalogo  BY public),
 
        -- Procedimientos de negocio (reserva y cálculo de multa)
        ADD (EXECUTE ON SCHEMA::Operaciones BY public),
 
        -- Cuenta con control total: se audita toda su actividad
        ADD (SELECT, INSERT, UPDATE, DELETE, EXECUTE ON DATABASE::gestion_biblioteca BY user_db_owner)
    WITH (STATE = ON);
END
GO
 
/* ---- A.4 Verificar que la auditoría quedó activa ---- */
SELECT name, status_desc, audit_file_path, audit_file_size
FROM sys.dm_server_audit_status
WHERE name = N'Audit_Biblioteca';
 
SELECT a.name AS especificacion, d.audit_action_name, d.class_desc,
       OBJECT_SCHEMA_NAME(d.major_id) + '.' + OBJECT_NAME(d.major_id) AS objeto
FROM sys.database_audit_specifications a
JOIN sys.database_audit_specification_details d
     ON d.database_specification_id = a.database_specification_id
WHERE a.name = N'Audit_Biblioteca_BD'
ORDER BY d.audit_action_name;
GO
 
/* ---- A.5 Pruebas (no cambian datos) ----*/
 
-- Prueba 1: acción DENEGADA. user_socio solo tiene SELECT en Catalogo.
-- Debe fallar con el error 229 y quedar registrada con succeeded = 0.
EXECUTE AS USER = 'user_socio';
    DELETE FROM Operaciones.Multa WHERE id_multa = 1;
REVERT;
GO
REVERT;   -- seguridad: lote aparte, vuelve a dbo si la prueba falló antes de su REVERT
GO
 
-- Prueba 2: acción PERMITIDA sobre dato sensible. user_RRHH puede actualizar
-- Personas.Empleado; se escribe el mismo valor, así que el dato no cambia.
EXECUTE AS USER = 'user_RRHH';
    UPDATE Personas.Empleado SET cargo = cargo WHERE id_empleado = 1;
REVERT;
GO
REVERT;   -- seguridad: lote aparte, vuelve a dbo si la prueba falló antes de su REVERT
GO
 
/* ---- A.6 Leer el registro de auditoría ---- */
-- Comprobación: debe devolver dbo. Si devuelve otro usuario, ejecutar REVERT; y repetir.
SELECT USER_NAME() AS usuario_actual;
GO
 
SELECT
    event_time,
    action_id,                       -- DL = DELETE, UP = UPDATE, IN = INSERT, EX = EXECUTE
    succeeded,                       -- 1 = permitido, 0 = denegado/fallido
    database_principal_name AS usuario,
    schema_name,
    object_name,
    statement
FROM sys.fn_get_audit_file(N'/var/opt/mssql/audit/Audit_Biblioteca*.sqlaudit', DEFAULT, DEFAULT)
WHERE action_id <> 'LGIF'
ORDER BY event_time DESC;
GO