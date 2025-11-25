/*
------------------------------------------------------------
Trabajo Práctico Integrador - ENTREGA 7
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

USE Com5600G03;
GO


CREATE OR ALTER PROCEDURE expensa.reporte_top_morosos
    @ConsorcioId INT,
    @TopN INT,
    @Rol VARCHAR(50) = 'PROPIETARIO'
AS
BEGIN
    SET NOCOUNT ON;
    
   
    DECLARE @FraseClave NVARCHAR(128) = N'MiClaveSegura2025$';

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
                    WHEN 'EMAIL' THEN 'Email: ' + CONVERT(VARCHAR(200), 
                        DecryptByPassPhrase(@FraseClave, pc.valor_Cifrado, 1, pc.valor_Dec))
                    WHEN 'TELEFONO' THEN 'Tel: ' + CONVERT(VARCHAR(200), 
                        DecryptByPassPhrase(@FraseClave, pc.valor_Cifrado, 1, pc.valor_Dec))
                END, ', '
            ) AS Contactos
        FROM persona.persona_contacto pc
        WHERE pc.es_preferido = 1
        GROUP BY pc.persona_id
    )
    SELECT TOP (@TopN)
        d.Unidad_Funcional,
        CONVERT(VARCHAR(200), 
            DecryptByPassPhrase(@FraseClave, p.nombre_completo_Cifrado, 1, p.nombre_completo_Dec)
        ) AS Propietario,
        p.tipo_doc AS TipoDocumento,
        CONVERT(VARCHAR(40), 
            DecryptByPassPhrase(@FraseClave, p.nro_doc_Cifrado, 1, p.nro_doc_Dec)
        ) AS NroDocumento,
        p.direccion AS Direccion,
        cp.Contactos,
        d.DeudaTotal
    FROM DeudaPorUF d
    JOIN unidad_funcional.uf_persona_vinculo upv 
        ON d.uf_id = upv.uf_id 
        AND upv.rol = @Rol 
        AND upv.fecha_hasta IS NULL
    JOIN persona.persona p ON upv.persona_id = p.persona_id
    LEFT JOIN ContactosPreferidos cp ON p.persona_id = cp.persona_id
    ORDER BY d.DeudaTotal DESC;
END;
GO


CREATE OR ALTER PROCEDURE expensa.reporte_deuda_periodo_usd
    @ConsorcioId INT = NULL,
    @Anio INT = NULL,
    @Mes INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
  
    DECLARE @FraseClave NVARCHAR(128) = N'MiClaveSegura2025$';

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

    -- Generar reporte con descifrado
    SELECT 
        c.nombre AS Consorcio,
        CONCAT(@Anio, '-', RIGHT('0' + CAST(@Mes AS VARCHAR(2)), 2)) AS Periodo,
        uf.codigo AS UnidadFuncional,
        ISNULL(
            CONVERT(VARCHAR(200), 
                DecryptByPassPhrase(@FraseClave, pna.nombre_completo_Cifrado, 1, pna.nombre_completo_Dec)
            ), 
            'Desconocido'
        ) AS Propietario,
        
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
        
    GROUP BY 
        c.nombre, 
        uf.codigo, 
        pna.nombre_completo_Cifrado, 
        pna.nombre_completo_Dec
        
    HAVING SUM(eu.deuda_anterior + eu.interes_mora) > 0
        
    ORDER BY DeudaTotal_ARS DESC;
END;
GO