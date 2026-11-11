USE gestion_biblioteca;
GO

-- Indice para mejorar la consulta de disponibilidad de libros
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'idx_ejemplar_isbn_estado'
      AND object_id = OBJECT_ID('Catalogo.Ejemplar')
)
BEGIN
    CREATE NONCLUSTERED INDEX idx_ejemplar_isbn_estado
    ON Catalogo.Ejemplar (ISBN, estado);
END;
GO
USE gestion_biblioteca;
GO

SELECT
    name AS Nombre_Indice,
    type_desc AS Tipo,
    is_disabled AS Deshabilitado
FROM sys.indexes
WHERE name = 'idx_ejemplar_isbn_estado'
  AND object_id = OBJECT_ID('Catalogo.Ejemplar');

-- Indice para la consulta avanzada 2

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'idx_prestamo_socio'
      AND object_id = OBJECT_ID('Operaciones.Prestamo')
)
BEGIN
    CREATE NONCLUSTERED INDEX idx_prestamo_socio
    ON Operaciones.Prestamo (id_socio)
    INCLUDE (id_prestamo);
END;
GO

-- Indice para mejorar la consulta avanzada 3
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'idx_prestamo_ejemplar'
      AND object_id = OBJECT_ID('Operaciones.Prestamo')
)
BEGIN
    CREATE NONCLUSTERED INDEX idx_prestamo_ejemplar
    ON Operaciones.Prestamo (id_ejemplar);
END;
GO
-- Indice para la consulta avanzada 4
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'idx_prestamo_socio_fecha'
      AND object_id = OBJECT_ID('Operaciones.Prestamo')
)
BEGIN
    CREATE NONCLUSTERED INDEX idx_prestamo_socio_fecha
    ON Operaciones.Prestamo (id_socio, fecha_prestamo DESC)
    INCLUDE (id_ejemplar, id_prestamo);
END;
GO
-- Indice para la consulta avanzada 5: Libros mas prestados
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'idx_ejemplar_isbn'
      AND object_id = OBJECT_ID('Catalogo.Ejemplar')
)
BEGIN
    CREATE NONCLUSTERED INDEX idx_ejemplar_isbn
    ON Catalogo.Ejemplar (ISBN)
    INCLUDE (id_ejemplar);
END;
GO