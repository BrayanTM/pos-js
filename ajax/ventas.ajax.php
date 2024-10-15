<?php

setlocale(LC_TIME, 'es_GT.UTF-8');

require_once "../modelos/ventas.modelo.php";
require_once "../modelos/productos.modelo.php";
require_once "../modelos/clientes.modelo.php";
require_once "../modelos/empresas.modelo.php";
require "../vendor/autoload.php";

use Dompdf\Dompdf;


/* ===================================================================================  */
/* P O S T   P E T I C I O N E S  */
/* ===================================================================================  */

if (isset($_POST["accion"])) {

    switch ($_POST["accion"]) {

        case 'obtener_moneda':

            $response = VentasModelo::mdlObtenerMoneda();

            echo json_encode($response, JSON_UNESCAPED_UNICODE);

            break;

        case 'obtener_simbolo_moneda':

            $response = VentasModelo::mdlObtenerSimboloMoneda($_POST["moneda"]);

            echo json_encode($response, JSON_UNESCAPED_UNICODE);

            break;
        case 'obtener_nro_boleta':

            $response = VentasModelo::mdlObtenerNroBoleta();

            echo json_encode($response, JSON_UNESCAPED_UNICODE);

            break;

        case 'registrar_venta':

            //Datos del comprobante
            $formulario_venta = [];
            parse_str($_POST['datos_venta'], $formulario_venta);

            // $detalle_productos = json_decode($_POST["arr_detalle_productos"]);
            $detalle_productos = json_decode($_POST["productos"]);


            if (isset($_POST["arr_cronograma"])) {
                $cronograma = json_decode($_POST["arr_cronograma"]);
            }

            // DATOS DEL EMISOR:
            $datos_emisor = VentasModelo::mdlObtenerDatosEmisor($formulario_venta["empresa_emisora"]);

            //DATOS DEL CLIENTE:
            if ($formulario_venta['tipo_documento'] == "0") {
                $formulario_venta['nro_documento'] = "99999999";
                $formulario_venta['nombre_cliente_razon_social'] = "CONSUMIDOR FINAL";
                $formulario_venta['direccion'] = "-";
                $formulario_venta['telefono'] = "-";
            }

            $datos_cliente = VentasModelo::mdlObtenerDatosCliente(
                $formulario_venta['tipo_documento'],
                $formulario_venta['nro_documento'],
                $formulario_venta['nombre_cliente_razon_social'],
                $formulario_venta['direccion'],
                $formulario_venta['telefono']
            );

            $count_items = 0;

            $total = 0;
            $total_iva = 0;
            $total_icbper = 0;
            $detalle_venta = array();


            //RECORREMOS EL DETALLE DE LOS PRODUCTOS DE LA VENTA
            for ($i = 0; $i < count($detalle_productos); $i++) {

                $count_items = $count_items + 1;

                $iva_producto = 0; //EN CASO EL PRODUCTO NO TENGA IVA, SE MANTIENE CON EL VALOR = 0
                $factor_iva = 1; //EN CASO EL PRODUCTO NO TENGA IVA, SE MANTIENE CON EL FACTOR = 1

                if ($detalle_productos[$i]->id_tipo_iva == 12) { //SI ES OPERACION GRAVADA = 12
                    $iva = ProductosModelo::mdlObtenerImpuesto($detalle_productos[$i]->id_tipo_iva);
                    $porcentaje_iva = $iva['impuesto'] / 100; //0.12;
                    $factor_iva = 1 + ($iva['impuesto'] / 100);
                    $iva_producto = $detalle_productos[$i]->precio * $detalle_productos[$i]->cantidad * $porcentaje_iva;
                } else $porcentaje_iva = 0.0; // SI ES INAFECTA O EXONERADA

                $total_impuestos_producto = $iva_producto;

                $afectacion = VentasModelo::ObtenerTipoAfectacionIVA($detalle_productos[$i]->id_tipo_iva);
                $costo_unitario = VentasModelo::ObtenerCostoUnitarioUnidadMedida($detalle_productos[$i]->codigo_producto);

                $producto = array(
                    'item'                  => $count_items,
                    'codigo'                => $detalle_productos[$i]->codigo_producto,
                    'descripcion'           => $detalle_productos[$i]->descripcion,
                    'porcentaje_iva'        => $porcentaje_iva * 100, //Para registrar el IVA que se consideró para la venta
                    'unidad'                => $costo_unitario['id_unidad_medida'], //$detalle_productos[$i]->unidad_medida,
                    'cantidad'              => $detalle_productos[$i]->cantidad,
                    'costo_unitario'        => $costo_unitario['costo_unitario'],
                    'valor_unitario'        => round($detalle_productos[$i]->precio, 42),
                    'precio_unitario'       => round($detalle_productos[$i]->precio * $factor_iva, 4),
                    'valor_total'           => round($detalle_productos[$i]->precio * $detalle_productos[$i]->cantidad, 4),
                    'iva'                   => round($iva_producto, 4),
                    'importe_total'         => round($detalle_productos[$i]->precio * $detalle_productos[$i]->cantidad * $factor_iva, 4),
                    'codigos'               => array($afectacion['codigo'], $afectacion['nombre_tributo'])
                );


                array_push($detalle_venta, $producto);

                //CALCULAMOS LOS TOTALES POR TIPO DE OPERACIÓN
                if ($detalle_productos[$i]->id_tipo_iva == 12) {
                    $total = $total + $producto['valor_total'];
                }

                if ($detalle_productos[$i]->id_tipo_iva == 5) {
                    $total = $total + $producto['valor_total'];
                }

                $total_iva = $total_iva + $iva_producto;
            }

            //OBTENER LA SERIE DEL COMPROBANTE
            $serie = VentasModelo::mdlObtenerSerie($formulario_venta['serie']);

            if ($formulario_venta["forma_pago"] == "1") {
                $forma_pago = "Contado";
            } else {
                $forma_pago = "Credito";
            }

            $monto_credito = 0;
            $cuotas = array();


            if ($forma_pago == "Credito") {

                for ($i = 0; $i < count($cronograma); $i++) {

                    $cuotas[] = array(
                        "cuota" => $cronograma[$i]->cuota,
                        "importe" => round($cronograma[$i]->importe, 2),
                        "vencimiento" => $cronograma[$i]->fecha_vencimiento
                    );
                }
            }

            //DATOS DE LA VENTA:
            $venta['id_empresa_emisora'] = $datos_emisor["id_empresa"];
            $venta['id_cliente'] = $datos_cliente["id"];
            $venta['tipo_operacion'] = $formulario_venta['tipo_operacion'];
            $venta['tipo_comprobante'] = $formulario_venta["tipo_comprobante"];
            $venta['id_serie'] = $serie['id'];
            $venta['serie'] = $serie['serie'];
            $venta['correlativo'] = intval($serie['correlativo']) + 1;
            $venta['fecha_emision'] = $formulario_venta['fecha_emision'];
            $venta['hora_emision'] = Date('H:i:s');
            $venta['fecha_vencimiento'] = Date('Y-m-d');
            $venta['moneda'] = $formulario_venta["moneda"];
            $venta['forma_pago'] = $forma_pago;
            $venta['medio_pago'] = $formulario_venta["medio_pago"];
            $venta['monto_credito'] = round($total + $total_iva, 2);
            $venta['total_impuestos'] = $total_iva;
            $venta['total_iva'] = $total_iva;
            $venta['total_sin_impuestos'] = $total;
            $venta['total_con_impuestos'] = $total + $total_iva;
            $venta['total_a_pagar'] = $total + $total_iva;
            $venta['vuelto'] = $formulario_venta["vuelto"];
            $venta['efectivo_recibido'] = $formulario_venta["total_recibido"];
            $venta['cuotas'] = $cuotas;


            if (isset($formulario_venta['rb_generar_venta']) && $formulario_venta['rb_generar_venta'] == 1) {


                /*****************************************************************************************
                R E G I S T R A R   V E N T A   Y   D E T A L L E   E N   L A   B D
                 *****************************************************************************************/
                $id_venta = VentasModelo::mdlRegistrarVenta($venta, $detalle_venta, $_POST["id_caja"]);

                if ($venta['forma_pago'] == 'Credito') {
                    $insert_cuotas = VentasModelo::mdlInsertarCuotas($id_venta, $cuotas);
                }
            } else {

                /*****************************************************************************************
                R E G I S T R A R   V E N T A   Y   D E T A L L E   E N   L A   B D
                 *****************************************************************************************/
                $id_venta = VentasModelo::mdlRegistrarVenta($venta, $detalle_venta, $_POST["id_caja"]);

                if ($id_venta > 0) {
                    $respuesta["id_venta"] = $id_venta;
                    $respuesta['tipo_msj'] = "success";
                    $respuesta['msj'] = "La venta se guardó correctamente";
                    echo json_encode($respuesta);
                } else {
                    $respuesta["id_venta"] = $id_venta;
                    $respuesta['tipo_msj'] = "error";
                    $respuesta['msj'] = "Error al generar la venta";
                    echo json_encode($respuesta);
                }
            }

            break;

        case 'obtener_ventas':

            $response = VentasModelo::mdlListarVentas($_POST["fechaDesde"], $_POST["fechaHasta"]);

            echo json_encode($response, JSON_UNESCAPED_UNICODE);

            break;

        case 'obtener_tipo_comprobante':

            $response = VentasModelo::mdlObtenerTipoComprobante();

            echo json_encode($response, JSON_UNESCAPED_UNICODE);

            break;

        case 'obtener_serie_comprobante':

            $response = VentasModelo::mdlObtenerSerieComprobante($_POST["id_filtro"]);

            echo json_encode($response, JSON_UNESCAPED_UNICODE);

            break;



        case 'obtener_tipo_documento':

            $response = VentasModelo::mdlObtenerTipoDocumento();

            echo json_encode($response, JSON_UNESCAPED_UNICODE);

            break;

        case 'obtener_forma_pago':

            $response = VentasModelo::mdlObtenerFormaPago();

            echo json_encode($response, JSON_UNESCAPED_UNICODE);

            break;

        case 'obtener_medio_pago':

            $response = VentasModelo::mdlObtenerMedioPago();

            echo json_encode($response, JSON_UNESCAPED_UNICODE);

            break;

        case 'obtener_correlativo_serie':

            $response = VentasModelo::mdlObtenerCorrelativoSerie($_POST["id_serie"]);

            echo json_encode($response, JSON_UNESCAPED_UNICODE);

            break;

        case 'obtener_tipo_operacion':

            $response = VentasModelo::mdlObtenerTipoOperacion();

            echo json_encode($response, JSON_UNESCAPED_UNICODE);

            break;

        case 'obtener_listado_boletas':

            $response = VentasModelo::mdlObtenerListadoBoletas($_POST);
            echo json_encode($response, JSON_UNESCAPED_UNICODE);
            break;

        case 'obtener_listado_boletas_x_fecha':

            $response = VentasModelo::mdlObtenerListadoBoletasPorFecha($_POST, $_POST["fecha_emision"], $_POST["id_empresa"]);
            echo json_encode($response, JSON_UNESCAPED_UNICODE);
            break;


            $response = VentasModelo::mdlPagarCuotas($_POST["id_venta"], $_POST["monto_a_pagar"], $_POST["medio_pago"]);

            echo json_encode($response, JSON_UNESCAPED_UNICODE);

            break;

        case 'obtener_listado_boletas_x_dia':

            $response = VentasModelo::mdlObtenerListadoBoletasPorDia($_POST);
            echo json_encode($response, JSON_UNESCAPED_UNICODE);
            break;

        case 'obtener_listado_boletas_x_mes':

            $response = VentasModelo::mdlObtenerListadoBoletasPorMes($_POST);
            echo json_encode($response, JSON_UNESCAPED_UNICODE);
            break;

        case 'obtener_ventas_dia':

            $response = VentasModelo::mdlObtenerVentasDia($_POST);
            echo json_encode($response, JSON_UNESCAPED_UNICODE);
            break;

        case 'obtener_ventas_mes':

            $response = VentasModelo::mdlObtenerVentasMes($_POST);
            echo json_encode($response, JSON_UNESCAPED_UNICODE);
            break;

        case 'obtener_detalle_venta':

            $response = VentasModelo::mdlObtenerVentaPorComprobante($_POST["id_serie"], $_POST["correlativo"]);

            echo json_encode($response, JSON_NUMERIC_CHECK);

            break;


        case "reporte_ventas":

            $response = VentasModelo::mdlReporteVentas($_POST["fecha_desde"], $_POST["fecha_hasta"]);

            echo json_encode($response, JSON_UNESCAPED_UNICODE);

            break;
    }
}

/* ===================================================================================  */
/* G E T   P E T I C I O N E S  */
/* ===================================================================================  */
if (isset($_GET["accion"])) {

    switch ($_GET["accion"]) {

        case 'generar_ticket':

            require('../vistas/assets/plugins/fpdf/fpdf.php');
            require("../phpqrcode/qrlib.php");

            $venta = VentasModelo::mdlObtenerVentaPorIdTicket($_GET["id_venta"]);

            if ($venta["forma_pago"] == "Credito") {
                $cuotas = VentasModelo::mdlObtenerCuotas($_GET["id_venta"]);
            }

            $pdf = new FPDF($orientation = 'P', $unit = 'mm', array(80, 1000));
            $pdf->AddPage();
            $pdf->setMargins(5, 5, 5);

            //NOMBRE DE LA EMPRESA
            $pdf->SetFont('Arial', 'B', 12);
            $pdf->Cell(60, 10, $venta["nombre_comercial"], 0, 0, 'C');

            //LOGO
            $pdf->Image('../vistas/assets/dist/img/logos_empresas/' . $venta["logo"] ?? 'AdminLTELogo.png', 30, 18, 20, 20);

            $pdf->Ln(25);

            //EMPRESA
            $pdf->SetFont('Arial', '', 8);
            $pdf->Cell(70, 15, strlen(utf8_decode($venta["empresa"])) > 30 ? substr(utf8_decode($venta["empresa"]), 0, 30) . "..." : utf8_decode($venta["empresa"]), 0, 0, 'C');

            //DIRECCION
            $pdf->Ln(5);
            $pdf->SetFont('Arial', '', 8);
            $pdf->Cell(70, 15, $venta["direccion_empresa"], 0, 0, 'C');

            //UBIGEO
            $pdf->Ln(5);
            $pdf->SetFont('Arial', '', 8);
            $pdf->Cell(70, 15, utf8_decode($venta["ubigeo"]), 0, 0, 'C');


            //NIT
            $pdf->Ln(5);
            $pdf->SetFont('Arial', 'B', 8);
            $pdf->Cell(70, 15, utf8_decode("NIT: " . $venta["nit"]), 0, 0, 'C');

            //BOLETA DE VENTA ELECTRONICA
            $pdf->Ln(15);
            $pdf->SetFont('Arial', '', 8);
            if ($venta["id_tipo_comprobante"] == "01") {
                $pdf->Cell(70, 6, utf8_decode("FACTURA ELECTRÓNICA"), 0, 0, 'C');
            } else if ($venta["id_tipo_comprobante"] == "NV")
                $pdf->Cell(70, 6, utf8_decode("NOTA DE VENTA"), 0, 0, 'C');
            else {
                $pdf->Cell(70, 6, utf8_decode("BOLETA DE VENTA ELECTRÓNICA"), 0, 0, 'C');
            }

            $pdf->Ln(5);
            $pdf->Cell(70, 6, utf8_decode("SERIE: " . $venta["serie"]) . " " . utf8_decode("CORRELATIVO: " . $venta["correlativo"]), 0, 0, 'C');
            $pdf->Ln(5);
            $pdf->Cell(70, 6, utf8_decode("FECHA EMISIÓN: " . $venta["fecha_emision"] . "  " . $venta["hora_emision"]), 0, 0, 'C');
            $pdf->Ln(5);
            $pdf->Cell(70, 6, strtoupper(utf8_decode("CAJERO: " . $venta["nombre_cajero"] . " " . $venta["apellido_cajero"])), 0, 0, 'C');
            $pdf->Ln(5);
            $pdf->Cell(70, 6, strtoupper(strlen(utf8_decode($venta["nombres_apellidos_razon_social"])) > 25 ? "CLIENTE:" . substr(utf8_decode($venta["nombres_apellidos_razon_social"]), 0, 25) . "..." : "CLIENTE:" . utf8_decode($venta["nombres_apellidos_razon_social"])), 0, 0, 'C');
            $pdf->Ln(5);
            $pdf->Cell(70, 6, strtoupper(utf8_decode("NRO. DOC.: " . $venta["nro_documento"])), 0, 0, 'C');


            $pdf->Ln(10);

            //INICIO DETALLE DE LA VENTA
            $pdf->Cell(70, 5, utf8_decode("-------------------------------------------------------------------------"), 0, 0, 'C');
            $pdf->Ln(5);
            $pdf->SetFont('Arial', 'B', 6);
            $pdf->Cell(13, 4, utf8_decode("CODIGO"), 0, 0, 'L');
            $pdf->Cell(30, 4, utf8_decode("DESCRIPCIÓN"), 0, 0, 'L');
            $pdf->Cell(8, 4, utf8_decode("CANT."), 0, 0, 'L');
            $pdf->Cell(10, 4, utf8_decode("P. UNIT"), 0, 0, 'L');
            $pdf->Cell(8, 4, utf8_decode("IMP."), 0, 0, 'C');

            $detalle_venta = VentasModelo::mdlObtenerDetalleVentaPorId($_GET["id_venta"]);

            foreach ($detalle_venta as $detalle) {
                $pdf->Ln(5);
                $pdf->SetFont('Arial', '', 6);
                $pdf->Cell(13, 4, strlen(utf8_decode($detalle["codigo_producto"])) > 8 ? substr(utf8_decode($detalle["codigo_producto"]), 0, 7) . "..." : utf8_decode($detalle["codigo_producto"]), 0, 0, 'L');
                $pdf->Cell(30, 4, strtoupper(strlen(utf8_decode($detalle["descripcion"])) > 25 ? substr(utf8_decode($detalle["descripcion"]), 0, 20) . "..." : utf8_decode($detalle["descripcion"])), 0, 0, 'L');
                $pdf->Cell(8, 4, $detalle["cantidad"], 0, 0, 'C');
                $pdf->Cell(10, 4, $detalle["precio_unitario"], 0, 0, 'C');
                $pdf->Cell(8, 4, $detalle["importe_total"], 0, 0, 'R');
            }

            $pdf->Ln(5);
            $pdf->Cell(70, 5, utf8_decode("--------------------------------------------------------------------------------------------------"), 0, 0, 'C');
            $pdf->Ln();
            //FIN DETALLE DE LA VENTA


            //INICIO RESUMEN IMPORTES
            $pdf->SetFont('Arial', 'B', 6);

            $pdf->Cell(50, 4, "IVA:", 0, 0, 'R');
            $pdf->Cell(20, 4, $venta["simbolo"] . " " . $venta["total_iva"], 0, 0, 'R');
            $pdf->Ln();

            $pdf->Cell(50, 4, "IMPORTE TOTAL:", 0, 0, 'R');
            $pdf->Cell(20, 4, $venta["simbolo"] . " " . $venta["importe_total"], 0, 0, 'R');
            $pdf->Ln(10);
            //FIN RESUMEN IMPORTES


            //FORMA DE PAGO
            $pdf->Cell(20, 4, strtoupper("Forma de Pago: "), 0, 0, 'L');
            $pdf->Cell(40, 4, strtoupper($venta["forma_pago"]), 0, 0, 'L');
            $pdf->Ln(5);

            if ($venta["forma_pago"] != "Credito") {

                //TOTAL RECIBIDO
                $pdf->Cell(25, 4, strtoupper("Efectivo Recibido: "), 0, 0, 'L');
                $pdf->Cell(40, 4, $venta["simbolo"] . ' ' . $venta["efectivo_recibido"], 0, 0, 'L');

                $pdf->Ln(5);

                //VUELTO
                $pdf->Cell(25, 4, strtoupper("Vuelto: "), 0, 0, 'L');
                $pdf->Cell(40, 4, $venta["simbolo"] . ' ' . $venta["vuelto"], 0, 0, 'L');

                $pdf->Ln(5);
            }

            //CALENDARIO DE PAGOS
            if ($venta["forma_pago"] == "Credito") {

                $pdf->Ln(5);
                $pdf->SetFont('Arial', '', 6);
                $pdf->Cell(10, 4, "Cuota", 0, 0, 'L');
                $pdf->Cell(20, 4, "Fecha Vencimiento", 0, 0, 'L');
                $pdf->Cell(20, 4, "Importe", 0, 0, 'C');
                $pdf->Cell(20, 4, "", 0, 0, 'C');

                for ($i = 0; $i < count($cuotas); $i++) {

                    $pdf->Ln(5);
                    $pdf->SetFont('Arial', '', 6);

                    $pdf->Cell(10, 4, $cuotas[$i]["cuota"], 0, 0, 'L');
                    $pdf->Cell(20, 4, $cuotas[$i]["fecha_vencimiento"], 0, 0, 'L');
                    $pdf->Cell(20, 4, $cuotas[$i]["importe"], 0, 0, 'C');
                    $pdf->Cell(20, 4, "", 0, 0, 'L');
                }
            }

            $pdf->Ln(30);
            $pdf->SetFont('Arial', '', 6);
            //QR
            /*NIT | TIPO DE DOCUMENTO | SERIE | NUMERO | MTO TOTAL IVA | MTO TOTAL DEL COMPROBANTE | FECHA DE EMISION |TIPO DE DOCUMENTO ADQUIRENTE | NUMERO DE DOCUMENTO ADQUIRENTE |*/
            $text_qr = $venta["nit"] . " | " . $venta["id_tipo_comprobante"] . " | " . $venta["serie"] . " | " . $venta["correlativo"] . " | " . $venta["total_iva"] . " | " . $venta["importe_total"] . " | " . $venta["fecha_emision"] . " | " . $venta["id_tipo_documento"] . " | " . $venta["nro_documento"];
            $ruta_qr = "../fe/qr/" . "prueba_qr" . '.png';

            QRcode::png($text_qr, $ruta_qr, 'Q', 15, 0);

            $pdf->Image($ruta_qr, 28, $pdf->GetY() - 20, 25, 25);

            $pdf->Ln(5);

            //HASH SIGNATURE
            $pdf->Cell(70, 4, $venta["hash_signature"], 0, 0, 'C');
            $pdf->Ln(10);

            //TEXTO
            $pdf->SetFont('Arial', 'B', 8);
            $pdf->Cell(70, 4, "GRACIAS POR TU COMPRA", 0, 0, 'C');

            // $detalle_venta = VentasModelo::mdlObtenerDetalleVenta($_GET["nro_boleta"]);

            $pdf->SetFont('Arial', '', 8);

            $pdf->Output('../fe/facturas/' . $venta["nit"] . "-" . $venta["id_tipo_comprobante"] . "-" . $venta["serie"] . "-" . $venta["correlativo"] . '.pdf', 'F');
            $pdf->Output();

            break;
    }
}
