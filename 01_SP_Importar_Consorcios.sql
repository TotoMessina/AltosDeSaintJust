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

USE Com5600G03;
GO

-- IMPORTAR TABLA CONSORCIOS DE CSV. Originalmente estos datos se encuentran en una tabla excel, se pide que exporte la hoja como csv para poder realizar la importacion

CREATE OR ALTER PROCEDURE administracion.importar_consorcios
    @RutaArchivo NVARCHAR(300)
AS
BEGIN
    SET NOCOUNT ON;

    CREATE TABLE #Consorcios (
        consorcioId VARCHAR(100), 
        nombreConsorcio VARCHAR(200),
        domicilio VARCHAR(200),
        cantUF INT,
        m2total NUMERIC(12,2)
    );

    DECLARE @SQL NVARCHAR(MAX) = '
        BULK INSERT #Consorcios
        FROM ''' + @RutaArchivo + '''
        WITH (
            FIELDTERMINATOR = '';'',
            ROWTERMINATOR = ''\n'',
			CODEPAGE =''65001'',
            FIRSTROW = 2
        );
    ';
    EXEC (@SQL);
	 
    -- Crear administración base si no existe
    
    IF NOT EXISTS (SELECT 1 FROM administracion.administracion WHERE nombre = 'Administración General')
    BEGIN
        INSERT INTO administracion.administracion (nombre, cuit, domicilio, email, telefono)
        VALUES ('Administración General', '30-00000000-0', 'Av. Principal 100', 'admin@email.com', '1122334455');
		print 'Administracion general creada.';
    END
	DECLARE @admin_id INT = (SELECT TOP 1 administracion_id FROM administracion.administracion WHERE nombre = 'Administración General');


	 -- 2) Insertar consorcios nuevos y capturar IDs
    DECLARE @Nuevos TABLE (consorcio_id INT PRIMARY KEY, nombre VARCHAR(200));

    INSERT INTO administracion.consorcio (administracion_id, nombre, domicilio, superficie_total_m2, fecha_alta)
    OUTPUT inserted.consorcio_id, inserted.nombre INTO @Nuevos(consorcio_id, nombre)
    SELECT
        @admin_id,
		LTRIM(RTRIM(c.nombreConsorcio)),
        LTRIM(RTRIM(c.domicilio)),
        c.m2total,
        GETDATE()
    FROM #Consorcios c
    WHERE NOT EXISTS (
        SELECT 1 FROM administracion.consorcio a WHERE a.nombre = c.nombreConsorcio
    );
	print 'Consorcio insertado.';
    -- Si no hubo nuevos, terminar
    IF NOT EXISTS (SELECT 1 FROM @Nuevos)
    BEGIN
        DROP TABLE #Consorcios;
        RETURN;
    END;

    -- Generar cbu principal para los consoricos
    DECLARE @CBUs TABLE (consorcio_id INT PRIMARY KEY, cbu VARCHAR(22));

    INSERT INTO @CBUs (consorcio_id, cbu)
    SELECT n.consorcio_id,
           (
             SELECT '' + CHAR(48 + (CONVERT(INT, SUBSTRING(r.bytes, d.i, 1)) % 10))
             FROM (VALUES
                  (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),
                  (11),(12),(13),(14),(15),(16),(17),(18),(19),(20),(21),(22)
             ) AS d(i)
             FOR XML PATH(''), TYPE
           ).value('.', 'varchar(22)') AS cbu
    FROM @Nuevos n
    CROSS APPLY (SELECT CRYPT_GEN_RANDOM(22) AS bytes) AS r;

    --  Crear cuentas bancarias 
    DECLARE @InsCtas TABLE (cuenta_id INT PRIMARY KEY, cbu VARCHAR(22));

    INSERT INTO administracion.cuenta_bancaria (banco, cbu_cvu)
    OUTPUT inserted.cuenta_id, inserted.cbu_cvu INTO @InsCtas(cuenta_id, cbu)
    SELECT 'Desconocido', c.cbu
    FROM @CBUs c
    WHERE NOT EXISTS (
        SELECT 1 FROM administracion.cuenta_bancaria cb WHERE cb.cbu_cvu = c.cbu
    );

    --  Vincular en la tabla intermedia como principal
    INSERT INTO administracion.consorcio_cuenta_bancaria (consorcio_id, cuenta_id, es_principal)
    SELECT cbu.consorcio_id, ins.cuenta_id, 1
    FROM @CBUs cbu
    JOIN @InsCtas ins
      ON ins.cbu = cbu.cbu
    WHERE NOT EXISTS (
        SELECT 1
        FROM administracion.consorcio_cuenta_bancaria l
        WHERE l.consorcio_id = cbu.consorcio_id AND l.es_principal = 1
    );
	print 'Cuentas bancarias listas.';

    DROP TABLE #Consorcios;
END;
GO
