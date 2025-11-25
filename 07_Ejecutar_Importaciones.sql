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

--Ejecutar todas los SP juntos incluyendo la seleccion del setvar

:setvar BasePath "C:\_temp\"  -- Para hacer uso de esto debemos ir arriba a la izquierda a Query->Modo SQLCMD

USE Com5600G03;
GO

PRINT '=== INICIO DE IMPORTACIONES ===';
PRINT '';

-- 1. Consorcios
-- Esperado:
--   - Se importan todos los consorcios que no existan previamente.
--   - Si no existe, se crea la administración base 'Administración General'.
--   - No deben generarse errores de PK/UNIQUE.
PRINT '1. Importando Consorcios';
EXEC administracion.importar_consorcios 
    @RutaArchivo = N'$(BasePath)datos varios(Consorcios).csv';
PRINT '';

-- 2. Unidades Funcionales
PRINT '2. Importando UF';
EXEC administracion.importar_uf
    @RutaArchivo = N'$(BasePath)UF por consorcio.txt';
PRINT '';

-- 3. Tipos de Gasto
PRINT '3. Cargando Tipos de Gasto';
EXEC administracion.cargar_tipo_gastos;
PRINT '';

EXEC administracion.crear_periodos @Anio = 2025;

-- 4. Proveedores
PRINT '4. Importando Proveedores';
EXEC administracion.cargar_proveedores
    @RutaArchivo = N'$(BasePath)datos varios(Proveedores).csv';
PRINT '';

-- 5. Gastos
PRINT '5. Importando Gastos';
EXEC administracion.importar_gastos
    @RutaArchivo = N'$(BasePath)Servicios.Servicios.json';
PRINT '';

-- 6. Cuentas
PRINT '6. Importando Cuentas';
EXEC unidad_funcional.importar_uf_cbu
     @RutaArchivo = N'$(BasePath)Inquilino-propietarios-UF.csv';
PRINT '';

-- 7. Personas
PRINT '7. Importando Inquilinos y Propietarios';
EXEC persona.importar_inquilinos_propietarios
    @RutaArchivo = N'$(BasePath)Inquilino-propietarios-datos.csv';
PRINT '';

-- 8. Pagos
PRINT '8. Importando Pagos';
EXEC banco.importar_conciliar_pagos
    @RutaArchivo = N'$(BasePath)pagos_consorcios.csv';
PRINT '';

-- 9. LLENAR Y SIMULAR EXPENSAS
EXEC expensa.llenar_expensas
PRINT '';

PRINT '=== FIN DE IMPORTACIONES ===';
GO

/*
select * from administracion.administracion
select * from administracion.consorcio
select * from administracion.consorcio_cuenta_bancaria
select * from administracion.cuenta_bancaria

select * from banco.banco_movimiento
select * from banco.pago

select * from expensa.gasto
select * from expensa.sub_tipo_gasto
select * from expensa.tipo_gasto
select * from expensa.periodo
select * from expensa.proveedor
select * from expensa.expensa_uf
select * from expensa.expensa_uf_detalle
select * from expensa.expensa_uf_interes

select * from persona.persona
select * from persona.persona_contacto

select * from unidad_funcional.unidad_funcional
select * from unidad_funcional.baulera
select * from unidad_funcional.cochera
select * from unidad_funcional.uf_cuenta
select * from unidad_funcional.uf_persona_vinculo
*/

