# historias/

Trazabilidad por iniciativa (OPT, incidente, APEX), separada por estado.

## Indice rapido

- [INVENTARIO.md](INVENTARIO.md) — tabla maestra con el estado de cada caso. Empezar aqui.

## Convencion de carpetas

```
historias/
├── INVENTARIO.md              # Tabla maestra
├── README.md                  # Este archivo
├── optimizaciones/
│   ├── produccion/            # OPT con cambio en PROD (ver CHANGELOG PROD)
│   ├── probados_no_promovidos/# OPT probada en QA/QA02/DESA, no esta en PROD
│   ├── descartados/           # OPT que no entrego beneficio o fue reemplazada
│   ├── diagnosticos/          # Mediciones, explain plans, equivalencias
│   ├── propuestas/            # Propuestas pendientes de aprobacion
│   └── soporte/               # Material reusable (scripts de medicion, mapas, planes)
├── incidentes/
│   ├── abiertos/              # Incidentes en investigacion / accion pendiente
│   ├── diagnosticos/          # Diagnosticos no concluidos
│   └── cerrados/              # Incidentes resueltos
├── soporte_qa02/              # Fixes y diagnosticos en QA02 que no son incidente formal
└── apex/
    ├── produccion/            # Releases APEX confirmados en PROD
    ├── en_qa/                 # Releases APEX probados en QA, no en PROD
    ├── pendientes_confirmacion/ # Historias sin estado documentado
    └── champion/              # Paquetes y plantillas de referencia
```

## Regla operativa

- Cada carpeta de historia debe tener `README.md` (detalle tecnico, historico) y `ESTADO.md` (metadato operativo).
- Cuando cambia el estado, **mover la carpeta** y actualizar `INVENTARIO.md` en el mismo commit.
- No borrar carpetas: los casos descartados se mueven a `descartados/`, no se eliminan.
- Cuando se promueve algo a PROD, registrar en `ENTORNOS_ORACLE/Produccion/CHANGELOG.md` el mismo dia.

## Plantilla ESTADO.md

Copiar [_plantillas/ESTADO.md](_plantillas/ESTADO.md) al crear una nueva historia.
