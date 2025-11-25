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

--CREACION DE ROLES PARA LA BD.

USE Com5600G03;
GO


IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'Administrativo General' AND type = 'R')
BEGIN
    CREATE ROLE [Administrativo General];
    PRINT '- Rol "Administrativo General" creado';
END
ELSE
    PRINT '- Rol "Administrativo General" ya existe';
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'Administrativo Bancario' AND type = 'R')
BEGIN
    CREATE ROLE [Administrativo Bancario];
    PRINT '- Rol "Administrativo Bancario" creado';
END
ELSE
    PRINT '- Rol "Administrativo Bancario" ya existe';
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'Administrativo Operativo' AND type = 'R')
BEGIN
    CREATE ROLE [Administrativo Operativo];
    PRINT '- Rol "Administrativo Operativo" creado';
END
ELSE
    PRINT '- Rol "Administrativo Operativo" ya existe';
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'Sistemas' AND type = 'R')
BEGIN
    CREATE ROLE [Sistemas];
    PRINT '- Rol "Sistemas" creado';
END
ELSE
    PRINT '- Rol "Sistemas" ya existe';
GO

----------------------------------------------------------------
-- 2. PERMISOS PARA "ADMINISTRATIVO GENERAL"
----------------------------------------------------------------

-- GRANT permisos correctos
GRANT EXECUTE ON administracion.importar_consorcios				 TO [Administrativo General];
GRANT EXECUTE ON administracion.importar_uf						 TO [Administrativo General];
GRANT EXECUTE ON unidad_funcional.importar_uf_cbu				 TO [Administrativo General];
GRANT EXECUTE ON persona.importar_inquilinos_propietarios		 TO [Administrativo General];
GRANT EXECUTE ON administracion.crear_periodos					 TO [Administrativo General];

GRANT EXECUTE ON expensa.reporte_recaudacion_semanal			 TO [Administrativo General];
GRANT EXECUTE ON expensa.reporte_recaudacion_mes_departamento	 TO [Administrativo General];
GRANT EXECUTE ON expensa.reporte_recudacion_tipo_periodo		 TO [Administrativo General];
GRANT EXECUTE ON expensa.reporte_top_gastos_ingresos			 TO [Administrativo General];
GRANT EXECUTE ON expensa.reporte_top_morosos					 TO [Administrativo General];
GRANT EXECUTE ON expensa.reporte_fechas_pagos_uf				 TO [Administrativo General];
GRANT EXECUTE ON expensa.reporte_deuda_periodo_usd				 TO [Administrativo General];

-- DENY 
DENY EXECUTE ON banco.importar_conciliar_pagos					 TO [Administrativo General];
DENY EXECUTE ON administracion.importar_gastos					 TO [Administrativo General];
DENY EXECUTE ON administracion.cargar_proveedores				 TO [Administrativo General];
DENY EXECUTE ON administracion.cargar_tipo_gastos				 TO [Administrativo General];
DENY EXECUTE ON expensa.llenar_expensas							 TO [Administrativo General];

PRINT '- Permisos asignados correctamente';
GO

----------------------------------------------------------------
-- 3. PERMISOS PARA "ADMINISTRATIVO BANCARIO"
----------------------------------------------------------------

-- GRANT permisos correctos
GRANT EXECUTE ON banco.importar_conciliar_pagos TO [Administrativo Bancario];


GRANT EXECUTE ON expensa.reporte_recaudacion_semanal			 TO [Administrativo Bancario];
GRANT EXECUTE ON expensa.reporte_recaudacion_mes_departamento	 TO [Administrativo Bancario];
GRANT EXECUTE ON expensa.reporte_recudacion_tipo_periodo		 TO [Administrativo Bancario];
GRANT EXECUTE ON expensa.reporte_top_gastos_ingresos			 TO [Administrativo Bancario];
GRANT EXECUTE ON expensa.reporte_top_morosos					 TO [Administrativo Bancario];
GRANT EXECUTE ON expensa.reporte_fechas_pagos_uf				 TO [Administrativo Bancario];
GRANT EXECUTE ON expensa.reporte_deuda_periodo_usd				 TO [Administrativo Bancario];

-- DENY explícito a importaciones que no le corresponden
DENY EXECUTE ON administracion.importar_consorcios				 TO [Administrativo Bancario];
DENY EXECUTE ON administracion.importar_uf						 TO [Administrativo Bancario];
DENY EXECUTE ON unidad_funcional.importar_uf_cbu				 TO [Administrativo Bancario];
DENY EXECUTE ON persona.importar_inquilinos_propietarios		 TO [Administrativo Bancario];
DENY EXECUTE ON administracion.importar_gastos					 TO [Administrativo Bancario];
DENY EXECUTE ON administracion.cargar_proveedores				 TO [Administrativo Bancario];
DENY EXECUTE ON administracion.cargar_tipo_gastos				 TO [Administrativo Bancario];
DENY EXECUTE ON expensa.llenar_expensas							 TO [Administrativo Bancario];
DENY EXECUTE ON administracion.crear_periodos					 TO [Administrativo Bancario];

PRINT '- Permisos asignados correctamente';
GO

----------------------------------------------------------------
-- 4. PERMISOS PARA "ADMINISTRATIVO OPERATIVO"
----------------------------------------------------------------
-- GRANT permisos correctos
GRANT EXECUTE ON administracion.importar_gastos					 TO [Administrativo Operativo];
GRANT EXECUTE ON administracion.cargar_proveedores				 TO [Administrativo Operativo];
GRANT EXECUTE ON administracion.cargar_tipo_gastos				 TO [Administrativo Operativo];
GRANT EXECUTE ON expensa.llenar_expensas						 TO [Administrativo Operativo];
GRANT EXECUTE ON administracion.crear_periodos					 TO [Administrativo Operativo];
GRANT EXECUTE ON administracion.importar_uf						 TO [Administrativo Operativo];
GRANT EXECUTE ON unidad_funcional.importar_uf_cbu				 TO [Administrativo Operativo];
GRANT EXECUTE ON persona.importar_inquilinos_propietarios		 TO [Administrativo Operativo];

GRANT EXECUTE ON expensa.reporte_recaudacion_semanal			 TO [Administrativo Operativo];
GRANT EXECUTE ON expensa.reporte_recaudacion_mes_departamento	 TO [Administrativo Operativo];
GRANT EXECUTE ON expensa.reporte_recudacion_tipo_periodo		 TO [Administrativo Operativo];
GRANT EXECUTE ON expensa.reporte_top_gastos_ingresos			 TO [Administrativo Operativo];
GRANT EXECUTE ON expensa.reporte_top_morosos					 TO [Administrativo Operativo];
GRANT EXECUTE ON expensa.reporte_fechas_pagos_uf				 TO [Administrativo Operativo];
GRANT EXECUTE ON expensa.reporte_deuda_periodo_usd				 TO [Administrativo Operativo];

-- DENY explícito a operaciones bancarias y consorcios
DENY EXECUTE ON banco.importar_conciliar_pagos					 TO [Administrativo Operativo];
DENY EXECUTE ON administracion.importar_consorcios				 TO [Administrativo Operativo];


PRINT '- Permisos asignados correctamente';
GO

----------------------------------------------------------------
-- 5. PERMISOS PARA "SISTEMAS"
---------------------------------------------------------------
GRANT EXECUTE ON expensa.reporte_recaudacion_semanal			TO [Sistemas];
GRANT EXECUTE ON expensa.reporte_recaudacion_mes_departamento	TO [Sistemas];
GRANT EXECUTE ON expensa.reporte_recudacion_tipo_periodo		TO [Sistemas];
GRANT EXECUTE ON expensa.reporte_top_gastos_ingresos			TO [Sistemas];
GRANT EXECUTE ON expensa.reporte_top_morosos					TO [Sistemas];
GRANT EXECUTE ON expensa.reporte_fechas_pagos_uf				TO [Sistemas];
GRANT EXECUTE ON expensa.reporte_deuda_periodo_usd				TO [Sistemas];

DENY EXECUTE ON administracion.importar_consorcios				TO [Sistemas];
DENY EXECUTE ON administracion.importar_uf						TO [Sistemas];
DENY EXECUTE ON unidad_funcional.importar_uf_cbu				TO [Sistemas];
DENY EXECUTE ON persona.importar_inquilinos_propietarios		TO [Sistemas];
DENY EXECUTE ON banco.importar_conciliar_pagos					TO [Sistemas];
DENY EXECUTE ON administracion.importar_gastos					TO [Sistemas];
DENY EXECUTE ON administracion.cargar_proveedores				TO [Sistemas];
DENY EXECUTE ON administracion.cargar_tipo_gastos				TO [Sistemas];
DENY EXECUTE ON expensa.llenar_expensas							TO [Sistemas];
DENY EXECUTE ON administracion.crear_periodos					TO [Sistemas];
PRINT '- Permisos asignados correctamente';
GO

--LISTAR TODOS LOS ROLES CREADOS

SELECT 
    name AS 'Rol',
    type_desc AS 'Tipo',
    create_date AS 'Fecha Creación',
    modify_date AS 'Última Modificación'
FROM sys.database_principals
WHERE type = 'R' 
    AND name IN (
        'Administrativo General', 
        'Administrativo Bancario', 
        'Administrativo Operativo', 
        'Sistemas'
    )
ORDER BY name;

-- LISTADO DE TODOS LOS SP Y SU ACCESO POR ROL

SELECT 
    SCHEMA_NAME(p.schema_id) AS 'Esquema',
    p.name AS 'Stored Procedure',
    MAX(CASE WHEN rol.name = 'Administrativo General' THEN 
        CASE WHEN perm.state = 'G' THEN 'GRANT' 
             WHEN perm.state = 'D' THEN 'DENY' 
             ELSE '-' END 
    END) AS 'Adm. General',
    MAX(CASE WHEN rol.name = 'Administrativo Bancario' THEN 
        CASE WHEN perm.state = 'G' THEN 'GRANT' 
             WHEN perm.state = 'D' THEN 'DENY' 
             ELSE '-' END 
    END) AS 'Adm. Bancario',
    MAX(CASE WHEN rol.name = 'Administrativo Operativo' THEN 
        CASE WHEN perm.state = 'G' THEN 'GRANT' 
             WHEN perm.state = 'D' THEN 'DENY' 
             ELSE '-' END 
    END) AS 'Adm. Operativo',
    MAX(CASE WHEN rol.name = 'Sistemas' THEN 
        CASE WHEN perm.state = 'G' THEN 'GRANT' 
             WHEN perm.state = 'D' THEN 'DENY' 
             ELSE '-' END 
    END) AS 'Sistemas'
FROM sys.objects p
LEFT JOIN sys.database_permissions perm ON p.object_id = perm.major_id
    AND perm.permission_name = 'EXECUTE'
LEFT JOIN sys.database_principals rol ON perm.grantee_principal_id = rol.principal_id
    AND rol.name IN ('Administrativo General', 'Administrativo Bancario', 'Administrativo Operativo', 'Sistemas')
WHERE p.type = 'P' -- Stored Procedures
    AND SCHEMA_NAME(p.schema_id) IN ('administracion', 'banco', 'expensa', 'persona', 'unidad_funcional')
GROUP BY SCHEMA_NAME(p.schema_id), p.name
ORDER BY SCHEMA_NAME(p.schema_id), p.name;




USE master; -- Se trabaja a nivel de servidor (Logins)
GO

PRINT '--- 1. Creación de Logins (Inicios de Sesión) ---';

IF EXISTS (SELECT name FROM sys.server_principals WHERE name = 'Test_AdmGeneral')
    DROP LOGIN Test_AdmGeneral;
CREATE LOGIN Test_AdmGeneral WITH PASSWORD = N'password', CHECK_POLICY = OFF;
PRINT '- Login Test_AdmGeneral creado';
GO

-- Login para Administrativo Bancario
IF EXISTS (SELECT name FROM sys.server_principals WHERE name = 'Test_AdmBancario')
    DROP LOGIN Test_AdmBancario;
CREATE LOGIN Test_AdmBancario WITH PASSWORD = N'password', CHECK_POLICY = OFF;
PRINT '- Login Test_AdmBancario creado';
GO

-- Login para Administrativo Operativo
IF EXISTS (SELECT name FROM sys.server_principals WHERE name = 'Test_AdmOperativo')
    DROP LOGIN Test_AdmOperativo;
CREATE LOGIN Test_AdmOperativo WITH PASSWORD = N'password', CHECK_POLICY = OFF;
PRINT '- Login Test_AdmOperativo creado';
GO

-- Login para Sistemas
IF EXISTS (SELECT name FROM sys.server_principals WHERE name = 'Test_Sistemas')
    DROP LOGIN Test_Sistemas;
CREATE LOGIN Test_Sistemas WITH PASSWORD = N'password', CHECK_POLICY = OFF;
PRINT '- Login Test_Sistemas creado';
GO

GRANT ADMINISTER BULK OPERATIONS TO Test_AdmBancario;
GRANT ADMINISTER BULK OPERATIONS TO Test_AdmOperativo;
GRANT ADMINISTER BULK OPERATIONS TO Test_AdmGeneral;
GO

USE Com5600G03; -- Se trabaja a nivel de base de datos (Usuarios y Roles)
GO


PRINT '--- 2. Creación de Usuarios y Mapeo al Login ---';

-- Usuario para Administrativo General
IF EXISTS (SELECT name FROM sys.database_principals WHERE name = 'Usuario_AdmGeneral')
    DROP USER Usuario_AdmGeneral;
CREATE USER Usuario_AdmGeneral FOR LOGIN Test_AdmGeneral;
PRINT '- Usuario Usuario_AdmGeneral creado';
GO

-- Usuario para Administrativo Bancario
IF EXISTS (SELECT name FROM sys.database_principals WHERE name = 'Usuario_AdmBancario')
    DROP USER Usuario_AdmBancario;
CREATE USER Usuario_AdmBancario FOR LOGIN Test_AdmBancario;
PRINT '- Usuario Usuario_AdmBancario creado';
GO

-- Usuario para Administrativo Operativo
IF EXISTS (SELECT name FROM sys.database_principals WHERE name = 'Usuario_AdmOperativo')
    DROP USER Usuario_AdmOperativo;
CREATE USER Usuario_AdmOperativo FOR LOGIN Test_AdmOperativo;
PRINT '- Usuario Usuario_AdmOperativo creado';
GO

-- Usuario para Sistemas
IF EXISTS (SELECT name FROM sys.database_principals WHERE name = 'Usuario_Sistemas')
    DROP USER Usuario_Sistemas;
CREATE USER Usuario_Sistemas FOR LOGIN Test_Sistemas;
PRINT '- Usuario Usuario_Sistemas creado';
GO


PRINT '--- 3. Asignación de Roles de BD a los Usuarios ---';

-- Asignar roles (Debería funcionar ahora que los usuarios existen)
ALTER ROLE [Administrativo General] ADD MEMBER Usuario_AdmGeneral;
PRINT '- Rol Administrativo General asignado a Usuario_AdmGeneral';
GO

ALTER ROLE [Administrativo Bancario] ADD MEMBER Usuario_AdmBancario;
PRINT '- Rol Administrativo Bancario asignado a Usuario_AdmBancario';
GO

ALTER ROLE [Administrativo Operativo] ADD MEMBER Usuario_AdmOperativo;
PRINT '- Rol Administrativo Operativo asignado a Usuario_AdmOperativo';
GO

ALTER ROLE [Sistemas] ADD MEMBER Usuario_Sistemas;
PRINT '- Rol Sistemas asignado a Usuario_Sistemas';
GO


PRINT 'Los Logins y Usuarios han sido creados correctamente y los roles asignados.';


/*
TESTING 
-Test_Sistemas

USE Com5600G03;
GO

DENY:
EXEC administracion.importar_consorcios 
    @RutaArchivo = 'C:\_temp\datos varios(Consorcios).csv';

DENY:
EXEC administracion.importar_uf
    @RutaArchivo = N'C:\_temp\UF por consorcio.txt';

GRANT:
EXEC expensa.reporte_recaudacion_mes_departamento
    @Anio        = 2025,
    @ConsorcioId = 2,
    @MesInicio   = 1,
    @MesFin      = 6;

TESTING
-Test_AdmOperativo

USE Com5600G03;
GO

DENY:
EXEC banco.importar_conciliar_pagos
    @RutaArchivo = N'C:\_temp\pagos_consorcios.csv',
    @IdCuentaDestino = 1;

GRANT:
EXEC administracion.cargar_tipo_gastos;

TESTING
-Test_AdmBancario

USE Com5600G03;
GO

DENY:
EXEC administracion.crear_periodos @Anio = 2026;

DENY:
EXEC administracion.cargar_proveedores
    @RutaArchivo = N'C:\_temp\datos varios(Proveedores).csv';

GRANT:
EXEC banco.importar_conciliar_pagos
    @RutaArchivo = N'C:\_temp\pagos_consorcios.csv',
    @IdCuentaDestino = 1;

TESTING
-Test_AdmGeneral

USE Com5600G03;
GO

DENY:
EXEC administracion.importar_gastos
    @RutaArchivo = N'C:\_temp\Servicios.Servicios.json';

DENY:
EXEC banco.importar_conciliar_pagos
    @RutaArchivo = N'C:\_temp\pagos_consorcios.csv',
    @IdCuentaDestino = 1;

GRANT:
EXEC unidad_funcional.importar_uf_cbu
     @RutaArchivo = N'C:\_temp\Inquilino-propietarios-UF.csv';

GRANT:
EXEC persona.importar_inquilinos_propietarios
    @RutaArchivo = N'C:\_temp\Inquilino-propietarios-datos.csv';
*/