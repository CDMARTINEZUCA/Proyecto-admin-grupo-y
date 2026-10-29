USE gestion_biblioteca;
GO

--Esquemas

--Esquema Catalogo
CREATE SCHEMA Catalogo AUTHORIZATION dbo;
GO

ALTER SCHEMA Catalogo TRANSFER Libro;
ALTER SCHEMA Catalogo TRANSFER Ejemplar;
ALTER SCHEMA Catalogo TRANSFER Autor;
ALTER SCHEMA Catalogo TRANSFER Categoria;
ALTER SCHEMA Catalogo TRANSFER Editorial;
ALTER SCHEMA Catalogo TRANSFER Libro_autor;
GO

--Esquema Operaciones
CREATE SCHEMA Operaciones AUTHORIZATION dbo;
GO

ALTER SCHEMA Operaciones TRANSFER Prestamo;
ALTER SCHEMA Operaciones TRANSFER Multa;
ALTER SCHEMA Operaciones TRANSFER Tarifa_multa;
ALTER SCHEMA Operaciones TRANSFER sp_reserva_libro;
ALTER SCHEMA Operaciones TRANSFER sp_calcular_multa;
GO

--Esquema Personas
CREATE SCHEMA Personas AUTHORIZATION dbo;
GO

ALTER SCHEMA Personas TRANSFER Socio;
ALTER SCHEMA Personas TRANSFER Empleado;
GO

CREATE SCHEMA Reportes AUTHORIZATION dbo;
GO
------------------------------------------

--Roles y usuarios
--Hacer la base de datos autocontenida para no crear logins 
USE master;
GO

ALTER DATABASE gestion_biblioteca
SET CONTAINMENT = PARTIAL;

USE gestion_biblioteca;
GO

--Rol gestor_catalogo
CREATE ROLE rol_gestor_catalogo;
GRANT SELECT, UPDATE, DELETE, INSERT ON SCHEMA :: Catalogo TO rol_gestor_catalogo;

--Usuario
CREATE USER user_gestor_catalogo WITH PASSWORD = 'Catalogo#123';
ALTER ROLE rol_gestor_catalogo ADD MEMBER user_gestor_catalogo

--Rol bibliotecario
CREATE ROLE rol_bibliotecario;
GRANT SELECT, EXEC ON SCHEMA :: Operaciones TO rol_bibliotecario;
GRANT SELECT ON SCHEMA :: Catalogo TO rol_bibliotecario;
GRANT SELECT ON Personas.Socio TO rol_bibliotecario;

--Usuario
CREATE USER user_bibliotecario WITH PASSWORD = 'Bibliotecario#123';
ALTER ROLE rol_bibliotecario ADD MEMBER user_bibliotecario;

--Rol RRHH
CREATE ROLE rol_RRHH;
GRANT SELECT, INSERT, UPDATE ON Personas.Empleado TO rol_RRHH;

--Usuario
CREATE USER user_RRHH WITH PASSWORD = 'RRHH#123';
ALTER ROLE rol_RRHH ADD MEMBER user_RRHH;

--Rol registro_socios
CREATE ROLE rol_registro_socios;
GRANT SELECT, INSERT, UPDATE ON Personas.Socio TO rol_registro_socios;

--Usuario
CREATE USER user_registro_socios WITH PASSWORD = 'RegistroSocios#123';
ALTER ROLE rol_registro_socios ADD MEMBER user_registro_socios;

--Rol auditor
CREATE ROLE rol_auditor;
GRANT SELECT ON SCHEMA :: Catalogo TO rol_auditor;
GRANT SELECT ON SCHEMA :: Operaciones TO rol_auditor;
GRANT SELECT ON SCHEMA :: Personas TO rol_auditor;
GRANT SELECT ON SCHEMA :: Reportes TO rol_auditor;

--Usuario
CREATE USER user_auditor WITH PASSWORD = 'Auditor#123';
ALTER ROLE rol_auditor ADD MEMBER user_auditor;

--Rol Analista
CREATE ROLE rol_analista;
GRANT SELECT ON SCHEMA :: Reportes TO rol_analista;

--Usuario
CREATE USER user_analista WITH PASSWORD = 'Analista#123';
ALTER ROLE rol_analista ADD MEMBER user_analista;

--Rol socio
CREATE ROLE rol_socio;
GRANT SELECT ON SCHEMA :: Catalogo TO rol_socio;

--Usuario
CREATE USER user_socio WITH PASSWORD = 'Socio#123';
ALTER ROLE rol_socio ADD MEMBER user_socio;

--Usuario db_owner
CREATE USER user_db_owner WITH PASSWORD = 'DBOwner#123';
ALTER ROLE db_owner ADD MEMBER user_db_owner;

--Usuario de backups
CREATE USER user_backups WITH PASSWORD = 'Backups#123';
ALTER ROLE db_backupoperator ADD MEMBER user_backups;
