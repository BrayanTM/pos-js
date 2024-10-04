<?php

require_once "conexion.php";

class UbigeosModelo
{

    static public function mdlObtenerDepartamentos()
    {
        $stmt = Conexion::conectar()->prepare("SELECT 
                                                    distinct departamento as id,
                                                            departamento as descripcion
                                                FROM 
                                                    tb_ubigeos
                                                ORDER BY departamento");
        $stmt->execute();
        return $stmt->fetchAll();
    }

    static public function mdlObtenerMunicipiosPorDepartamento($departamento)
    {
        $stmt = Conexion::conectar()->prepare("SELECT 
                                                    distinct municipio as id, municipio as descripcion
                                                FROM 
                                                    tb_ubigeos p 
                                                WHERE  (p.departamento  LIKE CONCAT('%', :departamento, '%'))
                                                ORDER BY municipio");
        
        $stmt->bindParam(":departamento", $departamento, PDO::PARAM_STR);
        $stmt->execute();
        return $stmt->fetchAll();
    }

    static public function mdlObtenerUbigeoPorDepMun($departamento, $municipio)
    {
        $stmt = Conexion::conectar()->prepare("SELECT distinct substring(ubigeo_renap,1,4) as ubigeo
                                                FROM tb_ubigeos 
                                                WHERE  (departamento  LIKE CONCAT('%', :departamento, '%')) 
                                                and (municipio  LIKE CONCAT('%', :municipio, '%'))");
        
        $stmt->bindParam(":departamento", $departamento, PDO::PARAM_STR);
        $stmt->bindParam(":municipio", $municipio, PDO::PARAM_STR);
        $stmt->execute();
        return $stmt->fetch();
    }
    

}
