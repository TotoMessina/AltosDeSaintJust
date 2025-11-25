/*
------------------------------------------------------------
Trabajo Pr�ctico Integrador - ENTREGA 5
Comisi�n: 5600
Grupo: 03
Materia: Bases de Datos Aplicada
Integrantes: 
Apellido y Nombre             - Github          - DNI
Villan Matias Nicolas         - MatiasKV0       - 46117338
Lucas Tadeo Messina           - TotoMessina     - 44552900
Oliveti Lautaro Nahuel        - lautioliveti    - 43863497
Mamani Estrada Lucas Gabriel  - lucasGME        - 43624305
Sotelo Matias Ivan            - MatiSotelo2004  - 45870010
------------------------------------------------------------
*/

USE Com5600G03;
GO

CREATE OR ALTER PROCEDURE banco.importar_conciliar_pagos
    @RutaArchivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    ---------------------------------------------------------
    -- 1) Cargar CSV en tabla temporal
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#PagosCSV') IS NOT NULL DROP TABLE #PagosCSV;
    
    CREATE TABLE #PagosCSV (
        id_pago_externo VARCHAR(50),
        fecha_texto VARCHAR(20),
        cbu_origen VARCHAR(40),
        valor_texto VARCHAR(50)
    );

    DECLARE @SQL NVARCHAR(MAX);
    SET @SQL = '
        BULK INSERT #PagosCSV
        FROM ''' + @RutaArchivo + '''
        WITH (
            FIELDTERMINATOR = '','',
            ROWTERMINATOR = ''\n'',
            FIRSTROW = 2,
            CODEPAGE = ''65001''
        );
    ';

    BEGIN TRY
        EXEC (@SQL);
    END TRY
    BEGIN CATCH
        PRINT 'Error al cargar el CSV: ' + ERROR_MESSAGE();
        DROP TABLE #PagosCSV;
        RETURN -1;
    END CATCH;


    ---------------------------------------------------------
    -- 2) Procesar pagos y determinar UF, consorcio y cuenta destino
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#PagosProcesados') IS NOT NULL DROP TABLE #PagosProcesados;

    SELECT
        csv.id_pago_externo,
        LTRIM(RTRIM(csv.cbu_origen)) AS cbu_origen,
        CONVERT(DATE, csv.fecha_texto, 103) AS fecha_pago,

        TRY_CAST(
            REPLACE(REPLACE(LTRIM(RTRIM(csv.valor_texto)), '$', ''), '.', '')
            AS NUMERIC(14,2)
        ) AS importe_pago,

        ufc.uf_id,
        uf.consorcio_id AS consorcio_id_origen,

        cb_origen.cuenta_id AS cuenta_origen_id,

        -- Selección automática de la cuenta principal del consorcio
        ccb_principal.cuenta_id AS cuenta_destino_id,

        CASE 
            WHEN ufc.uf_id IS NULL THEN 'CBU no vinculado a una UF'
            WHEN ccb_principal.cuenta_id IS NULL THEN 'El consorcio no tiene cuenta principal'
            ELSE NULL 
        END AS motivo_no_vinculado

    INTO #PagosProcesados
    FROM #PagosCSV csv
    LEFT JOIN administracion.cuenta_bancaria cb_origen 
        ON cb_origen.cbu_cvu = csv.cbu_origen
    LEFT JOIN unidad_funcional.uf_cuenta ufc 
        ON cb_origen.cuenta_id = ufc.cuenta_id AND ufc.fecha_hasta IS NULL
    LEFT JOIN unidad_funcional.unidad_funcional uf 
        ON uf.uf_id = ufc.uf_id
    LEFT JOIN administracion.consorcio_cuenta_bancaria ccb_principal
        ON ccb_principal.consorcio_id = uf.consorcio_id
       AND ccb_principal.es_principal = 1;


    ---------------------------------------------------------
    -- 3) Insertar movimientos sin duplicados
    ---------------------------------------------------------
    DECLARE @MovimientosInsertados TABLE (
        movimiento_id INT,
        cbu_origen VARCHAR(40),
        fecha DATE,
        importe NUMERIC(14,2)
    );

    INSERT INTO banco.banco_movimiento (
        consorcio_id,
        cuenta_id,
        cbu_origen,
        fecha,
        importe,
        estado_conciliacion
    )
    OUTPUT
        inserted.movimiento_id,
        inserted.cbu_origen,
        inserted.fecha,
        inserted.importe
    INTO @MovimientosInsertados
    SELECT
        p.consorcio_id_origen,
        p.cuenta_destino_id,
        p.cbu_origen,
        p.fecha_pago,
        p.importe_pago,
        CASE WHEN p.uf_id IS NOT NULL THEN 'ASOCIADO'
             ELSE 'PENDIENTE'
        END
    FROM #PagosProcesados p
    WHERE p.importe_pago IS NOT NULL
      AND p.consorcio_id_origen IS NOT NULL
      AND p.cuenta_destino_id IS NOT NULL
      AND NOT EXISTS (
            SELECT 1
            FROM banco.banco_movimiento bm
            WHERE bm.cbu_origen = p.cbu_origen
              AND bm.fecha      = p.fecha_pago
              AND bm.importe    = p.importe_pago
              AND bm.cuenta_id  = p.cuenta_destino_id
      );


    ---------------------------------------------------------
    -- 4) Insertar pagos sin duplicados
    ---------------------------------------------------------
    INSERT INTO banco.pago (
        uf_id,
        fecha,
        importe,
        tipo,
        movimiento_id,
        motivo_no_asociado,
        created_by
    )
    SELECT
        p.uf_id,
        p.fecha_pago,
        p.importe_pago,
        'ORDINARIO',
        mi.movimiento_id,
        p.motivo_no_vinculado,
        'SP_Importar'
    FROM #PagosProcesados p
    JOIN @MovimientosInsertados mi
      ON p.cbu_origen = mi.cbu_origen
     AND p.fecha_pago = mi.fecha
     AND p.importe_pago = mi.importe
    WHERE NOT EXISTS (
        SELECT 1 FROM banco.pago px
        WHERE px.uf_id = p.uf_id
          AND px.fecha = p.fecha_pago
          AND px.importe = p.importe_pago
          AND px.movimiento_id = mi.movimiento_id
    );

    DROP TABLE #PagosCSV;
    DROP TABLE #PagosProcesados;

END;
GO


-----------------------------------------------------------------------
----LLENAR EXPENSAS Y SIMULAR DEUDA
----------------------------------------------------------------------
CREATE OR ALTER PROCEDURE expensa.llenar_expensas
AS
BEGIN
    SET NOCOUNT ON;
	
	BEGIN TRY 
    INSERT INTO expensa.expensa_uf (
        periodo_id,
        uf_id,
        porcentaje,
        saldo_anterior_abonado,
        pagos_recibidos,
        deuda_anterior,
        interes_mora,
        expensas_ordinarias,
        expensas_extraordinarias,
        total_a_pagar,
        created_at,
        created_by
    )
    SELECT 
        per.periodo_id,
        uf.uf_id,
        uf.porcentaje,
        0 AS saldo_anterior_abonado,
        
        -- Pagos recibidos en ese mes (de la tabla banco.pago)
        ISNULL((
            SELECT SUM(p.importe)
            FROM banco.pago p
            WHERE p.uf_id = uf.uf_id
                AND YEAR(p.fecha) = per.anio
                AND MONTH(p.fecha) = per.mes
        ), 0) AS pagos_recibidos,
        
        -- Deuda anterior simulada (30% de las unidades funcionales con deuda) para poder probar los reportes
        CASE 
            WHEN uf.uf_id % 3 = 0 THEN ROUND(50000 + (uf.uf_id * 1234.56), 2)
            WHEN uf.uf_id % 5 = 0 THEN ROUND(30000 + (uf.uf_id * 789.12), 2)
            ELSE 0
        END AS deuda_anterior,
        
        -- Interes de mora (2% entre vtos, 5% post 2do vto)
        CASE 
            WHEN uf.uf_id % 3 = 0 THEN 
                ROUND((50000 + (uf.uf_id * 1234.56)) * per.interes_post_2do_pct / 100, 2)
            WHEN uf.uf_id % 5 = 0 THEN 
                ROUND((30000 + (uf.uf_id * 789.12)) * per.interes_entre_vtos_pct / 100, 2)
            ELSE 0
        END AS interes_mora,
        
       -- Expensas ordinarias 
        ISNULL((
            SELECT SUM(g.importe)
            FROM expensa.gasto g
            INNER JOIN expensa.tipo_gasto tg ON g.tipo_id = tg.tipo_id
            WHERE g.periodo_id = per.periodo_id
              AND g.consorcio_id = uf.consorcio_id
              AND tg.nombre = 'GASTOS ORDINARIOS'
        ), 0) AS expensas_ordinarias,

        -- Expensas extraordinarias
        ISNULL((
            SELECT SUM(g.importe)
            FROM expensa.gasto g
            INNER JOIN expensa.tipo_gasto tg ON g.tipo_id = tg.tipo_id
            WHERE g.periodo_id = per.periodo_id
              AND g.consorcio_id = uf.consorcio_id
              AND tg.nombre = 'GASTOS EXTRAORDINARIOS'
        ), 0) AS expensas_extraordinarias,
        
        -- Total a pagar
         ROUND(
            -- Deuda anterior
            (
                CASE 
                    WHEN uf.uf_id % 3 = 0 THEN (50000 + (uf.uf_id * 1234.56))
                    WHEN uf.uf_id % 5 = 0 THEN (30000 + (uf.uf_id * 789.12))
                    ELSE 0
                END
            ) +
            -- Interés de mora
            (
                CASE 
                    WHEN uf.uf_id % 3 = 0 THEN ((50000 + (uf.uf_id * 1234.56)) * per.interes_post_2do_pct / 100)
                    WHEN uf.uf_id % 5 = 0 THEN ((30000 + (uf.uf_id * 789.12)) * per.interes_entre_vtos_pct / 100)
                    ELSE 0
                END
            ) +
            -- Expensas ordinarias
            ISNULL((
                SELECT SUM(g.importe)
                FROM expensa.gasto g
                INNER JOIN expensa.tipo_gasto tg ON g.tipo_id = tg.tipo_id
                WHERE g.periodo_id = per.periodo_id
                    AND g.consorcio_id = uf.consorcio_id
                    AND tg.nombre = 'GASTOS ORDINARIOS'
            ), 0) +
            -- Expensas extraordinarias
            ISNULL((
                SELECT SUM(g.importe)
                FROM expensa.gasto g
                INNER JOIN expensa.tipo_gasto tg ON g.tipo_id = tg.tipo_id
                WHERE g.periodo_id = per.periodo_id
                    AND g.consorcio_id = uf.consorcio_id
                    AND tg.nombre = 'GASTOS EXTRAORDINARIOS'
            ), 0)
        , 2) AS total_a_pagar,
        
        GETDATE(),
        'SP-LLENAR_EXPENSAS'

    FROM unidad_funcional.unidad_funcional uf
    CROSS JOIN expensa.periodo per
    WHERE uf.consorcio_id = per.consorcio_id
        AND EXISTS (
            SELECT 1 FROM expensa.gasto g 
            WHERE g.periodo_id = per.periodo_id
        );
    
    -- Generar detalles de expensas
    INSERT INTO expensa.expensa_uf_detalle (
        expensa_uf_id,
        gasto_id,
        concepto,
        importe
    )
    SELECT 
        eu.expensa_uf_id,
        g.gasto_id,
        sg.nombre AS concepto,
        g.importe
    FROM expensa.expensa_uf eu
    INNER JOIN unidad_funcional.unidad_funcional uf ON eu.uf_id = uf.uf_id
    INNER JOIN expensa.gasto g ON g.periodo_id = eu.periodo_id 
        AND g.consorcio_id = uf.consorcio_id
    INNER JOIN expensa.sub_tipo_gasto sg ON g.sub_id = sg.sub_id;
    
    -- Generar intereses

    INSERT INTO expensa.expensa_uf_interes (
        expensa_uf_id,
        tipo,
        porcentaje,
        importe
    )
    SELECT 
        eu.expensa_uf_id,
        CASE WHEN eu.uf_id % 3 = 0 THEN 'POST_2DO' ELSE 'ENTRE_VTOS' END AS tipo,
        CASE WHEN eu.uf_id % 3 = 0 THEN 5.000 ELSE 2.000 END AS porcentaje,
        eu.interes_mora
    FROM expensa.expensa_uf eu
    WHERE eu.interes_mora > 0;
	END TRY
	BEGIN CATCH
	 print 'Pagos importados'
	END CATCH	
END;
GO