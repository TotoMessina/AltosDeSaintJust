/*
------------------------------------------------------------
Trabajo Práctico Integrador - ENTREGA 6
Comisión: 5600
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

--GENERACION DE REPORTES

USE Com5600G03
GO

--REPORTE 1 
-- Se desea analizar el flujo de caja en forma semanal. Debe presentar la recaudación por pagos ordinarios y extraordinarios de cada semana, 
-- el promedio en el periodo, y el acumulado progresivo.  

CREATE OR ALTER PROCEDURE expensa.reporte_recaudacion_semanal
    @FechaInicio DATE = NULL,
    @FechaFin DATE = NULL,
    @ConsorcioId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- CTE para calcular pagos por semana
    WITH PagosPorSemana AS (
        SELECT 
            DATEPART(YEAR, p.fecha) AS anio,
            DATEPART(WEEK, p.fecha) AS semana,
            DATEADD(DAY, 1 - DATEPART(WEEKDAY, p.fecha), p.fecha) AS inicio_semana,
            DATEADD(DAY, 7 - DATEPART(WEEKDAY, p.fecha), p.fecha) AS fin_semana,
            SUM(CASE WHEN p.tipo = 'ORDINARIO' THEN p.importe ELSE 0 END) AS pagos_ordinarios,
            SUM(CASE WHEN p.tipo = 'EXTRAORDINARIO' THEN p.importe ELSE 0 END) AS pagos_extraordinarios,
            SUM(p.importe) AS total_semana
        FROM banco.pago p
        INNER JOIN unidad_funcional.unidad_funcional uf ON p.uf_id = uf.uf_id
        WHERE p.fecha BETWEEN @FechaInicio AND @FechaFin
            AND (@ConsorcioId IS NULL OR uf.consorcio_id = @ConsorcioId)
        GROUP BY 
            DATEPART(YEAR, p.fecha),
            DATEPART(WEEK, p.fecha),
            DATEADD(DAY, 1 - DATEPART(WEEKDAY, p.fecha), p.fecha),
            DATEADD(DAY, 7 - DATEPART(WEEKDAY, p.fecha), p.fecha)
    ),
    PromediosYAcumulados AS (
        SELECT 
            anio,
            semana,
            inicio_semana,
            fin_semana,
            pagos_ordinarios,
            pagos_extraordinarios,
            total_semana,
            AVG(pagos_ordinarios) OVER () AS promedio_ordinarios,
            AVG(pagos_extraordinarios) OVER () AS promedio_extraordinarios,
            AVG(total_semana) OVER () AS promedio_total,
            SUM(pagos_ordinarios) OVER (ORDER BY anio, semana ROWS UNBOUNDED PRECEDING) AS acumulado_ordinarios,
            SUM(pagos_extraordinarios) OVER (ORDER BY anio, semana ROWS UNBOUNDED PRECEDING) AS acumulado_extraordinarios,
            SUM(total_semana) OVER (ORDER BY anio, semana ROWS UNBOUNDED PRECEDING) AS acumulado_total
        FROM PagosPorSemana
    )
    SELECT 
        anio AS Año,
        semana AS Semana,
        CONVERT(VARCHAR(10), inicio_semana, 103) AS Inicio_Semana,
        CONVERT(VARCHAR(10), fin_semana, 103) AS Fin_Semana,
		pagos_ordinarios, 
		pagos_extraordinarios, 
		total_semana, 
		promedio_ordinarios, 
		promedio_extraordinarios, 
		promedio_total, 
		acumulado_ordinarios, 
		acumulado_extraordinarios, 
		acumulado_total
    FROM PromediosYAcumulados
    ORDER BY anio, semana;

END;
GO


	 
------------------------------------------------------------------------------------------------
--REPORTE 2
--Presente el total de recaudación por mes y departamento en formato de tabla cruzada.
--------------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE expensa.reporte_recaudacion_mes_departamento
    @Anio INT = NULL,
    @ConsorcioId INT = NULL,
    @MesInicio INT = 1,
    @MesFin INT = 12
AS
BEGIN
    SET NOCOUNT ON;

    IF @MesInicio < 1 OR @MesInicio > 12 OR @MesFin < 1 OR @MesFin > 12 OR @MesInicio > @MesFin
    BEGIN
        RAISERROR('Los parámetros de mes deben estar entre 1 y 12, y MesInicio debe ser menor o igual a MesFin', 16, 1);
        RETURN;
    END;

    -- CTE para obtener recaudación por mes y departamento
    WITH RecaudacionBase AS (
        SELECT 
            uf.depto AS Departamento,
            MONTH(p.fecha) AS Mes,
            SUM(p.importe) AS Total_Recaudado
        FROM banco.pago p
        INNER JOIN unidad_funcional.unidad_funcional uf ON p.uf_id = uf.uf_id
        WHERE YEAR(p.fecha) = @Anio
            AND MONTH(p.fecha) BETWEEN @MesInicio AND @MesFin
            AND (@ConsorcioId IS NULL OR uf.consorcio_id = @ConsorcioId)
            AND uf.depto IS NOT NULL
        GROUP BY uf.depto, MONTH(p.fecha)
    )
    SELECT 
        Departamento,
        ISNULL([1],0) AS Enero,
        ISNULL([2],0) AS Febrero,
        ISNULL([3],0) AS Marzo,
        ISNULL([4],0) AS Abril,
        ISNULL([5],0) AS Mayo,
        ISNULL([6],0) AS Junio,
        ISNULL([7],0) AS Julio,
        ISNULL([8],0) AS Agosto,
        ISNULL([9],0) AS Septiembre,
        ISNULL([10],0) AS Octubre,
        ISNULL([11],0) AS Noviembre,
        ISNULL([12],0) AS Diciembre,
       
        (ISNULL([1], 0) + ISNULL([2], 0) + ISNULL([3], 0) + ISNULL([4], 0) + 
         ISNULL([5], 0) + ISNULL([6], 0) + ISNULL([7], 0) + ISNULL([8], 0) + 
         ISNULL([9], 0) + ISNULL([10], 0) + ISNULL([11], 0) + ISNULL([12], 0)) AS Total_anual
	 FROM RecaudacionBase
		PIVOT (
			SUM(Total_Recaudado)
			FOR Mes IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
		) AS Cruzado
		ORDER BY Departamento;
	END;
GO



----------------------------------------------------------------------------------
--REPORTE 3: Presente un cuadro cruzado con la recaudación total desagregada 
--según su procedencia (ordinario, extraordinario, etc.) según el periodo. 
---------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE expensa.reporte_recudacion_tipo_periodo
    @Anio INT = NULL,
    @ConsorcioId INT = NULL,
    @TipoPago VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- CTE para obtener recaudación por tipo y periodo
    WITH RecaudacionPorTipo AS (
        SELECT 
            p.tipo AS TipoPago,
            CONCAT(YEAR(p.fecha), '-', RIGHT('0' + CAST(MONTH(p.fecha) AS VARCHAR(2)), 2)) AS Periodo,
            SUM(p.importe) AS TotalRecaudado
        FROM banco.pago p
        INNER JOIN unidad_funcional.unidad_funcional uf ON p.uf_id = uf.uf_id
        WHERE (@Anio IS NULL OR YEAR(p.fecha) = @Anio)
            AND (@ConsorcioId IS NULL OR uf.consorcio_id = @ConsorcioId)
            AND (@TipoPago IS NULL OR p.tipo = @TipoPago)
        GROUP BY p.tipo, YEAR(p.fecha), MONTH(p.fecha)
    )
    -- Generar resultado en formato XML
    SELECT 
        TipoPago AS [@tipo],
        Periodo AS [@periodo],
        TotalRecaudado AS [@total]
    FROM RecaudacionPorTipo
    ORDER BY Periodo, TipoPago
    FOR XML PATH('Recaudacion'), ROOT('Reportes');
END;
GO


----------------------------------------------------------------------------------------
-- REPORTE 4: Obtenga los 5 (cinco) meses de mayores gastos y los 5 (cinco) de mayores ingresos.  
-----------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE expensa.reporte_top_gastos_ingresos
    @Anio INT = NULL,
    @ConsorcioId INT = NULL,
    @TopN INT = 5
AS
BEGIN
    SET NOCOUNT ON;

    -- CTE para calcular gastos por periodo
    WITH GastosPorPeriodo AS (
        SELECT 
            p.periodo_id,
            c.nombre AS Consorcio,
            p.anio,
            p.mes,
            CONCAT(p.anio, '-', RIGHT('0' + CAST(p.mes AS VARCHAR(2)), 2)) AS Periodo,
            SUM(ISNULL(g.importe, 0)) AS TotalGastos
        FROM expensa.periodo p
        INNER JOIN administracion.consorcio c ON p.consorcio_id = c.consorcio_id
        LEFT JOIN expensa.gasto g ON p.periodo_id = g.periodo_id
        WHERE (@Anio IS NULL OR p.anio = @Anio)
            AND (@ConsorcioId IS NULL OR p.consorcio_id = @ConsorcioId)
        GROUP BY p.periodo_id, c.nombre, p.anio, p.mes
    ),
    -- CTE para calcular ingresos por periodo
    IngresosPorPeriodo AS (
        SELECT 
            p.periodo_id,
            c.nombre AS Consorcio,
            p.anio,
            p.mes,
            CONCAT(p.anio, '-', RIGHT('0' + CAST(p.mes AS VARCHAR(2)), 2)) AS Periodo,
            SUM(ISNULL(pg.importe, 0)) AS TotalIngresos
        FROM expensa.periodo p
        INNER JOIN administracion.consorcio c ON p.consorcio_id = c.consorcio_id
        LEFT JOIN unidad_funcional.unidad_funcional uf ON c.consorcio_id = uf.consorcio_id
        LEFT JOIN banco.pago pg ON uf.uf_id = pg.uf_id 
            AND YEAR(pg.fecha) = p.anio 
            AND MONTH(pg.fecha) = p.mes
        WHERE (@Anio IS NULL OR p.anio = @Anio)
            AND (@ConsorcioId IS NULL OR p.consorcio_id = @ConsorcioId)
        GROUP BY p.periodo_id, c.nombre, p.anio, p.mes
    )
    -- Top 5 mayores gastos
    SELECT 
        'MAYORES GASTOS' AS Categoria,
        Consorcio,
        Periodo,
        ISNULL(TotalGastos,0) AS Monto
    FROM (
        SELECT 
            Consorcio,
            Periodo,
            TotalGastos,
            ROW_NUMBER() OVER (ORDER BY TotalGastos DESC) AS Ranking
        FROM GastosPorPeriodo
    ) AS TopGastos
    WHERE Ranking <= @TopN

    UNION ALL

    -- Top 5 mayores ingresos
    SELECT 
        'MAYORES INGRESOS' AS Categoria,
        Consorcio,
        Periodo,
        ISNULL(TotalIngresos,0) AS Monto
    FROM (
        SELECT 
            Consorcio,
            Periodo,
            TotalIngresos,
            ROW_NUMBER() OVER (ORDER BY TotalIngresos DESC) AS Ranking
        FROM IngresosPorPeriodo
    ) AS TopIngresos
    WHERE Ranking <= @TopN
    ORDER BY Categoria, Monto DESC;
END;
GO
-------------------------------------------------------------------------
-----------------------------REPORTE 5-----------------------------------

--Obtenga los 3 (tres) propietarios con mayor morosidad--

CREATE OR ALTER PROCEDURE expensa.reporte_top_morosos
    @ConsorcioId INT,
    @TopN INT,
    @Rol VARCHAR(50) = 'PROPIETARIO'
AS
BEGIN
    SET NOCOUNT ON;

    WITH DeudaPorUF AS (
        SELECT 
            uf.uf_id,
            uf.codigo AS Unidad_Funcional,
            SUM(eu.deuda_anterior + eu.interes_mora) AS DeudaTotal
        FROM expensa.expensa_uf eu
        JOIN expensa.periodo per ON eu.periodo_id = per.periodo_id
        JOIN unidad_funcional.unidad_funcional uf ON eu.uf_id = uf.uf_id
        WHERE uf.consorcio_id = @ConsorcioId
            AND (eu.deuda_anterior > 0 OR eu.interes_mora > 0)
        GROUP BY uf.uf_id, uf.codigo
    ),
    ContactosPreferidos AS (
        SELECT 
            pc.persona_id,
            STRING_AGG(
                CASE pc.tipo
                    WHEN 'email' THEN 'Email: ' + pc.valor
                    WHEN 'telefono' THEN 'Tel: ' + pc.valor
                END,
                ', '
            ) AS Contactos
        FROM persona.persona_contacto pc
        WHERE pc.es_preferido = 1
        GROUP BY pc.persona_id
    )
    SELECT TOP (@TopN)
        d.Unidad_Funcional,
        p.nombre_completo AS Propietario,
        p.tipo_doc AS TipoDocumento,
        p.nro_doc AS NroDocumento,
        p.direccion AS Direccion,
        cp.Contactos,
        d.DeudaTotal
    FROM DeudaPorUF d
    JOIN unidad_funcional.uf_persona_vinculo upv 
        ON d.uf_id = upv.uf_id AND upv.rol = @Rol AND upv.fecha_hasta IS NULL
    JOIN persona.persona p ON upv.persona_id = p.persona_id
    LEFT JOIN ContactosPreferidos cp ON p.persona_id = cp.persona_id
    ORDER BY d.DeudaTotal DESC;
END;
GO

 ---------------------------------------------------------
 --REPORTE 6
 ---------------------------------------------------------
 /*Muestre las fechas de pagos de expensas ordinarias de cada UF y la cantidad de días que
 pasan entre un pago y el siguiente, para el conjunto examinado.*/


CREATE OR ALTER PROCEDURE expensa.reporte_fechas_pagos_uf
    @ConsorcioId INT,
    @UFCodigo INT,
    @TipoPago VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    WITH PagosOrdenados AS (
        SELECT 
            p.pago_id,
            p.fecha AS FechaPago,
            LAG(p.fecha) OVER (ORDER BY p.fecha) AS FechaPagoAnterior,
            p.tipo
        FROM banco.pago p
        INNER JOIN unidad_funcional.unidad_funcional uf 
            ON p.uf_id = uf.uf_id
        WHERE uf.consorcio_id = @ConsorcioId
          AND uf.codigo = @UFCodigo
		  AND p.tipo = @TipoPago
    )
    SELECT 
        p.tipo AS [@tipo_pago],
        CONVERT(VARCHAR(10), FechaPago, 103) AS [@fecha_pago],
        CASE 
            WHEN p.FechaPagoAnterior IS NULL THEN 'Primer pago'
            ELSE CONVERT(VARCHAR(10), p.FechaPagoAnterior, 103)
        END AS [@fecha_pago_anterior],
        CASE 
            WHEN p.FechaPagoAnterior IS NULL THEN NULL
            ELSE DATEDIFF(DAY, p.FechaPagoAnterior, p.FechaPago)
        END AS [@dias_desde_ultimo_pago]
    FROM PagosOrdenados p
    ORDER BY p.FechaPago
    FOR XML PATH('Pago'), ROOT('Reporte_Pagos');
END;
GO

------------------------------------------------------------
--  REPORTE 7 Deudas anteriores y totales de UF en pesos y dolares
------------------------------------------------------------
CREATE OR ALTER PROCEDURE expensa.reporte_deuda_periodo_usd
    @ConsorcioId INT = NULL,
    @Anio INT = NULL,
    @Mes INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @ConsorcioId IS NULL OR @Anio IS NULL OR @Mes IS NULL
    BEGIN
        PRINT 'Debe proporcionar ConsorcioId, Año y Mes';
        RETURN -1;
    END

    -- Consumir API de cotización del dólar
    DECLARE @url NVARCHAR(256) = 'https://dolarapi.com/v1/dolares/oficial'
    DECLARE @Object INT 
    DECLARE @json TABLE(respuesta NVARCHAR(MAX)) 
    DECLARE @respuesta NVARCHAR(MAX)
    DECLARE @CotizacionVenta DECIMAL(18, 2)
    
    -- Crear objeto HTTP 
    EXEC sp_OACreate 'MSXML2.XMLHTTP', @Object OUT 
    EXEC sp_OAMethod @Object, 'OPEN', NULL, 'GET', @url, 'FALSE' 
    EXEC sp_OAMethod @Object, 'SEND' 
    EXEC sp_OAMethod @Object, 'RESPONSETEXT', @respuesta OUTPUT
    
    -- Guardar la respuesta JSON en la tabla 
    INSERT @json 
    EXEC sp_OAGetProperty @Object, 'RESPONSETEXT'
    
    -- Extraer la respuesta a una variable 
    SELECT @respuesta = respuesta FROM @json
    
    -- Extraer el valor de venta del JSON
    SET @CotizacionVenta = JSON_VALUE(@respuesta, '$.venta')
    
    -- Destruir objeto
    EXEC sp_OADestroy @Object

    -- Validar cotización
    IF @CotizacionVenta IS NULL OR @CotizacionVenta = 0
    BEGIN
        SET @CotizacionVenta = 1500.00;
        PRINT 'ADVERTENCIA: No se pudo obtener cotización de API, usando valor por defecto';
    END

    -- Generar reporte
    SELECT 
        c.nombre AS Consorcio,
        CONCAT(@Anio, '-', RIGHT('0' + CAST(@Mes AS VARCHAR(2)), 2)) AS Periodo,
        uf.codigo AS UnidadFuncional,
        ISNULL(pna.nombre_completo, 'Desconocido') AS Propietario,
        
        -- Deudas en ARS
        ISNULL(SUM(eu.deuda_anterior), 0) AS DeudaAnterior_ARS,
        ISNULL(SUM(eu.interes_mora), 0) AS InteresMora_ARS,
        ISNULL(SUM(eu.deuda_anterior + eu.interes_mora), 0) AS DeudaTotal_ARS,
        
        -- Conversión a USD usando API
        ROUND(ISNULL(SUM(eu.deuda_anterior), 0) / @CotizacionVenta, 2) AS DeudaAnterior_USD,
        ROUND(ISNULL(SUM(eu.interes_mora), 0) / @CotizacionVenta, 2) AS InteresMora_USD,
        ROUND(ISNULL(SUM(eu.deuda_anterior + eu.interes_mora), 0) / @CotizacionVenta, 2) AS DeudaTotal_USD,
        
        -- Info de cotización
        @CotizacionVenta AS TasaCambio_ARS_USD,
        GETDATE() AS FechaConsulta
        
    FROM expensa.periodo p
    INNER JOIN administracion.consorcio c 
        ON p.consorcio_id = c.consorcio_id
    INNER JOIN expensa.expensa_uf eu 
        ON p.periodo_id = eu.periodo_id
    INNER JOIN unidad_funcional.unidad_funcional uf 
        ON eu.uf_id = uf.uf_id
    LEFT JOIN unidad_funcional.uf_persona_vinculo upv 
        ON uf.uf_id = upv.uf_id 
        AND upv.rol = 'PROPIETARIO' 
        AND upv.fecha_hasta IS NULL
    LEFT JOIN persona.persona pna 
        ON upv.persona_id = pna.persona_id
    
    WHERE p.consorcio_id = @ConsorcioId
        AND p.anio = @Anio
        AND p.mes = @Mes
        
    GROUP BY c.nombre, uf.codigo, pna.nombre_completo
        
    HAVING SUM(eu.deuda_anterior + eu.interes_mora) > 0
        
    ORDER BY DeudaTotal_ARS DESC;

END;
GO



