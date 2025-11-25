/*
------------------------------------------------------------
Trabajo Práctico Integrador - ENTREGA 5
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

-- IMPORTAR TABLA DE UNIDAD FUNCIONAL DESDE TXT.

USE Com5600G03;
GO

CREATE OR ALTER PROCEDURE administracion.importar_uf
    @RutaArchivo NVARCHAR(400)
AS
BEGIN
    SET NOCOUNT ON;

    ------------------------------------------------------------
    -- 1. Crear tabla temporal
    ------------------------------------------------------------
    IF OBJECT_ID('tempdb..#uf_archivo') IS NOT NULL
        DROP TABLE #uf_archivo;

    CREATE TABLE #uf_archivo (
        NombreConsorcio VARCHAR(200),
        NroUF           VARCHAR(20),
        Piso            VARCHAR(20),
        Depto           VARCHAR(20),
        Coeficiente     VARCHAR(50),
        M2UF            VARCHAR(50),
        Bauleras        VARCHAR(10),
        Cochera         VARCHAR(10),
        M2Baulera       VARCHAR(50),
        M2Cochera       VARCHAR(50)
    );

    ------------------------------------------------------------
    -- 2. Cargar el archivo TXT 
    ------------------------------------------------------------
    DECLARE @sql_bulk NVARCHAR(MAX) =
        N'BULK INSERT #uf_archivo
          FROM N''' + @RutaArchivo + N'''
          WITH (
            FIELDTERMINATOR = ''\t'',  
            ROWTERMINATOR   = ''\n'',
            CODEPAGE        = ''65001'',
            FIRSTROW        = 2
          );';
    
    BEGIN TRY
        EXEC (@sql_bulk);
    END TRY
    BEGIN CATCH
        PRINT 'Error: No se pudo cargar el archivo.';
        PRINT ERROR_MESSAGE();
        IF OBJECT_ID('tempdb..#uf_archivo') IS NOT NULL
            DROP TABLE #uf_archivo;
        RETURN -1;
    END CATCH;

    ------------------------------------------------------------
    -- 3. Crear tabla temporal de datos procesados 
    ------------------------------------------------------------
    IF OBJECT_ID('tempdb..#uf_procesadas') IS NOT NULL
        DROP TABLE #uf_procesadas;

    SELECT
        c.consorcio_id,
        u.NroUF,
        u.Piso,
        u.Depto,
        u.Bauleras,
        u.Cochera,
        TRY_CONVERT(NUMERIC(18, 6), REPLACE(REPLACE(LTRIM(RTRIM(ISNULL(u.M2UF, '0'))), '.', ''), ',', '.')) AS M2UF,
        TRY_CONVERT(NUMERIC(18, 6), REPLACE(REPLACE(LTRIM(RTRIM(ISNULL(u.M2Baulera, '0'))), '.', ''), ',', '.')) AS M2Baulera,
        TRY_CONVERT(NUMERIC(18, 6), REPLACE(REPLACE(LTRIM(RTRIM(ISNULL(u.M2Cochera, '0'))), '.', ''), ',', '.')) AS M2Cochera,
        TRY_CONVERT(NUMERIC(18, 6), REPLACE(REPLACE(LTRIM(RTRIM(ISNULL(u.Coeficiente, '0'))), '.', ''), ',', '.')) AS Coeficiente

    INTO #uf_procesadas
    FROM #uf_archivo u
    JOIN administracion.consorcio c
        ON c.nombre = u.NombreConsorcio
    WHERE
        u.NroUF IS NOT NULL AND u.NombreConsorcio IS NOT NULL
        AND LTRIM(RTRIM(u.NroUF)) <> '';

    DROP TABLE #uf_archivo;

    ------------------------------------------------------------
    -- 4. INSERTAR Unidades Funcionales (UF)
    ------------------------------------------------------------
    PRINT 'Importando Unidades Funcionales...';
    
    INSERT INTO unidad_funcional.unidad_funcional
        (consorcio_id, codigo, piso, depto, superficie_m2, porcentaje)
    SELECT
        p.consorcio_id,
        p.NroUF AS codigo,
        p.Piso,
        p.Depto,
        CAST(p.M2UF AS NUMERIC(12,2)) AS superficie_m2,
        
        CAST(p.Coeficiente AS NUMERIC(7,4)) AS porcentaje

    FROM #uf_procesadas p
    WHERE NOT EXISTS (
        SELECT 1
        FROM unidad_funcional.unidad_funcional uf_ex
        WHERE uf_ex.consorcio_id = p.consorcio_id
          AND uf_ex.codigo = p.NroUF
    );

    ------------------------------------------------------------
    -- 5. INSERTAR Bauleras
    ------------------------------------------------------------
    PRINT 'Importando Bauleras...';
    
    INSERT INTO unidad_funcional.baulera
        (consorcio_id, uf_id, codigo, superficie_m2, porcentaje)
    SELECT
        p.consorcio_id,
        uf.uf_id,
        CONCAT('B-', LTRIM(RTRIM(p.NroUF))) AS codigo,
        CAST(p.M2Baulera AS NUMERIC(12,2)),
        CAST(p.Coeficiente AS NUMERIC(7,4)) AS porcentaje

    FROM #uf_procesadas p
    JOIN unidad_funcional.unidad_funcional uf 
        ON uf.consorcio_id = p.consorcio_id
        AND uf.codigo = p.NroUF
    WHERE
        p.Bauleras = 'SI'
    AND NOT EXISTS (
        SELECT 1
        FROM unidad_funcional.baulera b
        WHERE b.consorcio_id = p.consorcio_id
          AND b.codigo = CONCAT('B-', LTRIM(RTRIM(p.NroUF)))
    );

    ------------------------------------------------------------
    -- 6. INSERTAR Cocheras
    ------------------------------------------------------------
    PRINT 'Importando Cocheras...';
    
    INSERT INTO unidad_funcional.cochera
        (consorcio_id, uf_id, codigo, superficie_m2, porcentaje)
    SELECT
        p.consorcio_id,
        uf.uf_id,
        CONCAT('C-', LTRIM(RTRIM(p.NROUF))) AS codigo,
        CAST(p.M2Cochera AS NUMERIC(12,2)),
        
        CAST(p.Coeficiente AS NUMERIC(7,4)) AS porcentaje

    FROM #uf_procesadas p
    JOIN unidad_funcional.unidad_funcional uf 
        ON uf.consorcio_id = p.consorcio_id
        AND uf.codigo = p.NroUF
    WHERE
        p.Cochera = 'SI'
    AND NOT EXISTS (
        SELECT 1
        FROM unidad_funcional.cochera c
        WHERE c.consorcio_id = p.consorcio_id
          AND c.codigo = CONCAT('C-', LTRIM(RTRIM(p.NroUF)))
    );

    ------------------------------------------------------------
    -- 7. Limpieza final
    ------------------------------------------------------------
    DROP TABLE #uf_procesadas;

    PRINT 'Importación de Archivo UF (UF, Bauleras, Cocheras) finalizada.';
    
    SET NOCOUNT OFF;
END;
GO