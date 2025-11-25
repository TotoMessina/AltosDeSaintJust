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


PRINT '=== INICIO DE IMPLEMENTACIÓN DE CIFRADO ===';
GO

ALTER TABLE persona.persona
ADD 
    nro_doc_Cifrado VARBINARY(256),
    nro_doc_Hash VARBINARY(32),
    nro_doc_Dec VARBINARY(MAX),
    
    nombre_completo_Cifrado VARBINARY(256),
    nombre_completo_Hash VARBINARY(32),
    nombre_completo_Dec VARBINARY(MAX)
    
GO

ALTER TABLE persona.persona_contacto
ADD 
    valor_Cifrado VARBINARY(256),
    valor_Hash VARBINARY(32),
    valor_Dec VARBINARY(MAX);
GO

ALTER TABLE administracion.cuenta_bancaria
ADD 
    cbu_cvu_Cifrado VARBINARY(256),
    cbu_cvu_Hash VARBINARY(32),
    cbu_cvu_Dec VARBINARY(MAX);
GO

ALTER TABLE banco.banco_movimiento
ADD 
    cbu_origen_Cifrado VARBINARY(256),
    cbu_origen_Hash VARBINARY(32),
    cbu_origen_Dec VARBINARY(MAX);
GO

PRINT 'Columnas agregadas correctamente.';
GO



UPDATE persona.persona
SET 
    nro_doc_Dec = CONVERT(VARBINARY, nro_doc),
    nro_doc_Hash = HASHBYTES('SHA2_256', nro_doc),
    
    nombre_completo_Dec = CONVERT(VARBINARY, nombre_completo),
    nombre_completo_Hash = HASHBYTES('SHA2_256', nombre_completo)
    
GO

UPDATE persona.persona_contacto
SET 
    valor_Dec = CONVERT(VARBINARY, valor),
    valor_Hash = HASHBYTES('SHA2_256', valor);
GO

UPDATE administracion.cuenta_bancaria
SET 
    cbu_cvu_Dec = CONVERT(VARBINARY, cbu_cvu),
    cbu_cvu_Hash = HASHBYTES('SHA2_256', cbu_cvu);
GO

UPDATE banco.banco_movimiento
SET
	cbu_origen_Dec = CONVERT(VARBINARY, cbu_origen),
	cbu_origen_Hash = HASHBYTES('SHA2_256', cbu_origen);
GO
--------------------------------------------------------------
--SP DE CIFRADOS
--------------------------------------------------------------
CREATE OR ALTER PROCEDURE persona.sp_cifrar_personas
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FraseClave NVARCHAR(128) = N'MiClaveSegura2025$';

    UPDATE persona.persona
    SET 
        nro_doc_Cifrado = EncryptByPassPhrase(
            @FraseClave,
            nro_doc,
            1,
            nro_doc_Dec
        ),
        nombre_completo_Cifrado = EncryptByPassPhrase(
            @FraseClave,
            nombre_completo,
            1,
            nombre_completo_Dec
        )
    WHERE nro_doc_Cifrado IS NULL;

    PRINT 'Personas cifradas: ' + CAST(@@ROWCOUNT AS VARCHAR(10));
END;
GO



CREATE OR ALTER PROCEDURE persona.sp_cifrar_contactos
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @FraseClave NVARCHAR(128) = N'MiClaveSegura2025$';

    UPDATE persona.persona_contacto
    SET 
        valor_Cifrado = EncryptByPassPhrase(
            @FraseClave,
            valor,
            1,
            valor_Dec
        )
    WHERE valor_Cifrado IS NULL;
    
    PRINT 'Contactos cifrados: ' + CAST(@@ROWCOUNT AS VARCHAR(10));
END
GO

CREATE OR ALTER PROCEDURE administracion.sp_cifrar_cuentas
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @FraseClave NVARCHAR(128) = N'MiClaveSegura2025$';

    UPDATE administracion.cuenta_bancaria
    SET 
        cbu_cvu_Cifrado = EncryptByPassPhrase(
            @FraseClave,
            cbu_cvu,
            1,
            cbu_cvu_Dec
        )
    WHERE cbu_cvu_Cifrado IS NULL;
    
    PRINT 'Cuentas bancarias cifradas: ' + CAST(@@ROWCOUNT AS VARCHAR(10));
END;
GO

CREATE OR ALTER PROCEDURE banco.sp_cifrar_movimientos
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @FraseClave NVARCHAR(128) = N'MiClaveSegura2025$';

    UPDATE banco.banco_movimiento
    SET 
        cbu_origen_Dec = CONVERT(VARBINARY, cbu_origen),
        cbu_origen_Hash = HASHBYTES('SHA2_256', cbu_origen),
        
        cbu_origen_Cifrado = EncryptByPassPhrase(
            @FraseClave,
            cbu_origen,
            1,
            CONVERT(VARBINARY, cbu_origen) 
        )
    WHERE cbu_origen_Cifrado IS NULL 
      AND cbu_origen IS NOT NULL;

    PRINT 'Movimientos bancarios cifrados: ' + CAST(@@ROWCOUNT AS VARCHAR(10));
END;
GO

--------------EJECUTO SP DE CIFRADOS-----------------------------

EXEC persona.sp_cifrar_personas;
EXEC persona.sp_cifrar_contactos;
EXEC administracion.sp_cifrar_cuentas;
EXEC banco.sp_cifrar_movimientos;
GO
-----BORRO INDICES NOCLUSTER-------------
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_movimiento_cbu' AND object_id = OBJECT_ID('banco.banco_movimiento'))
BEGIN
    DROP INDEX IX_movimiento_cbu ON banco.banco_movimiento;
END
GO
-----BORRO COLUMNAS ORIGINALES----------
ALTER TABLE persona.persona
DROP CONSTRAINT UQ_persona_doc;
GO

ALTER TABLE persona.persona
DROP COLUMN nro_doc, nombre_completo;
GO


ALTER TABLE persona.persona_contacto
DROP CONSTRAINT UQ_persona_contacto;
GO

ALTER TABLE persona.persona_contacto
DROP COLUMN valor;
GO

ALTER TABLE administracion.cuenta_bancaria
DROP CONSTRAINT UQ_cuenta_cbu;
GO

ALTER TABLE administracion.cuenta_bancaria
DROP COLUMN cbu_cvu;
GO

ALTER TABLE banco.banco_movimiento
DROP COLUMN cbu_origen;
GO

CREATE OR ALTER PROCEDURE persona.sp_descifrar_personas
    @FraseClave NVARCHAR(128)
AS

BEGIN
    SET NOCOUNT ON;

    IF @FraseClave <> N'MiClaveSegura2025$'
         PRINT 'Frase clave incorrecta.';

    SELECT 
        persona_id,
        tipo_doc,
        CONVERT(VARCHAR(100),
            DecryptByPassPhrase(@FraseClave, nro_doc_Cifrado, 1, nro_doc_Dec)
        ) AS nro_doc_descifrado,
        CONVERT(VARCHAR(200),
            DecryptByPassPhrase(@FraseClave, nombre_completo_Cifrado, 1, nombre_completo_Dec)
        ) AS nombre_completo_descifrado
    FROM persona.persona;
END;
GO



GO
CREATE OR ALTER PROCEDURE persona.sp_descifrar_contactos
    @FraseClave NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

    IF @FraseClave <> N'MiClaveSegura2025$'
        PRINT 'Frase clave incorrecta.';
    SELECT 
        contacto_id,
        persona_id,
        tipo,
        CONVERT(VARCHAR(200),
            DecryptByPassPhrase(@FraseClave, valor_Cifrado, 1, valor_Dec)
        ) AS valor_descifrado,
        es_preferido
    FROM persona.persona_contacto;
END;
GO

CREATE OR ALTER PROCEDURE administracion.sp_descifrar_cuentas
    @FraseClave NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

    IF @FraseClave <> N'MiClaveSegura2025$'
        PRINT 'Frase clave incorrecta.';

    SELECT 
        cuenta_id,
        banco,
        alias,
        CONVERT(VARCHAR(100),
            DecryptByPassPhrase(@FraseClave, cbu_cvu_Cifrado, 1, cbu_cvu_Dec)
        ) AS cbu_cvu_descifrado
    FROM administracion.cuenta_bancaria;
END;
GO

CREATE OR ALTER PROCEDURE banco.sp_descifrar_movimientos
    @FraseClave NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

    IF @FraseClave <> N'MiClaveSegura2025$'
    BEGIN
         PRINT 'Frase clave incorrecta.';
         RETURN;
    END

    SELECT 
        movimiento_id,
        consorcio_id,
        cuenta_id,
        fecha,
        importe,
        estado_conciliacion,
        -- Descifrado
        CONVERT(VARCHAR(100),
            DecryptByPassPhrase(@FraseClave, cbu_origen_Cifrado, 1, cbu_origen_Dec)
        ) AS cbu_origen_descifrado
    FROM banco.banco_movimiento;
END;
GO


---------------------EJECUTO SP PARA DESCIFRAR TABLAS CIFRADAS-------------------

EXEC persona.sp_descifrar_personas N'MiClaveSegura2025$';
EXEC persona.sp_descifrar_contactos N'MiClaveSegura2025$';
EXEC administracion.sp_descifrar_cuentas N'MiClaveSegura2025$';
EXEC banco.sp_descifrar_movimientos N'MiClaveSegura2025$';
GO
