-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1:3306
-- Tiempo de generación: 03-10-2024 a las 21:26:07
-- Versión del servidor: 10.11.9-MariaDB
-- Versión de PHP: 7.2.34

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `u431254651_dist_guad`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE PROCEDURE `prc_ActualizarDetalleVenta` (IN `p_codigo_producto` VARCHAR(20), IN `p_cantidad` FLOAT, IN `p_id` INT)   BEGIN

 declare v_nro_boleta varchar(20);
 declare v_total_venta float;

/*
ACTUALIZAR EL STOCK DEL PRODUCTO QUE SEA MODIFICADO
......
.....
.......
*/

/*
ACTULIZAR CODIGO, CANTIDAD Y TOTAL DEL ITEM MODIFICADO
*/

 UPDATE venta_detalle 
 SET codigo_producto = p_codigo_producto, 
 cantidad = p_cantidad, 
 total_venta = (p_cantidad * (select precio_venta_producto from productos where codigo_producto = p_codigo_producto))
 WHERE id = p_id;
 
 set v_nro_boleta = (select nro_boleta from venta_detalle where id = p_id);
 set v_total_venta = (select sum(total_venta) from venta_detalle where nro_boleta = v_nro_boleta);
 
 update venta_cabecera
   set total_venta = v_total_venta
 where nro_boleta = v_nro_boleta;

END$$

CREATE PROCEDURE `prc_ListarCategorias` ()   BEGIN
select * from categorias;
END$$

CREATE PROCEDURE `prc_ListarProductos` ()   BEGIN  
    SELECT  
        '' as detalle,
        '' as acciones,
        p.id,
        codigo_producto,
        p.id_categoria,
        upper(c.descripcion) as nombre_categoria,
        upper(p.descripcion) as producto,
        imagen,
        p.id_tipo_afectacion_iva,
        upper(tai.descripcion) as tipo_afectacion_iva,
        p.id_unidad_medida,
        upper(cum.descripcion) as unidad_medida,
        ROUND(costo_unitario,2) as costo_unitario,
        ROUND(precio_unitario_con_iva,2) as precio_unitario_con_iva,
        ROUND(precio_unitario_sin_iva,2) as precio_unitario_sin_iva,
        ROUND(precio_unitario_mayor_con_iva,2) as precio_unitario_mayor_con_iva,
        ROUND(precio_unitario_mayor_sin_iva,2) as precio_unitario_mayor_sin_iva,
        ROUND(precio_unitario_oferta_con_iva,2) as precio_unitario_oferta_con_iva,
        ROUND(precio_unitario_oferta_sin_iva,2) as precio_unitario_oferta_sin_iva,
        stock,
        minimo_stock,
        ventas,
        ROUND(costo_total,2) as costo_total,
        p.fecha_creacion,
        p.fecha_actualizacion,
        case when p.estado = 1 then 'ACTIVO' else 'INACTIVO' end estado
    FROM productos p 
    INNER JOIN categorias c on p.id_categoria = c.id
    INNER JOIN tipo_afectacion_iva tai on tai.codigo = p.id_tipo_afectacion_iva
    INNER JOIN codigo_unidad_medida cum on cum.id = p.id_unidad_medida
    WHERE p.estado in (0,1)
    ORDER BY p.codigo_producto desc;
END$$

CREATE PROCEDURE `prc_ListarProductosMasVendidos` ()  NO SQL BEGIN

select  p.codigo_producto,
		p.descripcion,
        sum(vd.cantidad) as cantidad,
        sum(Round(vd.importe_total,2)) as total_venta
from detalle_venta vd inner join productos p on vd.codigo_producto = p.codigo_producto
group by p.codigo_producto,
		p.descripcion
order by  sum(Round(vd.importe_total,2)) DESC
limit 10;

END$$

CREATE PROCEDURE `prc_ListarProductosPocoStock` ()  NO SQL BEGIN
select p.codigo_producto,
		p.descripcion,
        p.stock,
        p.minimo_stock
from productos p
where p.stock <= p.minimo_stock
order by p.stock asc;
END$$

CREATE PROCEDURE `prc_movimentos_arqueo_caja_por_usuario` (`p_id_usuario` INT, `p_id_caja` INT)   BEGIN

	select 
	ac.monto_apertura as y,
	'APERTURA' as label,
	"#6c757d" as color
	from arqueo_caja ac inner join usuarios usu on ac.id_usuario = usu.id_usuario
	where ac.id_usuario = p_id_usuario
    and ac.id = p_id_caja
	and date(ac.fecha_apertura) = curdate()
	union  
	select 
	ac.ingresos as y,
	'INGRESOS' as label,
	"#28a745" as color
	from arqueo_caja ac inner join usuarios usu on ac.id_usuario = usu.id_usuario
	where ac.id_usuario = p_id_usuario
    and ac.id = p_id_caja
	and date(ac.fecha_apertura) = curdate()
	union
	select 
	ac.devoluciones as y,
	'DEVOLUCIONES' as label,
	"#ffc107" as color
	from arqueo_caja ac inner join usuarios usu on ac.id_usuario = usu.id_usuario
	where ac.id_usuario = p_id_usuario
    and ac.id = p_id_caja
	and date(ac.fecha_apertura) = curdate()
	union
	select 
	ac.gastos as y,
	'GASTOS' as label,
	"#17a2b8" as color
	from arqueo_caja ac inner join usuarios usu on ac.id_usuario = usu.id_usuario
	where ac.id_usuario = p_id_usuario
    and ac.id = p_id_caja
	and date(ac.fecha_apertura) = curdate();
END$$

CREATE PROCEDURE `prc_ObtenerDatosDashboard` ()  NO SQL BEGIN
  DECLARE totalProductos int;
  DECLARE totalCompras float;
  DECLARE totalVentas float;
  DECLARE ganancias float;
  DECLARE productosPocoStock int;
  DECLARE ventasHoy float;

  SET totalProductos = (SELECT
      COUNT(*)
    FROM productos p);
    
  SET totalCompras = (SELECT
      SUM(p.costo_total)
    FROM productos p);  

	SET totalVentas = 0;
  SET totalVentas = (SELECT
      SUM(v.importe_total)
    FROM venta v);

  SET ganancias = 0;
  SET ganancias = (SELECT
      SUM(dv.importe_total) - SUM(dv.cantidad * dv.costo_unitario)
    FROM detalle_venta dv);
    
  SET productosPocoStock = (SELECT
      COUNT(1)
    FROM productos p
    WHERE p.stock <= p.minimo_stock);
    
    SET ventasHoy = 0;
  SET ventasHoy = (SELECT
      SUM(v.importe_total)
    FROM venta v
    WHERE DATE(v.fecha_emision) = CURDATE());

  SELECT
    IFNULL(totalProductos, 0) AS totalProductos,
    IFNULL(CONCAT('Q. ', FORMAT(totalCompras, 2)), 0) AS totalCompras,
    IFNULL(CONCAT('Q. ', FORMAT(totalVentas, 2)), 0) AS totalVentas,
    IFNULL(CONCAT('Q. ', FORMAT(ganancias, 2), ' - ','  % ', FORMAT((ganancias / totalVentas) *100,2)), 0) AS ganancias,
    IFNULL(productosPocoStock, 0) AS productosPocoStock,
    IFNULL(CONCAT('Q. ', FORMAT(ventasHoy, 2)), 0) AS ventasHoy;



END$$

CREATE PROCEDURE `prc_obtenerNroBoleta` ()  NO SQL select serie_boleta,
		IFNULL(LPAD(max(c.nro_correlativo_venta)+1,8,'0'),'00000001') nro_venta 
from empresa c$$

CREATE PROCEDURE `prc_ObtenerVentasMesActual` ()  NO SQL BEGIN
SELECT date(vc.fecha_emision) as fecha_venta,
		sum(round(vc.importe_total,2)) as total_venta,
        ifnull((SELECT sum(round(vc1.importe_total,2))
			FROM venta vc1
		where date(vc1.fecha_emision) >= date(last_day(now() - INTERVAL 2 month) + INTERVAL 1 day)
		and date(vc1.fecha_emision) <= last_day(last_day(now() - INTERVAL 2 month) + INTERVAL 1 day)
        and date(vc1.fecha_emision) = DATE_ADD(date(vc.fecha_emision), INTERVAL -1 MONTH)
		group by date(vc1.fecha_emision)),0) as total_venta_ant
FROM venta vc
where date(vc.fecha_emision) >= date(last_day(now() - INTERVAL 1 month) + INTERVAL 1 day)
and date(vc.fecha_emision) <= last_day(date(CURRENT_DATE))
group by date(vc.fecha_emision);


END$$

CREATE PROCEDURE `prc_ObtenerVentasMesAnterior` ()  NO SQL BEGIN
SELECT date(vc.fecha_venta) as fecha_venta,
		sum(round(vc.total_venta,2)) as total_venta,
        sum(round(vc.total_venta,2)) as total_venta_ant
FROM venta_cabecera vc
where date(vc.fecha_venta) >= date(last_day(now() - INTERVAL 2 month) + INTERVAL 1 day)
and date(vc.fecha_venta) <= last_day(last_day(now() - INTERVAL 2 month) + INTERVAL 1 day)
group by date(vc.fecha_venta);
END$$

CREATE PROCEDURE `prc_pagar_cuotas_compra` (IN `p_id_compra` INT, IN `p_monto_a_pagar` FLOAT, IN `p_id_usuario` INT)   BEGIN

	DECLARE v_id INT;
	DECLARE v_id_compra INT;
	DECLARE v_cuota varchar(3);
	DECLARE v_importe FLOAT;
    DECLARE v_importe_pagado FLOAT;
    DECLARE v_saldo_pendiente FLOAT;
	DECLARE v_cuota_pagada BOOLEAN;
    DECLARE v_fecha_vencimiento DATE;
    
    DECLARE p_monto_a_pagar_original decimal(18,2);
    
    DECLARE v_id_arqueo_caja INT;
    
    DECLARE var_final INTEGER DEFAULT 0;
    
    DECLARE v_count INT DEFAULT 0;
    DECLARE v_mensaje varchar(500) DEFAULT '';
    
	DECLARE cursor1 CURSOR FOR 
    select id, 
			id_compra, 
            cuota, 
            importe, 
            importe_pagado, 
            saldo_pendiente, 
            cuota_pagada, 
            fecha_vencimiento
    from cuotas_compras c
    where c.id_compra = p_id_compra
    and c.cuota_pagada = 0
    order by c.id;
    
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET var_final = 1;
    set p_monto_a_pagar_original = p_monto_a_pagar;
    OPEN cursor1;

	  bucle: LOOP

		FETCH cursor1 
		INTO v_id,
			 v_id_compra, 
             v_cuota, 
             v_importe, 
             v_importe_pagado, 
             v_saldo_pendiente,
             v_cuota_pagada, 
             v_fecha_vencimiento;

		IF var_final = 1 THEN
		  LEAVE bucle;
		END IF;

		if(p_monto_a_pagar > 0 && (p_monto_a_pagar <= v_saldo_pendiente) ) then
			set v_mensaje = 'Monto a pagar menor al saldo pendiente de la cuota';
            update cuotas_compras c
			  set c.importe_pagado = round(ifnull(c.importe_pagado,0) + p_monto_a_pagar,2),
					c.saldo_pendiente = round(c.importe - ifnull(c.importe_pagado,0),2),
                    c.cuota_pagada = case when round(c.importe,2) = round(ifnull(c.importe_pagado,0),2) then 1 else 0 end                    
            where c.id = v_id;
            
            set p_monto_a_pagar = p_monto_a_pagar - v_saldo_pendiente;
            
            LEAVE bucle;
        end if;
        
        if(p_monto_a_pagar > 0 && (p_monto_a_pagar > v_saldo_pendiente)) then
        
			set v_mensaje = 'Monto a pagar mayor al saldo pendiente de la cuota';
        
			 update cuotas_compras c
			  set c.importe_pagado = round(c.importe,2),
					c.saldo_pendiente = 0,
                    c.cuota_pagada = case when round(c.importe,2) = round(ifnull(c.importe_pagado,0),2) then 1 else 0 end                    
            where c.id = v_id;
            
            set p_monto_a_pagar = p_monto_a_pagar - v_saldo_pendiente;
        end if;
		 
	  END LOOP bucle;
	  CLOSE cursor1; 
      
      SET v_saldo_pendiente = 0;
      
      select sum(ifnull(saldo_pendiente,0))
      into v_saldo_pendiente
      from cuotas_compras where id_compra = p_id_compra;
      
      if(v_saldo_pendiente <= 0) then
		update compras
			set pagado = 1
        where id = p_id_compra;
      end if;
    
     -- SELECT p_monto_a_pagar as vuelto;
     
     select id
     into v_id_arqueo_caja
     from arqueo_caja
	where id_usuario = p_id_usuario
    and estado = 1;
     
     insert into movimientos_arqueo_caja(id_arqueo_caja, id_tipo_movimiento, descripcion, monto, estado)
     values(v_id_arqueo_caja, 5, 'PAGO CUOTA DE COMPRA AL CREDITO', p_monto_a_pagar_original, 1);
     
     update arqueo_caja 
      set gastos = ifnull(gastos,0) + p_monto_a_pagar_original,
      	 monto_final = ifnull(monto_final,0) - p_monto_a_pagar_original
    where id_usuario = p_id_usuario
    and estado = 1;
     
     
END$$

CREATE PROCEDURE `prc_pagar_cuotas_factura` (IN `p_id_venta` INT, IN `p_monto_a_pagar` FLOAT, IN `p_id_usuario` INT, IN `p_medio_pago` INT)   BEGIN

	DECLARE v_id INT;
	DECLARE v_id_venta INT;
	DECLARE v_cuota varchar(3);
	DECLARE v_importe FLOAT;
    DECLARE v_importe_pagado FLOAT;
    DECLARE v_saldo_pendiente FLOAT;
	DECLARE v_cuota_pagada BOOLEAN;
    DECLARE v_fecha_vencimiento DATE;
    
    DECLARE v_id_medio_pago INT;
    DECLARE v_id_tipo_movimiento_caja INT;
    DECLARE v_afecta_caja INT;
    DECLARE v_medio_pago VARCHAR(100);
    
    DECLARE p_monto_a_pagar_original decimal(18,2);
    
    DECLARE v_id_arqueo_caja INT;
    
    DECLARE var_final INTEGER DEFAULT 0;
    
    DECLARE v_count INT DEFAULT 0;
    DECLARE v_mensaje varchar(500) DEFAULT '';
    
	DECLARE cursor1 CURSOR FOR 
    select id, 
			id_venta, 
            cuota, 
            importe, 
            importe_pagado, 
            saldo_pendiente, 
            cuota_pagada, 
            fecha_vencimiento
    from cuotas c
    where c.id_venta = p_id_venta
    and c.cuota_pagada = 0
    order by c.id;
    
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET var_final = 1;
    set p_monto_a_pagar_original = p_monto_a_pagar;
    OPEN cursor1;

	  bucle: LOOP

		FETCH cursor1 
		INTO v_id,
			 v_id_venta, 
             v_cuota, 
             v_importe, 
             v_importe_pagado, 
             v_saldo_pendiente,
             v_cuota_pagada, 
             v_fecha_vencimiento;

		IF var_final = 1 THEN
		  LEAVE bucle;
		END IF;

		if(p_monto_a_pagar > 0 && (p_monto_a_pagar <= v_saldo_pendiente) ) then
			set v_mensaje = 'Monto a pagar menor al saldo pendiente de la cuota';
            update cuotas c
			  set c.importe_pagado = round(ifnull(c.importe_pagado,0) + p_monto_a_pagar,2),
					c.saldo_pendiente = round(c.importe - ifnull(c.importe_pagado,0),2),
                    c.cuota_pagada = case when round(c.importe,2) = round(ifnull(c.importe_pagado,0),2) then 1 else 0 end,
                    c.medio_pago = p_medio_pago
            where c.id = v_id;
            
            set p_monto_a_pagar = p_monto_a_pagar - v_saldo_pendiente;
            
            LEAVE bucle;
        end if;
        
        if(p_monto_a_pagar > 0 && (p_monto_a_pagar > v_saldo_pendiente)) then
        
			set v_mensaje = 'Monto a pagar mayor al saldo pendiente de la cuota';
        
			 update cuotas c
			  set c.importe_pagado = round(c.importe,2),
					c.saldo_pendiente = 0,
                    c.cuota_pagada = case when round(c.importe,2) = round(ifnull(c.importe_pagado,0),2) then 1 else 0 end,
                    c.medio_pago = p_medio_pago
            where c.id = v_id;
            
            set p_monto_a_pagar = p_monto_a_pagar - v_saldo_pendiente;
        end if;
		 
	  END LOOP bucle;
	  CLOSE cursor1; 
      
      SET v_saldo_pendiente = 0;
      
      select sum(ifnull(saldo_pendiente,0))
      into v_saldo_pendiente
      from cuotas where id_venta = p_id_venta;
      
      if(v_saldo_pendiente = 0) then
		update venta
			set pagado = 1
        where id = p_id_venta;
      end if;
    
     -- SELECT p_monto_a_pagar as vuelto;
     
     select id
     into v_id_arqueo_caja
     from arqueo_caja
	where id_usuario = p_id_usuario
    and estado = 1;
     
     -- SETEMOS EL TIPO DE MOVIMIENTO DE CAJA 
     select mp.id as id_medio_pago, mp.id_tipo_movimiento_caja, tmc.afecta_caja, mp.descripcion as medio_pago
     INTO v_id_medio_pago, v_id_tipo_movimiento_caja, v_afecta_caja, v_medio_pago
	from medio_pago mp inner join tipo_movimiento_caja tmc on mp.id_tipo_movimiento_caja = tmc.id
	where mp.id = p_medio_pago;
    
     insert into movimientos_arqueo_caja(id_arqueo_caja, id_tipo_movimiento, descripcion, monto, estado)
     values(v_id_arqueo_caja, v_id_tipo_movimiento_caja, concat('PAGO ',v_medio_pago ,' CUOTA DE FACTURA'), p_monto_a_pagar_original, 1);
     
     if v_afecta_caja = 1 THEN
		 update arqueo_caja 
		  set ingresos = ifnull(ingresos,0) + p_monto_a_pagar_original,
			 monto_final = ifnull(monto_final,0) + p_monto_a_pagar_original
		where id_usuario = p_id_usuario
		and estado = 1;
    END IF;
     
     
END$$

CREATE PROCEDURE `prc_registrar_kardex_anulacion` (IN `p_id_venta` INT, IN `p_codigo_producto` VARCHAR(20))   BEGIN

	/*VARIABLES PARA EXISTENCIAS ACTUALES*/
	declare v_unidades_ex float;
	declare v_costo_unitario_ex float;    
	declare v_costo_total_ex float;
    
    declare v_unidades_in float;
	declare v_costo_unitario_in float;    
	declare v_costo_total_in float;
    
    declare v_cantidad_devolucion float;
	declare v_costo_unitario_devolucion float;   
    declare v_comprobante_devolucion varchar(20);   
    declare v_concepto_devolucion varchar(50);   
    
	/*OBTENEMOS LAS ULTIMAS EXISTENCIAS DEL PRODUCTO*/    
    SELECT k.ex_costo_unitario , k.ex_unidades, k.ex_costo_total
    into v_costo_unitario_ex, v_unidades_ex, v_costo_total_ex
    FROM kardex k
    WHERE k.codigo_producto = p_codigo_producto
    ORDER BY id DESC
    LIMIT 1;
    
    select   cantidad, 
			costo_unitario,
			concat(v.serie,'-',v.correlativo) as comprobante,
			'DEVOLUCIÓN' as concepto
	  into v_cantidad_devolucion, v_costo_unitario_devolucion,
			v_comprobante_devolucion, v_concepto_devolucion 
	from detalle_venta dv inner join venta v on dv.id_venta = v.id
    where dv.id_venta = p_id_venta and dv.codigo_producto = p_codigo_producto;
    
      /*SETEAMOS LOS VALORES PARA EL REGISTRO DE INGRESO*/
    SET v_unidades_in = v_cantidad_devolucion;
    SET v_costo_unitario_in = v_costo_unitario_devolucion;
    SET v_costo_total_in = v_unidades_in * v_costo_unitario_in;
    
    /*SETEAMOS LAS EXISTENCIAS ACTUALES*/
    SET v_unidades_ex = v_unidades_ex + ROUND(v_cantidad_devolucion,2);    
    SET v_costo_total_ex = ROUND(v_costo_total_ex + v_costo_total_in,2);
    SET v_costo_unitario_ex = ROUND(v_costo_total_ex/v_unidades_ex,2);


	INSERT INTO kardex(codigo_producto,
						fecha,
                        concepto,
                        comprobante,
                        in_unidades,
                        in_costo_unitario,
                        in_costo_total,
                        ex_unidades,
                        ex_costo_unitario,
                        ex_costo_total)
				VALUES(p_codigo_producto,
						curdate(),
                        v_concepto_devolucion,
                        v_comprobante_devolucion,
                        v_unidades_in,
                        v_costo_unitario_in,
                        v_costo_total_in,
                        v_unidades_ex,
                        v_costo_unitario_ex,
                        v_costo_total_ex);

	/*ACTUALIZAMOS EL STOCK, EL NRO DE VENTAS DEL PRODUCTO*/
	UPDATE productos 
	SET stock = v_unidades_ex, 
         costo_unitario = v_costo_unitario_ex,
         costo_total= v_costo_total_ex
	WHERE codigo_producto = p_codigo_producto ;  

END$$

CREATE PROCEDURE `prc_registrar_kardex_bono` (IN `p_codigo_producto` VARCHAR(20), IN `p_concepto` VARCHAR(100), IN `p_nuevo_stock` FLOAT)   BEGIN

	/*VARIABLES PARA EXISTENCIAS ACTUALES*/
	declare v_unidades_ex float;
	declare v_costo_unitario_ex float;    
	declare v_costo_total_ex float;
    
    declare v_unidades_in float;
	declare v_costo_unitario_in float;    
	declare v_costo_total_in float;
    
	/*OBTENEMOS LAS ULTIMAS EXISTENCIAS DEL PRODUCTO*/    
    SELECT k.ex_costo_unitario , k.ex_unidades, k.ex_costo_total
    into v_costo_unitario_ex, v_unidades_ex, v_costo_total_ex
    FROM kardex k
    WHERE k.codigo_producto = p_codigo_producto
    ORDER BY id DESC
    LIMIT 1;
    
    /*SETEAMOS LOS VALORES PARA EL REGISTRO DE INGRESO*/
    SET v_unidades_in = p_nuevo_stock - v_unidades_ex;
    SET v_costo_unitario_in = v_costo_unitario_ex;
    SET v_costo_total_in = v_unidades_in * v_costo_unitario_in;
    
    /*SETEAMOS LAS EXISTENCIAS ACTUALES*/
    SET v_unidades_ex = ROUND(p_nuevo_stock,2);    
    SET v_costo_total_ex = ROUND(v_costo_total_ex + v_costo_total_in,2);
    
    IF(v_costo_total_ex > 0) THEN
		SET v_costo_unitario_ex = ROUND(v_costo_total_ex/v_unidades_ex,2);
	else
		SET v_costo_unitario_ex = ROUND(0,2);
    END IF;
    
        
	INSERT INTO kardex(codigo_producto,
						fecha,
                        concepto,
                        comprobante,
                        in_unidades,
                        in_costo_unitario,
                        in_costo_total,
                        ex_unidades,
                        ex_costo_unitario,
                        ex_costo_total)
				VALUES(p_codigo_producto,
						curdate(),
                        p_concepto,
                        '',
                        v_unidades_in,
                        v_costo_unitario_in,
                        v_costo_total_in,
                        v_unidades_ex,
                        v_costo_unitario_ex,
                        v_costo_total_ex);

	/*ACTUALIZAMOS EL STOCK, EL NRO DE VENTAS DEL PRODUCTO*/
	UPDATE productos 
	SET stock = v_unidades_ex, 
         costo_unitario = v_costo_unitario_ex,
         costo_total= v_costo_total_ex
	WHERE codigo_producto = p_codigo_producto ;                      

END$$

CREATE PROCEDURE `prc_registrar_kardex_compra` (IN `p_id_compra` INT, IN `p_comprobante` VARCHAR(20), IN `p_codigo_producto` VARCHAR(20), IN `p_concepto` VARCHAR(100), IN `p_cantidad_compra` FLOAT, IN `p_costo_compra` FLOAT)   BEGIN

	/*VARIABLES PARA EXISTENCIAS ACTUALES*/
	declare v_unidades_ex float;
	declare v_costo_unitario_ex float;    
	declare v_costo_total_ex float;
    
    declare v_unidades_in float;
	declare v_costo_unitario_in float;    
	declare v_costo_total_in float;
    
	/*OBTENEMOS LAS ULTIMAS EXISTENCIAS DEL PRODUCTO*/    
    SELECT k.ex_costo_unitario , k.ex_unidades, k.ex_costo_total
    into v_costo_unitario_ex, v_unidades_ex, v_costo_total_ex
    FROM kardex k
    WHERE k.codigo_producto = p_codigo_producto
    ORDER BY id DESC
    LIMIT 1;
    
    /*SETEAMOS LOS VALORES PARA EL REGISTRO DE INGRESO*/
    SET v_unidades_in = p_cantidad_compra;
    SET v_costo_unitario_in = p_costo_compra;
    SET v_costo_total_in = v_unidades_in * v_costo_unitario_in;
    
    /*SETEAMOS LAS EXISTENCIAS ACTUALES*/
    SET v_unidades_ex = v_unidades_ex + ROUND(p_cantidad_compra,2);    
    SET v_costo_total_ex = ROUND(v_costo_total_ex + v_costo_total_in,2);
    SET v_costo_unitario_ex = ROUND(v_costo_total_ex/v_unidades_ex,2);

	INSERT INTO kardex(codigo_producto,
						fecha,
                        concepto,
                        comprobante,
                        in_unidades,
                        in_costo_unitario,
                        in_costo_total,
                        ex_unidades,
                        ex_costo_unitario,
                        ex_costo_total)
				VALUES(p_codigo_producto,
						curdate(),
                        p_concepto,
                        p_comprobante,
                        v_unidades_in,
                        v_costo_unitario_in,
                        v_costo_total_in,
                        v_unidades_ex,
                        v_costo_unitario_ex,
                        v_costo_total_ex);

	/*ACTUALIZAMOS EL STOCK, EL NRO DE VENTAS DEL PRODUCTO*/
	UPDATE productos 
	SET stock = v_unidades_ex, 
         costo_unitario = v_costo_unitario_ex,
         costo_total= v_costo_total_ex
	WHERE codigo_producto = p_codigo_producto ;  
  

END$$

CREATE PROCEDURE `prc_registrar_kardex_existencias` (IN `p_codigo_producto` VARCHAR(25), IN `p_concepto` VARCHAR(100), IN `p_comprobante` VARCHAR(100), IN `p_unidades` FLOAT, IN `p_costo_unitario` FLOAT, IN `p_costo_total` FLOAT)   BEGIN
  INSERT INTO kardex (codigo_producto, fecha, concepto, comprobante, in_unidades, in_costo_unitario, in_costo_total,ex_unidades, ex_costo_unitario, ex_costo_total)
    VALUES (p_codigo_producto, CURDATE(), p_concepto, p_comprobante, p_unidades, p_costo_unitario, p_costo_total, p_unidades, p_costo_unitario, p_costo_total);

END$$

CREATE PROCEDURE `prc_registrar_kardex_vencido` (IN `p_codigo_producto` VARCHAR(20), IN `p_concepto` VARCHAR(100), IN `p_nuevo_stock` FLOAT)   BEGIN

	declare v_unidades_ex float;
	declare v_costo_unitario_ex float;    
	declare v_costo_total_ex float;
    
    declare v_unidades_out float;
	declare v_costo_unitario_out float;    
	declare v_costo_total_out float;
    
	/*OBTENEMOS LAS ULTIMAS EXISTENCIAS DEL PRODUCTO*/    
    SELECT k.ex_costo_unitario , k.ex_unidades, k.ex_costo_total
    into v_costo_unitario_ex, v_unidades_ex, v_costo_total_ex
    FROM kardex k
    WHERE k.codigo_producto = p_codigo_producto
    ORDER BY ID DESC
    LIMIT 1;
    
    /*SETEAMOS LOS VALORES PARA EL REGISTRO DE SALIDA*/
    SET v_unidades_out = v_unidades_ex - p_nuevo_stock;
    SET v_costo_unitario_out = v_costo_unitario_ex;
    SET v_costo_total_out = v_unidades_out * v_costo_unitario_out;
    
    /*SETEAMOS LAS EXISTENCIAS ACTUALES*/
    SET v_unidades_ex = ROUND(p_nuevo_stock,2);    
    SET v_costo_total_ex = ROUND(v_costo_total_ex - v_costo_total_out,2);
    
    IF(v_costo_total_ex > 0) THEN
		SET v_costo_unitario_ex = ROUND(v_costo_total_ex/v_unidades_ex,2);
	else
		SET v_costo_unitario_ex = ROUND(0,2);
    END IF;
    
        
	INSERT INTO kardex(codigo_producto,
						fecha,
                        concepto,
                        comprobante,
                        out_unidades,
                        out_costo_unitario,
                        out_costo_total,
                        ex_unidades,
                        ex_costo_unitario,
                        ex_costo_total)
				VALUES(p_codigo_producto,
						curdate(),
                        p_concepto,
                        '',
                        v_unidades_out,
                        v_costo_unitario_out,
                        v_costo_total_out,
                        v_unidades_ex,
                        v_costo_unitario_ex,
                        v_costo_total_ex);

	/*ACTUALIZAMOS EL STOCK, EL NRO DE VENTAS DEL PRODUCTO*/
	UPDATE productos 
	SET stock = v_unidades_ex, 
         costo_unitario = v_costo_unitario_ex,
        costo_total = v_costo_total_ex
	WHERE codigo_producto = p_codigo_producto ;                      

END$$

CREATE PROCEDURE `prc_registrar_kardex_venta` (IN `p_codigo_producto` VARCHAR(20), IN `p_fecha` DATE, IN `p_concepto` VARCHAR(100), IN `p_comprobante` VARCHAR(100), IN `p_unidades` FLOAT)   BEGIN

	declare v_unidades_ex float;
	declare v_costo_unitario_ex float;    
	declare v_costo_total_ex float;
    
    declare v_costo_total_ex_actual float;
    
    declare v_unidades_out float;
	declare v_costo_unitario_out float;    
	declare v_costo_total_out float;
    

	/*OBTENEMOS LAS ULTIMAS EXISTENCIAS DEL PRODUCTO*/
    
    SELECT k.ex_costo_unitario , k.ex_unidades, k.ex_costo_total, k.ex_costo_total
    into v_costo_unitario_ex, v_unidades_ex, v_costo_total_ex, v_costo_total_ex_actual
    FROM kardex k
    WHERE k.codigo_producto = p_codigo_producto
    ORDER BY id DESC
    LIMIT 1;
    
    /*SETEAMOS LOS VALORES PARA EL REGISTRO DE SALIDA*/
    SET v_unidades_out = p_unidades;
    SET v_costo_unitario_out = v_costo_unitario_ex;
    SET v_costo_total_out = p_unidades * v_costo_unitario_ex;
    
    /*SETEAMOS LAS EXISTENCIAS ACTUALES*/
    SET v_unidades_ex = ROUND(v_unidades_ex - v_unidades_out,2);    
    SET v_costo_total_ex = ROUND(v_costo_total_ex -  v_costo_total_out,2);
    
    IF(v_costo_total_ex > 0) THEN
		SET v_costo_unitario_ex = ROUND(v_costo_total_ex/v_unidades_ex,2);
	else
		SET v_costo_unitario_ex = ROUND(v_costo_unitario_ex,2);
    END IF;
    
        
	INSERT INTO kardex(codigo_producto,
						fecha,
                        concepto,
                        comprobante,
                        out_unidades,
                        out_costo_unitario,
                        out_costo_total,
                        ex_unidades,
                        ex_costo_unitario,
                        ex_costo_total)
				VALUES(p_codigo_producto,
						p_fecha,
                        p_concepto,
                        p_comprobante,
                        v_unidades_out,
                        v_costo_unitario_out,
                        v_costo_total_out,
                        v_unidades_ex,
                        v_costo_unitario_ex,
                        v_costo_total_ex);

	/*ACTUALIZAMOS EL STOCK, EL NRO DE VENTAS DEL PRODUCTO*/
	UPDATE productos 
	SET stock = v_unidades_ex, 
		ventas = ventas + v_unidades_out,
        costo_unitario = v_costo_unitario_ex,
        costo_total = v_costo_total_ex
	WHERE codigo_producto = p_codigo_producto ;                      

END$$

CREATE PROCEDURE `prc_registrar_venta_detalle` (IN `p_nro_boleta` VARCHAR(8), IN `p_codigo_producto` VARCHAR(20), IN `p_cantidad` FLOAT, IN `p_total_venta` FLOAT)   BEGIN
declare v_precio_compra float;
declare v_precio_venta float;

SELECT p.precio_compra_producto,p.precio_venta_producto
into v_precio_compra, v_precio_venta
FROM productos p
WHERE p.codigo_producto  = p_codigo_producto;
    
INSERT INTO venta_detalle(nro_boleta,codigo_producto, cantidad, costo_unitario_venta,precio_unitario_venta,total_venta, fecha_venta) 
VALUES(p_nro_boleta,p_codigo_producto,p_cantidad, v_precio_compra, v_precio_venta,p_total_venta,curdate());
                                                        
END$$

CREATE PROCEDURE `prc_ReporteVentas` (IN `p_fecha_desde` DATE, IN `p_fecha_hasta` DATE)   BEGIN

	select v.fecha_emision,
			-- '' as fecha_vencimiento,
            case when upper(v.forma_pago) = 'CONTADO' then v.fecha_emision 
				else (select cuo.fecha_vencimiento from cuotas cuo where id_venta = v.id
						order by cuota desc limit 1) end as fecha_vencimiento,
			s.id_tipo_comprobante,
			v.serie,
			lpad(v.correlativo,13,'0') as correlativo,
			cli.id_tipo_documento,
			cli.nro_documento,
			cli.nombres_apellidos_razon_social,
			'' as valor_facturado_exportacion,
			'' as isc,        
			v.total_iva as iva,
			'' as otros_tributos_no_base_imponible,
			v.importe_total as importe_total_comprobante_pago,
			'' as tipo_cambio,
			/*REFERENCIA DEL COMPROBANTE DE PAGO O DOCUMENTO ORIGINAL QUE SE MODIFICA*/
			'' as fecha_referencia,
			'' as tipo_referencia,
			'' as serie_referencia,
			'' as nro_comprobante_pago_o_documento,
			case when v.id_moneda = 'GTQ' then 'Q' else '$' end as moneda,
			'' as equivalente_dolares_americanos,
			'' as fecha_vencimiento,
			case when upper(v.forma_pago) = 'CONTADO' then 'CON' else 'CRE' end as condicion_contado_credito,
			'' as codigo_centro_costos,
			'' as codigo_centro_costos_2,
			'70121' as cuenta_contable_base_imponible,
			'' as cuenta_contable_otros_tributos,
			'1212' as cuenta_contable_total,
			'' as regimen_especial,
			'' as porcentaje_regimen_especial,
			'' as importe_regimen_especial,
			'' as serie_documento_regimen_especial,
			'' as numero_documento_regimen_especial,
			'' as fecha_documento_regimen_especial,
			'' as codigo_presupuesto,
			'' as porcentaje_iva,
			'VENTA DE MERCADERIA' as glosa,
			'' as medio_pago,
			'' as condicion_percepción,
			'' as importe_calculo_regimen_especial,
			'' as impuesto_consumo_bolsas_plastico,
			'' as cuenta_contable_icbper
	from venta v inner join serie s on v.id_serie = s.id
				 inner join clientes cli on cli.id = v.id_cliente
	where v.fecha_emision between p_fecha_desde and p_fecha_hasta;
				 
END$$

CREATE PROCEDURE `prc_top_ventas_categorias` ()   BEGIN

select cast(sum(vd.importe_total)  AS DECIMAL(8,2)) as y, c.descripcion as label
    from detalle_venta vd inner join productos p on vd.codigo_producto = p.codigo_producto
                        inner join categorias c on c.id = p.id_categoria
    group by c.descripcion
    LIMIT 10;
END$$

CREATE PROCEDURE `prc_total_facturas_boletas` ()   BEGIN

select cast(sum(v.importe_total)  AS DECIMAL(8,2)) as y, tc.descripcion as label
    from venta v inner join serie s on v.id_serie = s.id
				 inner join tipo_comprobante tc on tc.codigo = s.id_tipo_comprobante
    group by s.id_tipo_comprobante
    LIMIT 10;
END$$

CREATE PROCEDURE `prc_truncate_all_tables` ()   BEGIN

SET FOREIGN_KEY_CHECKS = 0;

/*
truncate table arqueo_caja;

truncate table clientes;
truncate table compras;
truncate table cotizaciones;
truncate table cotizaciones_detalle;
truncate table cuotas;
truncate table cuotas_compras;
truncate table detalle_compra;
truncate table compras;
truncate table detalle_venta;
truncate table venta;
truncate table empresas;*/
truncate table codigo_unidad_medida;
truncate table tipo_afectacion_iva;
truncate table categorias;
truncate table kardex;
truncate table productos;
/*
truncate table movimientos_arqueo_caja;
truncate table proveedores;
truncate table resumenes_detalle;

truncate table resumenes;
truncate table serie;*/

SET FOREIGN_KEY_CHECKS = 1;

END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `arqueo_caja`
--

CREATE TABLE `arqueo_caja` (
  `id` int(11) NOT NULL,
  `id_usuario` int(11) NOT NULL,
  `fecha_apertura` datetime NOT NULL DEFAULT current_timestamp(),
  `fecha_cierre` datetime DEFAULT NULL,
  `monto_apertura` float NOT NULL,
  `ingresos` float DEFAULT NULL,
  `devoluciones` float DEFAULT NULL,
  `gastos` float DEFAULT NULL,
  `monto_final` float DEFAULT NULL,
  `monto_real` float DEFAULT NULL,
  `sobrante` float DEFAULT NULL,
  `faltante` float DEFAULT NULL,
  `estado` int(11) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `arqueo_caja`
--

INSERT INTO `arqueo_caja` (`id`, `id_usuario`, `fecha_apertura`, `fecha_cierre`, `monto_apertura`, `ingresos`, `devoluciones`, `gastos`, `monto_final`, `monto_real`, `sobrante`, `faltante`, `estado`) VALUES
(1, 14, '2024-09-13 16:22:56', '2024-09-13 19:07:17', 100, 0, 0, 0, 100, 100, 0, 0, 0),
(2, 14, '2024-09-13 19:11:08', '2024-09-14 00:04:27', 150, 0, 0, 0, 0, 95, 0, 0, 0),
(3, 14, '2024-09-14 00:04:33', '2024-09-14 01:20:44', 100, 0, 0, 0, 100, 100, 0, 0, 0),
(4, 14, '2024-09-14 02:20:13', '2024-09-17 10:46:48', 100, 0, 0, 0, 0, 100, 0, 0, 0),
(5, 14, '2024-09-17 10:48:23', '2024-09-17 18:42:50', 200, 1609.18, 0, 40, 1769.18, 1800, 30.82, 0, 0),
(6, 14, '2024-09-17 19:12:02', '2024-09-17 19:14:54', 200, 64.74, 5, 14, 245.74, 246, 0.26, 0, 0),
(7, 32, '2024-09-17 20:26:43', '2024-09-17 20:32:37', 200, 141.35, 38.31, 25, 278.04, 278.04, 0, 0, 0),
(8, 14, '2024-09-19 11:59:56', '2024-09-19 13:04:34', 200, 0, 0, 0, 200, 200, 0, 0, 0),
(9, 14, '2024-09-19 13:59:01', '2024-09-28 06:48:25', 200, 0, 0, 0, 0, 228.34, 0, 0, 0),
(10, 14, '2024-09-28 20:30:27', '2024-09-28 21:22:18', 200, 90.49, 0, 0, 290.49, 290.49, 0, 0, 0);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cajas`
--

CREATE TABLE `cajas` (
  `id` int(11) NOT NULL,
  `nombre_caja` varchar(100) NOT NULL,
  `estado` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Volcado de datos para la tabla `cajas`
--

INSERT INTO `cajas` (`id`, `nombre_caja`, `estado`) VALUES
(1, 'Sin Caja', 1),
(2, 'Caja Principal', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `categorias`
--

CREATE TABLE `categorias` (
  `id` int(11) NOT NULL,
  `descripcion` varchar(150) NOT NULL,
  `fecha_creacion` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `fecha_actualizacion` timestamp NULL DEFAULT NULL,
  `estado` int(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_spanish_ci;

--
-- Volcado de datos para la tabla `categorias`
--

INSERT INTO `categorias` (`id`, `descripcion`, `fecha_creacion`, `fecha_actualizacion`, `estado`) VALUES
(1, 'Productos de Higiene Personal', '2024-09-13 16:06:18', NULL, 1),
(2, 'Insecticidas y Repelentes', '2024-09-13 16:06:18', NULL, 1),
(3, 'Bolsas de Basura', '2024-09-13 16:06:18', NULL, 1),
(4, 'Papel Higiénico y Toallas de Papel', '2024-09-13 16:06:18', NULL, 1),
(5, 'Limpiavidrios', '2024-09-13 16:06:18', NULL, 1),
(6, 'Trapos, Esponjas y Paños', '2024-09-13 16:06:18', NULL, 1),
(7, 'Guantes y Equipo de Protección', '2024-09-13 16:06:18', NULL, 1),
(8, 'Escobas, Trapeadores y Mopas', '2024-09-13 16:06:18', NULL, 1),
(9, 'Aromatizantes y Ambientadores', '2024-09-13 16:06:18', NULL, 1),
(10, 'Productos para Limpieza de Cocinas', '2024-09-13 16:06:18', NULL, 1),
(11, 'Productos para Limpieza de Baños', '2024-09-13 16:06:18', NULL, 1),
(12, 'Productos para Lavandería', '2024-09-13 16:06:18', NULL, 1),
(13, 'Limpiadores Multiusos', '2024-09-13 16:06:18', NULL, 1),
(14, 'Desinfectantes', '2024-09-13 16:06:18', NULL, 1),
(15, 'Detergentes y Jabones', '2024-09-13 16:06:18', NULL, 1),
(17, 'Variado', '2024-09-17 23:49:14', NULL, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `clientes`
--

CREATE TABLE `clientes` (
  `id` int(11) NOT NULL,
  `id_tipo_documento` int(11) DEFAULT NULL,
  `nro_documento` varchar(20) DEFAULT NULL,
  `nombres_apellidos_razon_social` varchar(255) DEFAULT NULL,
  `direccion` varchar(255) DEFAULT NULL,
  `telefono` varchar(20) DEFAULT NULL,
  `estado` tinyint(4) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `clientes`
--

INSERT INTO `clientes` (`id`, `id_tipo_documento`, `nro_documento`, `nombres_apellidos_razon_social`, `direccion`, `telefono`, `estado`) VALUES
(1, 1, '3257244661401', 'JOSE BRAYAN TEBELAN MEJIA', '11 CALLE 9-39 ZONA 4', '49611233', 1),
(2, 4, '26577194', 'DIEGO', '20 CALLE A 2-104 ZONA 4', '57876150', 1),
(3, 0, '99999999', 'CONSUMIDOR FINAL', '-', '-', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `codigo_unidad_medida`
--

CREATE TABLE `codigo_unidad_medida` (
  `id` varchar(3) NOT NULL,
  `descripcion` varchar(150) NOT NULL,
  `estado` int(11) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `codigo_unidad_medida`
--

INSERT INTO `codigo_unidad_medida` (`id`, `descripcion`, `estado`) VALUES
('UND', 'UNIDADES', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `compras`
--

CREATE TABLE `compras` (
  `id` int(11) NOT NULL,
  `id_proveedor` int(11) DEFAULT NULL,
  `fecha_compra` datetime DEFAULT NULL,
  `id_tipo_comprobante` varchar(3) DEFAULT NULL,
  `serie` varchar(10) DEFAULT NULL,
  `correlativo` varchar(20) DEFAULT NULL,
  `id_moneda` varchar(3) DEFAULT NULL,
  `forma_pago` varchar(45) DEFAULT NULL,
  `total_iva` float DEFAULT NULL,
  `descuento` float DEFAULT NULL,
  `total_compra` float DEFAULT NULL,
  `estado` int(11) NOT NULL DEFAULT 1,
  `pagado` int(11) DEFAULT 0 COMMENT '0: Pendiente\\n1: Pagado'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Volcado de datos para la tabla `compras`
--

INSERT INTO `compras` (`id`, `id_proveedor`, `fecha_compra`, `id_tipo_comprobante`, `serie`, `correlativo`, `id_moneda`, `forma_pago`, `total_iva`, `descuento`, `total_compra`, `estado`, `pagado`) VALUES
(9, 3, '2024-09-14 00:00:00', '03', 'B00012', '22222', 'GTQ', 'CONTADO', 25.71, 10, 230, 2, 0),
(10, 3, '2024-09-17 00:00:00', '03', 'B16', '12345', 'GTQ', 'CONTADO', 0, 0, 720, 2, 0);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `configuraciones`
--

CREATE TABLE `configuraciones` (
  `id` varchar(3) NOT NULL,
  `ordinal` int(11) NOT NULL,
  `llave` varchar(150) NOT NULL,
  `valor` varchar(150) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Volcado de datos para la tabla `configuraciones`
--

INSERT INTO `configuraciones` (`id`, `ordinal`, `llave`, `valor`) VALUES
('100', 0, 'CONFIGURACION SERVIDOR CORREO', '-'),
('100', 1, 'HOST', ''),
('100', 2, 'USERNAME', ''),
('100', 3, 'PASSWORD', ''),
('100', 4, 'SMTPSECURE', 'ssl'),
('100', 5, 'PORT', '465'),
('100', 6, 'NOMBRE EMPRESA', ''),
('200', 0, 'WEBSERVICE sat / MODO FACTURACION', '-'),
('200', 1, 'PRODUCCION', ''),
('200', 2, 'DESARROLLO', ''),
('200', 3, 'MODO FACTURACION', 'DESARROLLO'),
('300', 0, 'API sat / GUÍAS DE REMISIÓN', ''),
('300', 1, 'CLIENT_ID_DESARROLLO', ''),
('300', 2, 'CLIENT_SECRET_DESARROLLO', ''),
('300', 3, 'CLIENT_ID_PRODUCCION', '-'),
('300', 4, 'CLIENT_SECRET_PRODUCCION', '-'),
('300', 5, 'API_AUTH_DESARROLLO', ''),
('300', 6, 'API_CPE_DESARROLLO', ''),
('300', 7, 'API_AUTH_PRODUCCION', ''),
('300', 8, 'API_CPE_PRODUCCION', ''),
('300', 9, 'MODO GUIA DE REMISION', 'DESARROLLO'),
('400', 0, 'USUARIO SOL SECUNDARIO', ''),
('400', 1, 'USUARIO SAT', ''),
('400', 2, 'CLAVE SAT', '');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cotizaciones`
--

CREATE TABLE `cotizaciones` (
  `id` int(11) NOT NULL,
  `id_empresa_emisora` int(11) DEFAULT NULL,
  `id_serie` int(11) NOT NULL,
  `serie` varchar(4) NOT NULL,
  `correlativo` int(11) NOT NULL,
  `fecha_cotizacion` date NOT NULL,
  `fecha_expiracion` date NOT NULL,
  `id_moneda` varchar(3) NOT NULL,
  `tipo_cambio` decimal(18,3) DEFAULT NULL,
  `comprobante_a_generar` varchar(3) NOT NULL,
  `id_cliente` int(11) NOT NULL,
  `total_iva` decimal(18,2) DEFAULT 0.00,
  `importe_total` decimal(18,2) DEFAULT 0.00,
  `estado` int(11) DEFAULT 0 COMMENT '0: Registrado\\n1: Confirmado\\n2: Cerrada',
  `id_usuario` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cotizaciones_detalle`
--

CREATE TABLE `cotizaciones_detalle` (
  `id` int(11) NOT NULL,
  `id_cotizacion` int(11) DEFAULT NULL,
  `item` int(11) DEFAULT NULL,
  `codigo_producto` varchar(20) DEFAULT NULL,
  `descripcion` varchar(150) DEFAULT NULL,
  `porcentaje_iva` decimal(18,2) DEFAULT NULL,
  `cantidad` decimal(18,2) DEFAULT NULL,
  `costo_unitario` decimal(18,2) DEFAULT NULL,
  `valor_unitario` decimal(18,2) DEFAULT NULL,
  `precio_unitario` decimal(18,2) DEFAULT NULL,
  `valor_total` decimal(18,2) DEFAULT NULL,
  `iva` decimal(18,2) DEFAULT NULL,
  `importe_total` decimal(18,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cuotas`
--

CREATE TABLE `cuotas` (
  `id` int(11) NOT NULL,
  `id_venta` int(11) DEFAULT NULL,
  `cuota` varchar(3) DEFAULT NULL,
  `importe` decimal(15,6) DEFAULT NULL,
  `importe_pagado` float NOT NULL,
  `saldo_pendiente` float NOT NULL,
  `cuota_pagada` tinyint(1) NOT NULL DEFAULT 0,
  `fecha_vencimiento` date DEFAULT NULL,
  `medio_pago` varchar(45) DEFAULT NULL,
  `estado` char(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci ROW_FORMAT=DYNAMIC;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cuotas_compras`
--

CREATE TABLE `cuotas_compras` (
  `id` int(11) NOT NULL,
  `id_compra` int(11) DEFAULT NULL,
  `cuota` varchar(3) DEFAULT NULL,
  `importe` decimal(15,6) DEFAULT NULL,
  `importe_pagado` float NOT NULL,
  `saldo_pendiente` float NOT NULL,
  `cuota_pagada` tinyint(1) NOT NULL DEFAULT 0,
  `fecha_vencimiento` date DEFAULT NULL,
  `estado` char(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci ROW_FORMAT=DYNAMIC;

--
-- Volcado de datos para la tabla `cuotas_compras`
--

INSERT INTO `cuotas_compras` (`id`, `id_compra`, `cuota`, `importe`, `importe_pagado`, `saldo_pendiente`, `cuota_pagada`, `fecha_vencimiento`, `estado`) VALUES
(1, 4, '1', 50.000000, 0, 50, 0, '2024-09-30', '1');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalle_compra`
--

CREATE TABLE `detalle_compra` (
  `id` int(11) NOT NULL,
  `id_compra` int(11) DEFAULT NULL,
  `codigo_producto` varchar(20) DEFAULT NULL,
  `cantidad` float DEFAULT NULL,
  `costo_unitario` float DEFAULT NULL,
  `descuento` float DEFAULT NULL,
  `subtotal` float DEFAULT NULL,
  `impuesto` float DEFAULT NULL,
  `total` float DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Volcado de datos para la tabla `detalle_compra`
--

INSERT INTO `detalle_compra` (`id`, `id_compra`, `codigo_producto`, `cantidad`, `costo_unitario`, `descuento`, `subtotal`, `impuesto`, `total`) VALUES
(17, 9, '12345', 20, 12, 10, 214.29, 25.71, 230),
(20, 10, '10', 16, 45, 0, 720, 0, 720);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalle_venta`
--

CREATE TABLE `detalle_venta` (
  `id` int(11) NOT NULL,
  `id_venta` int(11) DEFAULT NULL,
  `item` int(11) DEFAULT NULL,
  `codigo_producto` varchar(20) DEFAULT NULL,
  `descripcion` varchar(150) DEFAULT NULL,
  `porcentaje_iva` decimal(18,4) DEFAULT NULL,
  `cantidad` decimal(18,2) DEFAULT NULL,
  `costo_unitario` decimal(18,4) DEFAULT NULL,
  `valor_unitario` decimal(18,4) DEFAULT NULL,
  `precio_unitario` decimal(18,4) DEFAULT NULL,
  `valor_total` decimal(18,4) DEFAULT NULL,
  `iva` decimal(18,4) DEFAULT NULL,
  `importe_total` decimal(18,4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `detalle_venta`
--

INSERT INTO `detalle_venta` (`id`, `id_venta`, `item`, `codigo_producto`, `descripcion`, `porcentaje_iva`, `cantidad`, `costo_unitario`, `valor_unitario`, `precio_unitario`, `valor_total`, `iva`, `importe_total`) VALUES
(1, 1, 1, '7805000316785', 'Guantes Reutilizables de Nylon (Caja 100)', 12.0000, 6.00, 50.0000, 50.0000, 56.0000, 300.0000, 36.0000, 336.0000),
(2, 1, 2, '2', 'BOLSA XXL', 12.0000, 12.00, 12.0000, 13.3929, 15.0000, 160.7143, 19.2857, 180.0000),
(3, 2, 1, '1', 'BOLSA XL', 12.0000, 12.00, 12.0000, 13.3929, 15.0000, 160.7143, 19.2857, 180.0000),
(4, 2, 2, '7873238475323', 'Guantes de Nitrilo (Caja de 100)', 12.0000, 7.00, 13.0000, 13.0000, 14.5600, 91.0000, 10.9200, 101.9200),
(5, 3, 1, '7805000316785', 'Guantes Reutilizables de Nylon (Caja 100)', 12.0000, 2.00, 50.0000, 50.0000, 56.0000, 100.0000, 12.0000, 112.0000),
(6, 3, 2, '7546674783345', 'Mopa Giratoria', 12.0000, 2.00, 12.2000, 12.1964, 13.6600, 24.3929, 2.9271, 27.3200),
(7, 3, 3, '7465743456674', 'Trapeador con Esponja', 12.0000, 10.00, 11.6000, 11.5982, 12.9900, 115.9821, 13.9179, 129.9000),
(8, 4, 1, '3456734634566', 'Desinfectante para Inodoro 750ml', 12.0000, 4.00, 11.6000, 11.5982, 12.9900, 46.3929, 5.5671, 51.9600),
(9, 4, 2, '7465743456674', 'Trapeador con Esponja', 12.0000, 7.00, 11.6000, 11.5982, 12.9900, 81.1875, 9.7425, 90.9300),
(10, 5, 1, '7543625264654', 'Limpiador de Campanas Extractoras 400ml', 12.0000, 4.00, 12.0000, 12.0000, 13.4400, 48.0000, 5.7600, 53.7600),
(11, 5, 2, '7234512226253', 'Limpiador para Refrigeradores 750ml', 12.0000, 5.00, 11.9000, 11.9018, 13.3300, 59.5089, 7.1411, 66.6500),
(12, 6, 1, '5624357114523', 'Limpiador Multiusos en Toallitas 50 unidades', 12.0000, 4.00, 13.0000, 13.0000, 14.5600, 52.0000, 6.2400, 58.2400),
(13, 6, 2, '8474674347675', 'Limpiador de Vidrios de Cocina 500ml', 12.0000, 5.00, 11.4000, 11.4018, 12.7700, 57.0089, 6.8411, 63.8500),
(14, 6, 3, '7234512226253', 'Limpiador para Refrigeradores 750ml', 12.0000, 5.00, 11.9000, 11.9018, 13.3300, 59.5089, 7.1411, 66.6500),
(15, 7, 1, '10', 'JUANITO JUAN', 0.0000, 2.00, 45.0000, 45.0000, 45.0000, 90.0000, 0.0000, 90.0000),
(16, 8, 1, '9785543457689', 'Desinfectante para Frutas y Verduras 500ml', 12.0000, 4.00, 11.5000, 11.5000, 12.8800, 46.0000, 5.5200, 51.5200),
(17, 8, 2, '2345709918562', 'Limpiador Multiusos con Desinfectante 1L', 12.0000, 4.00, 12.3000, 12.3036, 13.7800, 49.2143, 5.9057, 55.1200),
(18, 9, 1, '2457743568734', 'Limpiador para Baños con Blanqueador 750ml', 12.0000, 3.00, 11.8000, 11.8036, 13.2200, 35.4107, 4.2493, 39.6600),
(19, 9, 2, '3456256356642', 'Aromatizante para Baños 250ml', 12.0000, 2.00, 11.2000, 11.1964, 12.5400, 22.3929, 2.6871, 25.0800),
(20, 10, 1, '2345223456756', 'Detergente para Lavavajillas 250ml', 12.0000, 3.00, 11.4000, 11.4018, 12.7700, 34.2054, 4.1046, 38.3100),
(21, 10, 2, '8474674347675', 'Limpiador de Vidrios de Cocina 500ml', 12.0000, 4.00, 11.4000, 11.4018, 12.7700, 45.6071, 5.4729, 51.0800),
(22, 10, 3, '5234627235772', 'Limpiador de Azulejos de Cocina 1L', 12.0000, 4.00, 11.6000, 11.5982, 12.9900, 46.3929, 5.5671, 51.9600),
(23, 11, 1, '7873238475323', 'Guantes de Nitrilo (Caja de 100)', 12.0000, 1.00, 13.0000, 13.0000, 14.5600, 13.0000, 1.5600, 14.5600),
(24, 11, 2, '2345709918562', 'Limpiador Multiusos con Desinfectante 1L', 12.0000, 1.00, 12.3000, 12.3036, 13.7800, 12.3036, 1.4764, 13.7800),
(25, 12, 1, '3456734634566', 'Desinfectante para Inodoro 750ml', 12.0000, 3.00, 11.6000, 11.5982, 12.9900, 34.7946, 4.1754, 38.9700),
(26, 12, 2, '6345624563456', 'Detergente Biodegradable para Ropa 1L', 12.0000, 4.00, 11.5000, 11.5000, 12.8800, 46.0000, 5.5200, 51.5200);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `empresas`
--

CREATE TABLE `empresas` (
  `id_empresa` int(11) NOT NULL,
  `genera_fact_electronica` tinyint(4) DEFAULT 1,
  `razon_social` text NOT NULL,
  `nombre_comercial` varchar(255) DEFAULT NULL,
  `id_tipo_documento` varchar(20) DEFAULT NULL,
  `nit` bigint(20) NOT NULL,
  `direccion` text NOT NULL,
  `simbolo_moneda` varchar(5) DEFAULT NULL,
  `email` text NOT NULL,
  `telefono` varchar(100) DEFAULT NULL,
  `departamento` varchar(100) DEFAULT NULL,
  `municipio` varchar(100) DEFAULT NULL,
  `ubigeo` varchar(6) DEFAULT NULL,
  `certificado_digital` varchar(255) DEFAULT NULL,
  `clave_certificado` varchar(45) DEFAULT NULL,
  `usuario_sat` varchar(45) DEFAULT NULL,
  `clave_sat` varchar(45) DEFAULT NULL,
  `es_principal` int(1) DEFAULT 0,
  `fact_bol_defecto` int(1) DEFAULT 0,
  `logo` varchar(150) DEFAULT NULL,
  `estado` tinyint(4) DEFAULT 1,
  `production` int(11) DEFAULT 0,
  `client_id` varchar(150) DEFAULT NULL,
  `client_secret` datetime DEFAULT NULL,
  `certificado_digital_pem` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Volcado de datos para la tabla `empresas`
--

INSERT INTO `empresas` (`id_empresa`, `genera_fact_electronica`, `razon_social`, `nombre_comercial`, `id_tipo_documento`, `nit`, `direccion`, `simbolo_moneda`, `email`, `telefono`, `departamento`, `municipio`, `ubigeo`, `certificado_digital`, `clave_certificado`, `usuario_sat`, `clave_sat`, `es_principal`, `fact_bol_defecto`, `logo`, `estado`, `production`, `client_id`, `client_secret`, `certificado_digital_pem`) VALUES
(1, 2, 'PRUEBA', 'PRUEBA', '4', 26577194, '11 CALLE 9 - 39 ZONA 4', 'Q', 'brayantebelan@gmail.com', '49611233', 'QUICHÉ', 'SANTA_CRUZ_DEL_QUICHÉ', '1401', '', '', NULL, NULL, 0, 0, '66e498575296d_936.jpg', 1, 0, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `forma_pago`
--

CREATE TABLE `forma_pago` (
  `id` int(11) NOT NULL,
  `descripcion` varchar(100) NOT NULL,
  `estado` int(11) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `forma_pago`
--

INSERT INTO `forma_pago` (`id`, `descripcion`, `estado`) VALUES
(1, 'Contado', 1),
(2, 'Crédito', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `historico_cargas_masivas`
--

CREATE TABLE `historico_cargas_masivas` (
  `id` int(11) NOT NULL,
  `categorias_insertadas` int(11) DEFAULT NULL,
  `categorias_excel` int(11) DEFAULT NULL,
  `productos_insertados` int(11) DEFAULT NULL,
  `productos_excel` int(11) DEFAULT NULL,
  `unidades_medida_insertadas` int(11) DEFAULT NULL,
  `unidades_medida_excel` varchar(45) DEFAULT NULL,
  `fecha_carga` datetime DEFAULT current_timestamp(),
  `estado_carga` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Volcado de datos para la tabla `historico_cargas_masivas`
--

INSERT INTO `historico_cargas_masivas` (`id`, `categorias_insertadas`, `categorias_excel`, `productos_insertados`, `productos_excel`, `unidades_medida_insertadas`, `unidades_medida_excel`, `fecha_carga`, `estado_carga`) VALUES
(1, 15, 15, NULL, 84, NULL, '8', '2024-09-12 23:06:07', 0),
(2, 15, 15, NULL, 84, NULL, '8', '2024-09-12 23:08:40', 0),
(3, 15, 15, NULL, 84, NULL, '8', '2024-09-12 23:11:02', 0),
(4, 15, 15, NULL, 84, NULL, '8', '2024-09-12 23:14:45', 0),
(5, 15, 15, NULL, 84, NULL, '8', '2024-09-12 23:19:27', 0),
(6, 15, 15, NULL, 84, 8, '8', '2024-09-12 23:21:17', 0),
(7, 15, 15, 84, 84, 8, '8', '2024-09-12 23:23:15', 1),
(8, 15, 15, 84, 84, 8, '8', '2024-09-12 23:38:07', 1),
(9, 15, 15, NULL, 84, 2, '2', '2024-09-12 23:51:09', 0),
(10, 15, 15, NULL, 84, 2, '2', '2024-09-12 23:51:31', 0),
(11, 15, 15, NULL, 84, 2, '2', '2024-09-12 23:55:48', 0),
(12, 15, 15, 84, 84, 2, '2', '2024-09-12 23:59:07', 1),
(13, 15, 15, 84, 84, 2, '2', '2024-09-13 10:06:18', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `impuestos`
--

CREATE TABLE `impuestos` (
  `id_tipo_operacion` int(11) NOT NULL,
  `impuesto` float DEFAULT NULL,
  `estado` tinyint(4) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `impuestos`
--

INSERT INTO `impuestos` (`id_tipo_operacion`, `impuesto`, `estado`) VALUES
(10, 12, 1),
(20, 0, 1),
(30, 0, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `kardex`
--

CREATE TABLE `kardex` (
  `id` int(11) NOT NULL,
  `codigo_producto` varchar(20) DEFAULT NULL,
  `fecha` datetime DEFAULT NULL,
  `concepto` varchar(100) DEFAULT NULL,
  `comprobante` varchar(50) DEFAULT NULL,
  `in_unidades` float DEFAULT NULL,
  `in_costo_unitario` float DEFAULT NULL,
  `in_costo_total` float DEFAULT NULL,
  `out_unidades` float DEFAULT NULL,
  `out_costo_unitario` float DEFAULT NULL,
  `out_costo_total` float DEFAULT NULL,
  `ex_unidades` float DEFAULT NULL,
  `ex_costo_unitario` float DEFAULT NULL,
  `ex_costo_total` float DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Volcado de datos para la tabla `kardex`
--

INSERT INTO `kardex` (`id`, `codigo_producto`, `fecha`, `concepto`, `comprobante`, `in_unidades`, `in_costo_unitario`, `in_costo_total`, `out_unidades`, `out_costo_unitario`, `out_costo_total`, `ex_unidades`, `ex_costo_unitario`, `ex_costo_total`) VALUES
(1, '7805000316785', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 50, 1500, NULL, NULL, NULL, 30, 50, 1500),
(2, '7873238475323', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 13, 390, NULL, NULL, NULL, 30, 13, 390),
(3, '4245605804422', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 12, 360, NULL, NULL, NULL, 30, 12, 360),
(4, '7873238475321', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 12, 360, NULL, NULL, NULL, 30, 12, 360),
(5, '3546334564565', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.4, 342, NULL, NULL, NULL, 30, 11.4, 342),
(6, '7456734562645', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.9, 357, NULL, NULL, NULL, 30, 11.9, 357),
(7, '7546674783345', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 12.2, 366, NULL, NULL, NULL, 30, 12.2, 366),
(8, '7465743456674', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.6, 348, NULL, NULL, NULL, 30, 11.6, 348),
(9, '3456734563456', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 12, 360, NULL, NULL, NULL, 30, 12, 360),
(10, '4356734773456', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.7, 351, NULL, NULL, NULL, 30, 11.7, 351),
(11, '7575280290743', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.5, 345, NULL, NULL, NULL, 30, 11.5, 345),
(12, '7546745356456', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 12.5, 375, NULL, NULL, NULL, 30, 12.5, 375),
(13, '7456723562645', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.8, 354, NULL, NULL, NULL, 30, 11.8, 354),
(14, '6435732523476', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.2, 336, NULL, NULL, NULL, 30, 11.2, 336),
(15, '6436234567234', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.5, 345, NULL, NULL, NULL, 30, 11.5, 345),
(16, '6543234523455', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 12.2, 366, NULL, NULL, NULL, 30, 12.2, 366),
(17, '6435245236235', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.4, 342, NULL, NULL, NULL, 30, 11.4, 342),
(18, '6543245262454', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.9, 357, NULL, NULL, NULL, 30, 11.9, 357),
(19, '4356372454563', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.6, 348, NULL, NULL, NULL, 30, 11.6, 348),
(20, '6435634245623', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 12.5, 375, NULL, NULL, NULL, 30, 12.5, 375),
(21, '7356342456723', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.7, 351, NULL, NULL, NULL, 30, 11.7, 351),
(22, '6454252345623', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.8, 354, NULL, NULL, NULL, 30, 11.8, 354),
(23, '6236543342453', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 12, 360, NULL, NULL, NULL, 30, 12, 360),
(24, '2345667723456', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.5, 345, NULL, NULL, NULL, 30, 11.5, 345),
(25, '7234512226253', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.9, 357, NULL, NULL, NULL, 30, 11.9, 357),
(26, '5234627235772', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.6, 348, NULL, NULL, NULL, 30, 11.6, 348),
(27, '7543625264654', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 12, 360, NULL, NULL, NULL, 30, 12, 360),
(28, '8474674347675', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.4, 342, NULL, NULL, NULL, 30, 11.4, 342),
(29, '6745894365785', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 12.2, 366, NULL, NULL, NULL, 30, 12.2, 366),
(30, '8954679005786', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.8, 354, NULL, NULL, NULL, 30, 11.8, 354),
(31, '7697856789578', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.5, 345, NULL, NULL, NULL, 30, 11.5, 345),
(32, '8476436632623', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 12, 360, NULL, NULL, NULL, 30, 12, 360),
(33, '6437833456256', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.7, 351, NULL, NULL, NULL, 30, 11.7, 351),
(34, '7452363456264', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 12.5, 375, NULL, NULL, NULL, 30, 12.5, 375),
(35, '3456256356642', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.2, 336, NULL, NULL, NULL, 30, 11.2, 336),
(36, '2457743568734', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.8, 354, NULL, NULL, NULL, 30, 11.8, 354),
(37, '7452634627723', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 12, 360, NULL, NULL, NULL, 30, 12, 360),
(38, '2345635677356', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.5, 345, NULL, NULL, NULL, 30, 11.5, 345),
(39, '3456734634566', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.6, 348, NULL, NULL, NULL, 30, 11.6, 348),
(40, '3457632563466', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 12.5, 375, NULL, NULL, NULL, 30, 12.5, 375),
(41, '2757243653266', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.7, 351, NULL, NULL, NULL, 30, 11.7, 351),
(42, '2688245236234', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 12, 360, NULL, NULL, NULL, 30, 12, 360),
(43, '8735632546747', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.8, 354, NULL, NULL, NULL, 30, 11.8, 354),
(44, '7422764388924', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.5, 345, NULL, NULL, NULL, 30, 11.5, 345),
(45, '7654256523564', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 13, 390, NULL, NULL, NULL, 30, 13, 390),
(46, '6543883456132', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.9, 357, NULL, NULL, NULL, 30, 11.9, 357),
(47, '2452788993456', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 12.2, 366, NULL, NULL, NULL, 30, 12.2, 366),
(48, '7894785946745', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.6, 348, NULL, NULL, NULL, 30, 11.6, 348),
(49, '6345672457789', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 12.5, 375, NULL, NULL, NULL, 30, 12.5, 375),
(50, '2456723456234', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.2, 336, NULL, NULL, NULL, 30, 11.2, 336),
(51, '2435672452345', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.7, 351, NULL, NULL, NULL, 30, 11.7, 351),
(52, '7434365245266', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 12, 360, NULL, NULL, NULL, 30, 12, 360),
(53, '2345272452345', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.8, 354, NULL, NULL, NULL, 30, 11.8, 354),
(54, '1432465723453', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.5, 345, NULL, NULL, NULL, 30, 11.5, 345),
(55, '5624357114523', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 13, 390, NULL, NULL, NULL, 30, 13, 390),
(56, '2345709918562', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 12.3, 369, NULL, NULL, NULL, 30, 12.3, 369),
(57, '4673246251349', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.8, 354, NULL, NULL, NULL, 30, 11.8, 354),
(58, '5678345632239', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.7, 351, NULL, NULL, NULL, 30, 11.7, 351),
(59, '4567843645389', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.5, 345, NULL, NULL, NULL, 30, 11.5, 345),
(60, '5678909467568', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 12, 360, NULL, NULL, NULL, 30, 12, 360),
(61, '9768085678595', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.3, 339, NULL, NULL, NULL, 30, 11.3, 339),
(62, '2345678862364', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.5, 345, NULL, NULL, NULL, 30, 11.5, 345),
(63, '3563722563634', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 12.5, 375, NULL, NULL, NULL, 30, 12.5, 375),
(64, '7453632625436', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.2, 336, NULL, NULL, NULL, 30, 11.2, 336),
(65, '4567484365432', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11, 330, NULL, NULL, NULL, 30, 11, 330),
(66, '9785543457689', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.5, 345, NULL, NULL, NULL, 30, 11.5, 345),
(67, '6654356252676', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 12.2, 366, NULL, NULL, NULL, 30, 12.2, 366),
(68, '3456722456373', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.6, 348, NULL, NULL, NULL, 30, 11.6, 348),
(69, '7654643324665', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.7, 351, NULL, NULL, NULL, 30, 11.7, 351),
(70, '3456724524565', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 13.5, 405, NULL, NULL, NULL, 30, 13.5, 405),
(71, '2456772122567', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.9, 357, NULL, NULL, NULL, 30, 11.9, 357),
(72, '6543245234676', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 12, 360, NULL, NULL, NULL, 30, 12, 360),
(73, '7265451246553', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 12.5, 375, NULL, NULL, NULL, 30, 12.5, 375),
(74, '2346245245167', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.8, 354, NULL, NULL, NULL, 30, 11.8, 354),
(75, '2462456754565', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 12, 360, NULL, NULL, NULL, 30, 12, 360),
(76, '6345624563456', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.5, 345, NULL, NULL, NULL, 30, 11.5, 345),
(77, '7654224562453', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 10.7, 321, NULL, NULL, NULL, 30, 10.7, 321),
(78, '2345223456756', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 11.4, 342, NULL, NULL, NULL, 30, 11.4, 342),
(79, '2345622345345', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 12, 360, NULL, NULL, NULL, 30, 12, 360),
(80, '2345645624534', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 14, 420, NULL, NULL, NULL, 30, 14, 420),
(81, '5432562345234', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 12, 360, NULL, NULL, NULL, 30, 12, 360),
(82, '2352466534532', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 10, 300, NULL, NULL, NULL, 30, 10, 300),
(83, '9878765345622', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 4, 120, NULL, NULL, NULL, 30, 4, 120),
(84, '1987625643234', '2024-09-13 00:00:00', 'INVENTARIO INICIAL', '', 30, 10, 300, NULL, NULL, NULL, 30, 10, 300),
(85, '9878765345622', '2024-09-13 00:00:00', 'DISMINUCIÓN DE STOCK POR MODULO DE INVENTARIO', '', NULL, NULL, NULL, 20, 4, 80, 10, 4, 40),
(86, '1', '2024-09-13 00:00:00', 'REGISTRADO EN SISTEMA', '', 0, 0, 0, NULL, NULL, NULL, 0, 0, 0),
(87, '2', '2024-09-13 00:00:00', 'REGISTRADO EN SISTEMA', '', 0, 0, 0, NULL, NULL, NULL, 0, 0, 0),
(88, '2', '2024-09-13 00:00:00', 'COMPRA', 'F001-1', 15, 12, 180, NULL, NULL, NULL, 15, 12, 180),
(89, '1', '2024-09-13 00:00:00', 'COMPRA', 'F001-1', 15, 12, 180, NULL, NULL, NULL, 15, 12, 180),
(90, '12345', '2024-09-14 00:00:00', 'REGISTRADO EN SISTEMA', '', 0, 0, 0, NULL, NULL, NULL, 0, 0, 0),
(91, '12345', '2024-09-14 00:00:00', 'COMPRA', 'B00012-22222', 20, 12, 240, NULL, NULL, NULL, 20, 12, 240),
(92, '7873238475321', '2024-09-14 00:00:00', 'DISMINUCIÓN DE STOCK POR MODULO DE INVENTARIO', '', NULL, NULL, NULL, 20, 12, 240, 10, 12, 120),
(93, '7805000316785', '2024-09-17 00:00:00', 'VENTA', 'BO01-1', NULL, NULL, NULL, 6, 50, 300, 24, 50, 1200),
(94, '2', '2024-09-17 00:00:00', 'VENTA', 'BO01-1', NULL, NULL, NULL, 12, 12, 144, 3, 12, 36),
(95, '1', '2024-09-17 00:00:00', 'VENTA', 'BO01-2', NULL, NULL, NULL, 12, 12, 144, 3, 12, 36),
(96, '7873238475323', '2024-09-17 00:00:00', 'VENTA', 'BO01-2', NULL, NULL, NULL, 7, 13, 91, 23, 13, 299),
(97, '7805000316785', '2024-09-17 00:00:00', 'VENTA', 'BO01-3', NULL, NULL, NULL, 2, 50, 100, 22, 50, 1100),
(98, '7546674783345', '2024-09-17 00:00:00', 'VENTA', 'BO01-3', NULL, NULL, NULL, 2, 12.2, 24.4, 28, 12.2, 341.6),
(99, '7465743456674', '2024-09-17 00:00:00', 'VENTA', 'BO01-3', NULL, NULL, NULL, 10, 11.6, 116, 20, 11.6, 232),
(100, '3456734634566', '2024-09-17 00:00:00', 'VENTA', 'BO01-4', NULL, NULL, NULL, 4, 11.6, 46.4, 26, 11.6, 301.6),
(101, '7465743456674', '2024-09-17 00:00:00', 'VENTA', 'BO01-4', NULL, NULL, NULL, 7, 11.6, 81.2, 13, 11.6, 150.8),
(102, '7543625264654', '2024-09-17 00:00:00', 'VENTA', 'BO01-5', NULL, NULL, NULL, 4, 12, 48, 26, 12, 312),
(103, '7234512226253', '2024-09-17 00:00:00', 'VENTA', 'BO01-5', NULL, NULL, NULL, 5, 11.9, 59.5, 25, 11.9, 297.5),
(104, '12345', '2024-09-17 00:00:00', 'COMPRA', 'B00012-22222', 20, 12, 240, NULL, NULL, NULL, 40, 12, 480),
(105, '12345', '2024-09-17 00:00:00', 'COMPRA', 'B00012-22222', 20, 12, 240, NULL, NULL, NULL, 60, 12, 720),
(106, '5624357114523', '2024-09-17 00:00:00', 'VENTA', 'BO01-6', NULL, NULL, NULL, 4, 13, 52, 26, 13, 338),
(107, '8474674347675', '2024-09-17 00:00:00', 'VENTA', 'BO01-6', NULL, NULL, NULL, 5, 11.4, 57, 25, 11.4, 285),
(108, '7234512226253', '2024-09-17 00:00:00', 'VENTA', 'BO01-6', NULL, NULL, NULL, 5, 11.9, 59.5, 20, 11.9, 238),
(109, '10', '2024-09-17 00:00:00', 'REGISTRADO EN SISTEMA', '', 0, 0, 0, NULL, NULL, NULL, 0, 0, 0),
(110, '10', '2024-09-17 00:00:00', 'COMPRA', 'B16-12345', 16, 45, 720, NULL, NULL, NULL, 16, 45, 720),
(111, '10', '2024-09-18 00:00:00', 'VENTA', 'BO01-7', NULL, NULL, NULL, 2, 45, 90, 14, 45, 630),
(112, '9785543457689', '2024-09-18 00:00:00', 'VENTA', 'BO01-8', NULL, NULL, NULL, 4, 11.5, 46, 26, 11.5, 299),
(113, '2345709918562', '2024-09-18 00:00:00', 'VENTA', 'BO01-8', NULL, NULL, NULL, 4, 12.3, 49.2, 26, 12.3, 319.8),
(114, '2457743568734', '2024-09-18 00:00:00', 'VENTA', 'BO01-9', NULL, NULL, NULL, 3, 11.8, 35.4, 27, 11.8, 318.6),
(115, '3456256356642', '2024-09-18 00:00:00', 'VENTA', 'BO01-9', NULL, NULL, NULL, 2, 11.2, 22.4, 28, 11.2, 313.6),
(116, '2345223456756', '2024-09-18 00:00:00', 'VENTA', 'BO01-10', NULL, NULL, NULL, 3, 11.4, 34.2, 27, 11.4, 307.8),
(117, '8474674347675', '2024-09-18 00:00:00', 'VENTA', 'BO01-10', NULL, NULL, NULL, 4, 11.4, 45.6, 21, 11.4, 239.4),
(118, '5234627235772', '2024-09-18 00:00:00', 'VENTA', 'BO01-10', NULL, NULL, NULL, 4, 11.6, 46.4, 26, 11.6, 301.6),
(119, '7873238475323', '2024-09-19 00:00:00', 'VENTA', 'BO01-11', NULL, NULL, NULL, 1, 13, 13, 22, 13, 286),
(120, '2345709918562', '2024-09-19 00:00:00', 'VENTA', 'BO01-11', NULL, NULL, NULL, 1, 12.3, 12.3, 25, 12.3, 307.5),
(121, '3456734634566', '2024-09-28 00:00:00', 'VENTA', 'BO01-12', NULL, NULL, NULL, 3, 11.6, 34.8, 23, 11.6, 266.8),
(122, '6345624563456', '2024-09-28 00:00:00', 'VENTA', 'BO01-12', NULL, NULL, NULL, 4, 11.5, 46, 26, 11.5, 299);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `medio_pago`
--

CREATE TABLE `medio_pago` (
  `id` int(11) NOT NULL,
  `descripcion` varchar(150) DEFAULT NULL,
  `id_tipo_movimiento_caja` int(11) DEFAULT NULL,
  `fecha_registro` date DEFAULT current_timestamp(),
  `estado` int(11) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Volcado de datos para la tabla `medio_pago`
--

INSERT INTO `medio_pago` (`id`, `descripcion`, `id_tipo_movimiento_caja`, `fecha_registro`, `estado`) VALUES
(1, 'EFECTIVO', 3, '2024-03-18', 1),
(4, 'TRANSFERENCIA', 8, '2024-03-18', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `modulos`
--

CREATE TABLE `modulos` (
  `id` int(11) NOT NULL,
  `modulo` varchar(150) DEFAULT NULL,
  `padre_id` int(11) DEFAULT NULL,
  `vista` varchar(150) DEFAULT NULL,
  `icon_menu` varchar(150) DEFAULT NULL,
  `orden` int(11) DEFAULT NULL,
  `fecha_creacion` timestamp NULL DEFAULT NULL,
  `fecha_actualizacion` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Volcado de datos para la tabla `modulos`
--

INSERT INTO `modulos` (`id`, `modulo`, `padre_id`, `vista`, `icon_menu`, `orden`, `fecha_creacion`, `fecha_actualizacion`) VALUES
(1, 'Tablero Principal', 0, 'dashboard/dashboard.php', 'far fa-chart-bar', 0, NULL, NULL),
(2, 'Punto de Venta', 0, '', 'fas fa-store', 5, NULL, NULL),
(3, 'Productos', 0, NULL, 'fas fa-cart-plus', 1, NULL, NULL),
(4, 'Inventario', 3, 'inventario/productos/productos.php', 'fas fa-check-circle', 2, NULL, NULL),
(5, 'Carga Masiva', 3, 'inventario/carga_masiva_productos.php', 'fas fa-check-circle', 4, NULL, NULL),
(6, 'Categorías', 3, 'inventario/categorias.php', 'fas fa-check-circle', 3, NULL, NULL),
(7, 'Compras', 0, 'compras/compras.php', 'fas fa-dolly', 9, NULL, NULL),
(8, 'Reportes', 0, '', 'fas fa-chart-pie', 10, NULL, NULL),
(9, 'Administración', 0, NULL, 'fas fa-users-cog', 16, NULL, NULL),
(10, 'Módulos / Perfiles', 21, 'seguridad/seguridad_modulos_perfiles.php', 'fas fa-check-circle', 26, NULL, NULL),
(11, 'Caja', 0, 'caja/caja.php', 'fas fa-cash-register', 8, '0000-00-00 00:00:00', NULL),
(12, 'Tipo Afectación', 9, 'administracion/administrar_tipo_afectacion.php', 'fas fa-check-circle', 22, '0000-00-00 00:00:00', NULL),
(13, 'Tipo Comprobante', 9, 'administracion/administrar_tipo_comprobante.php', 'fas fa-check-circle', 21, '0000-00-00 00:00:00', NULL),
(14, 'Series', 9, 'administracion/administrar_series.php', 'fas fa-check-circle', 23, '0000-00-00 00:00:00', NULL),
(15, 'Clientes', 9, 'administracion/administrar_clientes.php', 'fas fa-check-circle', 17, '0000-00-00 00:00:00', NULL),
(16, 'Proveedores', 9, 'administracion/administrar_proveedores.php', 'fas fa-check-circle', 18, '0000-00-00 00:00:00', NULL),
(17, 'Empresa', 9, 'administracion/administrar_empresas.php', 'fas fa-check-circle', 19, '0000-00-00 00:00:00', NULL),
(18, 'Emitir Boleta', 2, 'ventas/venta_boleta.php', 'fas fa-check-circle', 6, '0000-00-00 00:00:00', NULL),
(21, 'Seguridad', 0, '', 'fas fa-user-shield', 24, '0000-00-00 00:00:00', NULL),
(22, 'Perfiles', 21, 'seguridad/perfiles/seguridad_perfiles.php', 'fas fa-check-circle', 25, '0000-00-00 00:00:00', NULL),
(23, 'Usuarios', 21, 'seguridad/seguridad_usuarios.php', 'fas fa-check-circle', 27, '0000-00-00 00:00:00', NULL),
(24, 'Tipo Documento', 9, 'administracion/administrar_tipo_documento.php', 'fas fa-check-circle', 20, '0000-00-00 00:00:00', NULL),
(25, 'Kardex Totalizado', 8, 'reportes/reporte_kardex_totalizado.php', 'fas fa-check-circle', 12, '0000-00-00 00:00:00', NULL),
(26, 'Ventas x Categoría', 8, 'reportes/reporte_ventas.php', 'fas fa-check-circle', 14, '0000-00-00 00:00:00', NULL),
(27, 'Ventas x Producto', 8, 'reportes/reporte_ventas_producto.php', 'fas fa-check-circle', 13, '0000-00-00 00:00:00', NULL),
(28, 'Kardex x Producto', 8, 'reportes/reporte_kardex_por_producto.php', 'fas fa-check-circle', 15, NULL, NULL),
(34, 'Cuadres de Caja', 8, 'reportes/cuadre_caja.php', 'fas fa-check-circle', 11, NULL, NULL),
(35, 'Comprob. Elect.', 2, 'ventas/listado_comprobantes_electronicos.php', 'fas fa-file-invoice', 7, NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `moneda`
--

CREATE TABLE `moneda` (
  `id` char(3) NOT NULL,
  `descripcion` varchar(45) NOT NULL,
  `simbolo` char(5) DEFAULT NULL,
  `estado` int(11) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Volcado de datos para la tabla `moneda`
--

INSERT INTO `moneda` (`id`, `descripcion`, `simbolo`, `estado`) VALUES
('GTQ', 'QUETZALES', 'Q', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `movimientos_arqueo_caja`
--

CREATE TABLE `movimientos_arqueo_caja` (
  `id` int(11) NOT NULL,
  `id_arqueo_caja` int(11) DEFAULT NULL,
  `id_tipo_movimiento` int(11) DEFAULT NULL,
  `descripcion` varchar(250) DEFAULT NULL,
  `monto` float DEFAULT NULL,
  `comprobante` varchar(45) DEFAULT NULL,
  `estado` int(11) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `movimientos_arqueo_caja`
--

INSERT INTO `movimientos_arqueo_caja` (`id`, `id_arqueo_caja`, `id_tipo_movimiento`, `descripcion`, `monto`, `comprobante`, `estado`) VALUES
(1, 1, 4, 'APERTURA CAJA', 100, NULL, 1),
(2, 2, 4, 'APERTURA CAJA', 150, NULL, 1),
(3, 2, 2, 'Desayuno', 25, NULL, 1),
(4, 2, 2, 'Almuerzo', 30, NULL, 1),
(5, 3, 4, 'APERTURA CAJA', 100, NULL, 1),
(6, 4, 4, 'APERTURA CAJA', 100, NULL, 1),
(7, 5, 4, 'APERTURA CAJA', 200, NULL, 1),
(8, 5, 3, 'INGRESO - EFECTIVO', 336, 'BO01-1', 1),
(9, 5, 3, 'INGRESO - EFECTIVO', 180, 'BO01-1', 1),
(10, 5, 3, 'INGRESO - EFECTIVO', 180, 'BO01-2', 1),
(11, 5, 3, 'INGRESO - EFECTIVO', 101.92, 'BO01-2', 1),
(12, 5, 2, 'Desayuno', 15, NULL, 1),
(13, 5, 2, 'Almuerzo', 25, NULL, 1),
(14, 5, 3, 'INGRESO - EFECTIVO', 112, 'BO01-3', 1),
(15, 5, 3, 'INGRESO - EFECTIVO', 27.32, 'BO01-3', 1),
(16, 5, 3, 'INGRESO - EFECTIVO', 129.9, 'BO01-3', 1),
(17, 5, 3, 'INGRESO - EFECTIVO', 51.96, 'BO01-4', 1),
(18, 5, 3, 'INGRESO - EFECTIVO', 90.93, 'BO01-4', 1),
(19, 5, 3, 'INGRESO - EFECTIVO', 53.76, 'BO01-5', 1),
(20, 5, 3, 'INGRESO - EFECTIVO', 66.65, 'BO01-5', 1),
(21, 5, 3, 'INGRESO - EFECTIVO', 58.24, 'BO01-6', 1),
(22, 5, 3, 'INGRESO - EFECTIVO', 63.85, 'BO01-6', 1),
(23, 5, 3, 'INGRESO - EFECTIVO', 66.65, 'BO01-6', 1),
(24, 5, 3, 'INGRESO - EFECTIVO', 90, 'BO01-7', 1),
(25, 5, 8, 'INGRESO - TRANSFERENCIA', 51.52, 'BO01-8', 1),
(26, 5, 8, 'INGRESO - TRANSFERENCIA', 55.12, 'BO01-8', 1),
(27, 6, 4, 'APERTURA CAJA', 200, NULL, 1),
(28, 6, 3, 'INGRESO - EFECTIVO', 39.66, 'BO01-9', 1),
(29, 6, 3, 'INGRESO - EFECTIVO', 25.08, 'BO01-9', 1),
(30, 6, 2, 'no se', 14, NULL, 1),
(31, 6, 1, 'don', 5, NULL, 1),
(32, 7, 4, 'APERTURA CAJA', 200, NULL, 1),
(33, 7, 3, 'INGRESO - EFECTIVO', 38.31, 'BO01-10', 1),
(34, 7, 3, 'INGRESO - EFECTIVO', 51.08, 'BO01-10', 1),
(35, 7, 3, 'INGRESO - EFECTIVO', 51.96, 'BO01-10', 1),
(36, 7, 2, 'Almuerzo', 25, NULL, 1),
(37, 7, 1, 'Deterjente', 38.31, NULL, 1),
(38, 8, 4, 'APERTURA CAJA', 200, NULL, 1),
(39, 9, 4, 'APERTURA CAJA', 200, NULL, 1),
(40, 9, 3, 'INGRESO - EFECTIVO', 14.56, 'BO01-11', 1),
(41, 9, 3, 'INGRESO - EFECTIVO', 13.78, 'BO01-11', 1),
(42, 10, 4, 'APERTURA CAJA', 200, NULL, 1),
(43, 10, 3, 'INGRESO - EFECTIVO', 38.97, 'BO01-12', 1),
(44, 10, 3, 'INGRESO - EFECTIVO', 51.52, 'BO01-12', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `perfiles`
--

CREATE TABLE `perfiles` (
  `id_perfil` int(11) NOT NULL,
  `descripcion` varchar(45) DEFAULT NULL,
  `estado` tinyint(4) DEFAULT NULL,
  `fecha_creacion` timestamp NULL DEFAULT NULL,
  `fecha_actualizacion` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Volcado de datos para la tabla `perfiles`
--

INSERT INTO `perfiles` (`id_perfil`, `descripcion`, `estado`, `fecha_creacion`, `fecha_actualizacion`) VALUES
(1, 'SUPER ADMINISTRADOR', 1, NULL, NULL),
(16, 'VENDEDOR', 1, NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `perfil_modulo`
--

CREATE TABLE `perfil_modulo` (
  `idperfil_modulo` int(11) NOT NULL,
  `id_perfil` int(11) DEFAULT NULL,
  `id_modulo` int(11) DEFAULT NULL,
  `vista_inicio` tinyint(4) DEFAULT NULL,
  `estado` tinyint(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Volcado de datos para la tabla `perfil_modulo`
--

INSERT INTO `perfil_modulo` (`idperfil_modulo`, `id_perfil`, `id_modulo`, `vista_inicio`, `estado`) VALUES
(0, 1, 13, 0, 1),
(0, 1, 1, 1, 1),
(0, 1, 4, 0, 1),
(0, 1, 3, 0, 1),
(0, 1, 6, 0, 1),
(0, 1, 5, 0, 1),
(0, 1, 18, 0, 1),
(0, 1, 2, 0, 1),
(0, 1, 11, 0, 1),
(0, 1, 7, 0, 1),
(0, 1, 34, 0, 1),
(0, 1, 8, 0, 1),
(0, 1, 25, 0, 1),
(0, 1, 27, 0, 1),
(0, 1, 26, 0, 1),
(0, 1, 28, 0, 1),
(0, 1, 15, 0, 1),
(0, 1, 9, 0, 1),
(0, 1, 16, 0, 1),
(0, 1, 17, 0, 1),
(0, 1, 24, 0, 1),
(0, 1, 12, 0, 1),
(0, 1, 14, 0, 1),
(0, 1, 22, 0, 1),
(0, 1, 21, 0, 1),
(0, 1, 10, 0, 1),
(0, 1, 23, 0, 1),
(0, 1, 35, 0, 1),
(0, 16, 1, 0, 1),
(0, 16, 4, 0, 1),
(0, 16, 3, 0, 1),
(0, 16, 6, 0, 1),
(0, 16, 18, 0, 1),
(0, 16, 2, 0, 1),
(0, 16, 11, 1, 1),
(0, 16, 35, 0, 1),
(0, 16, 15, 0, 1),
(0, 16, 9, 0, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `productos`
--

CREATE TABLE `productos` (
  `id` int(11) NOT NULL,
  `codigo_producto` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `id_categoria` int(11) DEFAULT NULL,
  `descripcion` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `id_tipo_afectacion_iva` int(11) NOT NULL,
  `id_unidad_medida` varchar(3) NOT NULL,
  `costo_unitario` float DEFAULT 0,
  `precio_unitario_con_iva` float DEFAULT 0,
  `precio_unitario_sin_iva` float DEFAULT 0,
  `precio_unitario_mayor_con_iva` float DEFAULT 0,
  `precio_unitario_mayor_sin_iva` float DEFAULT 0,
  `precio_unitario_oferta_con_iva` float DEFAULT 0,
  `precio_unitario_oferta_sin_iva` float DEFAULT NULL,
  `stock` float DEFAULT 0,
  `minimo_stock` float DEFAULT 0,
  `ventas` float DEFAULT 0,
  `costo_total` float DEFAULT 0,
  `imagen` varchar(255) DEFAULT 'no_image.jpg',
  `fecha_creacion` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `fecha_actualizacion` date DEFAULT NULL,
  `estado` int(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_spanish_ci;

--
-- Volcado de datos para la tabla `productos`
--

INSERT INTO `productos` (`id`, `codigo_producto`, `id_categoria`, `descripcion`, `id_tipo_afectacion_iva`, `id_unidad_medida`, `costo_unitario`, `precio_unitario_con_iva`, `precio_unitario_sin_iva`, `precio_unitario_mayor_con_iva`, `precio_unitario_mayor_sin_iva`, `precio_unitario_oferta_con_iva`, `precio_unitario_oferta_sin_iva`, `stock`, `minimo_stock`, `ventas`, `costo_total`, `imagen`, `fecha_creacion`, `fecha_actualizacion`, `estado`) VALUES
(1, '7805000316785', 7, 'Guantes Reutilizables de Nylon (Caja 100)', 12, 'UND', 50, 56, 50, 54.5, 48.5, 55, 49, 22, 10, 8, 1100, '66e4794bd2858_900.jpg', '2024-09-17 17:52:39', '2024-09-13', 1),
(2, '7873238475323', 7, 'Guantes de Nitrilo (Caja de 100)', 12, 'UND', 13, 14.56, 13, 13.06, 11.5, 13.56, 12, 22, 10, 8, 286, 'no_image.jpg', '2024-09-19 19:59:30', NULL, 1),
(3, '4245605804422', 7, 'Guantes de Vinilo (Caja de 100)', 12, 'UND', 12, 13.44, 12, 11.94, 10.5, 12.44, 11, 30, 10, 0, 360, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(4, '7873238475321', 7, 'Guantes de Látex Desechables (Caja de 100)', 12, 'UND', 12, 13.44, 12, 11.94, 10.5, 12.44, 11, 10, 10, 0, 120, 'no_image.jpg', '2024-09-14 08:39:11', NULL, 1),
(5, '3546334564565', 8, 'Escoba de Cerdas Medianas', 12, 'UND', 11.4, 12.77, 11.4, 11.27, 9.9, 11.77, 10.4, 30, 10, 0, 342, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(6, '7456734562645', 8, 'Cepillo para Esquinas', 12, 'UND', 11.9, 13.33, 11.9, 11.83, 10.4, 12.33, 10.9, 30, 10, 0, 357, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(7, '7546674783345', 8, 'Mopa Giratoria', 12, 'UND', 12.2, 13.66, 12.2, 12.16, 10.7, 12.66, 11.2, 28, 10, 2, 341.6, 'no_image.jpg', '2024-09-17 17:52:39', NULL, 1),
(8, '7465743456674', 8, 'Trapeador con Esponja', 12, 'UND', 11.6, 12.99, 11.6, 11.49, 10.1, 11.99, 10.6, 13, 10, 17, 150.8, 'no_image.jpg', '2024-09-17 17:58:34', NULL, 1),
(9, '3456734563456', 8, 'Mopa de Algodón', 12, 'UND', 12, 13.44, 12, 11.94, 10.5, 12.44, 11, 30, 10, 0, 360, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(10, '4356734773456', 8, 'Escoba de Cerdas Duraderas', 12, 'UND', 11.7, 13.1, 11.7, 11.6, 10.2, 12.1, 10.7, 30, 10, 0, 351, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(11, '7575280290743', 8, 'Cepillo para Pisos', 12, 'UND', 11.5, 12.88, 11.5, 11.38, 10, 11.88, 10.5, 30, 10, 0, 345, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(12, '7546745356456', 8, 'Mopa con Cubo Escurridor', 12, 'UND', 12.5, 14, 12.5, 12.5, 11, 13, 11.5, 30, 10, 0, 375, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(13, '7456723562645', 8, 'Trapeador de Microfibra', 12, 'UND', 11.8, 13.22, 11.8, 11.72, 10.3, 12.22, 10.8, 30, 10, 0, 354, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(14, '6435732523476', 8, 'Escoba de Cerdas Suaves', 12, 'UND', 11.2, 12.54, 11.2, 11.04, 9.7, 11.54, 10.2, 30, 10, 0, 336, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(15, '6436234567234', 9, 'Aromatizante de Pino 500ml', 12, 'UND', 11.5, 12.88, 11.5, 11.38, 10, 11.88, 10.5, 30, 10, 0, 345, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(16, '6543234523455', 9, 'Aromatizante de Ambiente Naranja 250ml', 12, 'UND', 12.2, 13.66, 12.2, 12.16, 10.7, 12.66, 11.2, 30, 10, 0, 366, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(17, '6435245236235', 9, 'Ambientador en Aerosol Citrus 300ml', 12, 'UND', 11.4, 12.77, 11.4, 11.27, 9.9, 11.77, 10.4, 30, 10, 0, 342, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(18, '6543245262454', 9, 'Aromatizante de Tela 300ml', 12, 'UND', 11.9, 13.33, 11.9, 11.83, 10.4, 12.33, 10.9, 30, 10, 0, 357, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(19, '4356372454563', 9, 'Aromatizante para Alfombras 500ml', 12, 'UND', 11.6, 12.99, 11.6, 11.49, 10.1, 11.99, 10.6, 30, 10, 0, 348, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(20, '6435634245623', 9, 'Aromatizante en Varillas 100ml', 12, 'UND', 12.5, 14, 12.5, 12.5, 11, 13, 11.5, 30, 10, 0, 375, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(21, '7356342456723', 9, 'Ambientador en Spray Vainilla 300ml', 12, 'UND', 11.7, 13.1, 11.7, 11.6, 10.2, 12.1, 10.7, 30, 10, 0, 351, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(22, '6454252345623', 9, 'Aromatizante en Gel Manzana 250g', 12, 'UND', 11.8, 13.22, 11.8, 11.72, 10.3, 12.22, 10.8, 30, 10, 0, 354, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(23, '6236543342453', 9, 'Aromatizante para Auto 50ml', 12, 'UND', 12, 13.44, 12, 11.94, 10.5, 12.44, 11, 30, 10, 0, 360, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(24, '2345667723456', 9, 'Ambientador en Spray Lavanda 300ml', 12, 'UND', 11.5, 12.88, 11.5, 11.38, 10, 11.88, 10.5, 30, 10, 0, 345, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(25, '7234512226253', 10, 'Limpiador para Refrigeradores 750ml', 12, 'UND', 11.9, 13.33, 11.9, 11.83, 10.4, 12.33, 10.9, 20, 10, 10, 238, 'no_image.jpg', '2024-09-17 20:31:38', NULL, 1),
(26, '5234627235772', 10, 'Limpiador de Azulejos de Cocina 1L', 12, 'UND', 11.6, 12.99, 11.6, 11.49, 10.1, 11.99, 10.6, 26, 10, 4, 301.6, 'no_image.jpg', '2024-09-18 02:28:23', NULL, 1),
(27, '7543625264654', 10, 'Limpiador de Campanas Extractoras 400ml', 12, 'UND', 12, 13.44, 12, 11.94, 10.5, 12.44, 11, 26, 10, 4, 312, 'no_image.jpg', '2024-09-17 18:00:04', NULL, 1),
(28, '8474674347675', 10, 'Limpiador de Vidrios de Cocina 500ml', 12, 'UND', 11.4, 12.77, 11.4, 11.27, 9.9, 11.77, 10.4, 21, 10, 9, 239.4, 'no_image.jpg', '2024-09-18 02:28:23', NULL, 1),
(29, '6745894365785', 10, 'Limpiador de Acero Inoxidable 750ml', 12, 'UND', 12.2, 13.66, 12.2, 12.16, 10.7, 12.66, 11.2, 30, 10, 0, 366, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(30, '8954679005786', 10, 'Limpiador de Placas de Cocina 500ml', 12, 'UND', 11.8, 13.22, 11.8, 11.72, 10.3, 12.22, 10.8, 30, 10, 0, 354, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(31, '7697856789578', 10, 'Limpiador de Microondas 400ml', 12, 'UND', 11.5, 12.88, 11.5, 11.38, 10, 11.88, 10.5, 30, 10, 0, 345, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(32, '8476436632623', 10, 'Desengrasante de Cocina 1L', 12, 'UND', 12, 13.44, 12, 11.94, 10.5, 12.44, 11, 30, 10, 0, 360, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(33, '6437833456256', 10, 'Limpiador de Superficies de Cocina 750ml', 12, 'UND', 11.7, 13.1, 11.7, 11.6, 10.2, 12.1, 10.7, 30, 10, 0, 351, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(34, '7452363456264', 10, 'Limpiador de Hornos en Spray 500ml', 12, 'UND', 12.5, 14, 12.5, 12.5, 11, 13, 11.5, 30, 10, 0, 375, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(35, '3456256356642', 11, 'Aromatizante para Baños 250ml', 12, 'UND', 11.2, 12.54, 11.2, 11.04, 9.7, 11.54, 10.2, 28, 10, 2, 313.6, 'no_image.jpg', '2024-09-18 01:12:53', NULL, 1),
(36, '2457743568734', 11, 'Limpiador para Baños con Blanqueador 750ml', 12, 'UND', 11.8, 13.22, 11.8, 11.72, 10.3, 12.22, 10.8, 27, 10, 3, 318.6, 'no_image.jpg', '2024-09-18 01:12:53', NULL, 1),
(37, '7452634627723', 11, 'Limpiador de Baldosas y Azulejos 1L', 12, 'UND', 12, 13.44, 12, 11.94, 10.5, 12.44, 11, 30, 10, 0, 360, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(38, '2345635677356', 11, 'Gel Antical para Baños 500ml', 12, 'UND', 11.5, 12.88, 11.5, 11.38, 10, 11.88, 10.5, 30, 10, 0, 345, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(39, '3456734634566', 11, 'Desinfectante para Inodoro 750ml', 12, 'UND', 11.6, 12.99, 11.6, 11.49, 10.1, 11.99, 10.6, 23, 10, 7, 266.8, 'no_image.jpg', '2024-09-28 20:31:43', NULL, 1),
(40, '3457632563466', 11, 'Limpiador Desincrustante para Baños 1L', 12, 'UND', 12.5, 14, 12.5, 12.5, 11, 13, 11.5, 30, 10, 0, 375, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(41, '2757243653266', 11, 'Limpiador de Espejos y Superficies 500ml', 12, 'UND', 11.7, 13.1, 11.7, 11.6, 10.2, 12.1, 10.7, 30, 10, 0, 351, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(42, '2688245236234', 11, 'Limpiador de Grifos y Duchas 400ml', 12, 'UND', 12, 13.44, 12, 11.94, 10.5, 12.44, 11, 30, 10, 0, 360, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(43, '8735632546747', 11, 'Limpiador de Baños en Gel 750ml', 12, 'UND', 11.8, 13.22, 11.8, 11.72, 10.3, 12.22, 10.8, 30, 10, 0, 354, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(44, '7422764388924', 11, 'Limpiador de Inodoro 500ml', 12, 'UND', 11.5, 12.88, 11.5, 11.38, 10, 11.88, 10.5, 30, 10, 0, 345, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(45, '7654256523564', 12, 'Removedor de Pelusas 100 hojas', 12, 'UND', 13, 14.56, 13, 13.06, 11.5, 13.56, 12, 30, 10, 0, 390, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(46, '6543883456132', 12, 'Blanqueador Líquido para Ropa 1L', 12, 'UND', 11.9, 13.33, 11.9, 11.83, 10.4, 12.33, 10.9, 30, 10, 0, 357, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(47, '2452788993456', 12, 'Quitamanchas Oxigenado 500g', 12, 'UND', 12.2, 13.66, 12.2, 12.16, 10.7, 12.66, 11.2, 30, 10, 0, 366, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(48, '7894785946745', 12, 'Removedor de Olores para Ropa 1L', 12, 'UND', 11.6, 12.99, 11.6, 11.49, 10.1, 11.99, 10.6, 30, 10, 0, 348, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(49, '6345672457789', 12, 'Refrescante de Telas 400ml', 12, 'UND', 12.5, 14, 12.5, 12.5, 11, 13, 11.5, 30, 10, 0, 375, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(50, '2456723456234', 12, 'Acondicionador de Telas 500ml', 12, 'UND', 11.2, 12.54, 11.2, 11.04, 9.7, 11.54, 10.2, 30, 10, 0, 336, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(51, '2435672452345', 12, 'Blanqueador para Ropa 1L', 12, 'UND', 11.7, 13.1, 11.7, 11.6, 10.2, 12.1, 10.7, 30, 10, 0, 351, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(52, '7434365245266', 12, 'Quitamanchas en Polvo 300g', 12, 'UND', 12, 13.44, 12, 11.94, 10.5, 12.44, 11, 30, 10, 0, 360, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(53, '2345272452345', 12, 'Quitamanchas en Spray 250ml', 12, 'UND', 11.8, 13.22, 11.8, 11.72, 10.3, 12.22, 10.8, 30, 10, 0, 354, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(54, '1432465723453', 12, 'Suavizante de Telas 1L', 12, 'UND', 11.5, 12.88, 11.5, 11.38, 10, 11.88, 10.5, 30, 10, 0, 345, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(55, '5624357114523', 13, 'Limpiador Multiusos en Toallitas 50 unidades', 12, 'UND', 13, 14.56, 13, 13.06, 11.5, 13.56, 12, 26, 10, 4, 338, 'no_image.jpg', '2024-09-17 20:31:38', NULL, 1),
(56, '2345709918562', 13, 'Limpiador Multiusos con Desinfectante 1L', 12, 'UND', 12.3, 13.78, 12.3, 12.28, 10.8, 12.78, 11.3, 25, 10, 5, 307.5, 'no_image.jpg', '2024-09-19 19:59:30', NULL, 1),
(57, '4673246251349', 13, 'Limpiador Multiusos Antigrasa 750ml', 12, 'UND', 11.8, 13.22, 11.8, 11.72, 10.3, 12.22, 10.8, 30, 10, 0, 354, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(58, '5678345632239', 13, 'Limpiador Multiusos para Superficies Delicadas 500ml', 12, 'UND', 11.7, 13.1, 11.7, 11.6, 10.2, 12.1, 10.7, 30, 10, 0, 351, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(59, '4567843645389', 13, 'Limpiador Multiusos con Vinagre 500ml', 12, 'UND', 11.5, 12.88, 11.5, 11.38, 10, 11.88, 10.5, 30, 10, 0, 345, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(60, '5678909467568', 13, 'Limpiador Multiusos Aromático 1L', 12, 'UND', 12, 13.44, 12, 11.94, 10.5, 12.44, 11, 30, 10, 0, 360, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(61, '9768085678595', 13, 'Limpiador Multiusos en Gel 500ml', 12, 'UND', 11.3, 12.66, 11.3, 11.16, 9.8, 11.66, 10.3, 30, 10, 0, 339, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(62, '2345678862364', 13, 'Limpiador Multiusos con Blanqueador 750ml', 12, 'UND', 11.5, 12.88, 11.5, 11.38, 10, 11.88, 10.5, 30, 10, 0, 345, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(63, '3563722563634', 13, 'Limpiador Multiusos Concentrado 1L', 12, 'UND', 12.5, 14, 12.5, 12.5, 11, 13, 11.5, 30, 10, 0, 375, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(64, '7453632625436', 13, 'Limpiador Multiusos en Spray 500ml', 12, 'UND', 11.2, 12.54, 11.2, 11.04, 9.7, 11.54, 10.2, 30, 10, 0, 336, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(65, '4567484365432', 14, 'Desinfectante de Manos en Gel 100ml', 12, 'UND', 11, 12.32, 11, 10.82, 9.5, 11.32, 10, 30, 10, 0, 330, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(66, '9785543457689', 14, 'Desinfectante para Frutas y Verduras 500ml', 12, 'UND', 11.5, 12.88, 11.5, 11.38, 10, 11.88, 10.5, 26, 10, 4, 299, 'no_image.jpg', '2024-09-18 00:11:51', NULL, 1),
(67, '6654356252676', 14, 'Desinfectante para Ropa 1L', 12, 'UND', 12.2, 13.66, 12.2, 12.16, 10.7, 12.66, 11.2, 30, 10, 0, 366, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(68, '3456722456373', 14, 'Desinfectante para Pisos 1L', 12, 'UND', 11.6, 12.99, 11.6, 11.49, 10.1, 11.99, 10.6, 30, 10, 0, 348, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(69, '7654643324665', 14, 'Desinfectante para Baños 750ml', 12, 'UND', 11.7, 13.1, 11.7, 11.6, 10.2, 12.1, 10.7, 30, 10, 0, 351, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(70, '3456724524565', 14, 'Desinfectante en Toallitas 100 unidades', 12, 'UND', 13.5, 15.12, 13.5, 13.62, 12, 14.12, 12.5, 30, 10, 0, 405, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(71, '2456772122567', 14, 'Desinfectante Concentrado 500ml', 12, 'UND', 11.9, 13.33, 11.9, 11.83, 10.4, 12.33, 10.9, 30, 10, 0, 357, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(72, '6543245234676', 14, 'Desinfectante en Spray para Superficies 400ml', 12, 'UND', 12, 13.44, 12, 11.94, 10.5, 12.44, 11, 30, 10, 0, 360, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(73, '7265451246553', 14, 'Aerosol Desinfectante 500ml', 12, 'UND', 12.5, 14, 12.5, 12.5, 11, 13, 11.5, 30, 10, 0, 375, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(74, '2346245245167', 14, 'Desinfectante Líquido Multiusos 1L', 12, 'UND', 11.8, 13.22, 11.8, 11.72, 10.3, 12.22, 10.8, 30, 10, 0, 354, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(75, '2462456754565', 15, 'Detergente en Polvo para Lavadora 1kg', 12, 'UND', 12, 13.44, 12, 11.94, 10.5, 12.44, 11, 30, 10, 0, 360, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(76, '6345624563456', 15, 'Detergente Biodegradable para Ropa 1L', 12, 'UND', 11.5, 12.88, 11.5, 11.38, 10, 11.88, 10.5, 26, 10, 4, 299, 'no_image.jpg', '2024-09-28 20:31:43', NULL, 1),
(77, '7654224562453', 15, 'Jabón de Barra Neutro 150g', 12, 'UND', 10.7, 11.98, 10.7, 10.48, 9.2, 10.98, 9.7, 30, 10, 0, 321, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(78, '2345223456756', 15, 'Detergente para Lavavajillas 250ml', 12, 'UND', 11.4, 12.77, 11.4, 11.27, 9.9, 11.77, 10.4, 27, 10, 3, 307.8, 'no_image.jpg', '2024-09-18 02:28:23', NULL, 1),
(79, '2345622345345', 15, 'Jabón Líquido Antibacterial 300ml', 12, 'UND', 12, 13.44, 12, 11.94, 10.5, 12.44, 11, 30, 10, 0, 360, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(80, '2345645624534', 15, 'Detergente para Platos 500ml', 12, 'UND', 14, 15.68, 14, 14.18, 12.5, 14.68, 13, 30, 10, 0, 420, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(81, '5432562345234', 15, 'Jabón Líquido para Manos 250ml', 12, 'UND', 12, 13.44, 12, 11.94, 10.5, 12.44, 11, 30, 10, 0, 360, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(82, '2352466534532', 15, 'Detergente en Polvo 500g', 12, 'UND', 10, 11.2, 10, 9.7, 8.5, 10.2, 9, 30, 10, 0, 300, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(83, '9878765345622', 15, 'Jabón en Barra para Ropa 200g', 12, 'UND', 4, 7, 6.25, 6, 5.36, 6.5, 5.8, 10, 10, 0, 40, '66e54c5a9b866_786.jpg', '2024-09-14 08:42:02', '2024-09-14', 1),
(84, '1987625643234', 15, 'Detergente Líquido para Ropa 1L', 12, 'UND', 10, 11.2, 10, 9.7, 8.5, 10.2, 9, 30, 10, 0, 300, 'no_image.jpg', '2024-09-13 17:13:36', NULL, 1),
(85, '1', 3, 'BOLSA XL', 12, 'UND', 12, 15, 13.39, 14, 12.5, 13, 11.61, 3, 10, 12, 36, '66e4d94ec9180_345.jpg', '2024-09-17 17:18:49', '2024-09-14', 1),
(86, '2', 3, 'BOLSA XXL', 12, 'UND', 12, 15, 13.39, 14, 12.5, 13, 11.61, 3, 10, 12, 36, '66e4d99e9b443_552.jpg', '2024-09-17 17:14:45', '2024-09-14', 1),
(87, '12345', 2, 'REPELENTE PRA MOSQUITOS', 12, 'UND', 12, 16, 14.29, 14.5, 12.95, 15, 13.39, 60, 10, 0, 720, '66e548e2067f6_590.jpg', '2024-09-17 20:30:17', '2024-09-14', 1),
(88, '100', 17, 'JUANITO JUAN', 5, 'UND', 45, 45, 45, 0, 0, 0, 0, 14, 10, 2, 630, '66ea170205696_533.png', '2024-09-18 00:01:32', '2024-09-18', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `proveedores`
--

CREATE TABLE `proveedores` (
  `id` int(11) NOT NULL,
  `id_tipo_documento` varchar(45) NOT NULL,
  `nit` varchar(45) NOT NULL,
  `razon_social` varchar(150) NOT NULL,
  `direccion` varchar(255) NOT NULL,
  `telefono` varchar(20) DEFAULT NULL,
  `estado` tinyint(4) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Volcado de datos para la tabla `proveedores`
--

INSERT INTO `proveedores` (`id`, `id_tipo_documento`, `nit`, `razon_social`, `direccion`, `telefono`, `estado`) VALUES
(1, '4', '5630096', 'CLEAN DEPOT - XELA', '0 AV 1-5 ZONA 1', '57876150', 1),
(2, '4', '26577194', 'XELAPAN', '11 CALLE 9 - 39 ZONA 4', '49611233', 0),
(3, '4', '12345651', 'SHALOM', '11 Calle 9 - 39 Zona 4 Santa Cruz del Quiché', '49611233', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `resumenes`
--

CREATE TABLE `resumenes` (
  `id` int(11) NOT NULL,
  `fecha_envio` date DEFAULT NULL,
  `fecha_referencia` date DEFAULT NULL,
  `correlativo` int(11) DEFAULT NULL,
  `resumen` smallint(6) DEFAULT NULL,
  `baja` smallint(6) DEFAULT NULL,
  `nombrexml` varchar(50) DEFAULT NULL,
  `mensaje_sat` varchar(200) DEFAULT NULL,
  `codigo_sat` varchar(20) DEFAULT NULL,
  `ticket` varchar(50) DEFAULT NULL,
  `estado` char(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci ROW_FORMAT=DYNAMIC;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `resumenes_detalle`
--

CREATE TABLE `resumenes_detalle` (
  `id` int(255) NOT NULL,
  `id_envio` int(11) DEFAULT NULL,
  `id_comprobante` int(11) DEFAULT NULL,
  `condicion` smallint(6) DEFAULT NULL COMMENT '1->Creacion, 2->Actualizacion, 3->Baja'
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci ROW_FORMAT=DYNAMIC;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `serie`
--

CREATE TABLE `serie` (
  `id` int(11) NOT NULL,
  `id_tipo_comprobante` varchar(3) NOT NULL,
  `serie` varchar(4) NOT NULL,
  `correlativo` int(11) DEFAULT NULL,
  `estado` int(11) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `serie`
--

INSERT INTO `serie` (`id`, `id_tipo_comprobante`, `serie`, `correlativo`, `estado`) VALUES
(1, '01', 'FA01', 0, 1),
(2, '03', 'BO01', 12, 1),
(3, 'RC', 'RC01', 0, 1),
(4, 'CTZ', 'CT01', 0, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tb_ubigeos`
--

CREATE TABLE `tb_ubigeos` (
  `ubigeo_renap` varchar(4) NOT NULL,
  `departamento` text DEFAULT NULL,
  `municipio` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Volcado de datos para la tabla `tb_ubigeos`
--

INSERT INTO `tb_ubigeos` (`ubigeo_renap`, `departamento`, `municipio`) VALUES
('0101', 'GUATEMALA', 'GUATEMALA'),
('0102', 'GUATEMALA', 'SANTA CATARINA PINULA'),
('0103', 'GUATEMALA', 'SAN JOSÉ PINULA'),
('0104', 'GUATEMALA', 'SAN JOSÉ DEL GOLFO'),
('0105', 'GUATEMALA', 'PALENCIA'),
('0106', 'GUATEMALA', 'CHINAUTLA'),
('0107', 'GUATEMALA', 'SAN PEDRO AYAMPUC'),
('0108', 'GUATEMALA', 'MIXCO'),
('0109', 'GUATEMALA', 'SAN PEDRO SACATEPÉQUEZ'),
('0110', 'GUATEMALA', 'SAN JUAN SACATEPÉQUEZ'),
('0111', 'GUATEMALA', 'SAN RAIMUNDO'),
('0112', 'GUATEMALA', 'CHUARRANCHO'),
('0113', 'GUATEMALA', 'FRAIJANES'),
('0114', 'GUATEMALA', 'AMATITLÁN'),
('0115', 'GUATEMALA', 'VILLA NUEVA'),
('0116', 'GUATEMALA', 'VILLA CANALES'),
('0117', 'GUATEMALA', 'PETAPA'),
('0201', 'EL PROGRESO', 'GUASTATOYA'),
('0202', 'EL PROGRESO', 'MORAZÁN'),
('0203', 'EL PROGRESO', 'SAN AGUSTÍN ACASAGUASTLÁN'),
('0204', 'EL PROGRESO', 'SAN CRISTÓBAL ACASAGUASTLÁN'),
('0205', 'EL PROGRESO', 'EL JÍCARO'),
('0206', 'EL PROGRESO', 'SANARE'),
('0207', 'EL PROGRESO', 'SANARATE'),
('0208', 'EL PROGRESO', 'SAN ANTONIO LA PAZ'),
('0301', 'SACATEPÉQUEZ', 'ANTIGUA GUATEMALA'),
('0302', 'SACATEPÉQUEZ', 'JOCOTENANGO'),
('0303', 'SACATEPÉQUEZ', 'PASTORES'),
('0304', 'SACATEPÉQUEZ', 'SUMPANGO'),
('0305', 'SACATEPÉQUEZ', 'SANTO DOMINGO XENACOJ'),
('0306', 'SACATEPÉQUEZ', 'SANTIAGO SACATEPÉQUEZ'),
('0307', 'SACATEPÉQUEZ', 'SAN BARTOLOMÉ MILPAS ALTAS'),
('0308', 'SACATEPÉQUEZ', 'SAN LUCAS SACATEPÉQUEZ'),
('0309', 'SACATEPÉQUEZ', 'SANTA LUCÍA MILPAS ALTAS'),
('0310', 'SACATEPÉQUEZ', 'MAGDALENA MILPAS ALTAS'),
('0311', 'SACATEPÉQUEZ', 'SANTA MARÍA DE JESUS'),
('0312', 'SACATEPÉQUEZ', 'CIUDAD VIEJA'),
('0313', 'SACATEPÉQUEZ', 'SAN MIGUEL DUEÑAS'),
('0314', 'SACATEPÉQUEZ', 'ALOTENANGO'),
('0315', 'SACATEPÉQUEZ', 'SAN ANTONIO AGUAS CALIENTES'),
('0316', 'SACATEPÉQUEZ', 'SANTA CATALINA BARAHONA'),
('0401', 'CHIMALTENANGO', 'CHIMALTENANGO'),
('0402', 'CHIMALTENANGO', 'SAN JOSÉ POAQUIL'),
('0403', 'CHIMALTENANGO', 'SAN MARTÍN JILOTEPEQUE'),
('0404', 'CHIMALTENANGO', 'COMALAPA'),
('0405', 'CHIMALTENANGO', 'SANTA APOLONIA'),
('0406', 'CHIMALTENANGO', 'TECPÁN GUATEMALA'),
('0407', 'CHIMALTENANGO', 'PATZÚN'),
('0408', 'CHIMALTENANGO', 'POCHUTA'),
('0409', 'CHIMALTENANGO', 'PATZICÍA'),
('0410', 'CHIMALTENANGO', 'SANTA CRUZ BALANYÁ'),
('0411', 'CHIMALTENANGO', 'ACATENANGO'),
('0412', 'CHIMALTENANGO', 'YEPÓCAPA'),
('0413', 'CHIMALTENANGO', 'SAN ANDRÉS ITZAPA'),
('0414', 'CHIMALTENANGO', 'PÁRRAMOS'),
('0415', 'CHIMALTENANGO', 'ZARAGOZA'),
('0416', 'CHIMALTENANGO', 'EL TEJAR'),
('0501', 'ESCUINTLA', 'ESCUINTLA'),
('0502', 'ESCUINTLA', 'SANTA LUCÍA COTZUMALGUAPA'),
('0503', 'ESCUINTLA', 'LA DEMOCRACIA'),
('0504', 'ESCUINTLA', 'SIQUINALÁ'),
('0505', 'ESCUINTLA', 'MASAGUA'),
('0506', 'ESCUINTLA', 'TIQUISATE'),
('0507', 'ESCUINTLA', 'LA GOMERA'),
('0508', 'ESCUINTLA', 'GUANAGAZAPA'),
('0509', 'ESCUINTLA', 'SAN JOSÉ'),
('0510', 'ESCUINTLA', 'IZTAPA'),
('0511', 'ESCUINTLA', 'PALÍN'),
('0512', 'ESCUINTLA', 'SAN VICENTE PACAYA'),
('0513', 'ESCUINTLA', 'NUEVA CONCEPCIÓN'),
('0601', 'SANTA ROSA', 'CUILAPA'),
('0602', 'SANTA ROSA', 'BARBERENA'),
('0603', 'SANTA ROSA', 'SANTA ROSA DE LIMA'),
('0604', 'SANTA ROSA', 'CASILLAS'),
('0605', 'SANTA ROSA', 'SAN RAFAEL LAS FLORES'),
('0606', 'SANTA ROSA', 'ORATORIO'),
('0607', 'SANTA ROSA', 'SAN JUAN TECUACO'),
('0608', 'SANTA ROSA', 'CHIQUIMULILLA'),
('0609', 'SANTA ROSA', 'TAXISCO'),
('0610', 'SANTA ROSA', 'SANTA MARÍA IXHUATÁN'),
('0611', 'SANTA ROSA', 'GUAZACAPÁN'),
('0612', 'SANTA ROSA', 'SANTA CRUZ NARANJO'),
('0613', 'SANTA ROSA', 'PUEBLO NUEVO VIÑAS'),
('0614', 'SANTA ROSA', 'NUEVA SANTA ROSA'),
('0701', 'SOLOLÁ', 'SOLOLÁ'),
('0702', 'SOLOLÁ', 'SAN JOSÉ CHACAYÁ'),
('0703', 'SOLOLÁ', 'SANTA MARÍA VISITACIÓN'),
('0704', 'SOLOLÁ', 'SANTA LUCÍA UTATLÁN'),
('0705', 'SOLOLÁ', 'NAHUALÁ'),
('0706', 'SOLOLÁ', 'SANTA CATARINA IXTAHUACÁN'),
('0707', 'SOLOLÁ', 'SANTA CLARA LA LAGUNA'),
('0708', 'SOLOLÁ', 'CONCEPCIÓN'),
('0709', 'SOLOLÁ', 'SAN ANDRÉS SEMETABAJ'),
('0710', 'SOLOLÁ', 'PANAJACHEL'),
('0711', 'SOLOLÁ', 'SANTA CATARINA PALOPÓ'),
('0712', 'SOLOLÁ', 'SAN ANTONIO PALOPÓ'),
('0713', 'SOLOLÁ', 'SAN LUCAS TOLIMÁN'),
('0714', 'SOLOLÁ', 'SANTA CRUZ LA LAGUNA'),
('0715', 'SOLOLÁ', 'SAN PABLO LA LAGUNA'),
('0716', 'SOLOLÁ', 'SAN MARCOS LA LAGUNA'),
('0717', 'SOLOLÁ', 'SAN JUAN LA LAGUNA'),
('0718', 'SOLOLÁ', 'SAN PEDRO LA LAGUNA'),
('0719', 'SOLOLÁ', 'SANTIAGO ATITLÁN'),
('0801', 'TOTONICAPÁN', 'TOTONICAPÁN'),
('0802', 'TOTONICAPÁN', 'SAN CRISTÓBAL TOTONICAPÁN'),
('0803', 'TOTONICAPÁN', 'SAN FRANCISCO EL ALTO'),
('0804', 'TOTONICAPÁN', 'SAN ANDRÉS XECUL'),
('0805', 'TOTONICAPÁN', 'MOMOSTENANGO'),
('0806', 'TOTONICAPÁN', 'SANTA MARÍA CHIQUIMULA'),
('0807', 'TOTONICAPÁN', 'SANTA LUCÍA LA REFORMA'),
('0808', 'TOTONICAPÁN', 'SAN BARTOLO'),
('0901', 'QUETZALTENANGO', 'QUETZALTENANGO'),
('0902', 'QUETZALTENANGO', 'SALCAJÁ'),
('0903', 'QUETZALTENANGO', 'OLINTEPEQUE'),
('0904', 'QUETZALTENANGO', 'SAN CARLOS SIJA'),
('0905', 'QUETZALTENANGO', 'SIBILIA'),
('0906', 'QUETZALTENANGO', 'CABRICÁN'),
('0907', 'QUETZALTENANGO', 'CAJOLÁ'),
('0908', 'QUETZALTENANGO', 'SAN MIGUEL SIGUILÁ'),
('0909', 'QUETZALTENANGO', 'OSTUNCALCO'),
('0910', 'QUETZALTENANGO', 'SAN MATEO'),
('0911', 'QUETZALTENANGO', 'CONCEPCIÓN CHIQUIRICHAPA'),
('0912', 'QUETZALTENANGO', 'SAN MARTÍN SACATEPÉQUEZ'),
('0913', 'QUETZALTENANGO', 'ALMOLONGA'),
('0914', 'QUETZALTENANGO', 'CANTEL'),
('0915', 'QUETZALTENANGO', 'HUITÁN'),
('0916', 'QUETZALTENANGO', 'ZUNIL'),
('0917', 'QUETZALTENANGO', 'COLOMBA'),
('0918', 'QUETZALTENANGO', 'SAN FRANCISCO LA UNIÓN'),
('0919', 'QUETZALTENANGO', 'EL PALMAR'),
('0920', 'QUETZALTENANGO', 'COATEPEQUE'),
('0921', 'QUETZALTENANGO', 'GÉNOVA'),
('0922', 'QUETZALTENANGO', 'FLORES COSTA CUCA'),
('0923', 'QUETZALTENANGO', 'LA ESPERANZA'),
('0924', 'QUETZALTENANGO', 'PALESTINA DE LOS ALTOS'),
('1001', 'SUCHITEPÉQUEZ', 'MAZATENANGO'),
('1002', 'SUCHITEPÉQUEZ', 'CUYOTENANGO'),
('1003', 'SUCHITEPÉQUEZ', 'SAN FRANCISCO ZAPOTITLÁN'),
('1004', 'SUCHITEPÉQUEZ', 'SAN BERNARDINO'),
('1005', 'SUCHITEPÉQUEZ', 'SAN JOSÉ EL ÍDOLO'),
('1006', 'SUCHITEPÉQUEZ', 'SANTO DOMINGO SUCHITEPÉQUEZ'),
('1007', 'SUCHITEPÉQUEZ', 'SAN LORENZO'),
('1008', 'SUCHITEPÉQUEZ', 'SAMAYAC'),
('1009', 'SUCHITEPÉQUEZ', 'SAN PABLO JOCOPILAS'),
('1010', 'SUCHITEPÉQUEZ', 'SAN ANTONIO SUCHITEPÉQUEZ'),
('1011', 'SUCHITEPÉQUEZ', 'SAN MIGUEL PANÁN'),
('1012', 'SUCHITEPÉQUEZ', 'SAN GABRIEL'),
('1013', 'SUCHITEPÉQUEZ', 'CHICACAO'),
('1014', 'SUCHITEPÉQUEZ', 'PATULUL'),
('1015', 'SUCHITEPÉQUEZ', 'SANTA BÁRBARA'),
('1016', 'SUCHITEPÉQUEZ', 'SAN JUAN BAUTISTA'),
('1017', 'SUCHITEPÉQUEZ', 'SANTO TOMÁS LA UNIÓN'),
('1018', 'SUCHITEPÉQUEZ', 'ZUNILITO'),
('1019', 'SUCHITEPÉQUEZ', 'PUEBLO NUEVO'),
('1020', 'SUCHITEPÉQUEZ', 'RÍO BRAVO'),
('1101', 'RETALHULEU', 'RETALHULEU'),
('1102', 'RETALHULEU', 'SAN SEBASTIÁN'),
('1103', 'RETALHULEU', 'SANTA CRUZ MULUÁ'),
('1104', 'RETALHULEU', 'SAN MARTÍN ZAPOTITLÁN'),
('1105', 'RETALHULEU', 'SAN FELIPE'),
('1106', 'RETALHULEU', 'SAN ANDRÉS VILLA SECA'),
('1107', 'RETALHULEU', 'CHAMPERICO'),
('1108', 'RETALHULEU', 'NUEVO SAN CARLOS'),
('1109', 'RETALHULEU', 'EL ASINTAL'),
('1201', 'SAN MARCOS', 'SAN MARCOS'),
('1202', 'SAN MARCOS', 'SAN PEDRO SACATEPÉQUEZ'),
('1203', 'SAN MARCOS', 'SAN ANTONIO SACATEPÉQUEZ'),
('1204', 'SAN MARCOS', 'COMITANCILLO'),
('1205', 'SAN MARCOS', 'SAN MIGUEL IXTAHUACÁN'),
('1206', 'SAN MARCOS', 'CONCEPCIÓN TUTUAPA'),
('1207', 'SAN MARCOS', 'TACANÁ'),
('1208', 'SAN MARCOS', 'SIBINAL'),
('1209', 'SAN MARCOS', 'TAJUMULCO'),
('1210', 'SAN MARCOS', 'TEJUTLA'),
('1211', 'SAN MARCOS', 'SAN RAFAEL PIE DE LA CUESTA'),
('1212', 'SAN MARCOS', 'NUEVO PROGRESO'),
('1213', 'SAN MARCOS', 'EL TUMBADOR'),
('1214', 'SAN MARCOS', 'EL RODEO'),
('1215', 'SAN MARCOS', 'MALACATÁN'),
('1216', 'SAN MARCOS', 'CATARINA'),
('1217', 'SAN MARCOS', 'AYUTLA'),
('1218', 'SAN MARCOS', 'OCÓS'),
('1219', 'SAN MARCOS', 'SAN PABLO'),
('1220', 'SAN MARCOS', 'EL QUETZAL'),
('1221', 'SAN MARCOS', 'LA REFORMA'),
('1222', 'SAN MARCOS', 'PAJAPITA'),
('1223', 'SAN MARCOS', 'IXCHIGUÁN'),
('1224', 'SAN MARCOS', 'SAN JOSÉ OJETENAM'),
('1225', 'SAN MARCOS', 'SAN CRISTÓBAL CUCHO'),
('1226', 'SAN MARCOS', 'SIPACAPA'),
('1227', 'SAN MARCOS', 'ESQUIPULAS PALO GORDO'),
('1228', 'SAN MARCOS', 'RÍO BLANCO'),
('1229', 'SAN MARCOS', 'SAN LORENZO'),
('1301', 'HUEHUETENANGO', 'HUEHUETENANGO'),
('1302', 'HUEHUETENANGO', 'CHIANTLA'),
('1303', 'HUEHUETENANGO', 'MALACATANCITO'),
('1304', 'HUEHUETENANGO', 'CUILCO'),
('1305', 'HUEHUETENANGO', 'NENTÓN'),
('1306', 'HUEHUETENANGO', 'SAN PEDRO NECTA'),
('1307', 'HUEHUETENANGO', 'JACALTENANGO'),
('1308', 'HUEHUETENANGO', 'SOLOMA'),
('1309', 'HUEHUETENANGO', 'IXTAHUACÁN'),
('1310', 'HUEHUETENANGO', 'SANTA BÁRBARA'),
('1311', 'HUEHUETENANGO', 'LA LIBERTAD'),
('1312', 'HUEHUETENANGO', 'LA DEMOCRACIA'),
('1313', 'HUEHUETENANGO', 'SAN MIGUEL ACATÁN'),
('1314', 'HUEHUETENANGO', 'SAN RAFAEL LA INDEPENDENCIA'),
('1315', 'HUEHUETENANGO', 'TODOS SANTOS CUCHUMATANES'),
('1316', 'HUEHUETENANGO', 'SAN JUAN ATITÁN'),
('1317', 'HUEHUETENANGO', 'SANTA EULALIA'),
('1318', 'HUEHUETENANGO', 'SAN MATEO IXTATÁN'),
('1319', 'HUEHUETENANGO', 'COLOTENANGO'),
('1320', 'HUEHUETENANGO', 'SAN SEBASTIÁN HUEHUETENANGO'),
('1321', 'HUEHUETENANGO', 'TECTITÁN'),
('1322', 'HUEHUETENANGO', 'CONCEPCIÓN HUISTA'),
('1323', 'HUEHUETENANGO', 'SAN JUAN IXCOY'),
('1324', 'HUEHUETENANGO', 'SAN ANTONIO HUISTA'),
('1325', 'HUEHUETENANGO', 'SAN SEBASTIÁN COATÁN'),
('1326', 'HUEHUETENANGO', 'BARILLAS'),
('1327', 'HUEHUETENANGO', 'AGUACATÁN'),
('1328', 'HUEHUETENANGO', 'SAN RAFAEL PETZAL'),
('1329', 'HUEHUETENANGO', 'SAN GASPAR IXCHIL'),
('1330', 'HUEHUETENANGO', 'SANTIAGO CHIMALTENANGO'),
('1331', 'HUEHUETENANGO', 'SANTA ANA HUISTA'),
('1401', 'QUICHÉ', 'SANTA_CRUZ_DEL_QUICHÉ'),
('1402', 'QUICHÉ', 'CHICHÉ'),
('1403', 'QUICHÉ', 'CHINIQUE'),
('1404', 'QUICHÉ', 'ZACUALPA'),
('1405', 'QUICHÉ', 'CHAJUL'),
('1406', 'QUICHÉ', 'CHICHICASTENANGO'),
('1407', 'QUICHÉ', 'PATZITÉ'),
('1408', 'QUICHÉ', 'SAN ANTONIO ILOTENANGO'),
('1409', 'QUICHÉ', 'SAN PEDRO JOCOPILAS'),
('1410', 'QUICHÉ', 'CUNÉN'),
('1411', 'QUICHÉ', 'SAN JUAN COTZAL'),
('1412', 'QUICHÉ', 'JOYABAJ'),
('1413', 'QUICHÉ', 'NEBAJ'),
('1414', 'QUICHÉ', 'SAN ANDRÉS SAJCABAJÁ'),
('1415', 'QUICHÉ', 'USPANTÁN'),
('1416', 'QUICHÉ', 'SACAPULAS'),
('1417', 'QUICHÉ', 'SAN BARTOLOMÉ JOCOTENANGO'),
('1418', 'QUICHÉ', 'CANILLÁ'),
('1419', 'QUICHÉ', 'CHICAMÁN'),
('1420', 'QUICHÉ', 'IXCÁN'),
('1421', 'QUICHÉ', 'PACHALUM'),
('1501', 'BAJA VERAPAZ', 'SALAMÁ'),
('1502', 'BAJA VERAPAZ', 'SAN MIGUEL CHICAJ'),
('1503', 'BAJA VERAPAZ', 'RABINAL'),
('1504', 'BAJA VERAPAZ', 'CUBULCO'),
('1505', 'BAJA VERAPAZ', 'GRANADOS'),
('1506', 'BAJA VERAPAZ', 'EL CHOL'),
('1507', 'BAJA VERAPAZ', 'SAN JERÓNIMO'),
('1508', 'BAJA VERAPAZ', 'PURULHÁ'),
('1601', 'ALTA VERAPAZ', 'COBÁN'),
('1602', 'ALTA VERAPAZ', 'SANTA CRUZ VERAPAZ'),
('1603', 'ALTA VERAPAZ', 'SAN CRISTÓBAL VERAPAZ'),
('1604', 'ALTA VERAPAZ', 'TACTIC'),
('1605', 'ALTA VERAPAZ', 'TAMAHÚ'),
('1606', 'ALTA VERAPAZ', 'TUCURÚ'),
('1607', 'ALTA VERAPAZ', 'PANZÓS'),
('1608', 'ALTA VERAPAZ', 'SENAHÚ'),
('1609', 'ALTA VERAPAZ', 'SAN PEDRO CARCHÁ'),
('1610', 'ALTA VERAPAZ', 'SAN JUAN CHAMELCO'),
('1611', 'ALTA VERAPAZ', 'LANQUÍN'),
('1612', 'ALTA VERAPAZ', 'CAHABÓN'),
('1613', 'ALTA VERAPAZ', 'CHISEC'),
('1614', 'ALTA VERAPAZ', 'CHAHAL'),
('1615', 'ALTA VERAPAZ', 'FRAY BARTOLOMÉ DE LAS CASAS'),
('1701', 'PETÉN', 'FLORES'),
('1702', 'PETÉN', 'SAN JOSÉ'),
('1703', 'PETÉN', 'SAN BENITO'),
('1704', 'PETÉN', 'SAN ANDRÉS'),
('1705', 'PETÉN', 'LA LIBERTAD'),
('1706', 'PETÉN', 'SAN FRANCISCO'),
('1707', 'PETÉN', 'SANTA ANA'),
('1708', 'PETÉN', 'DOLORES'),
('1709', 'PETÉN', 'SAN LUIS'),
('1710', 'PETÉN', 'SAYAXCHÉ'),
('1711', 'PETÉN', 'MELCHOR DE MENCOS'),
('1712', 'PETÉN', 'POPTÚN'),
('1801', 'IZABAL', 'PUERTO BARRIOS'),
('1802', 'IZABAL', 'LÍVINGSTON'),
('1803', 'IZABAL', 'EL ESTOR'),
('1804', 'IZABAL', 'MORALES'),
('1805', 'IZABAL', 'LOS AMATES'),
('1901', 'ZACAPA', 'ZACAPA'),
('1902', 'ZACAPA', 'ESTANZUELA'),
('1903', 'ZACAPA', 'RÍO HONDO'),
('1904', 'ZACAPA', 'GUALÁN'),
('1905', 'ZACAPA', 'TECULUTÁN'),
('1906', 'ZACAPA', 'USUMATLÁN'),
('1907', 'ZACAPA', 'CABAÑAS'),
('1908', 'ZACAPA', 'SAN DIEGO'),
('1909', 'ZACAPA', 'LA UNIÓN'),
('1910', 'ZACAPA', 'HUITÉ'),
('2001', 'CHIQUIMULA', 'CHIQUIMULA'),
('2002', 'CHIQUIMULA', 'SAN JOSÉ LA ARADA'),
('2003', 'CHIQUIMULA', 'SAN JUAN ERMITA'),
('2004', 'CHIQUIMULA', 'JOCOTÁN'),
('2005', 'CHIQUIMULA', 'CAMOTÁN'),
('2006', 'CHIQUIMULA', 'OLOPA'),
('2007', 'CHIQUIMULA', 'ESQUIPULAS'),
('2008', 'CHIQUIMULA', 'CONCEPCIÓN LAS MINAS'),
('2009', 'CHIQUIMULA', 'QUETZALTEPEQUE'),
('2010', 'CHIQUIMULA', 'SAN JACINTO'),
('2011', 'CHIQUIMULA', 'IPALA'),
('2101', 'JALAPA', 'JALAPA'),
('2102', 'JALAPA', 'SAN PEDRO PINULA'),
('2103', 'JALAPA', 'SAN LUIS JILOTEPEQUE'),
('2104', 'JALAPA', 'SAN MANUEL CHAPARRÓN'),
('2105', 'JALAPA', 'SAN CARLOS ALZATATE'),
('2106', 'JALAPA', 'MONJAS'),
('2107', 'JALAPA', 'MATAQUESCUINTLA'),
('2201', 'JUTIAPA', 'JUTIAPA'),
('2202', 'JUTIAPA', 'EL PROGRESO'),
('2203', 'JUTIAPA', 'SANTA CATARINA MITA'),
('2204', 'JUTIAPA', 'AGUA BLANCA'),
('2205', 'JUTIAPA', 'ASUNCIÓN MITA'),
('2206', 'JUTIAPA', 'YUPILTEPEQUE'),
('2207', 'JUTIAPA', 'ATESCATEMPA'),
('2208', 'JUTIAPA', 'JEREZ'),
('2209', 'JUTIAPA', 'EL ADELANTO'),
('2210', 'JUTIAPA', 'ZAPOTITLÁN'),
('2211', 'JUTIAPA', 'COMAPA'),
('2212', 'JUTIAPA', 'JALPATAGUA'),
('2213', 'JUTIAPA', 'CONGUACO'),
('2214', 'JUTIAPA', 'MOYUTA'),
('2215', 'JUTIAPA', 'PASACO'),
('2216', 'JUTIAPA', 'SAN JOSÉ ACATEMPA'),
('2217', 'JUTIAPA', 'QUESADA');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tipo_afectacion_iva`
--

CREATE TABLE `tipo_afectacion_iva` (
  `id` int(11) NOT NULL,
  `codigo` char(3) NOT NULL,
  `descripcion` varchar(150) DEFAULT NULL,
  `nombre_tributo` varchar(45) DEFAULT NULL,
  `porcentaje_impuesto` decimal(10,0) DEFAULT NULL,
  `estado` int(11) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tipo_afectacion_iva`
--

INSERT INTO `tipo_afectacion_iva` (`id`, `codigo`, `descripcion`, `nombre_tributo`, `porcentaje_impuesto`, `estado`) VALUES
(1, '5', 'SIN IVA', 'SIVA', 0, 1),
(2, '12', 'IVA GENERAL', 'IVA', 12, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tipo_comprobante`
--

CREATE TABLE `tipo_comprobante` (
  `id` int(11) NOT NULL,
  `codigo` varchar(3) NOT NULL,
  `descripcion` varchar(50) NOT NULL,
  `estado` int(11) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Volcado de datos para la tabla `tipo_comprobante`
--

INSERT INTO `tipo_comprobante` (`id`, `codigo`, `descripcion`, `estado`) VALUES
(1, '01', 'FACTURA', 1),
(2, '03', 'BOLETA', 1),
(7, 'RC', 'RESUMEN COMPROBANTES', 1),
(11, 'CTZ', 'COTIZACIÓN', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tipo_documento`
--

CREATE TABLE `tipo_documento` (
  `id` int(11) NOT NULL,
  `descripcion` varchar(45) NOT NULL,
  `estado` int(11) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tipo_documento`
--

INSERT INTO `tipo_documento` (`id`, `descripcion`, `estado`) VALUES
(0, 'SIN DOCUMENTO', 1),
(1, 'DPI', 1),
(4, 'NIT', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tipo_movimiento_caja`
--

CREATE TABLE `tipo_movimiento_caja` (
  `id` int(11) NOT NULL,
  `descripcion` varchar(150) DEFAULT NULL,
  `afecta_caja` int(11) DEFAULT NULL,
  `estado` int(11) DEFAULT 1,
  `fecha_registro` date DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tipo_movimiento_caja`
--

INSERT INTO `tipo_movimiento_caja` (`id`, `descripcion`, `afecta_caja`, `estado`, `fecha_registro`) VALUES
(1, 'DEVOLUCIÓN', 1, 1, '2024-03-18'),
(2, 'GASTO', 1, 1, '2024-03-18'),
(3, 'INGRESO VENTA EFECTIVO', 1, 1, '2024-03-18'),
(4, 'APERTURA', 1, 1, '2024-03-18'),
(8, 'INGRESO TRANSFERENCIA', 0, 1, '2024-03-18');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tipo_operacion`
--

CREATE TABLE `tipo_operacion` (
  `codigo` varchar(4) NOT NULL,
  `descripcion` varchar(255) NOT NULL,
  `estado` tinyint(4) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tipo_operacion`
--

INSERT INTO `tipo_operacion` (`codigo`, `descripcion`, `estado`) VALUES
('0101', 'Venta interna', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tipo_precio_venta_unitario`
--

CREATE TABLE `tipo_precio_venta_unitario` (
  `codigo` varchar(2) NOT NULL,
  `descripcion` varchar(255) NOT NULL,
  `estado` tinyint(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tipo_precio_venta_unitario`
--

INSERT INTO `tipo_precio_venta_unitario` (`codigo`, `descripcion`, `estado`) VALUES
('01', 'Precio unitario (incluye el iva)', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuarios`
--

CREATE TABLE `usuarios` (
  `id_usuario` int(11) NOT NULL,
  `nombre_usuario` varchar(100) DEFAULT NULL,
  `apellido_usuario` varchar(100) DEFAULT NULL,
  `usuario` varchar(100) DEFAULT NULL,
  `clave` text DEFAULT NULL,
  `id_perfil_usuario` int(11) DEFAULT NULL,
  `id_caja` int(11) DEFAULT 1,
  `email` varchar(150) DEFAULT NULL,
  `estado` tinyint(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Volcado de datos para la tabla `usuarios`
--

INSERT INTO `usuarios` (`id_usuario`, `nombre_usuario`, `apellido_usuario`, `usuario`, `clave`, `id_perfil_usuario`, `id_caja`, `email`, `estado`) VALUES
(14, 'ADMINISTRADOR', 'ADMINISTRADOR', 'admin', '$2a$07$azybxcags23425sdg23sdeanQZqjaf6Birm2NvcYTNtJw24CsO5uq', 1, 2, NULL, 1),
(32, 'Brayan', 'Tebelan', 'BrayanT', '$2a$07$azybxcags23425sdg23sde1r/z9K6yeAX7IcyjCPFWt2IdhvVXyV6', 16, 2, NULL, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `venta`
--

CREATE TABLE `venta` (
  `id` int(11) NOT NULL,
  `id_empresa_emisora` int(11) NOT NULL,
  `id_cliente` int(11) NOT NULL,
  `id_serie` int(11) NOT NULL,
  `serie` varchar(4) NOT NULL,
  `correlativo` int(11) NOT NULL,
  `tipo_comprobante_modificado` varchar(10) DEFAULT NULL,
  `id_serie_modificado` int(11) DEFAULT NULL,
  `correlativo_modificado` varchar(10) DEFAULT NULL,
  `fecha_emision` date NOT NULL,
  `hora_emision` varchar(10) NOT NULL,
  `id_moneda` varchar(3) NOT NULL,
  `forma_pago` varchar(45) NOT NULL,
  `medio_pago` varchar(45) NOT NULL,
  `tipo_operacion` varchar(10) NOT NULL,
  `total_iva` decimal(18,2) DEFAULT 0.00,
  `importe_total` decimal(18,2) DEFAULT 0.00,
  `efectivo_recibido` decimal(18,2) DEFAULT 0.00,
  `vuelto` decimal(18,2) DEFAULT 0.00,
  `nombre_xml` varchar(255) DEFAULT NULL,
  `xml_base64` text DEFAULT NULL,
  `xml_cdr_sat_base64` text DEFAULT NULL,
  `codigo_error_sat` text DEFAULT NULL,
  `mensaje_respuesta_sat` text DEFAULT NULL,
  `hash_signature` varchar(150) DEFAULT NULL,
  `estado_respuesta_sat` int(11) DEFAULT 0 COMMENT '1: Comprobante enviado correctamente - 2: Rechazado, enviado con errores - 0: Pendiente de envío - 3: Anulado sat',
  `estado_comprobante` int(11) DEFAULT 0 COMMENT '0: Pendiente de envío\n1: Registrado en sat\n2: Anulado sat',
  `id_usuario` int(11) DEFAULT NULL,
  `pagado` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `venta`
--

INSERT INTO `venta` (`id`, `id_empresa_emisora`, `id_cliente`, `id_serie`, `serie`, `correlativo`, `tipo_comprobante_modificado`, `id_serie_modificado`, `correlativo_modificado`, `fecha_emision`, `hora_emision`, `id_moneda`, `forma_pago`, `medio_pago`, `tipo_operacion`, `total_iva`, `importe_total`, `efectivo_recibido`, `vuelto`, `nombre_xml`, `xml_base64`, `xml_cdr_sat_base64`, `codigo_error_sat`, `mensaje_respuesta_sat`, `hash_signature`, `estado_respuesta_sat`, `estado_comprobante`, `id_usuario`, `pagado`) VALUES
(1, 1, 3, 2, 'BO01', 1, NULL, NULL, NULL, '2024-09-17', '19:14:45', 'GTQ', 'Contado', '1', '', 55.29, 516.00, 516.00, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0, 14, 1),
(2, 1, 3, 2, 'BO01', 2, NULL, NULL, NULL, '2024-09-17', '19:18:49', 'GTQ', 'Contado', '1', '', 30.21, 281.92, 281.92, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0, 14, 1),
(3, 1, 1, 2, 'BO01', 3, NULL, NULL, NULL, '2024-09-17', '19:52:39', 'GTQ', 'Contado', '1', '', 28.85, 269.22, 300.00, 30.78, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0, 14, 1),
(4, 1, 3, 2, 'BO01', 4, NULL, NULL, NULL, '2024-09-17', '19:58:34', 'GTQ', 'Contado', '1', '', 15.31, 142.89, 150.00, 7.11, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0, 14, 1),
(5, 1, 1, 2, 'BO01', 5, NULL, NULL, NULL, '2024-09-17', '20:00:04', 'GTQ', 'Contado', '1', '', 12.90, 120.41, 150.00, 29.59, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0, 14, 1),
(6, 1, 3, 2, 'BO01', 6, NULL, NULL, NULL, '2024-09-17', '22:31:38', 'GTQ', 'Contado', '1', '', 20.22, 188.74, 188.74, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0, 14, 1),
(7, 1, 1, 2, 'BO01', 7, NULL, NULL, NULL, '2024-09-17', '02:01:32', 'GTQ', 'Contado', '1', '', 0.00, 90.00, 100.00, 10.00, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0, 14, 1),
(8, 1, 2, 2, 'BO01', 8, NULL, NULL, NULL, '2024-09-17', '02:11:51', 'GTQ', 'Contado', '4', '', 11.43, 106.64, 110.00, 3.36, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0, 14, 1),
(9, 1, 3, 2, 'BO01', 9, NULL, NULL, NULL, '2024-09-17', '03:12:53', 'GTQ', 'Contado', '1', '', 6.94, 64.74, 64.74, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0, 14, 1),
(10, 1, 2, 2, 'BO01', 10, NULL, NULL, NULL, '2024-09-17', '04:28:23', 'GTQ', 'Contado', '1', '', 15.14, 141.35, 150.00, 8.65, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0, 32, 1),
(11, 1, 1, 2, 'BO01', 11, NULL, NULL, NULL, '2024-09-19', '21:59:30', 'GTQ', 'Contado', '1', '', 3.04, 28.34, 28.34, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0, 14, 1),
(12, 1, 2, 2, 'BO01', 12, NULL, NULL, NULL, '2024-09-28', '20:31:43', 'GTQ', 'Contado', '1', '', 9.70, 90.49, 90.49, 0.00, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0, 14, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `venta_detalle`
--

CREATE TABLE `venta_detalle` (
  `id` int(11) NOT NULL,
  `id_venta` int(11) DEFAULT NULL,
  `item` int(11) DEFAULT NULL,
  `codigo_producto` varchar(20) DEFAULT NULL,
  `descripcion` varchar(150) DEFAULT NULL,
  `porcentaje_iva` decimal(18,4) DEFAULT NULL,
  `cantidad` decimal(18,4) DEFAULT NULL,
  `costo_unitario` decimal(18,4) DEFAULT NULL,
  `valor_unitario` decimal(18,4) DEFAULT NULL,
  `precio_unitario` decimal(18,4) DEFAULT NULL,
  `valor_total` decimal(18,4) DEFAULT NULL,
  `iva` decimal(18,4) DEFAULT NULL,
  `importe_total` decimal(18,4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `arqueo_caja`
--
ALTER TABLE `arqueo_caja`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `cajas`
--
ALTER TABLE `cajas`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `categorias`
--
ALTER TABLE `categorias`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `clientes`
--
ALTER TABLE `clientes`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `codigo_unidad_medida`
--
ALTER TABLE `codigo_unidad_medida`
  ADD UNIQUE KEY `id_UNIQUE` (`id`);

--
-- Indices de la tabla `compras`
--
ALTER TABLE `compras`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `configuraciones`
--
ALTER TABLE `configuraciones`
  ADD PRIMARY KEY (`id`,`ordinal`);

--
-- Indices de la tabla `cotizaciones`
--
ALTER TABLE `cotizaciones`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `cotizaciones_detalle`
--
ALTER TABLE `cotizaciones_detalle`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `cuotas`
--
ALTER TABLE `cuotas`
  ADD PRIMARY KEY (`id`) USING BTREE;

--
-- Indices de la tabla `cuotas_compras`
--
ALTER TABLE `cuotas_compras`
  ADD PRIMARY KEY (`id`) USING BTREE;

--
-- Indices de la tabla `detalle_compra`
--
ALTER TABLE `detalle_compra`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_cod_producto_idx` (`codigo_producto`),
  ADD KEY `fk_id_compra_idx` (`id_compra`);

--
-- Indices de la tabla `detalle_venta`
--
ALTER TABLE `detalle_venta`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `empresas`
--
ALTER TABLE `empresas`
  ADD PRIMARY KEY (`id_empresa`);

--
-- Indices de la tabla `forma_pago`
--
ALTER TABLE `forma_pago`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `historico_cargas_masivas`
--
ALTER TABLE `historico_cargas_masivas`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `impuestos`
--
ALTER TABLE `impuestos`
  ADD PRIMARY KEY (`id_tipo_operacion`);

--
-- Indices de la tabla `kardex`
--
ALTER TABLE `kardex`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_id_producto_idx` (`codigo_producto`);

--
-- Indices de la tabla `medio_pago`
--
ALTER TABLE `medio_pago`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `modulos`
--
ALTER TABLE `modulos`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `moneda`
--
ALTER TABLE `moneda`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `movimientos_arqueo_caja`
--
ALTER TABLE `movimientos_arqueo_caja`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `perfiles`
--
ALTER TABLE `perfiles`
  ADD PRIMARY KEY (`id_perfil`);

--
-- Indices de la tabla `productos`
--
ALTER TABLE `productos`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `codigo_producto_UNIQUE` (`codigo_producto`),
  ADD KEY `fk_id_categoria_idx` (`id_categoria`);

--
-- Indices de la tabla `proveedores`
--
ALTER TABLE `proveedores`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `resumenes`
--
ALTER TABLE `resumenes`
  ADD PRIMARY KEY (`id`) USING BTREE;

--
-- Indices de la tabla `resumenes_detalle`
--
ALTER TABLE `resumenes_detalle`
  ADD PRIMARY KEY (`id`) USING BTREE,
  ADD KEY `fk_id_envio` (`id_envio`) USING BTREE,
  ADD KEY `fk_idventa` (`id_comprobante`) USING BTREE;

--
-- Indices de la tabla `serie`
--
ALTER TABLE `serie`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `tb_ubigeos`
--
ALTER TABLE `tb_ubigeos`
  ADD PRIMARY KEY (`ubigeo_renap`);

--
-- Indices de la tabla `tipo_afectacion_iva`
--
ALTER TABLE `tipo_afectacion_iva`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `tipo_comprobante`
--
ALTER TABLE `tipo_comprobante`
  ADD PRIMARY KEY (`id`,`codigo`);

--
-- Indices de la tabla `tipo_documento`
--
ALTER TABLE `tipo_documento`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `tipo_movimiento_caja`
--
ALTER TABLE `tipo_movimiento_caja`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `tipo_operacion`
--
ALTER TABLE `tipo_operacion`
  ADD PRIMARY KEY (`codigo`);

--
-- Indices de la tabla `tipo_precio_venta_unitario`
--
ALTER TABLE `tipo_precio_venta_unitario`
  ADD PRIMARY KEY (`codigo`);

--
-- Indices de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD PRIMARY KEY (`id_usuario`),
  ADD KEY `id_perfil_usuario` (`id_perfil_usuario`),
  ADD KEY `fk_id_caja_idx` (`id_caja`);

--
-- Indices de la tabla `venta`
--
ALTER TABLE `venta`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `venta_detalle`
--
ALTER TABLE `venta_detalle`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `arqueo_caja`
--
ALTER TABLE `arqueo_caja`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT de la tabla `cajas`
--
ALTER TABLE `cajas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `categorias`
--
ALTER TABLE `categorias`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT de la tabla `clientes`
--
ALTER TABLE `clientes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `compras`
--
ALTER TABLE `compras`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT de la tabla `cotizaciones`
--
ALTER TABLE `cotizaciones`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `cotizaciones_detalle`
--
ALTER TABLE `cotizaciones_detalle`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `cuotas`
--
ALTER TABLE `cuotas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `cuotas_compras`
--
ALTER TABLE `cuotas_compras`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `detalle_compra`
--
ALTER TABLE `detalle_compra`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- AUTO_INCREMENT de la tabla `detalle_venta`
--
ALTER TABLE `detalle_venta`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=27;

--
-- AUTO_INCREMENT de la tabla `empresas`
--
ALTER TABLE `empresas`
  MODIFY `id_empresa` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `forma_pago`
--
ALTER TABLE `forma_pago`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `historico_cargas_masivas`
--
ALTER TABLE `historico_cargas_masivas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT de la tabla `kardex`
--
ALTER TABLE `kardex`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=123;

--
-- AUTO_INCREMENT de la tabla `medio_pago`
--
ALTER TABLE `medio_pago`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `modulos`
--
ALTER TABLE `modulos`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=58;

--
-- AUTO_INCREMENT de la tabla `movimientos_arqueo_caja`
--
ALTER TABLE `movimientos_arqueo_caja`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=45;

--
-- AUTO_INCREMENT de la tabla `perfiles`
--
ALTER TABLE `perfiles`
  MODIFY `id_perfil` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT de la tabla `productos`
--
ALTER TABLE `productos`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=89;

--
-- AUTO_INCREMENT de la tabla `proveedores`
--
ALTER TABLE `proveedores`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `resumenes`
--
ALTER TABLE `resumenes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `resumenes_detalle`
--
ALTER TABLE `resumenes_detalle`
  MODIFY `id` int(255) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `serie`
--
ALTER TABLE `serie`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `tipo_afectacion_iva`
--
ALTER TABLE `tipo_afectacion_iva`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `tipo_comprobante`
--
ALTER TABLE `tipo_comprobante`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT de la tabla `tipo_movimiento_caja`
--
ALTER TABLE `tipo_movimiento_caja`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  MODIFY `id_usuario` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=33;

--
-- AUTO_INCREMENT de la tabla `venta`
--
ALTER TABLE `venta`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT de la tabla `venta_detalle`
--
ALTER TABLE `venta_detalle`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `detalle_compra`
--
ALTER TABLE `detalle_compra`
  ADD CONSTRAINT `fk_cod_producto` FOREIGN KEY (`codigo_producto`) REFERENCES `productos` (`codigo_producto`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_id_compra` FOREIGN KEY (`id_compra`) REFERENCES `compras` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla `kardex`
--
ALTER TABLE `kardex`
  ADD CONSTRAINT `fk_cod_producto_kardex` FOREIGN KEY (`codigo_producto`) REFERENCES `productos` (`codigo_producto`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla `productos`
--
ALTER TABLE `productos`
  ADD CONSTRAINT `fk_id_categoria` FOREIGN KEY (`id_categoria`) REFERENCES `categorias` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `resumenes_detalle`
--
ALTER TABLE `resumenes_detalle`
  ADD CONSTRAINT `fk_id_envio` FOREIGN KEY (`id_envio`) REFERENCES `resumenes` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD CONSTRAINT `fk_id_caja` FOREIGN KEY (`id_caja`) REFERENCES `cajas` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `usuarios_ibfk_1` FOREIGN KEY (`id_perfil_usuario`) REFERENCES `perfiles` (`id_perfil`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
