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

CREATE OR ALTER PROCEDURE persona.importar_inquilinos_propietarios
    @RutaArchivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    ------------------------------------------------------------
    -- Crear tabla temporal
    ------------------------------------------------------------
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

    ------------------------------------------------------------
    -- Cargar el archivo CSV
    ------------------------------------------------------------
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

    ------------------------------------------------------------
    -- Insertar personas
    ------------------------------------------------------------
    INSERT INTO persona.persona (nombre_completo, tipo_doc, nro_doc)
    SELECT
        MAX(UPPER(RTRIM(TRIM(ISNULL(nombre, '')) +' '+ RTRIM(LTRIM(ISNULL(apellido, '')))))) AS nombre_completo,
        'DNI',
        dni
    FROM #InquilinosPropietarios i
    WHERE 
        NOT EXISTS (
            SELECT 1 FROM persona.persona p WHERE p.nro_doc = i.dni
        )
        AND i.dni IS NOT NULL                  
        AND LTRIM(RTRIM(i.dni)) <> ''     
    GROUP BY dni;

    ------------------------------------------------------------
    -- Insertar contactos (email y telefono)
    ------------------------------------------------------------
    INSERT INTO persona.persona_contacto (persona_id, tipo, valor, es_preferido)
    SELECT 
        p.persona_id,
        'email',
        LOWER(RTRIM(LTRIM((i.email_personal)))),
        1
    FROM #InquilinosPropietarios i
    JOIN persona.persona p ON p.nro_doc = i.dni
    WHERE NOT EXISTS (
        SELECT 1 FROM persona.persona_contacto c 
        WHERE c.persona_id = p.persona_id AND c.valor = LOWER(RTRIM(LTRIM((i.email_personal))))
	);

    INSERT INTO persona.persona_contacto (persona_id, tipo, valor, es_preferido)
    SELECT 
        p.persona_id,
        'telefono',
        i.telefono_contacto,
        0
    FROM #InquilinosPropietarios i
    JOIN persona.persona p ON p.nro_doc = i.dni
    WHERE NOT EXISTS (
        SELECT 1 FROM persona.persona_contacto c 
        WHERE c.persona_id = p.persona_id AND c.valor = i.telefono_contacto
    );
    
    ------------------------------------------------------------
    -- Insertar cuentas bancarias (si tienen CBU)
    ------------------------------------------------------------
    INSERT INTO administracion.cuenta_bancaria (banco, alias, cbu_cvu)
    SELECT 
        'Desconocido',
        NULL,
        i.cbu_cvu
    FROM #InquilinosPropietarios i
    WHERE i.cbu_cvu IS NOT NULL
    AND NOT EXISTS (
        SELECT 1 FROM administracion.cuenta_bancaria c 
        WHERE c.cbu_cvu = i.cbu_cvu
    );

    ------------------------------------------------------------
    -- Insertar vinculos con unidad funcional (rol)
    ------------------------------------------------------------
    INSERT INTO unidad_funcional.uf_persona_vinculo (uf_id, persona_id, rol, fecha_desde)
    SELECT
        ufc.uf_id,
        p.persona_id,
        CASE WHEN i.inquilino = 1 THEN 'Inquilino' ELSE 'Propietario' END,
        GETDATE()
    FROM #InquilinosPropietarios i
    JOIN persona.persona p 
        ON p.nro_doc = i.dni

    JOIN administracion.cuenta_bancaria cb 
        ON i.cbu_cvu = cb.cbu_cvu
    JOIN unidad_funcional.uf_cuenta ufc 
        ON cb.cuenta_id = ufc.cuenta_id
    WHERE 
        i.cbu_cvu IS NOT NULL           
        AND ufc.uf_id IS NOT NULL       
        AND NOT EXISTS (               
            SELECT 1 FROM unidad_funcional.uf_persona_vinculo v 
            WHERE v.persona_id = p.persona_id 
              AND v.uf_id = ufc.uf_id
              AND v.rol = CASE WHEN i.inquilino = 1 THEN 'Inquilino' ELSE 'Propietario' END
        );

END;
GO
