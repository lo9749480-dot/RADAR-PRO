import os
import sqlite3
import time
import secrets
from typing import Optional

from fastapi import FastAPI, Header, HTTPException, Query
from pydantic import BaseModel, Field

APP_NAME = "RADAR PRO API"
DB_PATH = os.getenv("DATABASE_PATH", "radar_pro.sqlite3")
API_TOKEN = os.getenv("RADAR_API_TOKEN")

app = FastAPI(title=APP_NAME, version="2.0.0",
              description="Backend de reportes para GLOBAL EGG FINDER PRO. No se conecta a Roblox.")

def db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    with db() as conn:
        conn.execute("""
        CREATE TABLE IF NOT EXISTS agents (
            agent_id TEXT PRIMARY KEY,
            label TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'online',
            last_seen INTEGER NOT NULL
        )""")
        conn.execute("""
        CREATE TABLE IF NOT EXISTS reports (
            report_id INTEGER PRIMARY KEY AUTOINCREMENT,
            agent_id TEXT NOT NULL,
            server_id TEXT NOT NULL,
            egg_name TEXT NOT NULL,
            size REAL,
            multiplier REAL NOT NULL,
            generation REAL,
            rarity TEXT,
            created_at INTEGER NOT NULL
        )""")
        conn.execute("CREATE INDEX IF NOT EXISTS idx_reports_created ON reports(created_at DESC)")
        conn.execute("CREATE INDEX IF NOT EXISTS idx_reports_multiplier ON reports(multiplier DESC)")

init_db()

def require_token(x_radar_token: Optional[str]):
    if not API_TOKEN:
        raise HTTPException(status_code=503, detail="Falta configurar RADAR_API_TOKEN en el hosting.")
    if not x_radar_token or not secrets.compare_digest(x_radar_token, API_TOKEN):
        raise HTTPException(status_code=401, detail="Token inválido o faltante.")

class AgentIn(BaseModel):
    label: str = Field(min_length=1, max_length=60)

class HeartbeatIn(BaseModel):
    agent_id: str = Field(min_length=1, max_length=80)

class ReportIn(BaseModel):
    agent_id: str = Field(min_length=1, max_length=80)
    server_id: str = Field(min_length=1, max_length=120)
    egg_name: str = Field(min_length=1, max_length=100)
    size: Optional[float] = Field(default=None, ge=0)
    multiplier: float = Field(ge=0, le=100000)
    generation: Optional[float] = Field(default=None, ge=0)
    rarity: Optional[str] = Field(default=None, max_length=60)

@app.get("/")
def root():
    return {"name": APP_NAME, "version": "2.0.0", "docs": "/docs",
            "note": "Solo almacena reportes enviados por agentes autorizados."}

@app.get("/health")
def health():
    return {"ok": True, "timestamp": int(time.time())}

@app.post("/api/agents/register")
def register_agent(data: AgentIn, x_radar_token: Optional[str] = Header(default=None)):
    require_token(x_radar_token)
    agent_id = secrets.token_urlsafe(18)
    now = int(time.time())
    with db() as conn:
        conn.execute("INSERT INTO agents(agent_id,label,status,last_seen) VALUES(?,?,?,?)",
                     (agent_id, data.label, "online", now))
    return {"ok": True, "agent_id": agent_id, "message": "Agente registrado."}

@app.post("/api/agents/heartbeat")
def heartbeat(data: HeartbeatIn, x_radar_token: Optional[str] = Header(default=None)):
    require_token(x_radar_token)
    now = int(time.time())
    with db() as conn:
        cur = conn.execute("UPDATE agents SET status='online', last_seen=? WHERE agent_id=?",
                           (now, data.agent_id))
        if cur.rowcount == 0:
            raise HTTPException(status_code=404, detail="Agente no encontrado.")
    return {"ok": True, "last_seen": now}

@app.get("/api/agents")
def list_agents(x_radar_token: Optional[str] = Header(default=None)):
    require_token(x_radar_token)
    now = int(time.time())
    with db() as conn:
        rows = conn.execute(
            "SELECT agent_id,label,status,last_seen FROM agents ORDER BY last_seen DESC"
        ).fetchall()
    return {"agents": [dict(r) | {"online": now-r["last_seen"] < 120} for r in rows]}

@app.post("/api/reports")
def create_report(data: ReportIn, x_radar_token: Optional[str] = Header(default=None)):
    require_token(x_radar_token)
    now = int(time.time())
    with db() as conn:
        exists = conn.execute("SELECT 1 FROM agents WHERE agent_id=?", (data.agent_id,)).fetchone()
        if not exists:
            raise HTTPException(status_code=404, detail="Registra el agente primero.")
        cur = conn.execute("""
            INSERT INTO reports(agent_id,server_id,egg_name,size,multiplier,generation,rarity,created_at)
            VALUES(?,?,?,?,?,?,?,?)
        """, (data.agent_id, data.server_id, data.egg_name, data.size,
              data.multiplier, data.generation, data.rarity, now))
        report_id = cur.lastrowid
    return {"ok": True, "report_id": report_id, "created_at": now}

@app.get("/api/reports")
def get_reports(min_multiplier: float = Query(default=3, ge=0),
                limit: int = Query(default=50, ge=1, le=200)):
    with db() as conn:
        rows = conn.execute("""
            SELECT report_id,server_id,egg_name,size,multiplier,generation,rarity,created_at
            FROM reports WHERE multiplier>=? ORDER BY created_at DESC LIMIT ?
        """, (min_multiplier, limit)).fetchall()
    return {"reports": [dict(r) for r in rows]}

@app.get("/api/top")
def get_top(limit: int = Query(default=10, ge=1, le=100),
            min_multiplier: float = Query(default=3, ge=0)):
    with db() as conn:
        rows = conn.execute("""
            SELECT report_id,server_id,egg_name,size,multiplier,generation,rarity,created_at
            FROM reports WHERE multiplier>=? AND size IS NOT NULL
            ORDER BY size DESC LIMIT ?
        """, (min_multiplier, limit)).fetchall()
    return {"top": [dict(r) for r in rows]}
