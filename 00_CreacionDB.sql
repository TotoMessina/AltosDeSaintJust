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

----CREACIÓN DE LA BASE DE DATOS

USE master;
GO

-- Eliminar DB si existe
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'Com5600G03')
BEGIN
    ALTER DATABASE Com5600G03 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Com5600G03;
END
GO

-- Crear DB
CREATE DATABASE Com5600G03;
GO

USE Com5600G03;
GO

PRINT 'Base de datos Com5600G03 creada correctamente';
GO

----------------------------------------------------------------
-- CREACI�N DE ESQUEMAS
----------------------------------------------------------------
CREATE SCHEMA administracion;
GO
CREATE SCHEMA unidad_funcional;
GO
CREATE SCHEMA expensa;
GO
CREATE SCHEMA persona;
GO
CREATE SCHEMA banco;
GO

PRINT 'Esquemas creados correctamente';
GO

----------------------------------------------------------------
-- TABLAS DE ADMINISTRACI�N
----------------------------------------------------------------

-- Tabla administracion
CREATE TABLE administracion.administracion (
    administracion_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    cuit VARCHAR(20),
    domicilio VARCHAR(250),
    email VARCHAR(200),
    telefono VARCHAR(50),
    created_at DATETIME DEFAULT GETDATE(),
    CONSTRAINT UQ_administracion_nombre UNIQUE (nombre)
);

-- Tabla consorcio
CREATE TABLE administracion.consorcio (
    consorcio_id INT IDENTITY(1,1) PRIMARY KEY,
    administracion_id INT NOT NULL,
    nombre VARCHAR(200) NOT NULL,
    cuit VARCHAR(20),
    domicilio VARCHAR(250),
    superficie_total_m2 NUMERIC(12,2),
    fecha_alta DATE DEFAULT GETDATE(),
    FOREIGN KEY (administracion_id) REFERENCES administracion.administracion(administracion_id),
    CONSTRAINT UQ_consorcio_nombre UNIQUE (nombre)
);

-- Tabla cuenta_bancaria
CREATE TABLE administracion.cuenta_bancaria (
    cuenta_id INT IDENTITY(1,1) PRIMARY KEY,
    banco VARCHAR(120) NOT NULL,
    alias VARCHAR(120),
    cbu_cvu VARCHAR(40) NOT NULL,
    CONSTRAINT UQ_cuenta_cbu UNIQUE (cbu_cvu)
);

-- Tabla relaci�n consorcio-cuenta
CREATE TABLE administracion.consorcio_cuenta_bancaria (
    consorcio_cuenta_id INT IDENTITY(1,1) PRIMARY KEY,
    consorcio_id INT NOT NULL,
    cuenta_id INT NOT NULL,
    es_principal BIT DEFAULT 0,
    FOREIGN KEY (consorcio_id) REFERENCES administracion.consorcio(consorcio_id),
    FOREIGN KEY (cuenta_id) REFERENCES administracion.cuenta_bancaria(cuenta_id),
    CONSTRAINT UQ_consorcio_cuenta UNIQUE (consorcio_id, cuenta_id)
);

CREATE INDEX IX_consorcio_cuenta_principal ON administracion.consorcio_cuenta_bancaria(consorcio_id, es_principal) WHERE es_principal = 1;

PRINT 'Tablas de administraci�n creadas';
GO

----------------------------------------------------------------
-- TABLAS DE UNIDAD FUNCIONAL
----------------------------------------------------------------

-- Tabla unidad_funcional
CREATE TABLE unidad_funcional.unidad_funcional (
    uf_id INT IDENTITY(1,1) PRIMARY KEY,
    consorcio_id INT NOT NULL,
    codigo VARCHAR(50) NOT NULL,
    piso CHAR(3),
    depto CHAR(3),
    superficie_m2 NUMERIC(12,2) CHECK (superficie_m2 >= 0),
    porcentaje NUMERIC(7,4) CHECK (porcentaje >= 0 AND porcentaje <= 100),
    FOREIGN KEY (consorcio_id) REFERENCES administracion.consorcio(consorcio_id),
    CONSTRAINT UQ_uf_consorcio_codigo UNIQUE (consorcio_id, codigo)
);

-- Tabla uf_cuenta
CREATE TABLE unidad_funcional.uf_cuenta (
    uf_cuenta_id INT IDENTITY(1,1) PRIMARY KEY,
    uf_id INT NOT NULL,
    cuenta_id INT NOT NULL,
    fecha_desde DATE NOT NULL DEFAULT GETDATE(),
    fecha_hasta DATE,
    FOREIGN KEY (uf_id) REFERENCES unidad_funcional.unidad_funcional(uf_id),
    FOREIGN KEY (cuenta_id) REFERENCES administracion.cuenta_bancaria(cuenta_id),
    CONSTRAINT CK_uf_cuenta_fechas CHECK (fecha_hasta IS NULL OR fecha_hasta > fecha_desde)
);

CREATE INDEX IX_uf_cuenta_activas ON unidad_funcional.uf_cuenta(uf_id) WHERE fecha_hasta IS NULL;

-- Tabla cochera
CREATE TABLE unidad_funcional.cochera (
    cochera_id INT IDENTITY(1,1) PRIMARY KEY,
    consorcio_id INT NOT NULL,
    uf_id INT,
    codigo VARCHAR(50) NOT NULL,
    superficie_m2 NUMERIC(12,2) CHECK (superficie_m2 >= 0),
    porcentaje NUMERIC(7,4) CHECK (porcentaje >= 0 AND porcentaje <= 100),
    FOREIGN KEY (consorcio_id) REFERENCES administracion.consorcio(consorcio_id),
    FOREIGN KEY (uf_id) REFERENCES unidad_funcional.unidad_funcional(uf_id),
    CONSTRAINT UQ_cochera_codigo UNIQUE (consorcio_id, codigo)
);

-- Tabla baulera
CREATE TABLE unidad_funcional.baulera (
    baulera_id INT IDENTITY(1,1) PRIMARY KEY,
    consorcio_id INT NOT NULL,
    uf_id INT,
    codigo VARCHAR(50) NOT NULL,
    superficie_m2 NUMERIC(12,2) CHECK (superficie_m2 >= 0),
    porcentaje NUMERIC(7,4) CHECK (porcentaje >= 0 AND porcentaje <= 100),
    FOREIGN KEY (consorcio_id) REFERENCES administracion.consorcio(consorcio_id),
    FOREIGN KEY (uf_id) REFERENCES unidad_funcional.unidad_funcional(uf_id),
    CONSTRAINT UQ_baulera_codigo UNIQUE (consorcio_id, codigo)
);

PRINT 'Tablas de unidad funcional creadas';
GO

----------------------------------------------------------------
-- TABLAS DE PERSONA
----------------------------------------------------------------

-- Tabla persona
CREATE TABLE persona.persona (
    persona_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre_completo VARCHAR(200) NOT NULL,
    tipo_doc VARCHAR(20) DEFAULT 'DNI',
    nro_doc VARCHAR(40) NOT NULL,
    direccion VARCHAR(250),
    CONSTRAINT UQ_persona_doc UNIQUE (tipo_doc, nro_doc)
);

-- Tabla persona_contacto
CREATE TABLE persona.persona_contacto (
    contacto_id INT IDENTITY(1,1) PRIMARY KEY,
    persona_id INT NOT NULL,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('EMAIL', 'TELEFONO', 'WHATSAPP')),
    valor VARCHAR(200) NOT NULL,
    es_preferido BIT DEFAULT 0,
    FOREIGN KEY (persona_id) REFERENCES persona.persona(persona_id),
    CONSTRAINT UQ_persona_contacto UNIQUE (persona_id, tipo, valor)
);

-- Tabla uf_persona_vinculo
CREATE TABLE unidad_funcional.uf_persona_vinculo (
    uf_persona_id INT IDENTITY(1,1) PRIMARY KEY,
    uf_id INT NOT NULL,
    persona_id INT NOT NULL,
    rol VARCHAR(20) NOT NULL CHECK (rol IN ('PROPIETARIO', 'INQUILINO', 'RESPONSABLE')),
    fecha_desde DATE NOT NULL DEFAULT GETDATE(),
    fecha_hasta DATE,
    medio_envio_preferido VARCHAR(20) CHECK (medio_envio_preferido IN ('EMAIL', 'WHATSAPP', 'IMPRESO')) DEFAULT 'EMAIL',
    FOREIGN KEY (uf_id) REFERENCES unidad_funcional.unidad_funcional(uf_id),
    FOREIGN KEY (persona_id) REFERENCES persona.persona(persona_id),
    CONSTRAINT CK_uf_persona_fechas CHECK (fecha_hasta IS NULL OR fecha_hasta > fecha_desde)
);

CREATE INDEX IX_uf_persona_uf ON unidad_funcional.uf_persona_vinculo(uf_id, fecha_hasta);
CREATE INDEX IX_uf_persona_activos ON unidad_funcional.uf_persona_vinculo(uf_id) WHERE fecha_hasta IS NULL;

PRINT 'Tablas de persona creadas';
GO

----------------------------------------------------------------
-- TABLAS DE EXPENSAS
----------------------------------------------------------------

-- Tabla periodo
CREATE TABLE expensa.periodo (
    periodo_id INT IDENTITY(1,1) PRIMARY KEY,
    consorcio_id INT NOT NULL,
    anio SMALLINT NOT NULL,
    mes SMALLINT NOT NULL CHECK (mes BETWEEN 1 AND 12),
    vencimiento_1 DATE,
    vencimiento_2 DATE,
    interes_entre_vtos_pct NUMERIC(6,3) DEFAULT 2.000,
    interes_post_2do_pct NUMERIC(6,3) DEFAULT 5.000,
    FOREIGN KEY (consorcio_id) REFERENCES administracion.consorcio(consorcio_id),
    CONSTRAINT UQ_periodo_consorcio_anio_mes UNIQUE (consorcio_id, anio, mes),
    CONSTRAINT CK_periodo_vencimientos CHECK (vencimiento_2 IS NULL OR vencimiento_2 > vencimiento_1)
);

CREATE INDEX IX_periodo_consorcio_fecha ON expensa.periodo(consorcio_id, anio, mes);

-- Tabla tipo_gasto
CREATE TABLE expensa.tipo_gasto (
    tipo_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    CONSTRAINT UQ_tipo_gasto_nombre UNIQUE (nombre)
);

-- Tabla sub_tipo_gasto
CREATE TABLE expensa.sub_tipo_gasto (
    sub_id INT IDENTITY(1,1) PRIMARY KEY,
    tipo_id INT NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    FOREIGN KEY (tipo_id) REFERENCES expensa.tipo_gasto(tipo_id),
    CONSTRAINT UQ_sub_tipo_nombre UNIQUE (nombre)
);

-- Tabla proveedor
CREATE TABLE expensa.proveedor (
    proveedor_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    cuit VARCHAR(20),
    consorcio_id INT NOT NULL,
    sub_id INT NOT NULL,
    detalle VARCHAR(250)
);

CREATE INDEX IX_proveedor_consorcio ON expensa.proveedor(consorcio_id, sub_id);

-- Tabla gasto
CREATE TABLE expensa.gasto (
    gasto_id INT IDENTITY(1,1) PRIMARY KEY,
    consorcio_id INT NOT NULL,
    periodo_id INT NOT NULL,
    tipo_id INT NOT NULL,
    sub_id INT NOT NULL,
    proveedor_id INT,
    nro_factura VARCHAR(60),
    detalle TEXT,
    importe NUMERIC(14,2) NOT NULL CHECK (importe >= 0),
    cuota_num SMALLINT CHECK (cuota_num > 0),
    cuota_total SMALLINT CHECK (cuota_total > 0),
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME,
    created_by VARCHAR(50) DEFAULT 'SYSTEM',
    updated_by VARCHAR(50),
    FOREIGN KEY (consorcio_id) REFERENCES administracion.consorcio(consorcio_id),
    FOREIGN KEY (periodo_id) REFERENCES expensa.periodo(periodo_id),
    FOREIGN KEY (tipo_id) REFERENCES expensa.tipo_gasto(tipo_id),
    FOREIGN KEY (sub_id) REFERENCES expensa.sub_tipo_gasto(sub_id),
    FOREIGN KEY (proveedor_id) REFERENCES expensa.proveedor(proveedor_id),
    CONSTRAINT CK_gasto_cuotas CHECK (
        (cuota_num IS NULL AND cuota_total IS NULL) OR 
        (cuota_num IS NOT NULL AND cuota_total IS NOT NULL AND cuota_num <= cuota_total)
    )
);

CREATE INDEX IX_gasto_periodo ON expensa.gasto(periodo_id, consorcio_id);
CREATE INDEX IX_gasto_tipo ON expensa.gasto(tipo_id, sub_id);
CREATE INDEX IX_gasto_proveedor ON expensa.gasto(proveedor_id);

-- Tabla estado_financiero
CREATE TABLE expensa.estado_financiero (
    estado_id INT IDENTITY(1,1) PRIMARY KEY,
    periodo_id INT NOT NULL,
    saldo_anterior NUMERIC(14,2) DEFAULT 0,
    ingresos_en_termino NUMERIC(14,2) DEFAULT 0,
    ingresos_adeudados NUMERIC(14,2) DEFAULT 0,
    ingresos_adelantados NUMERIC(14,2) DEFAULT 0,
    egresos_del_mes NUMERIC(14,2) DEFAULT 0,
    saldo_cierre NUMERIC(14,2) DEFAULT 0,
    FOREIGN KEY (periodo_id) REFERENCES expensa.periodo(periodo_id),
    CONSTRAINT UQ_estado_periodo UNIQUE (periodo_id)
);

-- Tabla expensa_uf
CREATE TABLE expensa.expensa_uf (
    expensa_uf_id INT IDENTITY(1,1) PRIMARY KEY,
    periodo_id INT NOT NULL,
    uf_id INT NOT NULL,
    porcentaje NUMERIC(7,4),
    saldo_anterior_abonado NUMERIC(14,2) DEFAULT 0,
    pagos_recibidos NUMERIC(14,2) DEFAULT 0,
    deuda_anterior NUMERIC(14,2) DEFAULT 0,
    interes_mora NUMERIC(14,2) DEFAULT 0,
    expensas_ordinarias NUMERIC(14,2) DEFAULT 0,
    expensas_extraordinarias NUMERIC(14,2) DEFAULT 0,
    total_a_pagar NUMERIC(14,2) DEFAULT 0,
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME,
    created_by VARCHAR(50) DEFAULT 'SYSTEM',
    updated_by VARCHAR(50),
    FOREIGN KEY (periodo_id) REFERENCES expensa.periodo(periodo_id),
    FOREIGN KEY (uf_id) REFERENCES unidad_funcional.unidad_funcional(uf_id),
    CONSTRAINT UQ_expensa_uf_periodo UNIQUE (periodo_id, uf_id)
);

CREATE INDEX IX_expensa_uf_periodo ON expensa.expensa_uf(periodo_id);
CREATE INDEX IX_expensa_uf_uf ON expensa.expensa_uf(uf_id);

-- Tabla expensa_uf_detalle
CREATE TABLE expensa.expensa_uf_detalle (
    detalle_id INT IDENTITY(1,1) PRIMARY KEY,
    expensa_uf_id INT NOT NULL,
    gasto_id INT NOT NULL,
    concepto VARCHAR(200),
    importe NUMERIC(14,2) NOT NULL,
    FOREIGN KEY (expensa_uf_id) REFERENCES expensa.expensa_uf(expensa_uf_id),
    FOREIGN KEY (gasto_id) REFERENCES expensa.gasto(gasto_id)
);

-- Tabla expensa_uf_interes
CREATE TABLE expensa.expensa_uf_interes (
    id INT IDENTITY(1,1) PRIMARY KEY,
    expensa_uf_id INT NOT NULL,
    tipo VARCHAR(20) CHECK (tipo IN ('ENTRE_VTOS', 'POST_2DO')),
    porcentaje NUMERIC(6,3),
    importe NUMERIC(14,2),
    FOREIGN KEY (expensa_uf_id) REFERENCES expensa.expensa_uf(expensa_uf_id)
);

-- Tabla envio_documento
CREATE TABLE expensa.envio_documento (
    envio_id INT IDENTITY(1,1) PRIMARY KEY,
    periodo_id INT NOT NULL,
    uf_id INT NOT NULL,
    persona_id INT NOT NULL,
    medio VARCHAR(20) CHECK (medio IN ('EMAIL', 'WHATSAPP', 'IMPRESO')),
    destino VARCHAR(250),
    fecha_envio DATETIME DEFAULT GETDATE(),
    estado VARCHAR(30) CHECK (estado IN ('PENDIENTE', 'ENVIADO', 'ERROR', 'ENTREGADO')),
    FOREIGN KEY (periodo_id) REFERENCES expensa.periodo(periodo_id),
    FOREIGN KEY (uf_id) REFERENCES unidad_funcional.unidad_funcional(uf_id),
    FOREIGN KEY (persona_id) REFERENCES persona.persona(persona_id)
);

PRINT 'Tablas de expensas creadas';
GO

----------------------------------------------------------------
-- TABLAS DE BANCO Y PAGOS
----------------------------------------------------------------

-- Tabla banco_movimiento
CREATE TABLE banco.banco_movimiento (
    movimiento_id INT IDENTITY(1,1) PRIMARY KEY,
    consorcio_id INT NOT NULL,
    cuenta_id INT NOT NULL,
    cbu_origen VARCHAR(40),
    fecha DATE NOT NULL,
    importe NUMERIC(14,2) NOT NULL,
    estado_conciliacion VARCHAR(20) CHECK (estado_conciliacion IN ('PENDIENTE', 'ASOCIADO', 'NO_ASOCIADO')),
    FOREIGN KEY (consorcio_id) REFERENCES administracion.consorcio(consorcio_id),
    FOREIGN KEY (cuenta_id) REFERENCES administracion.cuenta_bancaria(cuenta_id)
);

CREATE INDEX IX_movimiento_fecha ON banco.banco_movimiento(consorcio_id, fecha);
CREATE INDEX IX_movimiento_cbu ON banco.banco_movimiento(cbu_origen);

-- Tabla pago
CREATE TABLE banco.pago (
    pago_id INT IDENTITY(1,1) PRIMARY KEY,
    uf_id INT NOT NULL,
    fecha DATE NOT NULL,
    importe NUMERIC(14,2) NOT NULL CHECK (importe > 0),
    tipo VARCHAR(20) CHECK (tipo IN ('ORDINARIO', 'EXTRAORDINARIO', 'MORA', 'ADELANTADO')),
    movimiento_id INT,
    motivo_no_asociado VARCHAR(200),
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME,
    created_by VARCHAR(50) DEFAULT 'SYSTEM',
    updated_by VARCHAR(50),
    FOREIGN KEY (uf_id) REFERENCES unidad_funcional.unidad_funcional(uf_id),
    FOREIGN KEY (movimiento_id) REFERENCES banco.banco_movimiento(movimiento_id)
);

CREATE INDEX IX_pago_uf ON banco.pago(uf_id, fecha);
CREATE INDEX IX_pago_movimiento ON banco.pago(movimiento_id);

