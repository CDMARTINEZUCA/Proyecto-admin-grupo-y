-- BASE DE DATOS PARA LA GESTIÓN DE UNA BIBLIOTECA

-- CREACIÓN DE LA BASE DE DATOS
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'gestion_biblioteca')
    CREATE DATABASE gestion_biblioteca;
GO
USE gestion_biblioteca;
GO

--Conexion a la BASE DE DATOS
-- USE gestion_biblioteca;

-- SECCIÓN 1: TABLAS BÁSICAS (DATOS QUE NO DEPENDEN DE OTRAS TABLAS)

GO

-- 1. EDITORIAL: Guarda las empresas que publican los libros
create table Editorial (
    id_editorial bigint IDENTITY(1,1),
    nombre varchar(100) not null,
    pais varchar(60) not null,

    constraint pk_editorial
        primary key (id_editorial),

    constraint uq_editorial_nombre
        unique (nombre)
);


-- 2. CATEGORIA: Los temas de los libros (ej. Terror, Romance, Historia)
create table Categoria (
    id_categoria bigint IDENTITY(1,1),
    nombre_categoria varchar(80) not null,

    constraint pk_categoria
        primary key (id_categoria),

    constraint uq_categoria_nombre
        unique (nombre_categoria)
);


-- 3. AUTOR: Los escritores de los libros
create table Autor (
    id_autor bigint IDENTITY(1,1),
    nombre varchar(100) not null,
    nacionalidad varchar(60) not null,

    constraint pk_autor
        primary key (id_autor)
);

-- 4. SOCIO: Las personas inscritas en la biblioteca para pedir libros
create table Socio (
    id_socio bigint IDENTITY(1,1),
    nombre varchar(80) not null,
    apellido varchar(80) not null,
    email varchar(120) not null,
    telefono varchar(20) not null,
    estado varchar(20) not null default 'Activo',

    constraint pk_socio
        primary key (id_socio),

    constraint uq_socio_email
        unique (email),

    constraint chk_socio_estado
        check (estado in ('Activo', 'Inactivo'))
);


-- 5. EMPLEADO: Los trabajadores de la biblioteca
create table Empleado (
    id_empleado bigint IDENTITY(1,1),
    nombre varchar(100) not null,
    cargo varchar(60) not null,

    constraint pk_empleado
        primary key (id_empleado)
);


-- 6. TARIFA_MULTA: Cuánto se cobra por cada día de retraso
create table Tarifa_multa (
    id_tarifa bigint IDENTITY(1,1),
    descripcion varchar(100) not null,
    precio_por_dia numeric(5,2) not null,

    constraint pk_tarifa
        primary key (id_tarifa),

    constraint chk_tarifa_precio
        check (precio_por_dia >= 0)
);

-- SECCIÓN 2: TABLAS DE INFORMACIÓN DE LIBROS


-- 7. LIBRO: Los datos generales de cada libro
create table Libro (
    ISBN varchar(20),
    titulo varchar(200) not null,
    anio_publicacion int not null,
    id_editorial bigint not null,
    id_categoria bigint not null,

    constraint pk_libro
        primary key (ISBN),

    constraint fk_libro_editorial
        foreign key (id_editorial)
        references Editorial(id_editorial)
        ON DELETE NO ACTION
        on update cascade,

    constraint fk_libro_categoria
        foreign key (id_categoria)
        references Categoria(id_categoria)
        ON DELETE NO ACTION
        on update cascade,

    constraint chk_anio_valido
        check (
            anio_publicacion >= 1400
            and anio_publicacion <= YEAR(GETDATE())
        )
);


-- 8. EJEMPLAR: Los libros físicos reales que están en la biblioteca
-- (Un mismo "Libro" puede tener varios "Ejemplares" físicos en la biblioteca)
create table Ejemplar (
    id_ejemplar bigint IDENTITY(1,1),
    ISBN varchar(20) not null,
    estado varchar(30) not null default 'Disponible',

    constraint pk_ejemplar
        primary key (id_ejemplar),

    constraint fk_ejemplar_libro
        foreign key (ISBN)
        references Libro(ISBN)
        ON DELETE NO ACTION,

    constraint chk_ejemplar_estado
        check (estado in ('Disponible', 'Reservado'))
);


-- SECCIÓN 3: TABLAS DE OPERACIONES (LO QUE PASA EN LA BIBLIOTECA)


-- 9. LIBRO_AUTOR: Une los libros con sus autores
-- Sirve porque un libro puede tener varios autores y un autor puede escribir varios libros
create table Libro_autor (
    id_autor bigint not null,
    ISBN varchar(20) not null,

    constraint pk_libro_autor
        primary key (id_autor, ISBN),

    constraint fk_la_autor
        foreign key (id_autor)
        references Autor(id_autor)
        on delete cascade,

    constraint fk_la_libro
        foreign key (ISBN)
        references Libro(ISBN)
        on delete cascade
);


-- 10. PRESTAMO: Controla cuándo se lleva un libro un socio y cuándo lo devuelve
create table Prestamo (
    id_prestamo bigint IDENTITY(1,1),
    id_ejemplar bigint not null,
    id_socio bigint not null,
    id_empleado_prestamo bigint not null,
    fecha_prestamo date not null,
    fecha_limite date not null,
    fecha_devolucion date,
    id_empleado_devolucion bigint,
    estado_prestamo varchar(20) not null default 'Prestado',

    constraint pk_prestamo
        primary key (id_prestamo),

    constraint fk_prestamo_ejemplar
        foreign key (id_ejemplar)
        references Ejemplar(id_ejemplar)
        ON DELETE NO ACTION,

    constraint fk_prestamo_socio
        foreign key (id_socio)
        references Socio(id_socio)
        ON DELETE NO ACTION,

    constraint fk_prestamo_emp_pres
        foreign key (id_empleado_prestamo)
        references Empleado(id_empleado)
        ON DELETE NO ACTION,

    constraint fk_prestamo_emp_dev
        foreign key (id_empleado_devolucion)
        references Empleado(id_empleado)
        ON DELETE NO ACTION,

    constraint chk_prestamo_estado
        check (estado_prestamo in ('Prestado', 'Devuelto', 'Vencido')),

    constraint chk_fechas_prestamo
        check (fecha_limite >= fecha_prestamo),

    constraint chk_fechas_devolucion
        check (
            fecha_devolucion is null
            or fecha_devolucion >= fecha_prestamo
        )
);


-- 11. MULTA: Registra los cobros a los socios que devolvieron los libros tarde
create table Multa (
    id_multa bigint IDENTITY(1,1),
    id_prestamo bigint not null,
    id_tarifa bigint not null,
    dias_retraso int not null,
    monto_total numeric(8,2) not null,
    estado_pago varchar(20) not null default 'Pendiente',

    constraint pk_multa
        primary key (id_multa),

    constraint uq_multa_prestamo
        unique (id_prestamo),

    constraint fk_multa_prestamo
        foreign key (id_prestamo)
        references Prestamo(id_prestamo)
        ON DELETE NO ACTION
        on update cascade,

    constraint fk_multa_tarifa
        foreign key (id_tarifa)
        references Tarifa_multa(id_tarifa)
        ON DELETE NO ACTION
        on update cascade,

    constraint chk_dias_retraso
        check (dias_retraso > 0),

    constraint chk_monto_positivo
        check (monto_total >= 0),

    constraint chk_estado_pago
        check (estado_pago in ('Pendiente', 'Pagada'))
);

GO