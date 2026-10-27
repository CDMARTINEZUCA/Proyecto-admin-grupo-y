USE gestion_biblioteca;
GO

--Evitar llaves duplicadas al insertar datos nuevos
DECLARE @max_prestamo BIGINT = (SELECT ISNULL(MAX(id_prestamo), 1) FROM prestamo);
DBCC CHECKIDENT ('prestamo', RESEED, @max_prestamo);

DECLARE @max_ejemplar BIGINT = (SELECT ISNULL(MAX(id_ejemplar), 1) FROM ejemplar);
DBCC CHECKIDENT ('ejemplar', RESEED, @max_ejemplar);

DECLARE @max_socio BIGINT = (SELECT ISNULL(MAX(id_socio), 1) FROM socio);
DBCC CHECKIDENT ('socio', RESEED, @max_socio);

DECLARE @max_multa BIGINT = (SELECT ISNULL(MAX(id_multa), 1) FROM multa);
DBCC CHECKIDENT ('multa', RESEED, @max_multa);
GO

----------------------------------------------------------------------
--actualizar fecha limite prestamo
CREATE OR ALTER TRIGGER trg_actualizar_limite_prestamo
ON prestamo
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO prestamo (id_ejemplar, id_socio, id_empleado_prestamo, fecha_prestamo, fecha_limite, fecha_devolucion, id_empleado_devolucion, estado_prestamo)
    SELECT 
        id_ejemplar,
        id_socio,
        id_empleado_prestamo,
        ISNULL(fecha_prestamo, CAST(GETDATE() AS DATE)),
        DATEADD(day, 7, ISNULL(fecha_prestamo, CAST(GETDATE() AS DATE))),
        fecha_devolucion,
        id_empleado_devolucion,
        ISNULL(estado_prestamo, 'Prestado')
    FROM inserted;
END;
GO

----------------------------------------------------------------------
--calcular multa
CREATE OR ALTER PROCEDURE sp_calcular_multa
    @p_id_multa BIGINT,
    @p_id_empleado BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_id_prestamo BIGINT;
    SELECT @v_id_prestamo = id_prestamo FROM multa WHERE id_multa = @p_id_multa;
    
    UPDATE multa
    SET estado_pago = 'Pagada'
    WHERE id_multa = @p_id_multa;
    
    UPDATE prestamo
    SET estado_prestamo = 'Devuelto',
        fecha_devolucion = CAST(GETDATE() AS DATE),
        id_empleado_devolucion = @p_id_empleado
    WHERE id_prestamo = @v_id_prestamo;
END;
GO

------------------------------------------------------------------------------
---reserva de libro con validacion disponibilidad
CREATE OR ALTER PROCEDURE sp_reserva_libro
    @p_id_ejemplar BIGINT,
    @p_id_socio BIGINT,
    @p_id_empleado BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_estado_ejemplar VARCHAR(30);
    
    SELECT @v_estado_ejemplar = estado
    FROM ejemplar
    WHERE id_ejemplar = @p_id_ejemplar;
    
    IF @v_estado_ejemplar = 'Disponible'
    BEGIN
        INSERT INTO prestamo(id_ejemplar, id_socio, id_empleado_prestamo, fecha_prestamo, fecha_limite, estado_prestamo)
        VALUES(@p_id_ejemplar, @p_id_socio, @p_id_empleado, CAST(GETDATE() AS DATE), DATEADD(day, 7, CAST(GETDATE() AS DATE)), 'Prestado');
        
        UPDATE ejemplar
        SET estado = 'Reservado'
        WHERE id_ejemplar = @p_id_ejemplar;
        
        PRINT 'Libro reservado con éxito';
    END
    ELSE
    BEGIN
        RAISERROR('El ejemplar %I64d no esta disponible (estado actual: %s)', 16, 1, @p_id_ejemplar, @v_estado_ejemplar);
    END
END;
GO

--------------------------------------------------------------------------------
--actualizar estado prestamo
CREATE OR ALTER TRIGGER trg_actualiza_estado_prestamo
ON prestamo
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE e
    SET e.estado = 'Disponible'
    FROM ejemplar e
    JOIN inserted i ON e.id_ejemplar = i.id_ejemplar
    JOIN deleted d ON i.id_prestamo = d.id_prestamo
    WHERE i.estado_prestamo = 'Devuelto' AND d.estado_prestamo <> 'Devuelto';
    
    IF EXISTS (
        SELECT 1 
        FROM inserted i 
        JOIN deleted d ON i.id_prestamo = d.id_prestamo 
        WHERE i.estado_prestamo = 'Vencido' AND d.estado_prestamo <> 'Vencido'
    )
    BEGIN
        UPDATE e
        SET e.estado = 'Reservado'
        FROM ejemplar e
        JOIN inserted i ON e.id_ejemplar = i.id_ejemplar
        JOIN deleted d ON i.id_prestamo = d.id_prestamo
        WHERE i.estado_prestamo = 'Vencido' AND d.estado_prestamo <> 'Vencido';
        
        INSERT INTO multa (id_prestamo, id_tarifa, dias_retraso, monto_total, estado_pago)
        SELECT 
            i.id_prestamo,
            2,
            DATEDIFF(day, i.fecha_limite, CAST(GETDATE() AS DATE)),
            DATEDIFF(day, i.fecha_limite, CAST(GETDATE() AS DATE)) * t.precio_por_dia,
            'Pendiente'
        FROM inserted i
        JOIN deleted d ON i.id_prestamo = d.id_prestamo
        CROSS JOIN tarifa_multa t
        WHERE i.estado_prestamo = 'Vencido' 
          AND d.estado_prestamo <> 'Vencido'
          AND t.id_tarifa = 2
          AND DATEDIFF(day, i.fecha_limite, CAST(GETDATE() AS DATE)) > 0;
    END
END;
GO

------------------------------------------------------------------------------------------
--actualizar estado multa
CREATE OR ALTER TRIGGER trg_actualiza_estado_multa
ON multa
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE p
    SET p.estado_prestamo = 'Devuelto',
        p.fecha_devolucion = CAST(GETDATE() AS DATE)
    FROM prestamo p
    JOIN inserted i ON p.id_prestamo = i.id_prestamo
    JOIN deleted d ON i.id_multa = d.id_multa
    WHERE i.estado_pago = 'Pagada' AND d.estado_pago <> 'Pagada';
END;
GO

------------------------------------------------------------------------------------------
--libros por categoria
CREATE OR ALTER FUNCTION fn_consulta_categoria(@p_nombre_categoria VARCHAR(80))
RETURNS TABLE
AS
RETURN
(
    SELECT l.isbn AS isbn_libro, l.titulo AS titulo_libro
    FROM libro l
    INNER JOIN categoria c ON l.id_categoria = c.id_categoria
    WHERE c.nombre_categoria = @p_nombre_categoria
);
GO
