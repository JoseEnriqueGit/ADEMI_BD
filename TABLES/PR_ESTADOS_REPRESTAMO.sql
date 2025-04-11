CREATE TABLE PR_ESTADOS_REPRESTAMO (
    CODIGO_EMPRESA                NUMBER(4) NOT NULL,
    CODIGO_ESTADO                 VARCHAR2(5 BYTE) NOT NULL,
    DES_ESTADO                    VARCHAR2(100 BYTE),
    ORDEN                         NUMBER(5),
    IND_NOTIFICA_CLIENTE          VARCHAR2(1 BYTE),
    ESTADO                        VARCHAR2(5 BYTE),
    ICONO                         VARCHAR2(100 BYTE),
    ADICIONADO_POR                VARCHAR2(30 BYTE),
    FECHA_ADICION                 DATE,
    MODIFICADO_POR                VARCHAR2(30 BYTE),
    FECHA_MODIFICACION            DATE,
    IND_CAMBIA_ESTADO_REPRE       VARCHAR2(1 BYTE),
    GRUPO                         VARCHAR2(50 BYTE),
    COLOR                         VARCHAR2(50 BYTE),
    IND_CAMBIA_ESTADO_ORIGINAL    VARCHAR2(1 BYTE),
    COMENTARIO                    VARCHAR2(4000 BYTE),
    CONSTRAINT PK_PR_ESTADOS_REPRESTAMO PRIMARY KEY (
        CODIGO_EMPRESA, 
        CODIGO_ESTADO
    )
);

--ESTOS SON LOS ESTADOS REGITRADOS

| CODIGO_ESTADO | DES_ESTADO | COMENTARIO |
| --- | --- | --- |
| AEP | AYUDA EN ATENCION | Ayuda que está siendo atendida actualmente por el Contact Center |
| AP | ACEPTA | El cliente ha aceptado el Représtamo en la pantalla de bienvenida. |
| AN | LINK VENCIDO | Link expirado al transcurrir los 10 días sin utilización o préstamo cancelado. |
| AYN | AYUDA PENDIENTE | Ayuda Pendiente de atención por el Contact Center |
| AYR | AYUDA ATENDIDA | Ayuda que ya ha sido atendida por el Contact Center |
| BLI | BLOQUEO IDENTIFICACION | Bloqueo por digitar la Identificación incorrectamente agotando la cantidad de intentos |
| BLP | BLOQUEO PIN | Bloqueo por digitar el PIN incorrectamente agotando la cantidad de intentos |
| CC | CREDITO CANCELADO | Crédito Cancelado |
| CFF | PRÉSTAMO FUD-FEC CREADA | FUD y FEC creada. |
| CP | CANAL PENDIENTE | SOLICITUD PENDIENTE DE CANAL |
| CRA | PRESTAMO APROBADO-FINALIZA PROCESO | Préstamo ha sido aprobado por la vertical. |
| CRD | PRESTAMO DESEMBOLSADO | El préstamo ha sido desembolsado por el cliente. |
| CRH | CAPTURA DE DATOS | Preparación de documentación legal del crédito |
| CRN | CREDITO ANULADO | Anulación del crédito desde FileFlow o Sysde |
| CRS | PRESTAMO SOLICITADO | Inicio el proceso en el Core del Préstamo. |
| CRV | PRESTAMO EN VALIDACION | Validación de los datos de la FUD y FEC con el cliente. |
| CRY | DOCUMENTACION FIRMADA | DOCUMENTOS FIRMADOS |
| CLS | Clasificación SIB | Estado para guardar la clasificación de la Superintendencia |
| DBA | NOTIFICACION DESBLOQUEO | Notificación de desbloqueo |
| EP | EN PROCESO | El cliente está registrando los datos del Représtamo después de haber aceptado. |
| LA | LINK ACTIVADO | Indicador que el cliente ha presionado el Link de la notificación y ha entrado a la aplicación. |
| MS | DESPUES | Cliente decide realizar el proceso más adelante. |
| NE | NOTIFICACION ERROR | Notificación enviada al cliente. |
| NBD | NOTIFICACION DESEMBOLSO | Notificación de desembolso |
| NP | NOTIFICACION PENDIENTE | Solicitudes (Représtamos) pendientes de notificar. |
| NR | NOTIFICACION ENVIADA | Notificación recibida por parte del cliente. |
| NTE | NOTIFICACION ENCUESTA | Notificación de encuesta |
| PX | Pendiente Xcore | Carga Inicial de los Représtamos |
| PS | SOLICITAR PIN | Solicitud de PIN de validación |
| RE | CREADO | Carga Inicial de los Représtamos |
| RCS | RECHAZO POR CLIENTE CASTIGADO EN SB | Carga Inicial de los Représtamos |
| RSB | RECHAZO POR CLIENTE NO EN A,B EN SB | Carga Inicial de los Représtamos |
| RXT | RECHAZADO POR TIPO DE CREDITO | Carga Inicial de los Représtamos |
| RXA | ANULADO | Carga Inicial de los Représtamos |
| RXC | RECHAZO POR XCORE INFERIOR 745 | Carga Inicial de los Représtamos |
| RXW | RECHAZADO POR WOLD COMPLIANCE | Carga Inicial de los Représtamos |
| RZ | DECLINADO | El cliente ha declinado la solicitud del Représtamo. |
| SC | SOLICITUD COMPLETADA | El cliente ha completado la solicitud de Représtamo seleccionado lo que quiere. |
| VR | VALIDACION DEL AREA DE RIESGO | El área de Riesgo va a validar contra la superintendencia la data correspondiente a la calificación de riesgo SIB |