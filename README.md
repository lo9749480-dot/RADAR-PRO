# RADAR PRO Backend v2

Backend FastAPI + SQLite para guardar reportes que envíen agentes autorizados.

## Importante
Este backend **no inicia sesión en Roblox, no crea bots, no inspecciona partidas ni descubre huevos por sí solo**. Solo almacena datos que un agente autorizado envíe. La API pública de servidores de Roblox no revela los huevos dentro de cada partida.

No compartas cookies, contraseñas ni tokens de Roblox. `RADAR_API_TOKEN` es un secreto del backend: configúralo en el panel del hosting y no lo subas a GitHub.

## Archivos
- `app.py`: API.
- `requirements.txt`: dependencias.
- `render.yaml`: configuración inicial para Render.
- `README.md`: instrucciones.

## Despliegue en Render
1. Sube estos archivos a tu repositorio privado de GitHub.
2. En Render crea un **New Web Service** y conecta el repositorio.
3. Render puede detectar `render.yaml`. Si configuras el servicio manualmente:
   - Build command: `pip install -r requirements.txt`
   - Start command: `uvicorn app:app --host 0.0.0.0 --port $PORT`
4. Añade la variable secreta `RADAR_API_TOKEN` en Environment. Usa un valor largo y aleatorio; nunca lo publiques.
5. Cuando termine, abre `https://TU-SERVICIO.onrender.com/health` y luego `/docs`.

## Rutas
- `GET /` información de la API
- `GET /health` estado
- `POST /api/agents/register` registrar agente (requiere `X-Radar-Token`)
- `POST /api/agents/heartbeat` latido (requiere token)
- `GET /api/agents` listar agentes (requiere token)
- `POST /api/reports` guardar reporte (requiere token)
- `GET /api/reports?min_multiplier=3&limit=50` consultar reportes
- `GET /api/top?limit=10&min_multiplier=3` TOP por tamaño

La API usa `X-Radar-Token` en las rutas privadas. Para producción con muchos agentes, sustituye SQLite por una base de datos administrada y añade límites de uso, moderación y verificación de reportes.
