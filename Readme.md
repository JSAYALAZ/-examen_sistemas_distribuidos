# Guía Final Paso a Paso: Desde la Creación de la Imagen Docker hasta Despliegue, Pruebas y Verificación Canary 80/20

> **Documento Unificado y Completo de Operación y Auditoría**  
> Este archivo contiene el flujo de trabajo unificado (**README.md** + **paso_a_paso.md**), optimizado tanto para entornos **Windows (PowerShell)** como **Linux/macOS (Bash)**. Incluye desde la compilación local de Docker hasta la verificación avanzada de despliegues Canary en Kubernetes.

---

## 📋 Tabla de Contenidos

1. [Estructura del Proyecto](#-1-estructura-del-proyecto)
2. [Requisitos Previos](#-2-requisitos-previos)
3. [Fase 1: Construcción y Prueba Local de la Imagen Docker](#-fase-1-construcción-y-prueba-local-de-la-imagen-docker)
   - [1.1 Construcción Multi-Stage Fail-Fast](#11-construcción-multi-stage-fail-fast)
   - [1.2 Ejecución del Contenedor Local](#12-ejecución-del-contenedor-local)
   - [1.3 Comprobaciones de Endpoints HTTP](#13-comprobaciones-de-endpoints-http)
   - [1.4 Escaneo Local de Vulnerabilidades con Trivy](#14-escaneo-local-de-vulnerabilidades-con-trivy)
4. [Fase 2: Preparación del Clúster Kubernetes (Minikube)](#-fase-2-preparación-del-clúster-kubernetes-minikube)
   - [2.1 Iniciar Minikube](#21-iniciar-minikube)
   - [2.2 Cargar la Imagen Local en Minikube](#22-cargar-la-imagen-local-en-minikube)
5. [Fase 3: Auditoría del Componente Adicional 1 — Manejo de Secretos](#-fase-3-auditoría-del-componente-adicional-1--manejo-de-secretos)
   - [3.1 Crear el Secret](#31-crear-el-secret)
   - [3.2 Inspeccionar y Decodificar el Secret (PowerShell vs Bash)](#32-inspeccionar-y-decodificar-el-secret-powershell-vs-bash)
6. [Fase 4: Despliegue Estable (v1 - Blue) y Auditoría del Componente Adicional 3 — Probes con Arranque Lento](#-fase-4-despliegue-estable-v1---blue-y-auditoría-del-componente-adicional-3--probes-con-arranque-lento)
   - [4.1 Aplicar Manifiestos de la Versión Estable](#41-aplicar-manifiestos-de-la-versión-estable)
   - [4.2 Monitorear el Arranque Lento (Readiness / Startup Probes)](#42-monitorear-el-arranque-lento-readiness--startup-probes)
   - [4.3 Obtener el Nombre del Pod en Variable (Compatibilidad Windows / Linux)](#43-obtener-el-nombre-del-pod-en-variable-compatibilidad-windows--linux)
   - [4.4 Validar Inyección del Secret dentro del Pod](#44-validar-inyección-del-secret-dentro-del-pod)
7. [Fase 5: Despliegue de la Estrategia Canary (v2 - Green)](#-fase-5-despliegue-de-la-estrategia-canary-v2---green)
   - [5.1 Aplicar Manifiestos Canary](#51-aplicar-manifiestos-canary)
   - [5.2 Verificar la Distribución 80/20 de Réplicas](#52-verificar-la-distribución-8020-de-réplicas)
8. [Fase 6: Guía Detallada de Verificación de la Estrategia Canary (Apertura de Puertos y Pruebas)](#-fase-6-guía-detallada-de-verificación-de-la-estrategia-canary-apertura-de-puertos-y-pruebas)
   - [6.1 Cómo Abrir el Puerto Local (Port-Forwarding)](#61-cómo-abrir-el-puerto-local-port-forwarding)
   - [6.2 Alternativa NodePort en Minikube](#62-alternativa-nodeport-en-minikube)
   - [6.3 Prueba Automática de Tráfico Canary (Script PowerShell para Windows)](#63-prueba-automática-de-tráfico-canary-script-powershell-para-windows)
   - [6.4 Prueba Automática de Tráfico Canary (Script Bash para Linux / Git Bash)](#64-prueba-automática-de-tráfico-canary-script-bash-para-linux--git-bash)
   - [6.5 Verificación Visual en Navegador Web](#65-verificación-visual-en-navegador-web)
9. [Fase 7: Verificación del Almacenamiento Efímero (Base de Datos Local JSON)](#-fase-7-verificación-del-almacenamiento-efímero-base-de-datos-local-json)
10. [Fase 8: Auditoría del Componente Adicional 2 — Escaneo de Seguridad DevSecOps con Trivy en CI/CD](#-fase-8-auditoría-del-componente-adicional-2--escaneo-de-seguridad-devsecops-con-trivy-en-cicd)
11. [Fase 9: Justificación Técnica — Estrategia Canary vs. Blue-Green](#-fase-9-justificación-técnica--estrategia-canary-vs-blue-green)
12. [Tabla Comparativa de Comandos: PowerShell vs. Bash](#-tabla-comparativa-de-comandos-powershell-vs-bash)

---

## 📁 1. Estructura del Proyecto

```text
inventario-app/
├── .github/
│   └── workflows/
│       └── ci-cd.yml             # Pipeline CI/CD (Build, Test, Trivy Scan, GHCR Push)
├── k8s/
│   ├── deployment.yaml           # Deployment Estable (v1, color blue, 4 réplicas)
│   ├── service.yaml              # Service unificado (NodePort 30080)
│   ├── secret.yaml               # Secret de Kubernetes (API_KEY)
│   └── canary/
│       ├── deployment-canary.yaml# Deployment Canary (v2, color green, 1 réplica)
│       └── service-canary.yaml   # Service Canary dedicado (NodePort 30081)
├── data/
│   └── products.json             # Base de datos local JSON (efímera en contenedor)
├── public/                       # Frontend estático (HTML5, CSS3, JS Vanilla)
│   ├── index.html
│   ├── app.js
│   └── styles.css
├── db.js                         # Módulo de persistencia local JSON
├── server.js                     # API REST Express con /health, /version y arranque lento
├── server.test.js                # Suite de pruebas unitarias (node --test)
├── Dockerfile                    # Docker build Multi-Stage con fail-fast estricto
├── paso_a_paso.md                # Guía técnica específica de componentes
├── README.md                     # Documentación general
└── final.md                      # GUÍA PASO A PASO UNIFICADA Y COMPLETA
```

---

## 🛠️ 2. Requisitos Previos

Asegúrate de contar con los siguientes programas instalados en tu sistema:
- **Docker Desktop** (con soporte de contenedores Linux activado).
- **Minikube** y **kubectl** instalados y añadidos al PATH del sistema.
- **PowerShell 7+** (o PowerShell 5.1 incluido en Windows) O **Git Bash / WSL / Linux Terminal**.

---

## 🐳 Fase 1: Construcción y Prueba Local de la Imagen Docker

### 1.1 Construcción Multi-Stage Fail-Fast

El `Dockerfile` utiliza una arquitectura de dos etapas:
1. **Stage 1 (Build & Test)**: Instala todas las dependencias y ejecuta `npm test`. Si las pruebas unitarias fallan, el proceso de build se interrumpe inmediatamente (**Fail-Fast**).
2. **Stage 2 (Production)**: Genera una imagen limpia y ligera basada en `node:18-alpine` conservando únicamente dependencias de producción.

Ejecuta en tu terminal (en el directorio `inventario-app`):

```powershell
# En PowerShell o Bash
docker build -t inventario-app:v1 .
docker build -t inventario-app:latest .
```

### 1.2 Ejecución del Contenedor Local

Inicia el contenedor localmente pasando variables de entorno de prueba:

```powershell
# En PowerShell o Bash
docker run -d `
  --name inventario-container `
  -p 3000:3000 `
  -e APP_VERSION=v1 `
  -e APP_COLOR=blue `
  -e STARTUP_DELAY_SECONDS=5 `
  -e API_KEY=local-test-key `
  inventario-app:v1
```

> *Nota: En Bash/Linux, reemplaza el carácter de acento grave (``` ` ```) por una barra invertida (`\`).*

### 1.3 Comprobaciones de Endpoints HTTP

#### En PowerShell (Windows):
```powershell
# 1. Comprobar salud (/health)
Invoke-RestMethod -Uri "http://localhost:3000/health"

# 2. Comprobar versión (/version)
Invoke-RestMethod -Uri "http://localhost:3000/version"

# 3. Listar productos (/api/products)
Invoke-RestMethod -Uri "http://localhost:3000/api/products"

# 4. Crear un producto de prueba (POST)
$body = @{ name="Teclado RGB"; sku="TEC-999"; stock=15; price=59.99 } | ConvertTo-Json
Invoke-RestMethod -Uri "http://localhost:3000/api/products" -Method POST -ContentType "application/json" -Body $body
```

#### En Bash (Linux / macOS / Git Bash):
```bash
# 1. Health check
curl -i http://localhost:3000/health

# 2. Version check
curl -i http://localhost:3000/version

# 3. Listar productos
curl -i http://localhost:3000/api/products

# 4. Crear producto
curl -i -X POST http://localhost:3000/api/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Teclado RGB","sku":"TEC-999","stock":15,"price":59.99}'
```

Limpiar el contenedor local al finalizar la prueba:
```powershell
docker stop inventario-container
docker rm inventario-container
```

---

### 1.4 Escaneo Local de Vulnerabilidades con Trivy

Simula localmente el análisis DevSecOps que ejecuta GitHub Actions:

```powershell
# En PowerShell o Bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock `
  aquasec/trivy:latest image --severity CRITICAL --exit-code 1 inventario-app:v1
```

- **Resultado esperado:** Si no se detectan vulnerabilidades de severidad `CRITICAL`, retornará código de salida `0`. De encontrar alguna, abortará con código de salida `1`.

---

## ☸️ Fase 2: Preparación del Clúster Kubernetes (Minikube)

### 2.1 Iniciar Minikube

```powershell
minikube start
```

### 2.2 Cargar la Imagen Local en Minikube

Para que Minikube pueda utilizar la imagen recién construida localmente sin descargarla de un registry externo:

**Opción A (Recomendada - Construcción directa en Minikube):**
```powershell
minikube image build -t inventario-app:latest .
```

**Opción B (Carga de imagen existente):**
```powershell
minikube image load inventario-app:latest
```

---

## 🔐 Fase 3: Auditoría del Componente Adicional 1 — Manejo de Secretos

El archivo `k8s/secret.yaml` define las credenciales sensibles desacopladas del código fuente.

### 3.1 Crear el Secret

```powershell
kubectl apply -f k8s/secret.yaml
```

### 3.2 Inspeccionar y Decodificar el Secret (PowerShell vs Bash)

#### En PowerShell (Windows):
> ⚠️ **Solución al problema de variables:** En PowerShell no se usa `$VAL=$(cmd)`. Se asigna directamente `$VAL = (cmd)`.

```powershell
# 1. Verificar existencia del secret
kubectl get secrets inventario-secrets

# 2. Obtener el valor codificado en Base64 y decodificarlo directamente en PowerShell:
$encodedKey = (kubectl get secret inventario-secrets -o jsonpath='{.data.API_KEY}')
$decodedKey = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encodedKey))

Write-Host "API_KEY Decodificada: $decodedKey"
# Output esperado: prod-secret-api-key-998877665544332211
```

#### En Bash (Linux / Git Bash):
```bash
kubectl get secret inventario-secrets -o jsonpath="{.data.API_KEY}" | base64 --decode
echo ""
# Output esperado: prod-secret-api-key-998877665544332211
```

---

## 🚀 Fase 4: Despliegue Estable (v1 - Blue) y Auditoría del Componente Adicional 3 — Probes con Arranque Lento

El despliegue base simula un tiempo de inicialización de 15 segundos (`STARTUP_DELAY_SECONDS=15`). Kubernetes utiliza `startupProbe` y `readinessProbe` para garantizar que no se envíe tráfico hasta que el servicio esté listo.

### 4.1 Aplicar Manifiestos de la Versión Estable

```powershell
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

### 4.2 Monitorear el Arranque Lento (Readiness / Startup Probes)

Observa la evolución de los Pods en tiempo real:

```powershell
kubectl get pods -l app=inventario-app -w
```

**Comportamiento Esperado:**
- Durante los primeros **15 segundos**, los Pods mostrarán estado `0/1 Running` (la sonda `/health` devuelve HTTP 503).
- Al cumplir los **15 segundos**, cambian a `1/1 Running` sin registrar ningún reinicio (`RESTARTS: 0`).

También puedes monitorear el despliegue mediante:
```powershell
kubectl rollout status deployment/inventario-app-stable
```

### 4.3 Obtener el Nombre del Pod en Variable (Compatibilidad Windows / Linux)

> 💡 **PROBLEMA SOLUCIONADO:** El comando bash `POD_NAME=$(kubectl ...)` falla en PowerShell con errores de sintaxis. A continuación se detallan las formas correctas para cada terminal:

#### 🟢 En PowerShell (Windows):
```powershell
# Guardar en variable de PowerShell
$POD_NAME = (kubectl get pods -l track=stable -o jsonpath='{.items[0].metadata.name}')

# Verificar la variable
Write-Host "Nombre del Pod activo: $POD_NAME"
```

#### 🐧 En Bash (Linux / macOS / Git Bash):
```bash
POD_NAME=$(kubectl get pods -l track=stable -o jsonpath="{.items[0].metadata.name}")
echo "Nombre del Pod activo: $POD_NAME"
```

---

### 4.4 Validar Inyección del Secret dentro del Pod

Una vez obtenida la variable `$POD_NAME`:

#### En PowerShell (Windows):
```powershell
# Inspeccionar variables de entorno inyectadas mediante secretKeyRef
kubectl exec $POD_NAME -- env | Select-String "API_KEY"
# Output esperado: API_KEY=prod-secret-api-key-998877665544332211
```

#### En Bash (Linux / Git Bash):
```bash
kubectl exec $POD_NAME -- env | grep API_KEY
# Output esperado: API_KEY=prod-secret-api-key-998877665544332211
```

---

## 🟢 Fase 5: Despliegue de la Estrategia Canary (v2 - Green)

La estrategia Canary despliega 1 réplica de la versión v2 (Green) junto a las 4 réplicas existentes de la versión v1 (Blue).

### 5.1 Aplicar Manifiestos Canary

```powershell
kubectl apply -f k8s/canary/deployment-canary.yaml
kubectl apply -f k8s/canary/service-canary.yaml
```

### 5.2 Verificar la Distribución 80/20 de Réplicas

Consulta la lista de Pods agrupados por la etiqueta unificada `app=inventario-app`:

```powershell
kubectl get pods -l app=inventario-app -o wide
```

**Resultado:**
- `inventario-app-stable-xxxxx` (4 Pods, versión `v1`, color `blue`) -> **80% del tráfico**
- `inventario-app-canary-xxxxx` (1 Pod, versión `v2`, color `green`) -> **20% del tráfico**

---

## 🧪 Fase 6: Guía Detallada de Verificación de la Estrategia Canary (Apertura de Puertos y Pruebas)

### 6.1 Cómo Abrir el Puerto Local (Port-Forwarding)

Para acceder al servicio desde tu máquina local (Windows o Linux), debes redirigir un puerto de tu máquina local al puerto del Service unificado de Kubernetes.

Ejecuta el siguiente comando en una **terminal dedicada** (déjala abierta):

```powershell
kubectl port-forward svc/inventario-service 3000:3000
```

> 📌 **¿Qué hace este comando?**  
> Conecta el puerto `3000` de tu máquina (`http://localhost:3000`) directamente con el `inventario-service` en Kubernetes, el cual balancea la carga entre los 5 Pods (4 estables + 1 canary).

---

### 6.2 Alternativa NodePort en Minikube

Si prefieres usar la función nativa de Minikube sin `port-forward`:

```powershell
# Obtener la URL pública expuesta por Minikube
minikube service inventario-service --url
```
O accede directamente a `http://localhost:30080` (si el túnel de Minikube está activo).

---

### 6.3 Prueba Automática de Tráfico Canary (Script PowerShell para Windows)

Abre una **segunda ventana de PowerShell** (mientras mantienes el `port-forward` corriendo en la primera) y ejecuta el siguiente script:

```powershell
# Script de validación de tráfico Canary en PowerShell
$url = "http://localhost:3000/version"
$v1_count = 0
$v2_count = 0

Write-Host "==================================================" -ForegroundColor Yellow
Write-Host " Iniciando prueba de 50 peticiones HTTP a $url " -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Yellow

1..50 | ForEach-Object {
    try {
        $res = Invoke-RestMethod -Uri $url -Method Get
        if ($res.version -eq "v2") {
            $v2_count++
            Write-Host "Peticion $_`: Version $($res.version) ($($res.color)) [CANARY]" -ForegroundColor Green
        } else {
            $v1_count++
            Write-Host "Peticion $_`: Version $($res.version) ($($res.color)) [STABLE]" -ForegroundColor Cyan
        }
    } catch {
        Write-Host "Peticion $_`: Error de conexion" -ForegroundColor Red
    }
}

Write-Host "--------------------------------------------------"
Write-Host "RESULTADOS DE LA PRUEBA CANARY (50 PETICIONES):" -ForegroundColor Yellow
Write-Host "Version v1 (Stable - Blue) : $v1_count peticiones ($($v1_count * 2)%)" -ForegroundColor Cyan
Write-Host "Version v2 (Canary - Green): $v2_count peticiones ($($v2_count * 2)%)" -ForegroundColor Green
Write-Host "--------------------------------------------------"
```

**Resultado esperado aproximado:**
- Version v1 (Stable - Blue): ~40 peticiones (**~80%**)
- Version v2 (Canary - Green): ~10 peticiones (**~20%**)

---

### 6.4 Prueba Automática de Tráfico Canary (Script Bash para Linux / Git Bash)

```bash
#!/bin/bash
URL="http://localhost:3000/version"
v1_count=0
v2_count=0

echo "--- Iniciando 50 peticiones al servicio Canary ---"

for i in {1..50}; do
  res=$(curl -s $URL)
  version=$(echo $res | grep -o '"version":"[^"]*"' | cut -d'"' -f4)
  color=$(echo $res | grep -o '"color":"[^"]*"' | cut -d'"' -f4)

  if [ "$version" == "v2" ]; then
    ((v2_count++))
    echo "Petición $i: Version $version ($color) [CANARY]"
  else
    ((v1_count++))
    echo "Petición $i: Version $version ($color) [STABLE]"
  fi
done

echo "--------------------------------------------------"
echo "RESULTADOS:"
echo "Version v1 (Stable): $v1_count peticiones ($((v1_count * 100 / 50))%)"
echo "Version v2 (Canary): $v2_count peticiones ($((v2_count * 100 / 50))%)"
```

---

### 6.5 Verificación Visual en Navegador Web

1. Abre tu navegador web en **`http://localhost:3000`**.
2. Observa la barra superior (Header):
   - Cuando el balanceador te dirija a una réplica v1, verás el distintivo **Azul (v1 - Stable)**.
   - Al recargar la página (puedes presionar `Ctrl + F5` para evitar caché), en aproximadamente 1 de cada 5 intentos verás el distintivo **Verde (v2 - Canary)**.

---

## 💾 Fase 7: Verificación del Almacenamiento Efímero (Base de Datos Local JSON)

### 7.1 ¿Qué ocurre con la base de datos al eliminar un Pod?

En este sistema, la base de datos es un archivo JSON local (`data/products.json`) alojado en la capa de almacenamiento efímera del contenedor (**OverlayFS**).

### 7.2 Pasos para verificar la pérdida de persistencia:

1. **Crear un nuevo producto mediante la API:**
   ```powershell
   # En PowerShell
   $body = @{ name="Producto Efimero Test"; sku="EFF-001"; stock=5; price=10.00 } | ConvertTo-Json
   Invoke-RestMethod -Uri "http://localhost:3000/api/products" -Method POST -ContentType "application/json" -Body $body
   ```

2. **Verificar que el producto fue registrado:**
   ```powershell
   Invoke-RestMethod -Uri "http://localhost:3000/api/products"
   ```

3. **Eliminar el Pod activo para forzar su reinicio por Kubernetes:**
   ```powershell
   $POD_NAME = (kubectl get pods -l track=stable -o jsonpath='{.items[0].metadata.name}')
   kubectl delete pod $POD_NAME
   ```

4. **Verificar que el nuevo Pod ha vuelto al estado Semilla (Seed):**
   Al consultar nuevamente los productos, el ítem `Producto Efimero Test` **ha desaparecido** y la base de datos ha vuelto a sus valores iniciales.

> 💡 **Recomendación para Producción:** Para lograr persistencia real entre reinicios se debe usar un **PersistentVolumeClaim (PVC)** montado en `/app/data` o conectar la aplicación a una base de datos externa (PostgreSQL, MongoDB, etc.).

---

## 🛡️ Fase 8: Auditoría del Componente Adicional 2 — Escaneo de Seguridad DevSecOps con Trivy en CI/CD

El workflow `.github/workflows/ci-cd.yml` ejecuta automáticamente Trivy antes de autorizar la publicación en GitHub Container Registry (GHCR).

```yaml
- name: Escaneo de Seguridad con Trivy
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: 'inventario-app:${{ github.sha }}'
    format: 'table'
    exit-code: '1'          # Detiene el pipeline si hay fallos
    ignore-unfixed: true
    vuln-type: 'os,library'
    severity: 'CRITICAL'    # Bloquea exclusivamente ante vulnerabilidades Críticas
```

### Cómo verificar en GitHub:
1. Sube tus cambios al repositorio con `git push origin main`.
2. Dirígete a la pestaña **Actions** en GitHub.
3. Selecciona la ejecución del workflow y revisa el paso **Escaneo de Seguridad con Trivy**.

---

## ⚖️ Fase 9: Justificación Técnica — Estrategia Canary vs. Blue-Green

| Criterio | Estrategia Canary (Seleccionada) | Estrategia Blue-Green |
| :--- | :--- | :--- |
| **Uso de Recursos** | **Eficiente (Bajo)**: Solo requiere adicionar réplicas progresivas (ej. 4 v1 + 1 v2 = 5 pods totales, +25% de recursos). | **Costoso (Alto)**: Requiere duplicar la infraestructura al 100% (4 v1 + 4 v2 = 8 pods totales, +100% de recursos). |
| **Radio de Impacto (Blast Radius)** | **Limitado**: Si v2 presenta un error no detectado, solo afecta al **20%** de las peticiones. | **Masivo**: Al conmutar el router, el **100%** de los usuarios reciben la nueva versión inmediatamente. |
| **Validación en Producción** | **Progresiva y Real**: Permite monitorear métricas, consumo de memoria y errores HTTP 5xx con usuarios reales en baja escala. | **Todo o Nada**: Las pruebas se realizan internamente antes del switch, sin tráfico real progresivo. |
| **Rollback** | **Inmediato**: Basta con escalar a 0 el deployment Canary (`kubectl scale deployment inventario-app-canary --replicas=0`). | **Inmediato**: Cambiar la ruta del Service de vuelta al entorno Blue. |

---

## 📊 Tabla Comparativa de Comandos: PowerShell vs. Bash

Para evitar errores de sintaxis según la terminal que utilices:

| Operación | PowerShell (Windows) 🟢 | Bash (Linux / Git Bash) 🐧 |
| :--- | :--- | :--- |
| **Guardar Pod en Variable** | `$POD_NAME = (kubectl get pods -l track=stable -o jsonpath='{.items[0].metadata.name}')` | `POD_NAME=$(kubectl get pods -l track=stable -o jsonpath="{.items[0].metadata.name}")` |
| **Imprimir Variable** | `Write-Host $POD_NAME` | `echo $POD_NAME` |
| **Filtrar Entorno (Grep)** | `kubectl exec $POD_NAME -- env \| Select-String "API_KEY"` | `kubectl exec $POD_NAME -- env \| grep API_KEY` |
| **Decodificar Base64** | `[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encoded))` | `echo $encoded \| base64 --decode` |
| **Petición GET HTTP** | `Invoke-RestMethod -Uri "http://localhost:3000/version"` | `curl -s http://localhost:3000/version` |
| **Multi-línea en Terminal** | Usar acento grave (``` ` ```) al final de línea | Usar barra invertida (`\`) al final de línea |
