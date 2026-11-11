USE gestion_biblioteca;
GO

-- Consulta 1: Disponibilidad de libros

SELECT
    l.ISBN,
    l.titulo,
    COUNT(e.id_ejemplar) AS total_ejemplares,
    SUM(CASE
        WHEN e.estado = 'Disponible' THEN 1
        ELSE 0
    END) AS ejemplares_disponibles,
    SUM(CASE
        WHEN e.estado = 'Reservado' THEN 1
        ELSE 0
    END) AS ejemplares_reservados
FROM Catalogo.Libro AS l
LEFT JOIN Catalogo.Ejemplar AS e
    ON l.ISBN = e.ISBN
GROUP BY
    l.ISBN,
    l.titulo
ORDER BY
    l.titulo;
    
-- Consulta 2: Socios con mas prestamos que el promedio

WITH PrestamosPorSocio AS (
    SELECT
        s.id_socio,
        s.nombre,
        s.apellido,
        COUNT(p.id_prestamo) AS total_prestamos
    FROM Personas.Socio s
    LEFT JOIN Operaciones.Prestamo p
        ON s.id_socio = p.id_socio
    GROUP BY
        s.id_socio,
        s.nombre,
        s.apellido
)
SELECT
    id_socio,
    nombre,
    apellido,
    total_prestamos
FROM PrestamosPorSocio
WHERE total_prestamos > (
    SELECT AVG(CAST(total_prestamos AS DECIMAL(10,2)))
    FROM PrestamosPorSocio
)
ORDER BY total_prestamos DESC;
   
-- Consulta 3: Autores cuyos libros nunca han sido prestados

SELECT
    a.id_autor,
    a.nombre
FROM Catalogo.Autor a
WHERE EXISTS (
    SELECT 1
    FROM Catalogo.Libro_autor la
    WHERE la.id_autor = a.id_autor
)
AND NOT EXISTS (
    SELECT 1
    FROM Catalogo.Libro_autor la
    INNER JOIN Catalogo.Ejemplar e
        ON la.ISBN = e.ISBN
    INNER JOIN Operaciones.Prestamo p
        ON e.id_ejemplar = p.id_ejemplar
    WHERE la.id_autor = a.id_autor
)
ORDER BY a.nombre;

-- Consulta 4: Ultimo prestamo realizado por cada socio

SELECT
    s.id_socio,
    s.nombre,
    s.apellido,
    ultimo.id_prestamo,
    ultimo.fecha_prestamo,
    ultimo.titulo
FROM Personas.Socio AS s
CROSS APPLY (
    SELECT TOP 1
        p.id_prestamo,
        p.fecha_prestamo,
        l.titulo
    FROM Operaciones.Prestamo AS p
    INNER JOIN Catalogo.Ejemplar AS e
        ON p.id_ejemplar = e.id_ejemplar
    INNER JOIN Catalogo.Libro AS l
        ON e.ISBN = l.ISBN
    WHERE p.id_socio = s.id_socio
    ORDER BY
        p.fecha_prestamo DESC,
        p.id_prestamo DESC
) AS ultimo
ORDER BY s.id_socio;

-- Consulta 5: Libros mas prestados
SELECT
    l.ISBN,
    l.titulo,
    COUNT(p.id_prestamo) AS total_prestamos
FROM Catalogo.Libro AS l
INNER JOIN Catalogo.Ejemplar AS e
    ON l.ISBN = e.ISBN
INNER JOIN Operaciones.Prestamo AS p
    ON e.id_ejemplar = p.id_ejemplar
GROUP BY l.ISBN, l.titulo
ORDER BY total_prestamos DESC;