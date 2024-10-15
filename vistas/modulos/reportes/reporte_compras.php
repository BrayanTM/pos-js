<!-- Content Header (Page header) -->
<div class="content-header pb-1">
    <div class="container-fluid">
        <div class="row mb-2">
            <div class="col-sm-6">
                <h2 class="m-0 fw-bold">REPORTE DE COMPRAS</h2>
            </div><!-- /.col -->
            <div class="col-sm-6  d-none d-md-block">
                <ol class="breadcrumb float-sm-right">
                    <li class="breadcrumb-item"><a href="index.php">Inicio</a></li>
                    <li class="breadcrumb-item active">Reporte de Compras</li>
                </ol>
            </div><!-- /.col -->
        </div><!-- /.row -->
    </div><!-- /.container-fluid -->
</div>
<!-- /.content-header -->

<div class="content">

    <div class="row">

        <div class="col-12 ">

            <div class="card card-primary card-outline card-outline-tabs">

                <div class="card-header p-0 border-bottom-0">

                    <ul class="nav nav-tabs" id="custom-tabs-four-tab" role="tablist">

                        <!-- TAB LISTADO DE COMPRAS  -->
                        <li class="nav-item">
                            <a class="nav-link active my-0" id="listado-compras-tab" data-toggle="pill" href="#listado-compras" role="tab" aria-controls="listado-compras" aria-selected="true"><i class="fas fa-list"></i> Listado de Compras</a>
                        </li>

                    </ul>

                </div>

                <div class="card-body">

                    <div class="tab-content" id="custom-tabs-four-tabContent">

                        <!-- TAB CONTENT LISTADO DE COMPRAS -->
                        <div class="tab-pane fade active show" id="listado-compras" role="tabpanel" aria-labelledby="listado-compras-tab">

                            <div class="row">

                                <!--LISTADO DE COMPRAS -->
                                <div class="col-md-12">
                                    <table id="tbl_compras" class="table w-100 shadow border border-secondary">
                                        <thead class="bg-main text-left">
                                            <th></th> <!-- 0 -->
                                            <th>Id</th> <!-- 1 -->
                                            <th>Id Proveedor</th> <!-- 2 -->
                                            <th>Proveedor</th> <!-- 3 -->
                                            <th>Fech. Compra</th> <!-- 4 -->
                                            <th>Id Tipo Comprobante</th> <!-- 5 -->
                                            <th>Comprobante</th> <!-- 6 -->
                                            <th>Serie</th> <!-- 7 -->
                                            <th>Correlativo</th> <!-- 8 -->
                                            <th>Moneda</th> <!-- 9 -->
                                            <th>Total IVA</th> <!-- 10 -->
                                            <th>Descuento</th> <!-- 11 -->
                                            <th>Total Compra</th> <!-- 12 -->
                                            <th>Estado</th> <!-- 13 -->
                                        </thead>
                                    </table>
                                </div>

                            </div>

                        </div>

                    </div>

                </div>

            </div><!-- /.card -->

        </div>

    </div>

</div>

<div class="loading">Loading</div>

<script>
    //Variables Globales
    var itemProducto = 1;

    $(document).ready(function() {

        fnc_MostrarLoader()

        fnc_CargarDataTableListadoCompras();

        $('#tbl_compras tbody').on('click', '.btnImprimirCompra', function() {
            fnc_ImprimirCompra($("#tbl_compras").DataTable().row($(this).parents('tr')).data());
        });

        fnc_OcultarLoader();

    });
    // FIN DE DOCUMENT READY

    function fnc_MostrarLoader() {
        $(".loading").removeClass('d-none');
        $(".loading").addClass('d-block');
    }

    function fnc_OcultarLoader() {
        $(".loading").removeClass('d-block');
        $(".loading").addClass('d-none')
    }

    /*==========================================================================================================================================
    C A R G A R   D A T A T A B L E   L I S T A D O   D E  C O M P R A S
    *=========================================================================================================================================*/
    function fnc_CargarDataTableListadoCompras() {

        if ($.fn.DataTable.isDataTable('#tbl_compras')) {
            $('#tbl_compras').DataTable().destroy();
            $('#tbl_compras tbody').empty();
        }

        $("#tbl_compras").DataTable({
            dom: 'Bfrtip',
            buttons: [{
                extend: 'excel',
                title: function() {
                    var printTitle = 'LISTADO DE COMPRAS';
                    return printTitle
                },
                exportOptions: {
                    columns: [3, 4, 6, 7, 8, 9, 10, 11, 12, 13]
                }
            }, 'pageLength'],
            // fixedColumns: {
            //     left: 2,
            //     right: 2
            // },
            // scrollCollapse: true,
            autoWidth: true,
            scrollX: true,
            pageLength: 10,
            processing: true,
            serverSide: true,
            order: [],
            ajax: {
                url: 'ajax/compras.ajax.php',
                data: {
                    'accion': 'obtener_compras'
                },
                type: 'POST'
            },
            "autoWidth": true,
            columnDefs: [{
                    "className": "dt-center",
                    "targets": "_all"
                },

                {
                    targets: [2, 5],
                    visible: false
                },
                {
                    targets: 13,
                    createdCell: function(td, cellData, rowData, row, col) {

                        if (rowData[13] == 'CONFIRMADO') {
                            $(td).html('<span class="bg-success px-2 py-1 rounded-pill fw-bold"> ' + rowData[13] + ' </span>')
                        }

                        if (rowData[13] == 'REGISTRADO') {
                            $(td).html('<span class="my-bg px-2 py-1 rounded-pill fw-bold text-white"> ' + rowData[13] + ' </span>')
                        }
                    }
                },
                {
                    targets: 0,
                    orderable: false,
                    createdCell: function(td, cellData, rowData, row, col) {

                        if (rowData[13] != 'CONFIRMADO') {
                            $(td).html(`<center> 
                                        <span class='btnImprimirCompra px-1' style='cursor:pointer;' data-bs-toggle='tooltip' data-bs-placement='top' title='Imprimir Compra'> 
                                            <i class='fas fa-file-pdf fs-5 text-danger'></i>
                                        </span>
                                    </center>`);
                        } else {
                            $(td).html(`<center> 
                                        <span class='btnImprimirCompra px-1' style='cursor:pointer;' data-bs-toggle='tooltip' data-bs-placement='top' title='Imprimir Compra'> 
                                            <i class='fas fa-file-pdf fs-5 text-danger'></i>
                                        </span>
                                    </center>`);
                        }

                    }
                },
            ],
            language: {
                url: "ajax/language/spanish.json"
            }
        })

        ajustarHeadersDataTables($("#tbl_compras"))
    }

    function fnc_ImprimirCompra(data) {

        $id_compra = data[1]

        window.open($ruta+'vistas/modulos/impresiones/generar_registro_compra.php?id_compra=' + $id_compra,
            'fullscreen=yes' +
            "resizable=0,"
        );
    }
</script>