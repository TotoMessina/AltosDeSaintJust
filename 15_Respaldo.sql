/*
------------------------------------------------------------
Trabajo Práctico Integrador - ENTREGA 7
Enunciado: Definición de política de backup, programación y RPO
           para la base de datos Com5600G03.
Fecha de entrega: 21-11-2025
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

-- POLÍTICA DE BACKUP PARA Com5600G03
-- Nota: no se requiere código de BACKUP en T-SQL, solo la definición
--       de la política, la programación (schedule) y el RPO.

-- 1) Objetivo general
--    Proteger la base de datos Com5600G03 frente a fallos lógicos,
--    errores de usuario y fallos de infraestructura, minimizando
--    la pérdida de datos y el tiempo de recuperación.

-- 2) Tipo de respaldos definidos
--    a) Backup FULL de base de datos
--    b) Backup DIFERENCIAL de base de datos
--    c) Backup de LOG de transacciones

-- 3) Política de ejecución

-- 3.1) BACKUP FULL
--      - Frecuencia: semanal
--      - Día: domingo
--      - Horario: 02:00 – 03:00 AM
--      - Justificación: horario de baja actividad y referencia
--        completa para diferenciales y logs.

-- 3.2) BACKUP DIFERENCIAL
--      - Frecuencia: diaria
--      - Días: lunes a sábado
--      - Horario: 03:00 AM
--      - Justificación: permite acotar el número de archivos de log
--        necesarios para una restauración y reduce la ventana de
--        exposición desde el último FULL.

-- 3.3) BACKUP DE LOG DE TRANSACCIONES
--      - Frecuencia: cada 1 hora
--      - Días: lunes a domingo
--      - Horario: de 08:00 a 20:00
--      - Justificación: durante el horario de mayor movimiento se
--        reduce la posible pérdida de datos a una hora como máximo.

-- 4) RPO (Recovery Point Objective)
--    - Se define un RPO de 1 hora.
--    - Esto significa que, ante un incidente grave, la pérdida máxima
--      de datos aceptable es la correspondiente al intervalo entre
--      dos backups de log consecutivos (1 hora).
--    - Con la combinación FULL + DIFERENCIAL + LOG se puede recuperar
--      la base hasta un punto en el tiempo dentro de esa ventana.

-- 5) RTO (Recovery Time Objective) - opcionalmente documentado
--    - No se solicita explícitamente en el enunciado, pero se deja
--      como referencia que el diseño de la política apunta a un RTO
--      razonable (en el orden de pocas horas) dada la necesidad de:
--        * Restaurar último FULL
--        * Aplicar último DIFERENCIAL disponible
--        * Aplicar secuencia de LOGs hasta el punto deseado

-- 6) Resumen de programación (Schedule)

--    - Backup FULL:
--        * Domingos a las 02:00 AM

--    - Backup DIFERENCIAL:
--        * Lunes a sábado a las 03:00 AM

--    - Backup LOG:
--        * Todos los días, cada 1 hora, de 08:00 a 20:00

-- 7) Observaciones finales
--    - Los backups se almacenan en un medio distinto al disco de datos,
--      con retención suficiente para cubrir al menos 4 semanas de historia.
--    - Es recomendable probar periódicamente el procedimiento de
--      restauración en un entorno de pruebas para validar el plan.
