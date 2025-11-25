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

USE Com5600G03
GO

CREATE OR ALTER PROCEDURE administracion.cargar_tipo_gastos
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. CARGA DE TIPO_GASTO
	
    CREATE TABLE #tipos(nombre NVARCHAR(100));
    INSERT INTO #tipos (nombre)
    VALUES
        ('GASTOS ORDINARIOS'),
        ('GASTOS EXTRAORDINARIOS');

    INSERT INTO expensa.tipo_gasto (nombre)
    SELECT t.nombre
    FROM #tipos t
    WHERE NOT EXISTS (SELECT 1 FROM expensa.tipo_gasto tg WHERE tg.nombre = t.nombre);

    PRINT 'Tipos de gasto cargados.';

    -- 2. CARGA DE SUB_TIPO_GASTO

    CREATE TABLE #subtipos(tipo_nombre NVARCHAR(100), sub_nombre NVARCHAR(150));

    INSERT INTO #subtipos (tipo_nombre, sub_nombre)
    VALUES
        ('GASTOS ORDINARIOS', 'GASTOS DE LIMPIEZA'),
        ('GASTOS ORDINARIOS', 'GASTOS GENERALES'),
        ('GASTOS ORDINARIOS','SERVICIOS PUBLICOS'),
        ('GASTOS ORDINARIOS', 'GASTOS DE ADMINISTRACION'),
        ('GASTOS ORDINARIOS', 'GASTOS BANCARIOS'),
        ('GASTOS ORDINARIOS', 'SEGUROS'),
		('GASTOS EXTRAORDINARIOS', 'CONSTRUCCIONES'),
        ('GASTOS EXTRAORDINARIOS', 'REPARACIONES');

    INSERT INTO expensa.sub_tipo_gasto (tipo_id, nombre)
    SELECT tg.tipo_id, s.sub_nombre
    FROM #subtipos s
    INNER JOIN expensa.tipo_gasto tg ON tg.nombre = s.tipo_nombre
    WHERE NOT EXISTS (
        SELECT 1 FROM expensa.sub_tipo_gasto sg WHERE sg.nombre = s.sub_nombre
    );

    PRINT 'Subtipos de gasto cargados.';

	DROP TABLE #tipos
	DROP TABLE #subtipos
END;
GO

----------------------------------------------------------------------------------
----------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE administracion.cargar_proveedores
    @RutaArchivo NVARCHAR(400)
AS
BEGIN 
    SET NOCOUNT ON;
    
    BEGIN TRY
        CREATE TABLE #prove(
            tipo NVARCHAR(100),
            tipoNombre NVARCHAR(100),
            detalle NVARCHAR(100),
            nombreConsorcio VARCHAR(100)
        );

        DECLARE @sql_bulk NVARCHAR(MAX) =
        N'BULK INSERT #prove
        FROM N''' + @RutaArchivo + N'''
        WITH (
           FIELDTERMINATOR = '';'',
           ROWTERMINATOR   = ''\n'',
           CODEPAGE        = ''65001'',
           FIRSTROW        = 2 
        );';
        EXEC (@sql_bulk);

        -- Tabla temporal para proveedores únicos del CSV
        -- elimina duplicados dentro del archivo antes de insertar
        CREATE TABLE #proveedores_unicos (
            nombre VARCHAR(200),
            detalle VARCHAR(250),
            consorcio_id INT,
            sub_id INT
        );

        -- Insertar solo registros únicos del CSV (eliminando duplicados del archivo)
        INSERT INTO #proveedores_unicos (nombre, detalle, consorcio_id, sub_id)
        SELECT DISTINCT
            LTRIM(RTRIM(P.tipoNombre)) AS nombre, 
            LTRIM(RTRIM(P.detalle)) AS detalle, 
            con.consorcio_id, 
            sg.sub_id 
        FROM #prove AS P
        INNER JOIN administracion.consorcio AS con 
            ON LTRIM(RTRIM(P.nombreConsorcio)) = con.nombre
        INNER JOIN expensa.sub_tipo_gasto AS sg 
            ON LTRIM(RTRIM(P.tipo)) = sg.nombre
        WHERE P.tipo IS NOT NULL 
          AND P.tipoNombre IS NOT NULL;

        -- Insertar proveedores únicos que no existen en la BD
        INSERT INTO expensa.proveedor(
            nombre,
            detalle,
            consorcio_id,
            sub_id
        )
        SELECT 
            pu.nombre,
            pu.detalle,
            pu.consorcio_id,
            pu.sub_id
        FROM #proveedores_unicos pu
        WHERE NOT EXISTS(
            SELECT 1 
            FROM expensa.proveedor as e
            WHERE e.consorcio_id = pu.consorcio_id
              AND e.sub_id = pu.sub_id
              AND e.nombre = pu.nombre
        );

       
		print 'Proveedores importados'
        DROP TABLE #prove;
        DROP TABLE #proveedores_unicos;
        
    END TRY
    BEGIN CATCH
        PRINT 'Error al cargar proveedores: ' + ERROR_MESSAGE();
        IF OBJECT_ID('tempdb..#prove') IS NOT NULL DROP TABLE #prove;
        IF OBJECT_ID('tempdb..#proveedores_unicos') IS NOT NULL DROP TABLE #proveedores_unicos;
        THROW;
    END CATCH
END;
GO

----------------------------------------------------------------------------------
----------------------------------------------------------------------------------

-- IMPORTAR GASTOS DESDE JSON.
CREATE OR ALTER PROCEDURE administracion.importar_gastos
    @RutaArchivo NVARCHAR(400)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- 1. Tabla temporal para el JSON
        IF OBJECT_ID('tempdb..#gastos_archivo') IS NOT NULL DROP TABLE #gastos_archivo;
        CREATE TABLE #gastos_archivo(
            ConsorcioNombre VARCHAR(200),
            MesNombre VARCHAR(50),
            Bancarios VARCHAR(50),
            Limpieza VARCHAR(50),
            Administracion VARCHAR(50),
            Seguros VARCHAR(50),
            GastosGenerales VARCHAR(50),
            Agua VARCHAR(50),
            Luz VARCHAR(50)
        );

        -- 2. Cargar JSON
        DECLARE @bulk_json NVARCHAR(MAX) = N'
        INSERT INTO #gastos_archivo (
            ConsorcioNombre, MesNombre, Bancarios, Limpieza, Administracion,
            Seguros, GastosGenerales, Agua, Luz
        )
        SELECT
            ConsorcioNombre, Mes, BANCARIOS, LIMPIEZA, ADMINISTRACION,
            SEGUROS, GastosGenerales, Agua, Luz
        FROM OPENROWSET(BULK ''' + @RutaArchivo + ''', SINGLE_CLOB) as j
        CROSS APPLY OPENJSON(BulkColumn)
        WITH (
            ConsorcioNombre VARCHAR(200) ''$."Nombre del consorcio"'',
            Mes VARCHAR(50) ''$.Mes'',
            BANCARIOS VARCHAR(50) ''$.BANCARIOS'',
            LIMPIEZA VARCHAR(50) ''$.LIMPIEZA'',
            ADMINISTRACION VARCHAR(50) ''$.ADMINISTRACION'',
            SEGUROS VARCHAR(50) ''$.SEGUROS'',
            GastosGenerales VARCHAR(50) ''$."GASTOS GENERALES"'',
            Agua VARCHAR(50) ''$."SERVICIOS PUBLICOS-Agua"'',
            Luz VARCHAR(50) ''$."SERVICIOS PUBLICOS-Luz"''
        );';
        EXEC(@bulk_json);

        -- 3. Tabla de mapeo de meses
        CREATE TABLE #mesNumero(
            NombreMes VARCHAR(50) PRIMARY KEY,
            NumeroMes INT
        );
        INSERT INTO #mesNumero (NombreMes, NumeroMes)
        VALUES
            ('enero', 1), ('febrero', 2), ('marzo', 3), ('abril', 4),
            ('mayo', 5), ('junio', 6), ('julio', 7), ('agosto', 8),
            ('septiembre', 9), ('octubre', 10), ('noviembre', 11), ('diciembre', 12);

        -- 4. Insertar gastos con todas las relaciones
        INSERT INTO expensa.gasto (
            consorcio_id,
            periodo_id,
            tipo_id, 
            sub_id,
            proveedor_id,
            importe,
            detalle,
            created_at,
            created_by
        )
        SELECT
            c.consorcio_id,
            p.periodo_id,
            sg.tipo_id, 
            sg.sub_id,
            pr.proveedor_id,
            CASE
                WHEN g.ImporteCrudo IS NULL OR LTRIM(RTRIM(g.ImporteCrudo)) = '' THEN NULL
                WHEN g.ImporteCrudo LIKE '%,%' OR g.ImporteCrudo LIKE '%.%' THEN
                    CAST(
                        CAST(REPLACE(REPLACE(LTRIM(RTRIM(g.ImporteCrudo)), ',', ''), '.', '') AS bigint) / 100.0
                        AS NUMERIC(12,2)
                    )
                ELSE
                    CAST(LTRIM(RTRIM(g.ImporteCrudo)) AS NUMERIC(12,2))
            END AS Importe,
            tg.nombre + ' - ' + g.SubTipoNombre AS detalle,
            GETDATE(),
            'SYSTEM'
        FROM #gastos_archivo AS t
        INNER JOIN administracion.consorcio AS c 
            ON LTRIM(RTRIM(t.ConsorcioNombre)) = c.nombre
        INNER JOIN #mesNumero AS m 
            ON m.NombreMes = LOWER(LTRIM(RTRIM(REPLACE(t.MesNombre, ' ', ''))))
        INNER JOIN expensa.periodo AS p 
            ON c.consorcio_id = p.consorcio_id 
            AND p.anio = YEAR(GETDATE()) 
            AND p.mes = m.NumeroMes
        CROSS APPLY (
            VALUES
                ('BANCARIOS', t.Bancarios),
                ('LIMPIEZA', t.Limpieza),
                ('ADMINISTRACION', t.Administracion),
                ('SEGUROS', t.Seguros),
                ('GASTOS GENERALES', t.GastosGenerales),
                ('Agua', t.Agua),
                ('Luz', t.Luz)
        ) AS g(SubTipoNombre, ImporteCrudo)
        INNER JOIN expensa.sub_tipo_gasto AS sg 
            ON  sg.nombre = CASE g.SubTipoNombre
				WHEN 'BANCARIOS' THEN 'GASTOS BANCARIOS'
                WHEN 'LIMPIEZA' THEN 'GASTOS DE LIMPIEZA'
                WHEN 'ADMINISTRACION' THEN 'GASTOS DE ADMINISTRACION'
                WHEN 'SEGUROS' THEN 'SEGUROS'
                WHEN 'GASTOS GENERALES' THEN 'GASTOS GENERALES'
                WHEN 'Agua' THEN 'SERVICIOS PUBLICOS'
                WHEN 'Luz' THEN 'SERVICIOS PUBLICOS'
                ELSE g.SubTipoNombre
            END
        INNER JOIN expensa.tipo_gasto AS tg 
            ON tg.tipo_id = sg.tipo_id
        LEFT JOIN expensa.proveedor AS pr
            ON pr.sub_id = sg.sub_id 
            AND pr.consorcio_id = c.consorcio_id
        WHERE 
            g.ImporteCrudo IS NOT NULL 
            AND g.ImporteCrudo != '0,00'
            AND NOT EXISTS (
                SELECT 1
                FROM expensa.gasto eg
                WHERE eg.consorcio_id = c.consorcio_id
                  AND eg.periodo_id = p.periodo_id
                  AND eg.sub_id = sg.sub_id
            );

        PRINT 'Gastos importados correctamente';

        DROP TABLE #gastos_archivo;
        DROP TABLE #mesNumero;
        
    END TRY
    BEGIN CATCH
        PRINT 'Error al importar gastos: ' + ERROR_MESSAGE();
        IF OBJECT_ID('tempdb..#gastos_archivo') IS NOT NULL DROP TABLE #gastos_archivo;
        IF OBJECT_ID('tempdb..#mesNumero') IS NOT NULL DROP TABLE #mesNumero;
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE administracion.crear_periodos
    @Anio SMALLINT
AS
BEGIN
    SET NOCOUNT ON
    INSERT INTO expensa.periodo (consorcio_id, anio, mes, vencimiento_1, vencimiento_2)
    SELECT 
        c.consorcio_id,
        @Anio,
        m.mes,
        DATEFROMPARTS(@Anio, m.mes, 10),
        DATEFROMPARTS(@Anio, m.mes, 20)
    FROM administracion.consorcio c
    CROSS JOIN (VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12)) AS m(mes)
    WHERE NOT EXISTS (
        SELECT 1 FROM expensa.periodo p
        WHERE p.consorcio_id = c.consorcio_id 
          AND p.anio = @Anio 
          AND p.mes = m.mes
    );
END;
GO


