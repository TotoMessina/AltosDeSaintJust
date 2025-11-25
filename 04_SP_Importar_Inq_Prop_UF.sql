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

CREATE OR ALTER PROCEDURE unidad_funcional.importar_uf_cbu
    @RutaArchivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Tabla temporal
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

        -- Insertar cuentas bancarias únicas
        INSERT INTO administracion.cuenta_bancaria (banco, alias, cbu_cvu)
        SELECT 
            'Desconocido',
            NULL,
            u.cbu_cvu
        FROM #UnidadesFuncionales u
        WHERE u.cbu_cvu IS NOT NULL
          AND LEN(LTRIM(RTRIM(u.cbu_cvu))) > 0
          AND NOT EXISTS (
              SELECT 1 FROM administracion.cuenta_bancaria c 
              WHERE c.cbu_cvu = u.cbu_cvu
          );

        -- Insertar unidades funcionales únicas
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

        -- Vincular UF con cuentas
        INSERT INTO unidad_funcional.uf_cuenta (uf_id, cuenta_id, fecha_desde)
        SELECT 
            uf.uf_id,
            cb.cuenta_id,
            GETDATE()
        FROM #UnidadesFuncionales u
        INNER JOIN administracion.consorcio c ON c.nombre = u.nombre_consorcio
        INNER JOIN unidad_funcional.unidad_funcional uf 
            ON uf.codigo = u.nro_unidad AND uf.consorcio_id = c.consorcio_id
        INNER JOIN administracion.cuenta_bancaria cb ON cb.cbu_cvu = u.cbu_cvu
        WHERE NOT EXISTS (
            SELECT 1 
            FROM unidad_funcional.uf_cuenta x
            WHERE x.uf_id = uf.uf_id AND x.cuenta_id = cb.cuenta_id AND x.fecha_hasta IS NULL
        );

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