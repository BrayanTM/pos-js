<?php

session_start();

require_once "conexion.php";
require_once "configuraciones.modelo.php";
require_once "empresas.modelo.php";
require_once "clientes.modelo.php";
// require_once "vendor/autoload.php";

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\SMTP;
use PHPMailer\PHPMailer\Exception;

//Load Composer's autoloader
require '../vendor/autoload.php';

class VentasModelo
{

    public $resultado;


    static public function mdlObtenerNroBoleta()
    {

        $stmt = Conexion::conectar()->prepare("call prc_obtenerNroBoleta()");

        $stmt->execute();

        return $stmt->fetch(PDO::FETCH_OBJ);
    }


    static public function mdlObtenerTipoMovimientoCajaPorMedioPago($id_medio_pago)
    {


        $stmt = Conexion::conectar()->prepare("SELECT mp.id as id_medio_pago,
                                                    mp.id_tipo_movimiento_caja,
                                                    tmc.afecta_caja,
                                                    mp.descripcion as medio_pago
                                            FROM medio_pago mp inner join tipo_movimiento_caja tmc on mp.id_tipo_movimiento_caja = tmc.id
                                            WHERE mp.id = :id_medio_pago");

        $stmt->bindParam(":id_medio_pago", $id_medio_pago, PDO::PARAM_STR);

        $stmt->execute();

        return $stmt->fetch();
    }
    /* =========================================================================================
    R E G I S T R A R   V E N T A
    ========================================================================================= */
    static public function mdlRegistrarVenta($venta, $detalle_venta, $id_caja)
    {

        $id_usuario = $_SESSION["usuario"]->id_usuario;

        $date = date('Y-m-d');

        $dbh = Conexion::conectar();

        if ($venta['forma_pago'] == 'Credito') {
            $pagado = 0;
        } else {
            $pagado = 1;
        }

        //ELIMINAR TABLAS DEL SISTEMA
        try {

            $stmt = $dbh->prepare("INSERT INTO venta(id_empresa_emisora, 
                                                    id_cliente, 
                                                    id_serie, 
                                                    serie, 
                                                    correlativo, 
                                                    fecha_emision, 
                                                    hora_emision, 
                                                    id_moneda, 
                                                    forma_pago, 
                                                    medio_pago,
                                                    total_iva, 
                                                    importe_total,
                                                    efectivo_recibido,
                                                    vuelto,
                                                    id_usuario,
                                                    pagado)
            VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
            $dbh->beginTransaction();
            $stmt->execute(array(
                $venta['id_empresa_emisora'],
                $venta['id_cliente'],
                $venta['id_serie'],
                $venta['serie'],
                $venta['correlativo'],
                $venta['fecha_emision'],
                $venta['hora_emision'],
                $venta['moneda'],
                $venta['forma_pago'],
                $venta['medio_pago'],
                $venta['total_iva'],
                $venta['total_a_pagar'],
                $venta['efectivo_recibido'],
                $venta['vuelto'],
                $id_usuario,
                $pagado
            ));
            $id_venta = $dbh->lastInsertId();
            $dbh->commit();

            $stmt = $dbh->prepare("UPDATE serie
                                     SET correlativo = correlativo + 1 
                                    WHERE id = ?");
            $dbh->beginTransaction();
            $stmt->execute(array(
                $venta['id_serie']
            ));
            $dbh->commit();

            //GUARDAR EL DETALLE DE LA VENTA:
            foreach ($detalle_venta as $producto) {

                $stmt = $dbh->prepare("INSERT INTO detalle_venta(id_venta, 
                                                                item, 
                                                                codigo_producto, 
                                                                descripcion, 
                                                                porcentaje_iva, 
                                                                cantidad, 
                                                                costo_unitario,
                                                                valor_unitario, 
                                                                precio_unitario, 
                                                                valor_total, 
                                                                iva, 
                                                                importe_total)
                            VALUES(?,?,?,?,?,?,?,?,?,?,?,?)");
                $dbh->beginTransaction();
                $stmt->execute(array(
                    $id_venta,
                    $producto['item'],
                    $producto['codigo'],
                    $producto['descripcion'],
                    $producto['porcentaje_iva'],
                    $producto['cantidad'],
                    $producto['costo_unitario'],
                    $producto['valor_unitario'],
                    $producto['precio_unitario'],
                    $producto['valor_total'],
                    $producto['iva'],
                    $producto['importe_total']
                ));
                $dbh->commit();


                //*************************************************************************** */
                // R E G I S T R A M O S   E L   I N G R E S O   E N   M O V I M I E N T O S
                //*************************************************************************** */

                $tipo_movimiento_caja = VentasModelo::mdlObtenerTipoMovimientoCajaPorMedioPago($venta['medio_pago']);

                $stmt = $dbh->prepare("INSERT INTO movimientos_arqueo_caja(id_arqueo_caja, 
                                                                                id_tipo_movimiento, 
                                                                                descripcion, 
                                                                                monto, 
                                                                                comprobante,
                                                                                estado)
                                                                        VALUES(:id_arqueo_caja, 
                                                                                :id_tipo_movimiento, 
                                                                                :descripcion, 
                                                                                :monto, 
                                                                                :comprobante,
                                                                                :estado)");

                $dbh->beginTransaction();
                $stmt->execute(array(
                    ':id_arqueo_caja' => $id_caja,
                    ':id_tipo_movimiento' => $venta['forma_pago'] == "Credito" ? 10 : $tipo_movimiento_caja["id_tipo_movimiento_caja"],
                    ':descripcion' => 'INGRESO - ' . ($venta['forma_pago'] == "Credito" ? "VENTA AL CREDITO" : $tipo_movimiento_caja['medio_pago']),
                    ':monto' =>  $producto['importe_total'],
                    ':comprobante' => $venta['serie'] . '-' . $venta['correlativo'],
                    ':estado' => 1
                ));
                $dbh->commit();

                if ($tipo_movimiento_caja["afecta_caja"] == "1" && $venta["forma_pago"] == "Contado") {

                    //*************************************************************************** */
                    // A C T U A L I Z A M O S   E L   I N G R E S O   A   C A J A
                    //*************************************************************************** */
                    $stmt = $dbh->prepare("UPDATE arqueo_caja
                                            SET ingresos = round(ifnull(ingresos,0) + :importe_venta,2),
                                                monto_final = ifnull(monto_apertura,0) + ifnull(ingresos,0) - ifnull(devoluciones,0) - ifnull(gastos,0)
                                        WHERE id = :id_caja");

                    $dbh->beginTransaction();
                    $stmt->execute(array(
                        ':importe_venta' => $producto['importe_total'],
                        ':id_caja' => $id_caja
                    ));
                    $dbh->commit();
                }

                //*************************************************************************** */
                // R E G I S T R A M O S   E L   K A R D E X   D E   S A L I D A S
                //*************************************************************************** */
                $concepto = 'VENTA';

                $stmt = Conexion::conectar()->prepare("call prc_registrar_kardex_venta (?,?,?,?,?)");

                $dbh->beginTransaction();
                $stmt->execute(array(
                    $producto['codigo'],
                    $date,
                    $concepto,
                    $venta['serie'] . '-' . $venta['correlativo'],
                    $producto['cantidad']

                ));
                $dbh->commit();
            }
        } catch (Exception $e) {
            $dbh->rollBack();
            return 0;
        }

        return $id_venta;
    }

    static public function mdlListarVentas($fechaDesde, $fechaHasta)
    {

        try {

            $stmt = Conexion::conectar()->prepare("SELECT Concat('Boleta Nro: ',v.nro_boleta,' - Total Venta: S./ ',Round(vc.total_venta,2)) as nro_boleta,
                                                            v.codigo_producto,
                                                            c.nombre_categoria,
                                                            p.descripcion_producto,
                                                            case when c.aplica_peso = 1 then concat(v.cantidad,' Kg(s)')
                                                            else concat(v.cantidad,' Und(s)') end as cantidad,                            
                                                            concat('S./ ',round(v.total_venta,2)) as total_venta,
                                                            v.fecha_venta
                                                            FROM venta_detalle v inner join productos p on v.codigo_producto = p.codigo_producto
                                                                                inner join venta_cabecera vc on cast(vc.nro_boleta as integer) = cast(v.nro_boleta as integer)
                                                                                inner join categorias c on c.id_categoria = p.id_categoria_producto
                                                    where DATE(v.fecha_venta) >= date(:fechaDesde) and DATE(v.fecha_venta) <= date(:fechaHasta)
                                                    order by v.nro_boleta asc");

            $stmt->bindParam(":fechaDesde", $fechaDesde, PDO::PARAM_STR);
            $stmt->bindParam(":fechaHasta", $fechaHasta, PDO::PARAM_STR);

            $stmt->execute();

            return $stmt->fetchAll();
        } catch (Exception $e) {
            return 'Excepción capturada: ' .  $e->getMessage() . "\n";
        }


        $stmt = null;
    }

    static public function mdlObtenerDetalleVenta($nro_boleta)
    {

        try {

            $stmt = Conexion::conectar()->prepare("select concat('B001-',vc.nro_boleta) as nro_boleta,
                                                        vc.total_venta,
                                                        vc.fecha_venta,
                                                        vd.codigo_producto,
                                                        upper(p.descripcion_producto) as descripcion_producto,
                                                        vd.cantidad,
                                                        vd.precio_unitario_venta,
                                                        vd.total_venta
                                                from venta_cabecera vc inner join venta_detalle vd on vc.nro_boleta = vd.nro_boleta
                                                                        inner join productos p on p.codigo_producto = vd.codigo_producto
                                                where vc.nro_boleta =  :nro_boleta");

            $stmt->bindParam(":nro_boleta", $nro_boleta, PDO::PARAM_STR);

            $stmt->execute();

            return $stmt->fetchAll();
        } catch (Exception $e) {
            return 'Excepción capturada: ' .  $e->getMessage() . "\n";
        }
    }

    /* =========================================================================================
    
    ========================================================================================= */
    static public function mdlObtenerTipoComprobante()
    {
        $stmt = Conexion::conectar()->prepare("select id,concat(codigo,'-',descripcion) as descripcion  from tipo_comprobante where estado = 1;");
        $stmt->execute();
        return $stmt->fetchAll();
    }

    /* =========================================================================================
    
    ========================================================================================= */
    static public function mdlObtenerMoneda()
    {
        $stmt = Conexion::conectar()->prepare("select id, concat(id, ' - ', descripcion) as descripcion  from moneda where estado = 1;");
        $stmt->execute();
        return $stmt->fetchAll();
    }

    static public function mdlObtenerSimboloMoneda($moneda)
    {
        $stmt = Conexion::conectar()->prepare("SELECT m.*  
                                                FROM moneda m
                                                where m.id = :id_moneda
                                                AND estado = 1");

        $stmt->bindParam(":id_moneda", $moneda, PDO::PARAM_STR);
        $stmt->execute();
        return $stmt->fetch();
    }


    /* =========================================================================================
    
    ========================================================================================= */
    static public function mdlObtenerTipoDocumento()
    {
        $stmt = Conexion::conectar()->prepare("select id,concat(id, ' - ', descripcion) as descripcion  from tipo_documento where estado = 1;");
        $stmt->execute();
        return $stmt->fetchAll();
    }

    /* =========================================================================================
    
    ========================================================================================= */
    static public function mdlObtenerTipoOperacion()
    {
        $stmt = Conexion::conectar()->prepare("select codigo,concat(codigo, ' - ', descripcion) as descripcion  from tipo_operacion where estado = 1;");
        $stmt->execute();
        return $stmt->fetchAll();
    }

    /* =========================================================================================
    
    ========================================================================================= */
    static public function mdlObtenerSerieComprobante($id_filtro)
    {
        $stmt = Conexion::conectar()->prepare("select id,serie as descripcion  
                                            from serie where estado = 1 and id_tipo_comprobante = :id_filtro");
        $stmt->bindParam(":id_filtro", $id_filtro, PDO::PARAM_STR);
        $stmt->execute();
        return $stmt->fetchAll();
    }

    /* =========================================================================================
    
    ========================================================================================= */
    static public function mdlObtenerCorrelativoSerie($id_serie)
    {
        $stmt = Conexion::conectar()->prepare("SELECT (correlativo  + 1) as correlativo
                                                FROM serie 
                                                WHERE estado = 1 
                                                AND id = :id_serie");
        $stmt->bindParam(":id_serie", $id_serie, PDO::PARAM_STR);
        $stmt->execute();
        return $stmt->fetch(PDO::FETCH_OBJ);
    }

    /* =========================================================================================
    
    ========================================================================================= */
    static public function mdlObtenerFormaPago()
    {
        $stmt = Conexion::conectar()->prepare("select id, descripcion  
                                            from forma_pago where estado = 1 ");
        $stmt->execute();
        return $stmt->fetchAll();
    }

    static public function mdlObtenerMedioPago()
    {
        $stmt = Conexion::conectar()->prepare("select id, descripcion  
                                            from medio_pago where estado = 1 ");
        $stmt->execute();
        return $stmt->fetchAll();
    }

    /* =========================================================================================
    
    ========================================================================================= */
    static public function mdlObtenerDatosEmisor($id_empresa)
    {
        $stmt = Conexion::conectar()->prepare("SELECT id_empresa, 
                                                        razon_social, 
                                                        nombre_comercial, 
                                                        id_tipo_documento as tipo_documento, 
                                                        nit, 
                                                        direccion, 
                                                        simbolo_moneda, 
                                                        email, 
                                                        telefono, 
                                                        departamento, 
                                                        municipio, 
                                                        ubigeo, 
                                                        usuario_sat, 
                                                        clave_sat,
                                                        certificado_digital,
                                                        clave_certificado
                                                FROM empresas
                                                where id_empresa = :id_empresa");
        $stmt->bindParam(":id_empresa", $id_empresa, PDO::PARAM_STR);
        $stmt->execute();
        return $stmt->fetch(PDO::FETCH_NAMED);
    }

    static public function mdlObtenerDatosEmisorDefecto()
    {
        $stmt = Conexion::conectar()->prepare("SELECT id_empresa, 
                                                        razon_social, 
                                                        nombre_comercial, 
                                                        id_tipo_documento as tipo_documento, 
                                                        nit, 
                                                        direccion, 
                                                        simbolo_moneda, 
                                                        email, 
                                                        telefono, 
                                                        departamento, 
                                                        municipio, 
                                                        ubigeo, 
                                                        usuario_sat, 
                                                        clave_sat,
                                                        certificado_digital,
                                                        clave_certificado
                                                FROM empresas
                                                LIMIT 1");

        $stmt->execute();
        return $stmt->fetch(PDO::FETCH_NAMED);
    }

    /* =========================================================================================
    
    ========================================================================================= */
    static public function mdlObtenerDatosCliente($tipo_documento, $nro_documento, $nombre_razon_social, $direccion, $telefono)
    {

        $stmt = Conexion::conectar()->prepare("SELECT id, 
                                                    id_tipo_documento as tipo_documento, 
                                                    nro_documento, 
                                                    nombres_apellidos_razon_social, 
                                                    direccion, 
                                                    telefono
                                                FROM clientes 
                                                where id_tipo_documento = :id_tipo_documento
                                                AND nro_documento = :nro_documento");

        $stmt->bindParam(":id_tipo_documento", $tipo_documento, PDO::PARAM_STR);
        $stmt->bindParam(":nro_documento", $nro_documento, PDO::PARAM_STR);
        $stmt->execute();

        $datos_cliente = $stmt->fetch(PDO::FETCH_NAMED);

        if ($datos_cliente) {
            return $datos_cliente;
        } else {

            $nro_documento = trim($nro_documento);

            $stmt = Conexion::conectar()->prepare("INSERT INTO clientes(id_tipo_documento, 
                                                                        nro_documento, 
                                                                        nombres_apellidos_razon_social, 
                                                                        direccion, 
                                                                        telefono)
                                                VALUES(:id_tipo_documento, 
                                                        trim(:nro_documento), 
                                                        :nombres_apellidos_razon_social, 
                                                        :direccion, 
                                                        :telefono)");

            $stmt->bindParam(":id_tipo_documento", $tipo_documento, PDO::PARAM_STR);
            $stmt->bindParam(":nro_documento", $nro_documento, PDO::PARAM_STR);
            $stmt->bindParam(":nombres_apellidos_razon_social", $nombre_razon_social, PDO::PARAM_STR);
            $stmt->bindParam(":direccion", $direccion, PDO::PARAM_STR);
            $stmt->bindParam(":telefono", $telefono, PDO::PARAM_STR);

            $stmt->execute();

            $stmt = Conexion::conectar()->prepare("SELECT id, 
                                                            id_tipo_documento as tipo_documento, 
                                                            nro_documento, 
                                                            nombres_apellidos_razon_social, 
                                                            direccion, 
                                                            telefono
                                                        FROM clientes 
                                                        where id_tipo_documento = :id_tipo_documento
                                                        AND nro_documento = :nro_documento");

            $stmt->bindParam(":id_tipo_documento", $tipo_documento, PDO::PARAM_STR);
            $stmt->bindParam(":nro_documento", $nro_documento, PDO::PARAM_STR);
            $stmt->execute();

            return $stmt->fetch(PDO::FETCH_NAMED);
        }
    }

    static public function mdlObtenerDatosClientePorId($id_cliente)
    {

        $stmt = Conexion::conectar()->prepare("SELECT id, 
                                                    id_tipo_documento as tipo_documento, 
                                                    nro_documento, 
                                                    nombres_apellidos_razon_social, 
                                                    direccion, 
                                                    telefono
                                                FROM clientes 
                                                where id = :id_cliente");

        $stmt->bindParam(":id_cliente", $id_cliente, PDO::PARAM_STR);
        $stmt->execute();

        return $stmt->fetch(PDO::FETCH_NAMED);
    }

    /* =========================================================================================
    
    ========================================================================================= */
    static public function mdlObtenerDatosClienteXml($id_cliente)
    {

        $stmt = Conexion::conectar()->prepare("SELECT id, 
                                                    id_tipo_documento as tipo_documento, 
                                                    nro_documento, 
                                                    nombres_apellidos_razon_social, 
                                                    direccion, 
                                                    telefono
                                                FROM clientes 
                                                where id = :id_cliente");

        $stmt->bindParam(":id_cliente", $id_cliente, PDO::PARAM_STR);
        $stmt->execute();

        return $stmt->fetch(PDO::FETCH_NAMED);
    }

    /* =========================================================================================
    
    ========================================================================================= */
    static public function mdlObtenerSerie($id_serie)
    {
        $stmt = Conexion::conectar()->prepare("SELECT *
                                                FROM serie 
                                                where id = :id_serie");
        $stmt->bindParam(":id_serie", $id_serie, PDO::PARAM_STR);
        $stmt->execute();
        return $stmt->fetch(PDO::FETCH_NAMED);
    }

    static public function mdlObtenerSeriePorTipo($id_tipo_comprobante)
    {
        $stmt = Conexion::conectar()->prepare("SELECT *
                                                FROM serie 
                                                where id_tipo_comprobante = :id_tipo_comprobante
                                                LIMIT 1");

        $stmt->bindParam(":id_tipo_comprobante", $id_tipo_comprobante, PDO::PARAM_STR);
        $stmt->execute();
        return $stmt->fetch();
    }

    /* =========================================================================================
    
    ========================================================================================= */
    static public function ObtenerTipoAfectacionIVA($id_tipo_afectacion)
    {
        $stmt = Conexion::conectar()->prepare("SELECT *
                                                FROM tipo_afectacion_iva 
                                                where estado = 1
                                                and codigo = :id_tipo_afectacion");
        $stmt->bindParam(":id_tipo_afectacion", $id_tipo_afectacion, PDO::PARAM_STR);
        $stmt->execute();
        return $stmt->fetch(PDO::FETCH_NAMED);
    }

    /* =========================================================================================
    
    ========================================================================================= */
    static public function ObtenerCostoUnitarioUnidadMedida($codigo_producto)
    {
        $stmt = Conexion::conectar()->prepare("SELECT costo_unitario, id_unidad_medida
                                                FROM productos 
                                                where codigo_producto = :codigo_producto");
        $stmt->bindParam(":codigo_producto", $codigo_producto, PDO::PARAM_STR);
        $stmt->execute();
        return $stmt->fetch(PDO::FETCH_NAMED);
    }

    /* =========================================================================================
    
    ========================================================================================= */
    static public function mdlObtenerListadoBoletas($post)
    {

        $id_usuario = $_SESSION["usuario"]->id_usuario;

        $columns = [
            "id",
            "comprobante",
            "forma_pago",
            "fecha_emision",
            "total_iva",
            "importe_total"

        ];

        $query = ' SELECT 
                         "" as opciones,
                         v.id,
                        concat(v.serie,"-",v.correlativo) as comprobante, 
                        v.fecha_emision,
                        upper(forma_pago) as forma_pago,
                        concat(mon.simbolo,format(v.total_iva,2)) as iva,
                        concat(mon.simbolo,format(v.importe_total,2)) as importe_total
                from venta v inner join serie s on v.id_serie = s.id
                             inner join moneda mon on mon.id = v.id_moneda';

        // var_dump($post["search"]["value"]);

        if (isset($post["search"]["value"])) {
            $query .= '  WHERE s.id_tipo_comprobante = "03"
                        AND v.id_usuario = "' . $id_usuario . '"
                        AND (v.serie like "%' . $post["search"]["value"] . '%"
                             or v.correlativo like "%' . $post["search"]["value"] . '%"
                             or concat(v.serie,"-",v.correlativo) like "%' . $post["search"]["value"] . '%"
                             or v.fecha_emision like "%' . $post["search"]["value"] . '%")';
        }

        if (isset($post["order"])) {
            $query .= ' ORDER BY ' . $columns[$post['order']['0']['column']] . ' ' . $post['order']['0']['dir'] . ' ';
        } else {
            $query .= ' ORDER BY v.id desc ';
        }

        //SE AGREGA PAGINACION
        if ($post["length"] != -1) {
            $query1 = " LIMIT " . $post["start"] . ", " . $post["length"];
        }

        $stmt = Conexion::conectar()->prepare($query);

        // var_dump($query);

        $stmt->execute();

        $number_filter_row = $stmt->rowCount();

        $stmt =  Conexion::conectar()->prepare($query . $query1);

        $stmt->execute();

        $results = $stmt->fetchAll(PDO::FETCH_NAMED);

        $data = array();

        foreach ($results as $row) {
            $sub_array = array();
            $sub_array[] = $row['opciones']; //0
            $sub_array[] = $row['id']; //1
            $sub_array[] = $row['comprobante']; //2
            $sub_array[] = $row['fecha_emision']; //3
            $sub_array[] = $row['forma_pago']; //4
            $sub_array[] = $row['iva']; //5
            $sub_array[] = $row['importe_total']; //6
            $data[] = $sub_array;
        }

        $stmt = Conexion::conectar()->prepare(" SELECT 1
                                                from venta v inner join serie s on v.id_serie = s.id
                                                where s.id_tipo_comprobante = '03'");

        $stmt->execute();

        $count_all_data = $stmt->rowCount();

        $clientes = array(
            'draw' => $post['draw'],
            "recordsTotal" => $count_all_data,
            "recordsFiltered" => $number_filter_row,
            "data" => $data
        );

        return $clientes;
    }

    /* =========================================================================================
    
    ========================================================================================= */
    static public function mdlObtenerListadoBoletasPorFecha($post, $fecha_emision, $id_empresa)
    {

        $columns = [
            "id",
            "comprobante",
            "fecha_emision",
            "total_iva",
            "importe_total"
        ];

        $query = " SELECT 
                         v.id,
                        concat(v.serie,'-',v.correlativo) as comprobante, 
                        v.fecha_emision,
                        concat(mon.simbolo,format(v.total_iva,2)) as iva,
                        concat(mon.simbolo,format(v.importe_total,2)) as importe_total
                from venta v inner join serie s on v.id_serie = s.id
                             inner join moneda mon on mon.id = v.id_moneda";

        if (isset($post["search"]["value"])) {
            $query .= '  WHERE s.id_tipo_comprobante = "03"  
                        AND date(v.fecha_emision) = "' . $fecha_emision . '"
                        AND v.id_empresa_emisora = "' . $id_empresa . '"
                        AND ifnull(estado_respuesta_sat,0) <> 1
                        AND ( v.serie like "%' . $post["search"]["value"] . '%" 
                                or ( case when v.estado_respuesta_sat = 2 then "Enviado, con errores"
                                when v.estado_respuesta_sat = 1 then "Comprobante enviado correctamente"
                                when v.estado_respuesta_sat is null then "Pendiente de envío"
                            end) like "%' . $post["search"]["value"] . '%"                      
                        or v.correlativo like "%' . $post["search"]["value"] . '%")';
        }

        if (isset($post["order"])) {
            $query .= ' ORDER BY ' . $columns[$post['order']['0']['column']] . ' ' . $post['order']['0']['dir'] . ' ';
        } else {
            $query .= ' ORDER BY v.id desc ';
        }

        //SE AGREGA PAGINACION
        if ($post["length"] != -1) {
            $query1 = " LIMIT " . $post["start"] . ", " . $post["length"];
        }

        $stmt = Conexion::conectar()->prepare($query);

        $stmt->execute();

        $number_filter_row = $stmt->rowCount();

        $stmt =  Conexion::conectar()->prepare($query . $query1);

        $stmt->execute();

        $results = $stmt->fetchAll(PDO::FETCH_NAMED);

        $data = array();

        foreach ($results as $row) {
            $sub_array = array();
            $sub_array[] = $row['id'];
            $sub_array[] = $row['comprobante'];
            $sub_array[] = $row['fecha_emision'];
            $sub_array[] = $row['iva'];
            $sub_array[] = $row['importe_total'];
            $data[] = $sub_array;
        }

        $stmt = Conexion::conectar()->prepare(" SELECT 1
                                                from venta v inner join serie s on v.id_serie = s.id
                                                where s.id_tipo_comprobante = '03'");

        $stmt->execute();

        $count_all_data = $stmt->rowCount();

        $clientes = array(
            'draw' => $post['draw'],
            "recordsTotal" => $count_all_data,
            "recordsFiltered" => $number_filter_row,
            "data" => $data
        );

        return $clientes;
    }

    static public function mdlObtenerListadoBoletasPorDia($post)
    {
        $id_usuario = $_SESSION["usuario"]->id_usuario;

        $columns = [
            "id",
            "comprobante",
            "forma_pago",
            "fecha_emision",
            "total_iva",
            "importe_total"

        ];

        $query = ' SELECT 
                         "" as opciones,
                         v.id,
                        concat(v.serie,"-",v.correlativo) as comprobante, 
                        v.fecha_emision,
                        upper(forma_pago) as forma_pago,
                        concat(mon.simbolo,format(v.total_iva,2)) as iva,
                        concat(mon.simbolo,format(v.importe_total,2)) as importe_total
                from venta v inner join serie s on v.id_serie = s.id
                             inner join moneda mon on mon.id = v.id_moneda';

        if (isset($post["search"]["value"])) {
            $query .= '  WHERE s.id_tipo_comprobante = "03"
                AND date(v.fecha_emision) = CURDATE()
                AND v.id_usuario = "' . $id_usuario . '"
                AND (v.serie like "%' . $post["search"]["value"] . '%"
                     or v.correlativo like "%' . $post["search"]["value"] . '%"
                     or concat(v.serie,"-",v.correlativo) like "%' . $post["search"]["value"] . '%"
                     or v.fecha_emision like "%' . $post["search"]["value"] . '%")';
        }

        if (isset($post["order"])) {
            $query .= ' ORDER BY ' . $columns[$post['order']['0']['column']] . ' ' . $post['order']['0']['dir'] . ' ';
        } else {
            $query .= ' ORDER BY v.id desc ';
        }

        //SE AGREGA PAGINACION
        if ($post["length"] != -1) {
            $query1 = " LIMIT " . $post["start"] . ", " . $post["length"];
        }

        $stmt = Conexion::conectar()->prepare($query);

        // var_dump($query);

        $stmt->execute();

        $number_filter_row = $stmt->rowCount();

        $stmt =  Conexion::conectar()->prepare($query . $query1);

        $stmt->execute();

        $results = $stmt->fetchAll(PDO::FETCH_NAMED);

        $data = array();

        foreach ($results as $row) {
            $sub_array = array();
            $sub_array[] = $row['opciones']; //0
            $sub_array[] = $row['id']; //1
            $sub_array[] = $row['comprobante']; //2
            $sub_array[] = $row['fecha_emision']; //3
            $sub_array[] = $row['forma_pago']; //4
            $sub_array[] = $row['iva']; //5
            $sub_array[] = $row['importe_total']; //6
            $data[] = $sub_array;
        }


        // $stmt = Conexion::conectar()->prepare("SELECT v.id,
        //                                                 concat(v.serie,'-',v.correlativo) as comprobante, 
        //                                                 v.fecha_emision,
        //                                                 concat(mon.simbolo,format(v.total_iva,2)) as iva,
        //                                                 concat(mon.simbolo,format(v.importe_total,2)) as importe_total
        //                                         from venta v inner join serie s on v.id_serie = s.id
        //                                                     inner join moneda mon on mon.id = v.id_moneda
        //                                         where s.id_tipo_comprobante = '03'
        //                                         AND date(v.fecha_emision) = :fechaHoy");

        // $stmt->bindParam(":fechaHoy", $fechaHoy, PDO::PARAM_STR);
        // $stmt->execute();

        // return $stmt->fetchAll();
        $stmt = Conexion::conectar()->prepare(" SELECT 1
                                                from venta v inner join serie s on v.id_serie = s.id
                                                where s.id_tipo_comprobante = '03'");

        $stmt->execute();

        $count_all_data = $stmt->rowCount();

        $clientes = array(
            'draw' => $post['draw'],
            "recordsTotal" => $count_all_data,
            "recordsFiltered" => $number_filter_row,
            "data" => $data
        );

        return $clientes;
    }

    static public function mdlObtenerVentasDia($post)
    {
        // Verificar los datos recibidos
        error_log("Datos recibidos: " . print_r($post, true));
    
        // Preparar la consulta
        $stmt = Conexion::conectar()->prepare(" SELECT
                                                    SUM(v.importe_total) AS total_ventas_dia
                                                FROM venta v
                                                WHERE DATE(v.fecha_emision) = CURDATE()");
    
        // Ejecutar la consulta
        $stmt->execute();
    
        // Verificar el resultado de la consulta
        $result = $stmt->fetch();
        error_log("Resultado de la consulta: " . print_r($result, true));
    
        // Retornar el resultado
        return $result;
    }

    /* =========================================================================================
    
    ========================================================================================= */
    static public function mdlObtenerListadoFacturas($post)
    {

        $id_usuario = $_SESSION["usuario"]->id_usuario;

        $columns = [
            "id",
            "comprobante",
            "fecha_emision",
            "forma_pago",
            "total_iva",
            "importe_total",
            "estado_respuesta_sat",
            "estado_sat",
            "nombre_xml",
            "estado_comprobante",
            "mensaje_respuesta_sat"
        ];

        $query = " SELECT 
                         '' as opciones,
                         v.id,
                        concat(v.serie,'-',v.correlativo) as comprobante, 
                        v.fecha_emision,
                        upper(forma_pago) as forma_pago,
                        concat(mon.simbolo,format(v.total_iva,2)) as iva,
                        concat(mon.simbolo,format(v.importe_total,2)) as importe_total,
                        v.estado_respuesta_sat,
                        case when v.estado_respuesta_sat = 2 then 'Enviado, con errores'
                            when v.estado_respuesta_sat = 1 then 'Comprobante enviado correctamente'
                            when v.estado_respuesta_sat is null then 'Pendiente de envío'
                        end as estado_sat,
                        nombre_xml,
                        estado_comprobante,
                        mensaje_respuesta_sat
                from venta v inner join serie s on v.id_serie = s.id
                             inner join moneda mon on mon.id = v.id_moneda";

        if (isset($post["search"]["value"])) {
            $query .= '  WHERE s.id_tipo_comprobante = "01"
                AND v.id_usuario = "' . $id_usuario . '"
                AND (v.serie like "%' . $post["search"]["value"] . '%"
                     or v.correlativo like "%' . $post["search"]["value"] . '%"
                     or concat(v.serie,"-",v.correlativo) like "%' . $post["search"]["value"] . '%"
                     or v.fecha_emision like "%' . $post["search"]["value"] . '%")';
        }

        if (isset($post["order"])) {
            $query .= ' ORDER BY ' . $columns[$post['order']['0']['column']] . ' ' . $post['order']['0']['dir'] . ' ';
        } else {
            $query .= ' ORDER BY v.id desc ';
        }

        //SE AGREGA PAGINACION
        if ($post["length"] != -1) {
            $query1 = " LIMIT " . $post["start"] . ", " . $post["length"];
        }

        $stmt = Conexion::conectar()->prepare($query);

        $stmt->execute();

        $number_filter_row = $stmt->rowCount();

        $stmt =  Conexion::conectar()->prepare($query . $query1);

        $stmt->execute();

        $results = $stmt->fetchAll(PDO::FETCH_NAMED);

        $data = array();

        foreach ($results as $row) {
            $sub_array = array();
            // $sub_array[] = $row['detalles'];
            $sub_array[] = $row['opciones'];
            $sub_array[] = $row['id'];
            $sub_array[] = $row['comprobante'];
            $sub_array[] = $row['fecha_emision'];
            $sub_array[] = $row['forma_pago'];
            $sub_array[] = $row['iva'];
            $sub_array[] = $row['importe_total'];
            $sub_array[] = $row['estado_respuesta_sat'];
            $sub_array[] = $row['estado_sat'];
            $sub_array[] = $row['nombre_xml'];
            $sub_array[] = $row['estado_comprobante'];
            $sub_array[] = $row['mensaje_respuesta_sat'];
            $data[] = $sub_array;
        }

        $stmt = Conexion::conectar()->prepare(" SELECT 1
                                                from venta v inner join serie s on v.id_serie = s.id
                                                where s.id_tipo_comprobante = '03'");

        $stmt->execute();

        $count_all_data = $stmt->rowCount();

        $clientes = array(
            'draw' => $post['draw'],
            "recordsTotal" => $count_all_data,
            "recordsFiltered" => $number_filter_row,
            "data" => $data
        );

        return $clientes;
    }

    /* =========================================================================================
    
    ========================================================================================= */
    static public function mdlObtenerVentaPorId($id_venta)
    {

        $stmt = Conexion::conectar()->prepare("SELECT e.id_empresa,
                                                    e.logo,
                                                    v.id_cliente,
                                                    e.razon_social as empresa,
                                                    e.nit,
                                                    e.direccion as direccion_empresa,
                                                    concat(e.provincia  ,'-' ,e.departamento ,'-' ,e.distrito) as ubigeo,
                                                    s.id_tipo_comprobante,
                                                    v.serie,
                                                    v.correlativo,
                                                    v.fecha_emision,
                                                    v.hora_emision,
                                                    u.usuario as cajero,
                                                    u.nombre_usuario as nombre_cajero,
                                                    u.apellido_usuario as apellido_cajero,
                                                    format(v.total_iva,2) as total_iva,
                                                    format(v.importe_total,2) as importe_total,
                                                    c.id_tipo_documento,
                                                    c.nro_documento,
                                                    c.nombres_apellidos_razon_social,
                                                    c.direccion,
                                                    c.telefono,
                                                    v.hash_signature,
                                                    m.simbolo,
                                                    v.forma_pago
                                            FROM venta v inner join empresas e on v.id_empresa_emisora = e.id_empresa
                                                        inner join moneda m on m.id = v.id_moneda
                                                        inner join serie s on s.id = v.id_serie
                                                        inner join clientes c on c.id = v.id_cliente
                                                        inner join usuarios u on u.id_usuario = v.id_usuario
                                            WHERE v.id = :id_venta");
        $stmt->bindParam(":id_venta", $id_venta, PDO::PARAM_STR);
        $stmt->execute();
        return $stmt->fetch(PDO::FETCH_NAMED);
    }

    static public function mdlObtenerVentaPorIdTicket($id_venta)
    {

        $stmt = Conexion::conectar()->prepare("SELECT e.id_empresa,
                                                    e.logo,
                                                    v.id_cliente,
                                                    e.razon_social as empresa,
                                                    e.nombre_comercial as nombre_comercial,
                                                    e.nit,
                                                    e.direccion as direccion_empresa,
                                                    concat(e.departamento ,' - ' ,e.municipio) as ubigeo,
                                                    s.id_tipo_comprobante,
                                                    v.serie,
                                                    v.correlativo,
                                                    v.fecha_emision,
                                                    v.hora_emision,
                                                    u.usuario as cajero,
                                                    u.nombre_usuario as nombre_cajero,
                                                    u.apellido_usuario as apellido_cajero,
                                                    format(v.total_iva,2) as total_iva,
                                                    format(v.importe_total,2) as importe_total,
                                                    c.id_tipo_documento,
                                                    c.nro_documento,
                                                    c.nombres_apellidos_razon_social ,
                                                    c.direccion,
                                                    c.telefono,
                                                    v.hash_signature,
                                                    m.simbolo,
                                                    v.forma_pago,
                                                    format(v.efectivo_recibido,2) as efectivo_recibido,
                                                    format(v.vuelto,2) as vuelto
                                            FROM venta v inner join empresas e on v.id_empresa_emisora = e.id_empresa
                                                        inner join moneda m on m.id = v.id_moneda
                                                        inner join serie s on s.id = v.id_serie
                                                        inner join clientes c on c.id = v.id_cliente
                                                        inner join usuarios u on u.id_usuario = v.id_usuario
                                            WHERE v.id = :id_venta");
        $stmt->bindParam(":id_venta", $id_venta, PDO::PARAM_STR);
        $stmt->execute();
        return $stmt->fetch(PDO::FETCH_NAMED);
    }

    static public function mdlObtenerVentaParaResumen($id_venta)
    {

        $stmt = Conexion::conectar()->prepare("SELECT v.id,
                                                s.id_tipo_comprobante,
                                                v.serie,
                                                v.correlativo,
                                                v.id_moneda,	
                                                v.total_iva,
                                                v.importe_total	
                                            FROM venta v  inner join serie s on s.id = v.id_serie
                                            WHERE v.id = :id_venta");
        $stmt->bindParam(":id_venta", $id_venta, PDO::PARAM_STR);
        $stmt->execute();
        return $stmt->fetch(PDO::FETCH_NAMED);
    }

    static public function mdlObtenerDetalleVentaPorId($id_venta)
    {

        $stmt = Conexion::conectar()->prepare("SELECT dv.codigo_producto, 
                                                    dv.descripcion,
                                                    dv.cantidad,
                                                    format(dv.precio_unitario,2) as precio_unitario,
                                                    format(dv.importe_total,2) as importe_total
                                            FROM detalle_venta dv 
                                            WHERE dv.id_venta  = :id_venta");
        $stmt->bindParam(":id_venta", $id_venta, PDO::PARAM_STR);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_NAMED);
    }

    static public function mdlInsertarCuotas($id_venta, $cronograma)
    {


        $dbh = Conexion::conectar();

        try {

            for ($i = 0; $i < count($cronograma); $i++) {

                $stmt = $dbh->prepare("INSERT INTO cuotas(id_venta, cuota, importe, importe_pagado,saldo_pendiente, cuota_pagada,fecha_vencimiento, estado)
                VALUES (:id_venta, :cuota, :importe, :importe_pagado, :saldo_pendiente, :cuota_pagada, :fecha_vencimiento, '1')");

                $dbh->beginTransaction();
                $stmt->execute(array(
                    ':id_venta'            => $id_venta,
                    ':cuota'            => $cronograma[$i]["cuota"],
                    ':importe'            => $cronograma[$i]["importe"],
                    ':importe_pagado'   => 0,
                    ':saldo_pendiente'   => $cronograma[$i]["importe"],
                    ':cuota_pagada'      => 0,
                    ':fecha_vencimiento' => $cronograma[$i]["vencimiento"]
                ));

                $dbh->commit();
            }

            return "ok";
        } catch (Exception $e) {
            $dbh->rollBack();
            return $e->getMessage();
        }
    }

    static public function mdlObtenerCuotas($id_venta)
    {

        $stmt = Conexion::conectar()->prepare("SELECT id, 
                                                    id_venta, 
                                                    cuota, 
                                                    round(importe, 2) as importe,
                                                    fecha_vencimiento, 
                                                    estado
                                            FROM cuotas c 
                                            WHERE c.id_venta  = :id_venta");

        $stmt->bindParam(":id_venta", $id_venta, PDO::PARAM_STR);
        $stmt->execute();

        return $stmt->fetchAll(PDO::FETCH_NAMED);
    }

    static public function mdlObtenerCuotasPorIdVenta($id_venta)
    {

        $stmt = Conexion::conectar()->prepare("SELECT 
                                                id, 
                                                cuota, 
                                                round(ifnull(importe,0),2) as  importe,
                                                round(ifnull(importe_pagado,0),2) as  importe_pagado,
                                                round(ifnull(saldo_pendiente,0),2) as saldo_pendiente,
                                                case when cuota_pagada = 0 then 'NO' else 'SI' end as cuota_pagada, 
                                                fecha_vencimiento
                                        from cuotas c
                                        where c.id_venta = :id_venta");

        $stmt->bindParam(":id_venta", $id_venta, PDO::PARAM_STR);
        $stmt->execute();

        return $stmt->fetchAll();
    }

    static public function mdlPagarCuotas($id_venta, $importe_a_pagar, $medio_pago)
    {

        $id_usuario = $_SESSION["usuario"]->id_usuario;

        $dbh = Conexion::conectar();

        try {

            $stmt = $dbh->prepare("call prc_pagar_cuotas_factura(:id_venta, :importe_a_pagar, :id_usuario, :medio_pago)");

            $dbh->beginTransaction();
            $stmt->execute(array(
                ':id_venta'            => $id_venta,
                ':importe_a_pagar'     => $importe_a_pagar,
                ':id_usuario'          => $id_usuario,
                ':medio_pago'          => $medio_pago
            ));

            $dbh->commit();

            $respuesta["tipo_msj"] = "success";
            $respuesta["msj"] = "Se registró el pago correctamente";
        } catch (Exception $e) {
            $dbh->rollBack();
            $respuesta["tipo_msj"] = "error";
            $respuesta["msj"] = "Error al registrar el pago " . $e->getMessage();
        }

        return $respuesta;
    }

    static public function mdlObtenerVentaPorComprobante($id_serie, $correlativo)
    {

        $stmt = Conexion::conectar()->prepare("SELECT v.id, 
                                                    v.id_empresa_emisora, 
                                                    v.id_cliente, 
                                                    v.id_serie, 
                                                    v.serie, 
                                                    v.correlativo, 
                                                    v.tipo_comprobante_modificado, 
                                                    v.id_serie_modificado, 
                                                    v.correlativo_modificado, 
                                                    v.motivo_nota_credito_debito, 
                                                    v.fecha_emision, 
                                                    v.hora_emision, 
                                                    v.fecha_vencimiento, 
                                                    v.id_moneda, 
                                                    v.forma_pago, 
                                                    v.tipo_operacion, 
                                                    v.total_operaciones_gravadas, 
                                                    v.total_operaciones_exoneradas, 
                                                    v.total_operaciones_inafectas, 
                                                    v.total_iva, 
                                                    v.importe_total, 
                                                    v.efectivo_recibido, 
                                                    v.vuelto, 
                                                    v.nombre_xml, 
                                                    v.xml_base64, 
                                                    v.xml_cdr_sat_base64, 
                                                    v.codigo_error_sat, 
                                                    v.mensaje_respuesta_sat, 
                                                    v.hash_signature, 
                                                    v.estado_respuesta_sat, 
                                                    v.estado_comprobante, 
                                                    v.id_usuario, 
                                                    v.pagado,
                                                    cli.*,
                                                    td.descripcion as descripcion_documento,
                                                    p.codigo_producto, 
                                                    p.id_categoria, 
                                                    p.descripcion, 
                                                    p.id_tipo_afectacion_iva, 
                                                    case when p.id_tipo_afectacion_iva = 10 
                                                            then 'GRAVADO' 
                                                        when p.id_tipo_afectacion_iva = 20 
                                                            then 'EXONERADO' 
                                                        when p.id_tipo_afectacion_iva = 30
                                                            then 'INAFECTO' 
                                                    end as tipo_afectacion_iva,
                                                    p.id_unidad_medida, 
                                                    cum.descripcion as unidad_medida, 
                                                    p.costo_unitario, 
                                                    dv.precio_unitario as precio_unitario_con_iva,
                                                    dv.valor_unitario as precio_unitario_sin_iva, 
                                                    dv.cantidad,
                                                    dv.importe_total as total_producto,
                                                    case when p.id_tipo_afectacion_iva = 10 then 1.18 else 1 end as factor_iva,
                                                    case when p.id_tipo_afectacion_iva = 10 then 0.18 else 0 end as porcentaje_iva
                                            FROM venta v inner join  detalle_venta dv on v.id = dv.id_venta
                                                        inner join productos p on dv.codigo_producto = p.codigo_producto
                                                        inner join codigo_unidad_medida cum on cum.id = p.id_unidad_medida
                                                        inner join clientes cli on cli.id = v.id_cliente
                                                        inner join tipo_documento td on td.id = cli.id_tipo_documento
                                            WHERE v.id_serie = :id_serie
                                            and v.correlativo = :correlativo
                                            order by dv.id asc");

        $stmt->bindParam(":id_serie", $id_serie, PDO::PARAM_STR);
        $stmt->bindParam(":correlativo", $correlativo, PDO::PARAM_STR);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_NAMED);
    }

    static public function mdlObtenerDetalleVentaPorComprobante($id_serie, $correlativo)
    {

        $stmt = Conexion::conectar()->prepare("SELECT v.id,
                                                    v.id_empresa_emisora,
                                                    v.id_cliente,
                                                    v.id_serie,
                                                    s.id_tipo_comprobante,
                                                    v.serie,
                                                    v.correlativo,
                                                    v.tipo_comprobante_modificado,
                                                    v.id_serie_modificado,
                                                    v.correlativo_modificado,
                                                    v.motivo_nota_credito_debito,
                                                    v.fecha_emision,
                                                    v.hora_emision,
                                                    v.fecha_vencimiento,
                                                    v.id_moneda,
                                                    v.forma_pago,
                                                    v.tipo_operacion,
                                                    v.total_operaciones_gravadas,
                                                    v.total_operaciones_exoneradas,
                                                    v.total_operaciones_inafectas,
                                                    v.total_iva,
                                                    v.importe_total,
                                                    v.efectivo_recibido,
                                                    v.vuelto,
                                                    v.nombre_xml,
                                                    v.xml_base64,
                                                    v.xml_cdr_sat_base64,
                                                    v.codigo_error_sat,
                                                    v.mensaje_respuesta_sat,
                                                    v.hash_signature,
                                                    v.estado_respuesta_sat,
                                                    v.estado_comprobante,
                                                    v.id_usuario,
                                                    v.pagado                                                 
                                            FROM venta v inner join serie s on v.id_serie = s.id
                                            WHERE v.id_serie = :id_serie
                                            AND v.correlativo = :correlativo");

        $stmt->bindParam(":id_serie", $id_serie, PDO::PARAM_STR);
        $stmt->bindParam(":correlativo", $correlativo, PDO::PARAM_STR);
        $stmt->execute();
        return $stmt->fetch(PDO::FETCH_NAMED);
    }

    static public function mdlReporteVentas($fecha_desde, $fecha_hasta)
    {

        $stmt = Conexion::conectar()->prepare("call prc_ReporteVentas(:fecha_desde, :fecha_hasta)");

        $stmt->bindParam(":fecha_desde", $fecha_desde, PDO::PARAM_STR);
        $stmt->bindParam(":fecha_hasta", $fecha_hasta, PDO::PARAM_STR);
        $stmt->execute();
        return $stmt->fetchAll();
    }
}
