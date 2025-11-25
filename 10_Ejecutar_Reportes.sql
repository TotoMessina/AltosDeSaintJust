/*
------------------------------------------------------------
Trabajo Pr�ctico Integrador - ENTREGA 6
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


--EJECUCION DE LOS REPORTES CREADOS

USE Com5600G03;
GO

------------------------------------------------------------------
-- REPORTE 1 - Recaudación semanal
-- Esperado:
--   - Muestra, por semana, pagos ordinarios, extraordinarios,
--     total semanal, promedios globales y acumulados.
--   - Filtra por rango de fechas y por Consorcio (opcional).
------------------------------------------------------------------
PRINT '=== REPORTE 1: Recaudación semanal ===';
EXEC expensa.reporte_recaudacion_semanal
    @FechaInicio = '2025-04-04',
    @FechaFin    = '2025-05-05',
    @ConsorcioId = 1;
GO

------------------------------------------------------------------
-- REPORTE 2 - Recaudación mensual por departamento
-- Esperado:
--   - Devuelve una fila por departamento (depto),
--     con columnas por mes (Enero..Diciembre) y Total_anual.
--   - Para el consorcio 2 y meses 1 a 6 deben aparecer importes
--     no nulos donde existan pagos.
------------------------------------------------------------------
PRINT '=== REPORTE 2: Recaudación mensual por departamento ===';
EXEC expensa.reporte_recaudacion_mes_departamento
    @Anio        = 2025,
    @ConsorcioId = 2,
    @MesInicio   = 1,
    @MesFin      = 6;
GO

------------------------------------------------------------------
-- REPORTE 3 - Recaudación por tipo y período (XML)
-- Esperado:
--   - Resultado en formato XML, con nodos que representan la
--     recaudación por tipo de pago en el período.
--   - Filtra solo pagos ORDINARIO del consorcio 3 en 2025.
------------------------------------------------------------------
PRINT '=== REPORTE 3: Recaudación por tipo y período (XML) ===';
EXEC expensa.reporte_recudacion_tipo_periodo
    @Anio        = 2025,
    @ConsorcioId = 3,
    @TipoPago    = 'ORDINARIO';   -- 'ORDINARIO' o 'EXTRAORDINARIO'
GO

------------------------------------------------------------------
-- REPORTE 4 - Top N meses por gastos/ingresos
-- Esperado:
--   - Devuelve las categorías 'MAYORES GASTOS' y 'MAYORES INGRESOS',
--     con los Top N períodos según importe.
--   - Para el consorcio 1 y Top 3 se esperan 3 filas por categoría
--     (si hay suficientes datos).
------------------------------------------------------------------
PRINT '=== REPORTE 4: Top N meses por gastos/ingresos ===';
EXEC expensa.reporte_top_gastos_ingresos
    @Anio        = 2025,
    @ConsorcioId = 1,
    @TopN        = 3;
GO

------------------------------------------------------------------
-- REPORTE 5 - Top morosos
-- Esperado:
--   - Devuelve las Top N unidades funcionales con mayor deuda
--     para el consorcio indicado y según el rol (PROPIETARIO / INQUILINO).
--   - Para consorcio 5 y Top 5, se esperan hasta 5 filas.
------------------------------------------------------------------
PRINT '=== REPORTE 5: Top morosos ===';
EXEC expensa.reporte_top_morosos
    @ConsorcioId = 5,
    @TopN        = 5,
    @Rol         = 'PROPIETARIO';
GO

------------------------------------------------------------------
-- REPORTE 6 - Fechas de pagos por UF
-- Esperado:
--   - Lista las fechas de pago de expensas de la UF indicada,
--     calculando diferencia de días entre pagos consecutivos.
--   - Filtra por tipo de pago (ORDINARIO / EXTRAORDINARIO).
------------------------------------------------------------------
PRINT '=== REPORTE 6: Fechas de pagos por UF ===';
EXEC expensa.reporte_fechas_pagos_uf
    @ConsorcioId = 1,
    @UFCodigo    = 1,
    @TipoPago    = 'ORDINARIO';
GO

------------------------------------------------------------------
-- REPORTE 7 - Deuda del período en USD
-- Esperado:
--   - Muestra el importe de deuda del consorcio indicado
--     para el mes y año especificados, convertido a USD
--     según cotización almacenada.
------------------------------------------------------------------
PRINT '=== REPORTE 7: Deuda del período en USD ===';
EXEC expensa.reporte_deuda_periodo_usd
    @ConsorcioId = 4,
    @Anio = 2025,
    @Mes = 5;
GO
