<!-- Content Header (Page header) -->
<div class="content-header">
    <div class="container-fluid">
        <div class="row mb-2">
            <div class="col-sm-6">
                <h2 class="m-0">Registrar Producto</h2>
            </div><!-- /.col -->
            <div class="col-sm-6">
                <ol class="breadcrumb float-sm-right">
                    <li class="breadcrumb-item"><a href="./">Inicio</a></li>
                    <li class="breadcrumb-item">Inventario</li>
                    <li class="breadcrumb-item active">Registrar</li>
                </ol>
            </div><!-- /.col -->
        </div><!-- /.row -->
    </div><!-- /.container-fluid -->
</div>
<!-- /.content-header -->

<!-- Main content -->
<div class="content">

    <div class="container-fluid">

        <div class="card card-gray shadow mt-3">

            <div class="card-body px-3 py-3" style="position: relative;">

                <span class="titulo-fieldset px-3 py-1">DATOS DEL PRODUCTO </span>

                <div class="row my-1">

                    <div class="col-12">

                        <form id="frm-datos-producto" class="needs-validation" novalidate>

                            <!-- Abrimos una fila -->
                            <div class="row">

                                <input type="hidden" name="impuesto_producto" id="impuesto_producto">

                                <!-- CODIGO DE BARRAS -->
                                <div class="col-12 col-lg-6 mb-2">
                                    <label class="mb-0 ml-1 text-sm my-text-color form-label"><i class="fas fa-barcode mr-1 my-text-color"></i>Código del Producto</label>
                                    <input type="text" placeholder="Ingrese el código del producto" class="form-control form-control-sm" id="codigo_producto" name="codigo_producto" onchange="validateJS(event, 'codigo_producto')" aria-label="Small" aria-describedby="inputGroup-sizing-sm" required>
                                    <div class="invalid-feedback">Ingrese el código del producto</div>
                                </div>

                                <!-- CATEGORIAS -->
                                <div class="col-12 col-lg-6 mb-2">
                                    <label class="mb-0 ml-1 text-sm my-text-color"><i class="fas fa-layer-group mr-1 my-text-color"></i>Categoría</label>
                                    <select class="form-select form-select-sm select2 cursor-pointer" id="id_categoria" name="id_categoria" aria-label="Floating label select example" required>
                                    </select>
                                    <div class="invalid-feedback">Seleccione la categoría</div>
                                </div>

                                <!-- DESCRIPCION DEL PRODUCTO -->
                                <div class="col-12 mb-2">
                                    <label class="mb-0 ml-1 text-sm my-text-color"><i class="fas fa-gifts mr-1 my-text-color"></i>Descripción</label>
                                    <input type="text" placeholder="Ingrese la descripción del producto" class="form-control form-control-sm" id="descripcion" name="descripcion" aria-label="Small" aria-describedby="inputGroup-sizing-sm" required>
                                    <div class="invalid-feedback">Ingrese descripción del producto</div>
                                </div>

                                <!-- TIPO AFECTACIÓN -->
                                <div class="col-12 col-lg-6 mb-2">
                                    <label class="mb-0 ml-1 text-sm my-text-color"><i class="fas fa-file-invoice-dollar mr-1 my-text-color"></i>Tipo Afectación</label>
                                    <select class="form-select form-select-sm select2 cursor-pointer" id="id_tipo_afectacion_iva" name="id_tipo_afectacion_iva" aria-label="Floating label select example" required>
                                    </select>
                                    <div class="invalid-feedback">Seleccione el Tipo de Afectación</div>
                                </div>

                                <!-- IMPUESTO -->
                                <div class="col-12 col-lg-2">
                                    <label class="mb-0 ml-1 text-sm my-text-color"><i class="fas fa-percentage mr-1 my-text-color"></i>IVA (%)</label>
                                    <input type="text" class="form-control form-control-sm" id="impuesto" name="impuesto" aria-label="Small" aria-describedby="inputGroup-sizing-sm" readonly>
                                </div>

                                <!-- UNIDAD MEDIDA -->
                                <div class="col-12 col-lg-4">
                                    <label class="mb-0 ml-1 text-sm my-text-color"><i class="fas fa-ruler mr-1 my-text-color"></i>Unidad/Medida</label>
                                    <select class="form-select form-select-sm select2 cursor-pointer" id="id_unidad_medida" name="id_unidad_medida" aria-label="Floating label select example" required>
                                    </select>
                                    <div class="invalid-feedback">Seleccione la Unidad de Medida</div>
                                </div>

                                <!-- IMAGEN -->
                                <div class="col-12 mb-2">
                                    <label class="mb-0 ml-1 text-sm my-text-color"><i class="fas fa-image mr-1 my-text-color"></i>Seleccione una imagen</label>
                                    <!-- <input type="file" class="form-control form-control-sm" id="imagen" name="imagen" accept="image/*" onchange="previewFile(this)"> -->
                                    <input type="file" class="form-control" id="imagen" name="imagen" accept="image/*" onchange="previewFile(this)">
                                </div>

                                <!-- PREVIEW IMAGEN -->
                                <div class="col-12 col-lg-3">
                                    <div style="width: 100%; height: 255px;">
                                        <img id="previewImg" src="vistas/assets/imagenes/no_image.jpg" class="border border-secondary" style="object-fit: fill; width: 100%; height: 100%;" alt="">
                                    </div>
                                </div>

                                <div class="col-lg-9">

                                    <div class="row">

                                        <!-- PRECIO DE VENTA (INC. IVA) -->
                                        <div class="col-12 col-lg-6 mb-2">
                                            <label class="mb-0 ml-1 text-sm my-text-color"><i class="mr-1 my-text-color">Q.</i>Precio (con IVA)</label>
                                            <input type="number" min="0" step="0.01" placeholder="Ingrese Precio con IVa" class="form-control form-control-sm" id="precio_unitario_con_iva" name="precio_unitario_con_iva" aria-label="Small" aria-describedby="inputGroup-sizing-sm" required>
                                        </div>

                                        <!-- PRECIO DE VENTA (SIN. IVA) -->
                                        <div class="col-12 col-lg-6 mb-2">
                                            <label class="mb-0 ml-1 text-sm my-text-color"><i class="mr-1 my-text-color">Q.</i>Precio (sin IVA)</label>
                                            <input type="number" min="0" step="0.01" placeholder="Ingrese Precio sin IVA" class="form-control form-control-sm" id="precio_unitario_sin_iva" name="precio_unitario_sin_iva" aria-label="Small" aria-describedby="inputGroup-sizing-sm">
                                        </div>

                                        <!-- PRECIO DE VENTA x MAYOR (INC. IVA) -->
                                        <div class="col-12 col-lg-6 mb-2">
                                            <label class="mb-0 ml-1 text-sm my-text-color"><i class="mr-1 my-text-color">Q.</i>Precio x Mayor (con IVA)</label>
                                            <input type="number" min="0" step="0.01" placeholder="Ingrese Precio x Mayor con IVA" class="form-control form-control-sm" id="precio_unitario_mayor_con_iva" name="precio_unitario_mayor_con_iva" aria-label="Small" aria-describedby="inputGroup-sizing-sm">
                                        </div>

                                        <!-- PRECIO DE VENTA x MAYOR (SIN. IVA) -->
                                        <div class="col-12 col-lg-6 mb-2">
                                            <label class="mb-0 ml-1 text-sm my-text-color"><i class="mr-1 my-text-color">Q.</i>Precio x Mayor (sin IVA)</label>
                                            <input type="number" min="0" step="0.01" placeholder="Ingrese Precio x Mayor sin IVA" class="form-control form-control-sm" id="precio_unitario_mayor_sin_iva" name="precio_unitario_mayor_sin_iva" aria-label="Small" aria-describedby="inputGroup-sizing-sm">
                                        </div>

                                        <!-- PRECIO VENTA EN OFERTA (INC. IVA) -->
                                        <div class="col-12 col-lg-6 mb-2">
                                            <label class="mb-0 ml-1 text-sm my-text-color"><i class="mr-1 my-text-color">Q.</i>Precio Oferta (con IVA)</label>
                                            <input type="number" min="0" step="0.01" placeholder="Ingrese precio oferta con IVA" class="form-control form-control-sm" id="precio_unitario_oferta_con_iva" name="precio_unitario_oferta_con_iva" aria-label="Small" aria-describedby="inputGroup-sizing-sm">
                                        </div>

                                        <!-- PRECIO VENTA EN OFERTA (SIN. IVA) -->
                                        <div class="col-12 col-lg-6 mb-2">
                                            <label class="mb-0 ml-1 text-sm my-text-color"><i class="mr-1 my-text-color">Q.</i>Precio Oferta (sin IVA)</label>
                                            <input type="number" min="0" step="0.01" placeholder="Ingrese precio oferta sin IVA" class="form-control form-control-sm" id="precio_unitario_oferta_sin_iva" name="precio_unitario_oferta_sin_iva" aria-label="Small" aria-describedby="inputGroup-sizing-sm">
                                        </div>

                                        <!-- MINIMO STOCK -->
                                        <div class="col-12 col-lg-12">
                                            <label class="mb-0 ml-1 text-sm my-text-color"><i class="fas fa-boxes mr-1 my-text-color"></i>Stock Mínimo</label>
                                            <input type="number" min="0" step="0.01" value="0.00" placeholder="Ingrese el Stock Mínimo" class="form-control form-control-sm" id="minimo_stock" name="minimo_stock" aria-label="Small" aria-describedby="inputGroup-sizing-sm">
                                        </div>

                                    </div>

                                </div>

                                <!-- BOTONERA -->
                                <div class="col-12 text-center mt-3">
                                    <a class="btn btn-sm btn-danger  fw-bold " id="btnCancelarRegistro" style="position: relative; width: 160px;" onclick="fnc_RegresarListadoProductos();">
                                        <span class="text-button">REGRESAR</span>
                                        <span class="btn fw-bold icon-btn-danger ">
                                            <i class="fas fa-undo-alt fs-5 text-white m-0 p-0"></i>
                                        </span>
                                    </a>

                                    <a class="btn btn-sm btn-success  fw-bold " id="btnGuardarProducto" style="position: relative; width: 160px;" onclick="fnc_registrarProducto();">
                                        <span class="text-button">REGISTRAR</span>
                                        <span class="btn fw-bold icon-btn-success ">
                                            <i class="fas fa-save fs-5 text-white m-0 p-0"></i>
                                        </span>
                                    </a>
                                </div>

                            </div>

                        </form>
                    </div>

                </div>

            </div>

        </div>



    </div>


</div>

<script>
    var Toast = Swal.mixin({
        toast: true,
        position: 'top-end',
        showConfirmButton: false,
        timer: 3000
    });

    $(document).ready(function() {

        fnc_MostrarLoader()

        fnc_InicializarFormulario();

        $("#precio_unitario_con_iva").on("keyup", function() {

            if ($("#impuesto").val() == '') {
                mensajeToast('warning', 'Seleccione el Tipo de Afectación')
                $("#precio_unitario_con_iva").val('')
                $("#precio_unitario_sin_iva").val('')
                return;
            }

            precio_unitario_con_iva = parseFloat($("#precio_unitario_con_iva").val());
            precio_unitario_sin_iva = parseFloat(precio_unitario_con_iva / (1 + ($("#impuesto_producto").val() / 100))).toFixed(2);
            $("#precio_unitario_sin_iva").val(precio_unitario_sin_iva);
        });

        $("#precio_unitario_sin_iva").on("keyup", function() {

            if ($("#impuesto").val() == '') {
                mensajeToast('warning', 'Seleccione el Tipo de Afectación')
                $("#precio_unitario_con_iva").val('')
                $("#precio_unitario_sin_iva").val('')
                return;
            }

            precio_unitario_sin_iva = parseFloat($("#precio_unitario_sin_iva").val());
            precio_unitario_con_iva = parseFloat(precio_unitario_sin_iva) + (parseFloat(precio_unitario_sin_iva) * parseFloat($("#impuesto_producto").val() / 100));
            $("#precio_unitario_con_iva").val(precio_unitario_con_iva.toFixed(2));
        });


        $("#precio_unitario_mayor_con_iva").on("keyup", function() {

            if ($("#impuesto").val() == '') {
                mensajeToast('warning', 'Seleccione el Tipo de Afectación')
                $("#precio_unitario_con_iva").val('')
                $("#precio_unitario_sin_iva").val('')
                return;
            }

            precio_unitario_mayor_con_iva = parseFloat($("#precio_unitario_mayor_con_iva").val());
            precio_unitario_mayor_sin_iva = parseFloat(precio_unitario_mayor_con_iva / (1 + ($("#impuesto_producto").val() / 100))).toFixed(2);
            $("#precio_unitario_mayor_sin_iva").val(precio_unitario_mayor_sin_iva)
        });

        $("#precio_unitario_mayor_sin_iva").on("keyup", function() {

            if ($("#impuesto").val() == '') {
                mensajeToast('warning', 'Seleccione el Tipo de Afectación')
                $("#precio_unitario_mayor_con_iva").val('')
                $("#precio_unitario_mayor_sin_iva").val('')
                return;
            }

            precio_unitario_mayor_sin_iva = parseFloat($("#precio_unitario_mayor_sin_iva").val());
            precio_unitario_mayor_con_iva = parseFloat(precio_unitario_mayor_sin_iva) + (parseFloat(precio_unitario_mayor_sin_iva) * parseFloat($("#impuesto_producto").val() / 100));
            $("#precio_unitario_mayor_con_iva").val(precio_unitario_mayor_con_iva.toFixed(2));
        });


        $("#precio_unitario_oferta_con_iva").on("keyup", function() {

            if ($("#impuesto").val() == '') {
                mensajeToast('warning', 'Seleccione el Tipo de Afectación')
                $("#precio_unitario_con_iva").val('')
                return;
            }

            precio_unitario_oferta_con_iva = parseFloat($("#precio_unitario_oferta_con_iva").val());
            precio_unitario_oferta_sin_iva = parseFloat(precio_unitario_oferta_con_iva / (1 + ($("#impuesto_producto").val() / 100))).toFixed(2);
            $("#precio_unitario_oferta_sin_iva").val(precio_unitario_oferta_sin_iva)
        });

        $("#precio_unitario_oferta_sin_iva").on("keyup", function() {

            if ($("#impuesto").val() == '') {
                mensajeToast('warning', 'Seleccione el Tipo de Afectación')
                $("#precio_unitario_oferta_con_iva").val('')
                $("#precio_unitario_oferta_sin_iva").val('')
                return;
            }

            precio_unitario_oferta_sin_iva = parseFloat($("#precio_unitario_oferta_sin_iva").val());
            precio_unitario_oferta_con_iva = parseFloat(precio_unitario_oferta_sin_iva) + (parseFloat(precio_unitario_oferta_sin_iva) * parseFloat($("#impuesto_producto").val() / 100));
            $("#precio_unitario_oferta_con_iva").val(precio_unitario_oferta_con_iva.toFixed(2));
        });

        $('#id_tipo_afectacion_iva').on('change', function(e) {

            $("#impuesto").val('');
            $("#impuesto_producto").val('');

            var formData = new FormData();
            formData.append('accion', 'obtener_impuesto_tipo_operacion')
            formData.append('id_tipo_afectacion', $('#id_tipo_afectacion_iva').val());
            response = SolicitudAjax('ajax/productos.ajax.php', 'POST', formData);

            if (response) {
                $("#impuesto").val(response['impuesto'])
                $("#impuesto_producto").val(response['impuesto']);

                precio_unitario_sin_iva = parseFloat($("#precio_unitario_con_iva").val() / (1 + ($("#impuesto_producto").val() / 100))).toFixed(2);
                if (precio_unitario_sin_iva > 0) {
                    $("#precio_unitario_sin_iva").val(precio_unitario_sin_iva);
                }

                precio_unitario_mayor_sin_iva = parseFloat($("#precio_unitario_mayor_con_iva").val() / (1 + ($("#impuesto_producto").val() / 100))).toFixed(2);
                if (precio_unitario_mayor_sin_iva > 0) {
                    $("#precio_unitario_mayor_sin_iva").val(precio_unitario_mayor_sin_iva);
                }

                precio_unitario_oferta_sin_iva = parseFloat($("#precio_unitario_oferta_con_iva").val() / (1 + ($("#impuesto_producto").val() / 100))).toFixed(2);
                if (precio_unitario_oferta_sin_iva > 0) {
                    $("#precio_unitario_oferta_sin_iva").val(precio_unitario_oferta_sin_iva);
                }

            }

        });

        fnc_OcultarLoader();

    });

    function fnc_InicializarFormulario() {

        fnc_cargarSelectCategorias();

        fnc_LimpiarControles();

        $('.select2').select2({
            placeholder: "Seleccione una categoría",
            dropdownCssClass: "myFont"
        });

        // fnc_cargarSelectCategorias();
    }

    function fnc_cargarSelectCategorias() {
        CargarSelect(null, $("#id_categoria_busqueda"), "--Todas las categorías--", "ajax/categorias.ajax.php", 'obtener_categorias', null, 1);
        CargarSelect(null, $("#id_categoria"), "--Seleccione una categoría--", "ajax/categorias.ajax.php", 'obtener_categorias');
        CargarSelect(null, $("#id_tipo_afectacion_iva"), "--Seleccione Tipo de Afectación IVA--", "ajax/productos.ajax.php", 'listar_tipo_afectacion');
        CargarSelect(null, $("#id_unidad_medida"), "--Seleccione una Unidad/Medida--", "ajax/productos.ajax.php", 'listar_unidad_medida');
    }

    // PREVISUALIZAR LA IMAGEN
    function previewFile(input) {

        var file = $("input[type=file]").get(0).files[0];

        if (file) {
            var reader = new FileReader();

            reader.onload = function() {
                $("#previewImg").attr("src", reader.result);
            }

            reader.readAsDataURL(file);
        }
    }

    function fnc_LimpiarControles() {
        // $("#mdlGestionarProducto").modal('hide');

        $("#codigo_producto").prop('readonly', false);

        $("#codigo_producto").val('');
        $("#id_categoria").val('');
        $("#descripcion").val('');
        $("#id_tipo_afectacion_iva").val('');
        $("#impuesto").val('');
        $("#id_unidad_medida").val('');
        $("#precio_unitario_con_iva").val('');
        $("#precio_unitario_sin_iva").val('');
        $("#precio_unitario_mayor_con_iva").val('');
        $("#precio_unitario_mayor_sin_iva").val('');
        $("#precio_unitario_oferta_con_iva").val('');
        $("#precio_unitario_oferta_sin_iva").val('');
        $("#minimo_stock").val('');

        $("#iptImagen").val('');
        $("#previewImg").attr("src", "vistas/assets/imagenes/no_image.jpg");
    }


    function fnc_registrarProducto() {

        var formData = new FormData();

        formData.append('detalle_producto', $("#frm-datos-producto").serialize());
        formData.append('accion', 'registrar_producto')

        var imagen_valida = true;

        var forms = document.getElementsByClassName('needs-validation');

        var validation = Array.prototype.filter.call(forms, function(form) {

            if (form.checkValidity() === true) {

                var file = $("#imagen").val();

                if (file) {

                    var ext = file.substring(file.lastIndexOf("."));

                    if (ext != ".jpg" && ext != ".png" && ext != ".gif" && ext != ".jpeg" && ext != ".webp") {
                        mensajeToast('error', "La extensión " + ext + " no es una imagen válida");
                        imagen_valida = false;
                    }

                    if (!imagen_valida) {
                        return;
                    }

                    const inputImage = document.querySelector('#imagen');
                    formData.append('archivo[]', inputImage.files[0])
                }

                Swal.fire({
                    title: 'Está seguro de registrar el producto?',
                    icon: 'warning',
                    showCancelButton: true,
                    confirmButtonColor: '#3085d6',
                    cancelButtonColor: '#d33',
                    confirmButtonText: 'Si, deseo registrarlo!',
                    cancelButtonText: 'Cancelar',
                }).then((result) => {

                    if (result.isConfirmed) {

                        response = SolicitudAjax("ajax/productos.ajax.php", "POST", formData);

                        // mensajeToast(response["tipo_msj"], response["msj"])
                        Swal.fire({
                            position: 'top-center',
                            icon: response["tipo_msj"],
                            title: response["msj"],
                            showConfirmButton: true
                        })

                        if (response["tipo_msj"] == "success") {
                            fnc_RegresarListadoProductos();
                        }

                    }
                })
            } else {
                // mensajeToast('warning', 'Complete los campos obligatorios.!')
                Toast.fire({
                    icon: 'warning',
                    title: 'Complete los campos obligatorios.!'
                })
            }

            form.classList.add('was-validated');

        });

    }

    function fnc_RegresarListadoProductos() {
        fnc_LimpiarControles();
        CargarContenido('vistas/modulos/inventario/productos/productos.php', 'content-wrapper');
    }
</script>