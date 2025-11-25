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

------------------------------------------------------------
-- SP MODIFICADO: importar_consorcios
------------------------------------------------------------
CREATE OR ALTER PROCEDURE administracion.importar_consorcios
    @RutaArchivo NVARCHAR(300)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @FraseClave NVARCHAR(128) = N'MiClaveSegura2025$';

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
        PRINT 'Administracion general creada.';
    END
    
    DECLARE @admin_id INT = (SELECT TOP 1 administracion_id FROM administracion.administracion WHERE nombre = 'Administración General');

    -- Insertar consorcios nuevos y capturar IDs
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
    
    PRINT 'Consorcios insertados: ' + CAST(@@ROWCOUNT AS VARCHAR(10));
    
    -- Si no hubo nuevos, terminar
    IF NOT EXISTS (SELECT 1 FROM @Nuevos)
    BEGIN
        DROP TABLE #Consorcios;
        PRINT 'No hay consorcios nuevos para procesar.';
        RETURN;
    END;

    -- Generar CBU principal para los consorcios
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

    -- Crear cuentas bancarias CON CIFRADO
    DECLARE @InsCtas TABLE (cuenta_id INT PRIMARY KEY, cbu VARCHAR(22));

    INSERT INTO administracion.cuenta_bancaria (
        banco, 
        cbu_cvu_Cifrado,
        cbu_cvu_Hash,
        cbu_cvu_Dec
    )
    OUTPUT inserted.cuenta_id, 
           CONVERT(VARCHAR(22), DecryptByPassPhrase(@FraseClave, inserted.cbu_cvu_Cifrado, 1, inserted.cbu_cvu_Dec))
    INTO @InsCtas(cuenta_id, cbu)
    SELECT 
        'Desconocido', 
        EncryptByPassPhrase(@FraseClave, c.cbu, 1, CONVERT(VARBINARY, c.cbu)),
        HASHBYTES('SHA2_256', c.cbu),
        CONVERT(VARBINARY, c.cbu)
    FROM @CBUs c
    WHERE NOT EXISTS (
        SELECT 1 FROM administracion.cuenta_bancaria cb 
        WHERE cb.cbu_cvu_Hash = HASHBYTES('SHA2_256', c.cbu)
    );

    PRINT 'Cuentas bancarias creadas: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

    -- Vincular en la tabla intermedia como principal
    INSERT INTO administracion.consorcio_cuenta_bancaria (consorcio_id, cuenta_id, es_principal)
    SELECT cbu.consorcio_id, ins.cuenta_id, 1
    FROM @CBUs cbu
    JOIN @InsCtas ins ON ins.cbu = cbu.cbu
    WHERE NOT EXISTS (
        SELECT 1
        FROM administracion.consorcio_cuenta_bancaria l
        WHERE l.consorcio_id = cbu.consorcio_id AND l.es_principal = 1
    );
    
    PRINT 'Vínculos consorcio-cuenta creados: ' + CAST(@@ROWCOUNT AS VARCHAR(10));
    PRINT 'Cuentas bancarias listas.';

    DROP TABLE #Consorcios;
END;
GO

------------------------------------------------------------
-- SP MODIFICADO: importar_inquilinos_propietarios
------------------------------------------------------------
CREATE OR ALTER PROCEDURE persona.importar_inquilinos_propietarios
    @RutaArchivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @FraseClave NVARCHAR(128) = N'MiClaveSegura2025$';

    IF OBJECT_ID('tempdb..#InquilinosPropietarios') IS NOT NULL
        DROP TABLE #InquilinosPropietarios;

    CREATE TABLE #InquilinosPropietarios (
        nombre VARCHAR(100),
        apellido VARCHAR(100),
        dni VARCHAR(20),
        email_personal VARCHAR(150),
        telefono_contacto VARCHAR(50),
        cbu_cvu VARCHAR(40),
        inquilino BIT
    );

    -- Cargar CSV
    DECLARE @SQL NVARCHAR(MAX);
    SET @SQL = '
        BULK INSERT #InquilinosPropietarios
        FROM ''' + @RutaArchivo + '''
        WITH (
            FIELDTERMINATOR = '';'',
            ROWTERMINATOR = ''\n'',
            FIRSTROW = 2,
            CODEPAGE = ''65001''
        );
    ';
    EXEC (@SQL);

    -- Insertar personas CON CIFRADO
    INSERT INTO persona.persona (
        tipo_doc,
        direccion,
        nro_doc_Cifrado,
        nro_doc_Hash,
        nro_doc_Dec,
        nombre_completo_Cifrado,
        nombre_completo_Hash,
        nombre_completo_Dec
    )
    SELECT
        'DNI',
        NULL,
        EncryptByPassPhrase(
            @FraseClave,
            i.dni,
            1,
            CONVERT(VARBINARY, i.dni)
        ),
        HASHBYTES('SHA2_256', i.dni),
        CONVERT(VARBINARY, i.dni),
        
        EncryptByPassPhrase(
            @FraseClave,
            UPPER(RTRIM(LTRIM(ISNULL(i.nombre, '')) +' '+ RTRIM(LTRIM(ISNULL(i.apellido, ''))))),
            1,
            CONVERT(VARBINARY, UPPER(RTRIM(LTRIM(ISNULL(i.nombre, '')) +' '+ RTRIM(LTRIM(ISNULL(i.apellido, ''))))))
        ),
        HASHBYTES('SHA2_256', UPPER(RTRIM(LTRIM(ISNULL(i.nombre, '')) +' '+ RTRIM(LTRIM(ISNULL(i.apellido, '')))))),
        CONVERT(VARBINARY, UPPER(RTRIM(LTRIM(ISNULL(i.nombre, '')) +' '+ RTRIM(LTRIM(ISNULL(i.apellido, ''))))))
    FROM (
        SELECT DISTINCT dni, nombre, apellido
        FROM #InquilinosPropietarios
        WHERE dni IS NOT NULL AND LTRIM(RTRIM(dni)) <> ''
    ) i
    WHERE NOT EXISTS (
        SELECT 1 FROM persona.persona p 
        WHERE p.nro_doc_Hash = HASHBYTES('SHA2_256', i.dni)
    );

    PRINT 'Personas insertadas: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

    -- Insertar contactos de EMAIL CON CIFRADO
    INSERT INTO persona.persona_contacto (
        persona_id, 
        tipo, 
        valor_Cifrado,
        valor_Hash,
        valor_Dec,
        es_preferido
    )
    SELECT 
        p.persona_id,
        'EMAIL',
        EncryptByPassPhrase(
            @FraseClave,
            LOWER(RTRIM(LTRIM(i.email_personal))),
            1,
            CONVERT(VARBINARY, LOWER(RTRIM(LTRIM(i.email_personal))))
        ),
        HASHBYTES('SHA2_256', LOWER(RTRIM(LTRIM(i.email_personal)))),
        CONVERT(VARBINARY, LOWER(RTRIM(LTRIM(i.email_personal)))),
        1
    FROM #InquilinosPropietarios i
    JOIN persona.persona p ON p.nro_doc_Hash = HASHBYTES('SHA2_256', i.dni)
    WHERE i.email_personal IS NOT NULL
      AND LTRIM(RTRIM(i.email_personal)) <> ''
      AND NOT EXISTS (
        SELECT 1 FROM persona.persona_contacto c 
        WHERE c.persona_id = p.persona_id 
          AND c.valor_Hash = HASHBYTES('SHA2_256', LOWER(RTRIM(LTRIM(i.email_personal))))
    );

    PRINT 'Emails insertados: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

    -- Insertar contactos de TELEFONO CON CIFRADO
    INSERT INTO persona.persona_contacto (
        persona_id, 
        tipo, 
        valor_Cifrado,
        valor_Hash,
        valor_Dec,
        es_preferido
    )
    SELECT 
        p.persona_id,
        'TELEFONO',
        EncryptByPassPhrase(
            @FraseClave,
            i.telefono_contacto,
            1,
            CONVERT(VARBINARY, i.telefono_contacto)
        ),
        HASHBYTES('SHA2_256', i.telefono_contacto),
        CONVERT(VARBINARY, i.telefono_contacto),
        0
    FROM #InquilinosPropietarios i
    JOIN persona.persona p ON p.nro_doc_Hash = HASHBYTES('SHA2_256', i.dni)
    WHERE i.telefono_contacto IS NOT NULL
      AND LTRIM(RTRIM(i.telefono_contacto)) <> ''
      AND NOT EXISTS (
        SELECT 1 FROM persona.persona_contacto c 
        WHERE c.persona_id = p.persona_id 
          AND c.valor_Hash = HASHBYTES('SHA2_256', i.telefono_contacto)
    );

    PRINT 'Teléfonos insertados: ' + CAST(@@ROWCOUNT AS VARCHAR(10));
    
    -- Insertar cuentas bancarias CON CIFRADO
    INSERT INTO administracion.cuenta_bancaria (
        banco, 
        alias, 
        cbu_cvu_Cifrado,
        cbu_cvu_Hash,
        cbu_cvu_Dec
    )
    SELECT 
        'Desconocido',
        NULL,
        EncryptByPassPhrase(
            @FraseClave,
            i.cbu_cvu,
            1,
            CONVERT(VARBINARY, i.cbu_cvu)
        ),
        HASHBYTES('SHA2_256', i.cbu_cvu),
        CONVERT(VARBINARY, i.cbu_cvu)
    FROM #InquilinosPropietarios i
    WHERE i.cbu_cvu IS NOT NULL
      AND LTRIM(RTRIM(i.cbu_cvu)) <> ''
      AND NOT EXISTS (
        SELECT 1 FROM administracion.cuenta_bancaria c 
        WHERE c.cbu_cvu_Hash = HASHBYTES('SHA2_256', i.cbu_cvu)
    );

    PRINT 'Cuentas bancarias insertadas: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

    -- Vincular UF con personas (usa HASH para buscar)
    INSERT INTO unidad_funcional.uf_persona_vinculo (
        uf_id, 
        persona_id, 
        rol, 
        fecha_desde
    )
    SELECT
        ufc.uf_id,
        p.persona_id,
        CASE WHEN i.inquilino = 1 THEN 'INQUILINO' ELSE 'PROPIETARIO' END,
        GETDATE()
    FROM #InquilinosPropietarios i
    JOIN persona.persona p 
        ON p.nro_doc_Hash = HASHBYTES('SHA2_256', i.dni)
    JOIN administracion.cuenta_bancaria cb 
        ON cb.cbu_cvu_Hash = HASHBYTES('SHA2_256', i.cbu_cvu)
    JOIN unidad_funcional.uf_cuenta ufc 
        ON cb.cuenta_id = ufc.cuenta_id
        AND ufc.fecha_hasta IS NULL
    WHERE i.cbu_cvu IS NOT NULL           
      AND ufc.uf_id IS NOT NULL       
      AND NOT EXISTS (               
        SELECT 1 FROM unidad_funcional.uf_persona_vinculo v 
        WHERE v.persona_id = p.persona_id 
          AND v.uf_id = ufc.uf_id
          AND v.rol = CASE WHEN i.inquilino = 1 THEN 'INQUILINO' ELSE 'PROPIETARIO' END
    );

    PRINT 'Vínculos UF-Persona creados: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

    DROP TABLE #InquilinosPropietarios;
    PRINT 'Importación de inquilinos y propietarios completada.';
END;
GO

------------------------------------------------------------
-- SP MODIFICADO: importar_uf_cbu
------------------------------------------------------------
CREATE OR ALTER PROCEDURE unidad_funcional.importar_uf_cbu
    @RutaArchivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @FraseClave NVARCHAR(128) = N'MiClaveSegura2025$';
    
    BEGIN TRY
        IF OBJECT_ID('tempdb..#UnidadesFuncionales') IS NOT NULL
            DROP TABLE #UnidadesFuncionales;

        CREATE TABLE #UnidadesFuncionales (
            cbu_cvu VARCHAR(40),
            nombre_consorcio VARCHAR(200),
            nro_unidad VARCHAR(50),
            piso VARCHAR(20),
            departamento VARCHAR(20)
        );

        -- Cargar CSV
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = '
            BULK INSERT #UnidadesFuncionales
            FROM ''' + @RutaArchivo + '''
            WITH (
                FIELDTERMINATOR = ''|'',
                ROWTERMINATOR = ''\n'',
                FIRSTROW = 2,
                CODEPAGE = ''65001''
            );
        ';
        EXEC (@SQL);

        -- Crear administración si no existe
        IF NOT EXISTS (SELECT 1 FROM administracion.administracion WHERE nombre = 'Administración General')
        BEGIN
            INSERT INTO administracion.administracion (nombre, cuit, domicilio, email, telefono)
            VALUES ('Administración General', '30-00000000-0', 'Av. Principal 100', 'admin@email.com', '1122334455');
            PRINT 'Administración General creada.';
        END

        DECLARE @admin_id INT = (SELECT TOP 1 administracion_id FROM administracion.administracion WHERE nombre = 'Administración General');

        -- Insertar consorcios
        INSERT INTO administracion.consorcio (administracion_id, nombre, cuit, domicilio, superficie_total_m2, fecha_alta)
        SELECT DISTINCT
            @admin_id,
            u.nombre_consorcio,
            '30-00000000-0',
            u.nombre_consorcio + ' 100',
            0,
            GETDATE()
        FROM #UnidadesFuncionales u
        WHERE NOT EXISTS (
            SELECT 1 FROM administracion.consorcio c WHERE c.nombre = u.nombre_consorcio
        );

        PRINT 'Consorcios insertados: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

        -- Insertar cuentas bancarias CON CIFRADO
        INSERT INTO administracion.cuenta_bancaria (
            banco, 
            alias, 
            cbu_cvu_Cifrado,
            cbu_cvu_Hash,
            cbu_cvu_Dec
        )
        SELECT 
            'Desconocido',
            NULL,
            EncryptByPassPhrase(
                @FraseClave,
                u.cbu_cvu,
                1,
                CONVERT(VARBINARY, u.cbu_cvu)
            ),
            HASHBYTES('SHA2_256', u.cbu_cvu),
            CONVERT(VARBINARY, u.cbu_cvu)
        FROM #UnidadesFuncionales u
        WHERE u.cbu_cvu IS NOT NULL
          AND LEN(LTRIM(RTRIM(u.cbu_cvu))) > 0
          AND NOT EXISTS (
              SELECT 1 FROM administracion.cuenta_bancaria c 
              WHERE c.cbu_cvu_Hash = HASHBYTES('SHA2_256', u.cbu_cvu)
          );

        PRINT 'Cuentas bancarias insertadas: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

        -- Insertar unidades funcionales
        INSERT INTO unidad_funcional.unidad_funcional (consorcio_id, codigo, piso, depto, superficie_m2, porcentaje)
        SELECT 
            c.consorcio_id,
            u.nro_unidad,
            u.piso,
            u.departamento,
            0,
            0
        FROM #UnidadesFuncionales u
        INNER JOIN administracion.consorcio c ON c.nombre = u.nombre_consorcio
        WHERE NOT EXISTS (
            SELECT 1 FROM unidad_funcional.unidad_funcional f
            WHERE f.codigo = u.nro_unidad AND f.consorcio_id = c.consorcio_id
        );

        PRINT 'Unidades funcionales insertadas: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

        -- Vincular UF con cuentas (usa HASH)
        INSERT INTO unidad_funcional.uf_cuenta (uf_id, cuenta_id, fecha_desde)
        SELECT 
            uf.uf_id,
            cb.cuenta_id,
            GETDATE()
        FROM #UnidadesFuncionales u
        INNER JOIN administracion.consorcio c ON c.nombre = u.nombre_consorcio
        INNER JOIN unidad_funcional.unidad_funcional uf 
            ON uf.codigo = u.nro_unidad AND uf.consorcio_id = c.consorcio_id
        INNER JOIN administracion.cuenta_bancaria cb 
            ON cb.cbu_cvu_Hash = HASHBYTES('SHA2_256', u.cbu_cvu)
        WHERE NOT EXISTS (
            SELECT 1 
            FROM unidad_funcional.uf_cuenta x
            WHERE x.uf_id = uf.uf_id AND x.cuenta_id = cb.cuenta_id AND x.fecha_hasta IS NULL
        );

        PRINT 'Vínculos UF-Cuenta creados: ' + CAST(@@ROWCOUNT AS VARCHAR(10));
        PRINT 'Unidades funcionales importadas correctamente';
        
        DROP TABLE #UnidadesFuncionales;
        
    END TRY
    BEGIN CATCH
        PRINT 'Error al importar UF: ' + ERROR_MESSAGE();
        IF OBJECT_ID('tempdb..#UnidadesFuncionales') IS NOT NULL 
            DROP TABLE #UnidadesFuncionales;
        THROW;
    END CATCH
END;
GO

------------------------------------------------------------
-- SP MODIFICADO: importar_conciliar_pagos
------------------------------------------------------------
CREATE OR ALTER PROCEDURE banco.importar_conciliar_pagos
    @RutaArchivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    -- Frase clave para encriptar los nuevos movimientos
    DECLARE @FraseClave NVARCHAR(128) = N'MiClaveSegura2025$';

    ---------------------------------------------------------
    -- 1) Cargar CSV en tabla temporal
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#PagosCSV') IS NOT NULL DROP TABLE #PagosCSV;
    
    CREATE TABLE #PagosCSV (
        id_pago_externo VARCHAR(50),
        fecha_texto VARCHAR(20),
        cbu_origen VARCHAR(100), -- Aumentado por seguridad
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
        PRINT 'Error al cargar el CSV. Verifique formato y ruta.';
        DROP TABLE #PagosCSV;
        RETURN -1;
    END CATCH;

    ---------------------------------------------------------
    -- 2) Procesar pagos y normalizar datos
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#PagosProcesados') IS NOT NULL DROP TABLE #PagosProcesados;

    SELECT
        csv.id_pago_externo,
        -- Limpiamos el CBU para usarlo luego
        LTRIM(RTRIM(csv.cbu_origen)) AS cbu_origen_texto,
        -- Generamos el Hash para búsquedas rápidas
        HASHBYTES('SHA2_256', LTRIM(RTRIM(csv.cbu_origen))) AS cbu_origen_hash,
        
        CONVERT(DATE, csv.fecha_texto, 103) AS fecha_pago,

        TRY_CAST(
            REPLACE(REPLACE(LTRIM(RTRIM(csv.valor_texto)), '$', ''), '.', '')
            AS NUMERIC(14,2)
        ) AS importe_pago,

        ufc.uf_id,
        uf.consorcio_id AS consorcio_id_origen,
        cb_origen.cuenta_id AS cuenta_origen_id,
        ccb_principal.cuenta_id AS cuenta_destino_id,

        CASE 
            WHEN ufc.uf_id IS NULL THEN 'CBU no vinculado a una UF'
            WHEN ccb_principal.cuenta_id IS NULL THEN 'El consorcio no tiene cuenta principal'
            ELSE NULL 
        END AS motivo_no_vinculado

    INTO #PagosProcesados
    FROM #PagosCSV csv
    -- JOIN usando HASH para encontrar la cuenta bancaria interna (si existe)
    LEFT JOIN administracion.cuenta_bancaria cb_origen 
        ON cb_origen.cbu_cvu_Hash = HASHBYTES('SHA2_256', LTRIM(RTRIM(csv.cbu_origen)))
    
    LEFT JOIN unidad_funcional.uf_cuenta ufc 
        ON cb_origen.cuenta_id = ufc.cuenta_id AND ufc.fecha_hasta IS NULL
    LEFT JOIN unidad_funcional.unidad_funcional uf 
        ON uf.uf_id = ufc.uf_id
    LEFT JOIN administracion.consorcio_cuenta_bancaria ccb_principal
        ON ccb_principal.consorcio_id = uf.consorcio_id
       AND ccb_principal.es_principal = 1;

    ---------------------------------------------------------
    -- 3) Insertar movimientos (CON ENCRIPTACIÓN)
    ---------------------------------------------------------
    -- Tabla variable para capturar los IDs generados y vincularlos luego
    DECLARE @MovimientosInsertados TABLE (
        movimiento_id INT,
        cbu_hash VARBINARY(32), -- Usamos hash para el join posterior
        fecha DATE,
        importe NUMERIC(14,2)
    );

    INSERT INTO banco.banco_movimiento (
        consorcio_id,
        cuenta_id,
        fecha,
        importe,
        estado_conciliacion,
        -- Columnas de Encriptación
        cbu_origen_Cifrado,
        cbu_origen_Hash,
        cbu_origen_Dec
    )
    OUTPUT
        inserted.movimiento_id,
        inserted.cbu_origen_Hash,
        inserted.fecha,
        inserted.importe
    INTO @MovimientosInsertados (movimiento_id, cbu_hash, fecha, importe)
    SELECT
        p.consorcio_id_origen,
        p.cuenta_destino_id,
        p.fecha_pago,
        p.importe_pago,
        CASE WHEN p.uf_id IS NOT NULL THEN 'ASOCIADO' ELSE 'PENDIENTE' END,
        
        -- Encriptamos al vuelo el CBU que viene del CSV
        EncryptByPassPhrase(@FraseClave, p.cbu_origen_texto, 1, CONVERT(VARBINARY, p.cbu_origen_texto)),
        p.cbu_origen_hash,
        CONVERT(VARBINARY, p.cbu_origen_texto)

    FROM #PagosProcesados p
    WHERE p.importe_pago IS NOT NULL
      AND p.consorcio_id_origen IS NOT NULL
      AND p.cuenta_destino_id IS NOT NULL
      -- Verificamos duplicados usando el HASH y los otros datos
      AND NOT EXISTS (
            SELECT 1
            FROM banco.banco_movimiento bm
            WHERE bm.cbu_origen_Hash = p.cbu_origen_hash
              AND bm.fecha      = p.fecha_pago
              AND bm.importe    = p.importe_pago
              AND bm.cuenta_id  = p.cuenta_destino_id
      );

    PRINT 'Movimientos insertados: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

    ---------------------------------------------------------
    -- 4) Insertar pagos (Vinculación)
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
    -- Hacemos JOIN con los insertados usando el Hash
    JOIN @MovimientosInsertados mi
      ON p.cbu_origen_hash = mi.cbu_hash
     AND p.fecha_pago = mi.fecha
     AND p.importe_pago = mi.importe
    WHERE NOT EXISTS (
        SELECT 1 FROM banco.pago px
        WHERE px.uf_id = p.uf_id
          AND px.fecha = p.fecha_pago
          AND px.importe = p.importe_pago
          AND px.movimiento_id = mi.movimiento_id
    );

    PRINT 'Pagos registrados: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

    DROP TABLE #PagosCSV;
    DROP TABLE #PagosProcesados;
END;
GO
