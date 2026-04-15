**Titulo:** Optimizacion de rendimiento del job de precalificacion de cancelados

**Descripcion:**
Yo como negocios requiero que se analice y optimice el rendimiento del job `P_Carga_Precalifica_Cancelado` del paquete `PR.PR_PKG_REPRESTAMOS`, el cual actualmente tarda en completarse, identificando los procedimientos que mas tiempo consumen y aplicando mejoras de rendimiento sin alterar los resultados funcionales del proceso.

**Criterios de aceptacion:**

- Que se identifiquen los procedimientos internos del job que mas tiempo consumen mediante mediciones con script.
- Que se apliquen optimizaciones a los procedimientos identificados como cuello de botella.
- Que el body del paquete `PR.PR_PKG_REPRESTAMOS` compile sin errores despues de aplicar los cambios.
- Que el job optimizado ejecute en menor tiempo que la version original.
- Que no se modifiquen procedimientos que no requieran optimizacion.
