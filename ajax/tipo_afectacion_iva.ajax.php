

<?php

require_once "../modelos/tipo_afectacion_iva.modelo.php";

//=========================================================================================
// PETICIONES POST
//=========================================================================================
if (isset($_POST["accion"])) {

    switch ($_POST["accion"]) {

        case 'obtener_tipo_afectacion_iva':

            $response = TipoAfectacionIvaModelo::mdlObtenerTipoAfectacionIva($_POST);
            echo json_encode($response, JSON_UNESCAPED_UNICODE);
            break;

        case 'obtener_porcentaje_impuesto':

            $response = TipoAfectacionIvaModelo::mdlObtenerPorcentajeImpuesto($_POST['codigo_afectacion']);
            echo json_encode($response, JSON_UNESCAPED_UNICODE);
            break;


        case 'validar_codigo_tipo_afectacion':

            $response = TipoAfectacionIvaModelo::mdlValidarCodigoAfectacion($_POST['codigo_tipo_afectacion']);
            echo json_encode($response, JSON_UNESCAPED_UNICODE);
            break;

        case 'eliminar_tipo_afectacion':

            $response = TipoAfectacionIvaModelo::mdlEliminarTipoAfectacion($_POST['id_tipo_afectacion']);
            echo json_encode($response, JSON_UNESCAPED_UNICODE);
            break;

        case 'registrar_tipo_afectacion_iva':

            //Datos del formulario
            $formulario_tipo_afectacion_iva = [];
            parse_str($_POST['datos_tipo_afectacion_iva'], $formulario_tipo_afectacion_iva);

            $response = TipoAfectacionIvaModelo::mdlRegistrarTipoAfectacionIva($formulario_tipo_afectacion_iva);
            echo json_encode($response, JSON_UNESCAPED_UNICODE);
            break;
    }
}
