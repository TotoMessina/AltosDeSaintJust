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

-- GENERACIÓN DE INDICES NO CLUSTER PARA LA OPTIMIZACION DE LOS REPORTES

USE Com5600G03;
GO

--------------------------------------------------------------------------------
--INDICE PARA REPORTE 1
--------------------------------------------------------------------------------


IF NOT EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = 'IX_reporte1' 
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_reporte1
    ON banco.pago (fecha, uf_id, tipo)
    INCLUDE (importe);
END;
GO

-----------------------------------------------------------------------------------
--INDICE PARA REPORTE 2
-----------------------------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = 'IX_reporte2' 
 
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_reporte2
    ON unidad_funcional.unidad_funcional (consorcio_id, uf_id)
    INCLUDE (depto);
END;
GO


-----------------------------------------------------------------------------------
--INDICE PARA REPORTE 3
-----------------------------------------------------------------------------------

IF NOT EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = 'IX_reporte3' 
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_reporte3
    ON expensa.periodo (consorcio_id, anio, mes)
    INCLUDE (periodo_id);
END;
GO

-----------------------------------------------------------------------------------
--INDICE PARA REPORTE 4
-----------------------------------------------------------------------------------

IF NOT EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = 'IX_reporte4'
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_reporte4
    ON expensa.gasto (periodo_id)
    INCLUDE (importe);
END;
GO
----------------------------------------------------------------------------------
--INDICE PARA REPORTE 5
----------------------------------------------------------------------------------

-- expensa_uf
IF NOT EXISTS (
	SELECT 1 
	FROM sys.indexes 
	WHERE name = 'IX_expensa_uf_deuda'
)
    BEGIN
        CREATE NONCLUSTERED INDEX IX_expensa_uf_deuda 
        ON expensa.expensa_uf(uf_id) 
        INCLUDE (deuda_anterior, interes_mora, periodo_id);
    END;
	GO
 -- uf_persona_vinculo
    IF NOT EXISTS (
	SELECT 1 
	FROM sys.indexes 
	WHERE name = 'IX_uf_persona_rol_activo'
	)
    BEGIN
        CREATE NONCLUSTERED INDEX IX_uf_persona_rol_activo 
        ON unidad_funcional.uf_persona_vinculo(uf_id, rol) 
        WHERE fecha_hasta IS NULL;
    END;
	GO
-- persona_contacto
    IF NOT EXISTS (
	SELECT 1 
	FROM sys.indexes 
	WHERE name = 'IX_persona_contacto_preferido')
    BEGIN
        CREATE NONCLUSTERED INDEX IX_persona_contacto_preferido 
        ON persona.persona_contacto(persona_id) 
        WHERE es_preferido = 1;
    END;
	GO


