USE gestion_biblioteca;
GO

--Consultas sugeridas

--Top 20 libros más prestados los últimos 3 meses
select TOP 20 l.titulo, count(p.id_ejemplar ) veces_prestado
from prestamo p 
join ejemplar e on p.id_ejemplar = e.id_ejemplar
join libro l on e.isbn = l.isbn
where DATEDIFF(day, p.fecha_prestamo, CAST(GETDATE() AS DATE)) <= 90
group by l.titulo
order by veces_prestado desc;

--Socios con multas pendientes
select p.id_prestamo , s.nombre + ' ' + s.apellido nombre_socio , m.dias_retraso, m.monto_total  
from multa m 
join prestamo p on m.id_prestamo = p.id_prestamo
join socio s on p.id_socio = s.id_socio
where m.estado_pago = 'Pendiente'
order by dias_retraso desc
OFFSET 20 ROWS FETCH NEXT 10 ROWS ONLY; --Muestra la 3 pag

--Autores con mayor número de títulos en catálogo
select TOP 10 a.id_autor  , a.nombre, count(*) numero_titulos
from libro l 
join libro_autor la on l.isbn = la.isbn
join autor a on la.id_autor = a.id_autor
group by a.nombre, a.id_autor 
order by numero_titulos desc;

--Ejemplares que nunca han sido prestados
select e.id_ejemplar , l.titulo 
from ejemplar e 
join libro l on e.isbn = l.isbn
left join prestamo p on e.id_ejemplar = p.id_ejemplar 
where p.id_ejemplar is null;

--Empleado que ha procesado más prestamos en el mes
select TOP 1 e.id_empleado , e.nombre , count(p.id_prestamo ) prestamos
from empleado e 
join prestamo p on e.id_empleado = p.id_empleado_prestamo
where MONTH(p.fecha_prestamo ) = MONTH(GETDATE())
and YEAR(p.fecha_prestamo ) = YEAR(GETDATE())
group by e.id_empleado, e.nombre 
order by prestamos  desc;

--Consultas inventadas

--Socios con más libros prestados
select TOP 10 s.id_socio , s.nombre  + ' ' + s.apellido nombre_socio, count (p.id_prestamo ) libros_prestados
from socio s 
join prestamo p on s.id_socio = p.id_socio
where p.estado_prestamo = 'Prestado'
group by s.id_socio, s.nombre , s.apellido 
order by libros_prestados desc;

--Categoría con más ejemplares
select TOP 3 c.nombre_categoria , count(e.id_ejemplar ) total_ejemplares
from libro l 
join categoria c on l.id_categoria = c.id_categoria
join ejemplar e on l.isbn = e.isbn 
group by c.nombre_categoria
order by total_ejemplares desc;

--Estado de libros en stock
select l.titulo ,
case 
	when count(e.id_ejemplar) >= 10 then 'Titulo bien abastecido'
	when count(e.id_ejemplar) between 7 and 9 then 'Titulo abastecido'
	when count(e.id_ejemplar) between 4 and 6 then 'Titulo poco abastecido'
	else 'Titulo muy poco abastecido'
end estado_stock , count(e.id_ejemplar ) cantidad_ejemplares
from libro l 
join ejemplar e on l.isbn = e.isbn
group by l.titulo 
order by cantidad_ejemplares desc;

--Socios que más tiempo han tenido un libro
select TOP 10 s.nombre + ' ' + s.apellido nombre_socio, p.fecha_prestamo , p.fecha_devolucion ,
DATEDIFF(day, p.fecha_prestamo, p.fecha_devolucion) dias_posecion 
from prestamo p 
join socio s on p.id_socio = s.id_socio
where p.estado_prestamo = 'Devuelto'
order by dias_posecion desc;

--Clasificación de devoluciones de este año
select p.id_prestamo , s.nombre + ' ' + s.apellido nombre_socio, MONTH(p.fecha_devolucion) mes_devuelto,
case
	when p.fecha_devolucion <= p.fecha_limite then 'Entregado a tiempo'
	when DATEDIFF(day, p.fecha_limite, p.fecha_devolucion) between 1 and 5 then 'Retraso leve'
	when DATEDIFF(day, p.fecha_limite, p.fecha_devolucion) between 6 and 9 then 'Retraso moderado'
	else 'Retraso grave'
end tipo_retraso
from prestamo p 
join socio s on p.id_socio = s.id_socio
where p.fecha_devolucion is not null
order by 
case 
	when p.fecha_devolucion <= p.fecha_limite then 1
	when DATEDIFF(day, p.fecha_limite, p.fecha_devolucion) between 1 and 5 then 2
	when DATEDIFF(day, p.fecha_limite, p.fecha_devolucion) between 6 and 9 then 3
	else 4
end;
