<?php

require_once "conexion.php";

class EmpresasModelo
{


    static public function mdlObtenerEmpresas_Select()
    {

        $stmt = Conexion::conectar()->prepare("SELECT id_empresa, razon_social 
                                                FROM empresas 
                                                WHERE estado = 1");

        $stmt->execute();
        return $stmt->fetchAll();
    }

    static public function mdlObtenerEmpresas($post)
    {

        $columns = [
            "id_empresa",
            "razon_social",
            "nombre_comercial",
            "id_tipo_documento",
            "tipo_documento",
            "nit",
            "direccion",
            "simbolo_moneda",
            "email",
            "telefono",
            "departamento",
            "municipio",
            "ubigeo",
            "usuario_sat",
            "clave_sat",
            "estado"
        ];

        $query = " SELECT 
                            '' as opciones,
                            e.id_empresa, 
                            e.razon_social, 
                            e.nombre_comercial, 
                            e.id_tipo_documento, 
                            td.descripcion as tipo_documento,
                            e.nit, 
                            e.direccion, 
                            e.simbolo_moneda, 
                            e.email, 
                            e.telefono, 
                            e.departamento, 
                            e.municipio, 
                            e.ubigeo, 
                            e.usuario_sat, 
                            e.clave_sat,
                            case when e.estado = 1 then 'ACTIVO' else 'INACTIVO' end as estado
                    FROM empresas e inner join tipo_documento td on e.id_tipo_documento = td.id";

        if (isset($post["search"]["value"])) {
            $query .= ' WHERE e.razon_social like "%' . $post["search"]["value"] . '%"
                        or e.nombre_comercial like "%' . $post["search"]["value"] . '%"
                        or td.descripcion like "%' . $post["search"]["value"] . '%"
                        or e.nit like "%' . $post["search"]["value"] . '%"
                        or e.direccion like "%' . $post["search"]["value"] . '%"
                        or e.email like "%' . $post["search"]["value"] . '%"
                        or e.telefono like "%' . $post["search"]["value"] . '%"
                        or e.departamento like "%' . $post["search"]["value"] . '%"
                        or e.municipio like "%' . $post["search"]["value"] . '%"
                        or case when e.estado = 1 then "ACTIVO" else "INACTIVO" end like "%' . $post["search"]["value"] . '%"';
        }

        if (isset($post["order"])) {
            $query .= ' ORDER BY ' . $columns[$post['order']['0']['column']] . ' ' . $post['order']['0']['dir'] . ' ';
        } else {
            $query .= ' ORDER BY e.id_empresa desc ';
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
            $sub_array[] = $row['opciones'];
            $sub_array[] = $row['id_empresa'];
            $sub_array[] = $row['razon_social'];
            $sub_array[] = $row['nombre_comercial'];
            $sub_array[] = $row['id_tipo_documento'];
            $sub_array[] = $row['tipo_documento'];
            $sub_array[] = $row['nit'];
            $sub_array[] = $row['direccion'];
            $sub_array[] = $row['simbolo_moneda'];
            $sub_array[] = $row['email'];
            $sub_array[] = $row['telefono'];
            $sub_array[] = $row['departamento'];
            $sub_array[] = $row['municipio'];
            $sub_array[] = $row['ubigeo'];
            $sub_array[] = $row['usuario_sat'];
            $sub_array[] = $row['clave_sat'];
            $sub_array[] = $row['estado'];
            $data[] = $sub_array;
        }

        $stmt = Conexion::conectar()->prepare(" SELECT  1
                                                FROM empresas e 
                                                INNER JOIN tipo_documento td 
                                                ON e.id_tipo_documento = td.id");

        $stmt->execute();

        $count_all_data = $stmt->rowCount();

        $empresas = array(
            'draw' => $post['draw'],
            "recordsTotal" => $count_all_data,
            "recordsFiltered" => $number_filter_row,
            "data" => $data
        );

        return $empresas;
    }

    //=========================================================================================
    // R E G I S T R A R   E M P R E S A
    //=========================================================================================
    static public function mdlRegistrarEmpresa($empresa, $certificado = null, $imagen_logo = null)
    {

        $dbh = Conexion::conectar();

        try {

            $stmt = $dbh->prepare("INSERT INTO empresas(genera_fact_electronica,
                                                        razon_social, 
                                                        nombre_comercial, 
                                                        id_tipo_documento, 
                                                        nit, 
                                                        direccion, 
                                                        email, 
                                                        telefono, 
                                                        departamento, 
                                                        municipio, 
                                                        ubigeo, 
                                                        certificado_digital,
                                                        clave_certificado,
                                                        logo,
                                                        estado)
                                    VALUES(:genera_fact_electronica,
                                            :razon_social, 
                                            UPPER(:nombre_comercial), 
                                            :id_tipo_documento, 
                                            :nit, 
                                            UPPER(:direccion), 
                                            :email, 
                                            :telefono, 
                                            UPPER(:departamento), 
                                            UPPER(:municipio), 
                                            :ubigeo, 
                                            :certificado_digital,
                                            :clave_certificado,
                                            :logo,
                                            :estado)");
            $dbh->beginTransaction();
            $stmt->execute(array(
                ':genera_fact_electronica' => $empresa['rb_genera_facturacion'],
                ':razon_social' => $empresa['razon_social'],
                ':nombre_comercial' => $empresa['nombre_comercial'],
                ':id_tipo_documento' => 4,
                ':nit' => $empresa['nro_documento'],
                ':direccion' => $empresa['direccion'],
                ':email' => $empresa['email'],
                ':telefono' => $empresa['telefono'],
                ':departamento' => $empresa['departamento'],
                ':municipio' => $empresa['municipio'],
                ':ubigeo' => $empresa['ubigeo'],
                ':certificado_digital' => isset($certificado["nombre_archivo"]) ? $certificado["nombre_archivo"] : '',
                ':clave_certificado' => isset( $empresa['clave_certificado']) ? $empresa['clave_certificado']:'',                
                ':logo' => $imagen_logo["nuevoNombre"] ?? '',
                ':estado' => $empresa['estado']
            ));
            $dbh->commit();

            //GUARDAMOS EL CERTIFICADO
            if ($certificado) {
                $guardarCertificado = new EmpresasModelo();
                $guardarCertificado->guardarCertificado('../fe/certificado/', $certificado);
            }

            //GUARDAMOS EL LOGO DE LA EMPRESA
            if ($imagen_logo) {
                $guardarImagen = new EmpresasModelo();
                $guardarImagen->guardarImagen($imagen_logo["folder"], $imagen_logo["ubicacionTemporal"], $imagen_logo["nuevoNombre"]);
            }

            $respuesta['tipo_msj'] = 'success';
            $respuesta['msj'] = 'Se registró la empresa correctamente';
        } catch (Exception $e) {
            $dbh->rollBack();
            $respuesta['tipo_msj'] = 'error';
            $respuesta['msj'] = 'Error al registrar la empresa ' . $e->getMessage();
        }

        return $respuesta;
    }

    public function guardarImagen($folder, $ubicacionTemporal, $nuevoNombre)
    {
        file_put_contents(strtolower($folder . $nuevoNombre), file_get_contents($ubicacionTemporal));
    }

    //=========================================================================================
    // A C T U A L I Z A R   E M P R E S A
    //=========================================================================================
    static public function mdlActualizarEmpresa($empresa, $certificado = null, $imagen_logo = null)
    {

        $dbh = Conexion::conectar();

        try {

            $stmt = Conexion::conectar()->prepare("select certificado_digital, clave_certificado, logo from empresas where id_empresa = :id_empresa");
            $stmt->bindParam(":id_empresa", $empresa["id_empresa"], PDO::PARAM_STR);
            $stmt->execute();

            $datos = $stmt->fetch();

            if ($empresa['rb_genera_facturacion'] == 1) {
                $certificado_actual = $datos["certificado_digital"];
                $clave_certificado_actual = $datos["clave_certificado"];
            } else {
                $certificado_actual = null;
                $clave_certificado_actual = null;
            }


            $logo_actual = $datos["logo"];


            $stmt = $dbh->prepare("UPDATE   empresas
                                     SET    genera_fact_electronica = ?,
                                            razon_social = upper(?), 
                                            nombre_comercial = upper(?), 
                                            id_tipo_documento = ?, 
                                            nit = ?, 
                                            direccion = upper(?), 
                                            email = ?, 
                                            telefono = ?, 
                                            departamento = upper(?), 
                                            municipio = upper(?), 
                                            ubigeo = ?, 
                                            certificado_digital = ?,
                                            clave_certificado = ?,
                                            logo = ?,                                            
                                            estado = ?
                                    WHERE   id_empresa = ?");
            $dbh->beginTransaction();
            $stmt->execute(array(
                $empresa['rb_genera_facturacion'],
                $empresa['razon_social'],
                $empresa['nombre_comercial'],
                4,
                $empresa['nro_documento'],
                $empresa['direccion'],
                $empresa['email'],
                $empresa['telefono'],
                $empresa['departamento'],
                $empresa['municipio'],
                $empresa['ubigeo'],
                isset($certificado['nombre_archivo']) ? strtolower($certificado['nombre_archivo']) : '',
                isset($empresa['clave_certificado']) ? $empresa['clave_certificado'] : '',                
                $imagen_logo["nuevoNombre"] ?? $logo_actual,                
                $empresa['estado'],
                $empresa['id_empresa']
            ));
            $dbh->commit();

            //GUARDAMOS EL CERTIFICADO
            if (isset($certificado)) {
                if ($certificado_actual != strtolower($certificado['nombre_archivo'])) {
                    $guardarCertificado = new EmpresasModelo();
                    $guardarCertificado->guardarCertificado('../fe/certificado/', $certificado);
                }
            }

            //GUARDAMOS EL LOGO DE LA EMPRESA
            if ($imagen_logo) {
                $guardarImagen = new EmpresasModelo();
                $guardarImagen->guardarImagen($imagen_logo["folder"], $imagen_logo["ubicacionTemporal"], $imagen_logo["nuevoNombre"]);
            }


            $respuesta['tipo_msj'] = 'success';
            $respuesta['msj'] = 'Se actualizó la empresa correctamente';
        } catch (Exception $e) {
            $dbh->rollBack();
            $respuesta['tipo_msj'] = 'error';
            $respuesta['msj'] = 'Error al actualizar la empresa ' . $e->getMessage();
        }

        return $respuesta;
    }

    static public function mdlValidarNitEmpresa($id_empresa, $nit)
    {

        $stmt = Conexion::conectar()->prepare(" SELECT count(1) as existe
                                            FROM empresas emp 
                                            WHERE emp.id_empresa != :id_empresa
                                            AND emp.nit = :nit");

        $stmt->bindParam(":id_empresa", $id_empresa, PDO::PARAM_STR);
        $stmt->bindParam(":nit", $nit, PDO::PARAM_STR);

        $stmt->execute();
        return $stmt->fetch(PDO::FETCH_NAMED);
    }

    public function guardarCertificado($folder, $certificado)
    {
        file_put_contents(strtolower($folder . $certificado["nombre_archivo"]), file_get_contents($certificado["ubicacionTemporal"]));
    }

    //=========================================================================================
    // OBTENER EMPRESA POR ID
    //=========================================================================================
    static public function mdlObtenerEmpresaPorId($id_empresa)
    {
        $stmt = Conexion::conectar()->prepare("SELECT id_empresa, 
                                                        genera_fact_electronica,
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
                                                        clave_certificado,
                                                        es_principal,
                                                        fact_bol_defecto,
                                                        logo,
                                                        estado
                                                FROM empresas
                                                where id_empresa = :id_empresa");
        $stmt->bindParam(":id_empresa", $id_empresa, PDO::PARAM_STR);
        $stmt->execute();
        return $stmt->fetch(PDO::FETCH_NAMED);
    }

    static public function mdlObtenerEmpresaDefecto()
    {

        $stmt = Conexion::conectar()->prepare("SELECT id_empresa                                                        
                                                FROM empresas
                                                WHERE estado = 1
                                                LIMIT 1");
        $stmt->execute();
        return $stmt->fetch(PDO::FETCH_NAMED);
    }

    static public function mdlEliminarEmpresa($id_empresa)
    {

        $dbh = Conexion::conectar();

        try {

            // Validamos que la empresa no tenga ventas asociadas
            $stmt = Conexion::conectar()->prepare("SELECT count(1) as cantidad FROM venta where id_empresa_emisora = :id_empresa");
            $stmt->bindParam(":id_empresa", $id_empresa, PDO::PARAM_STR);
            $stmt->execute();

            $existen_datos = $stmt->fetch(PDO::FETCH_NAMED);

            if ($existen_datos["cantidad"] > 0) {

                $respuesta['tipo_msj'] = 'error';
                $respuesta['msj'] = 'No se puede eliminar la empresa porque tiene ventas asociadas';

                return $respuesta;
            }

            $stmt = $dbh->prepare("DELETE FROM empresas WHERE id_empresa = :id_empresa");
            $dbh->beginTransaction();
            $stmt->execute(array(
                ':id_empresa' => $id_empresa
            ));
            $dbh->commit();

            $respuesta['tipo_msj'] = 'success';
            $respuesta['msj'] = 'Se eliminó la empresa correctamente';
        } catch (Exception $e) {
            $dbh->rollBack();
            $respuesta['tipo_msj'] = 'error';
            $respuesta['msj'] = 'Error al eliminar la empresa ' . $e->getMessage();
        }

        return $respuesta;
    }

    static public function mdlObtenerEmpresaPrincipal()
    {

        $stmt = Conexion::conectar()->prepare("SELECT id_empresa,
                                                        genera_fact_electronica,
                                                        razon_social,
                                                        nombre_comercial,
                                                        id_tipo_documento,
                                                        nit,
                                                        direccion,
                                                        simbolo_moneda,
                                                        email,
                                                        telefono,
                                                        departamento,
                                                        municipio,
                                                        ubigeo,
                                                        certificado_digital,
                                                        clave_certificado,
                                                        usuario_sat,
                                                        clave_sat,
                                                        logo,
                                                        estado,
                                                        production,
                                                        client_id,
                                                        client_secret,
                                                        certificado_digital_pem
                                                FROM empresas");
        $stmt->execute();
        return $stmt->fetch(PDO::FETCH_NAMED);
    }

    static public function mdlVerificarEmpresasRegistradas()
    {

        $stmt = Conexion::conectar()->prepare("SELECT count(1) as cantidad FROM empresas where estado = 1");
        $stmt->execute();
        return $stmt->fetch(PDO::FETCH_NAMED);
    }
}
