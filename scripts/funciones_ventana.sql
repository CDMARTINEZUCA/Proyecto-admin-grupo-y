USE gestion_biblioteca;
GO

-- Funcion 1: Numerar los prestamos de cada socio
SELECT
    id_socio,
    id_prestamo,
    fecha_prestamo,
    ROW_NUMBER() OVER (
        PARTITION BY id_socio
        ORDER BY fecha_prestamo DESC
    ) AS numero_prestamo
FROM Operaciones.Prestamo;
GO
-- Funcion 2: Clasificar los prestamos de cada socio
SELECT
    id_socio,
    id_prestamo,
    fecha_prestamo,
    RANK() OVER (
        PARTITION BY id_socio
        ORDER BY fecha_prestamo DESC
    ) AS ranking_prestamo
FROM Operaciones.Prestamo;
GO
-- Funcion 3: Ranking consecutivo de prestamos por socio
SELECT
    id_socio,
    id_prestamo,
    fecha_prestamo,
    DENSE_RANK() OVER (
        PARTITION BY id_socio
        ORDER BY fecha_prestamo DESC
    ) AS ranking_denso
FROM Operaciones.Prestamo;
GO
-- Funcion 4: Total acumulado de prestamos por socio
SELECT
    id_socio,
    id_prestamo,
    fecha_prestamo,
    COUNT(id_prestamo) OVER (
        PARTITION BY id_socio
        ORDER BY fecha_prestamo
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS prestamos_acumulados
FROM Operaciones.Prestamo;
GO
-- Funcion 5: Fecha del prestamo anterior por socio
SELECT
    id_socio,
    id_prestamo,
    fecha_prestamo,
    LAG(fecha_prestamo) OVER (
        PARTITION BY id_socio
        ORDER BY fecha_prestamo
    ) AS fecha_prestamo_anterior
FROM Operaciones.Prestamo;
GO