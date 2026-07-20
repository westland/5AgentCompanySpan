---
title: 5AgentCompany
emoji: 🧖
colorFrom: pink
colorTo: purple
sdk: docker
pinned: false
app_port: 7860
---

# DermaArtIA — Empresa de IA Multi-Agente Basada en Google Gemini

**Una empresa de IA autónoma de cinco agentes implementable para análisis de marketing, investigación y automatización en el sector de la estética.**  
*Copyright © 2026 J. Christopher Westland, todos los derechos reservados*

[![Release](https://img.shields.io/badge/release-v1.89-brightgreen)](https://github.com/westland/DermaArtIA/releases/tag/v1.89)
[![OpenClaw](https://img.shields.io/badge/OpenClaw-2026.4.26-blue)](https://openclaw.dev)
[![Platform](https://img.shields.io/badge/platform-Ubuntu%2024.04-orange)](https://ubuntu.com)
[![Interface](https://img.shields.io/badge/interface-FastAPI_Web_Portal-purple)](https://fastapi.tiangolo.com)

> **[El Manifiesto de DermaArtIA](MANIFESTO.md)** — La filosofía de la app DermaArt IA: Personalidad, Scripts de Acción y Tabúes; Realismo Estratégico de Drucker; y la Agencia de Costo Marginal Cero ejecutándose completamente en Google Gemini.

---

## ¿Qué es DermaArtIA?

DermaArtIA es una empresa de IA multi-agente que funciona 24/7 en un servidor seguro en la nube, diseñada para manejar operaciones de marketing de MedSpa y estética. Interactúas con los agentes a través de un **Portal Web seguro y a medida** que incluye:
1. **Centro de Comando Interactivo**: Chatea con Henry (Jefe de Personal) usando texto o **dictado por voz** a través del SpeechRecognition nativo del navegador.
2. **Barra Lateral Plegable Móvil**: Diseño móvil/tableta totalmente responsivo con un menú desplegable y paneles de control apilados.
3. **Centro de Trabajos Automatizados**: Programador en vivo que muestra el historial de ejecución cron, los estados de la última ejecución (ej. `ok`, `error`) y un botón de "Ejecutar Ahora" que se extrae directamente de la base de datos SQLite activa.
4. **Panel de Control de Integraciones y Autenticación**: Almacena de forma segura paquetes de credenciales para plataformas externas (WordPress, Instagram, Facebook, TikTok, Perfil de Negocio de Google) en la base de datos SQLite del backend, y configura listas de uso compartido detalladas. Las credenciales se sincronizan automáticamente con los espacios de trabajo de los agentes permitidos como archivos cifrados/con permisos, y se revocan/borran automáticamente cuando se desactiva el acceso.
5. **Visor de Informes y Sesiones Informativas**: Un lector limpio de Markdown donde Scout, Writer y Watcher envían memorandos automatizados e informes de investigación.
6. **Cargas Multimedia Interactivas y Gestor de Archivos del Espacio de Trabajo**: Sube imágenes o videos usando una zona de arrastrar y soltar o archivos adjuntos de chat para poner los activos directamente en el espacio de trabajo del agente.
7. **Publicación Social y Hub de IA Generativa**: Aprovecha Google Imagen y Veo para generar y modificar fotos y videos, y ejecuta scripts de Coder para actualizar páginas de WordPress y publicar posts en Instagram, Facebook y TikTok.

Los cinco agentes son:

| Agente | Modelo | Rol |
|-------|-------|------|
| **Henry** | Gemini 2.5 Flash | Jefe de Personal — orquesta el equipo, delega tareas |
| **Coder** | Gemini 2.5 Flash | Ingeniero de Software — escribe código, compila el estilo de la página de inicio |
| **Scout** | Gemini 2.5 Flash | Analista de Investigación — escaneos de precios de la competencia e investigación de mercado |
| **Writer** | Gemini 2.5 Flash | Creador de Contenido — redacción publicitaria, descripciones de distinción y memorandos |
| **Watcher** | Gemini 2.5 Flash | Monitor del Sistema — comprobaciones de salud, limpieza y registros de estado |

### Cómo Piensan y Operan los Agentes: Espacios de Trabajo de OpenClaw

En el marco de OpenClaw, los agentes no se ejecutan con instrucciones de código estáticas preprogramadas. En cambio, ellos **"se leen a sí mismos para existir"** al inicio de cada sesión. El espacio de trabajo de cada agente (ubicado en `deploy/configs/workspace-[nombre-del-agente]/`) contiene un conjunto de archivos Markdown sin formato (`.md`) que se inyectan dinámicamente en el prompt del sistema.

Aquí hay un resumen de los archivos del espacio de trabajo y las habilidades modulares:

| Archivo del Espacio de Trabajo | Función | Detalles y Estructura |
| :--- | :--- | :--- |
| **SOUL.md** | Identidad Central | Personalidad interna, principios, tono de comunicación y límites de comportamiento (formato de 6 secciones: *Apertura, Verdades Centrales, Límites, Vibra, Continuidad, Cierre*). |
| **IDENTITY.md** | Presentación | Detalles de presentación externa (nombre, emoji, descripción del avatar). |
| **AGENTS.md** | Estrategia | Manual de operaciones que incluye acciones de inicio, gestión de la memoria y reglas de uso de herramientas. |
| **USER.md** | Contexto | Información del perfil, preferencias y detalles sobre el operador humano. |
| **TOOLS.md** | Contexto | Detalles del entorno funcional (hosts de API, puertos, integraciones). |
| **MEMORY.md** | Contexto | Hechos seleccionados y contexto guardado a lo largo de las sesiones. |
| **HEARTBEAT.md** | Ejecución | Directrices de activación para ejecuciones programadas/proactivas. |
| **STYLE.md** | Salida | Reglas de formato y preferencias de visualización. |
| **SKILL.md** | Capacidades | Se encuentra dentro de los complementos de habilidades de código abierto modulares y descargables (`workspace-[nombre-del-agente]/skills/`). Contiene la definición y el esquema para herramientas específicas. |

---

## Arquitectura del Sistema

```
                      ┌──────────────────────────────┐
                      │ Navegador de Sumar Kasik     │ (Móvil o Escritorio)
                      └──────────────┬───────────────┘
                                     │ HTTPS (Puerto 443 / Puerto 80)
                                     ▼
                      ┌──────────────────────────────┐
                      │ Proxy Inverso Nginx          │ (Autenticación Básica + SSL Autofirmado)
                      └──────┬────────────────┬──────┘
             Archivos Estáticos│                │ Proxy API
                                     ▼                ▼
       ┌──────────────────────────┐    ┌──────────────────────────┐
       │ Panel Frontal            │    │ Portal Web FastAPI       │
       │ (JS Responsivo Móvil)    │    │ (Puerto 8000)            │
       └──────────────────────────┘    └──────┬───────────┬───────┘
                                              │           │ SQLite
                                              │ API REST  ▼
                                              │ (18789) ┌─────────────────┐
                                              │         │ Base de Datos   │
                                              ▼         │ (dermaart.db)   │
                                       ┌────────────┐   └─────────────────┘
                                       │ Gateway    │
                                       │ OpenClaw   │
                                       └──────┬─────┘
                                              │
                                              ▼
                                   ┌────────────────────┐
                                   │ API Google Gemini  │ (Gemini 2.5 Flash)
                                   └────────────────────┘
```

---

## Estructura del Repositorio

```
DermaArtIA/
│
├── MANIFESTO.md                     ← filosofía
├── README.md                        ← Este documento
│
├── portal/                          ← Backend del Portal FastAPI y Frontend estático
│   ├── main.py                      ← Servidor FastAPI (puerto 8000)
│   └── static/                      ← Archivos frontend HTML/CSS/JS
│       ├── index.html               ← Plantilla responsiva móvil
│       ├── styles.css               ← Diseño de layout y micro-animaciones
│       └── app.js                   ← Reconocimiento de voz y manejo de eventos
│
└── deploy/                          ← Implementación del servidor y configuraciones
    ├── README.md                    ← Guía de inicio rápido
    ├── deploy-openclaw.sh           ← Script principal de instalación (con parche JIT)
    ├── dermaart-portal.service      ← Unidad de servicio Systemd para el portal
    ├── dermaart-portal-nginx.conf   ← Plantilla del bloque de servidor Nginx
    ├── openclaw.service             ← Unidad de servicio Systemd para OpenClaw
    └── configs/
        ├── openclaw.json            ← Configuración del Gateway (ajustes de Gemini)
        ├── jobs.json                ← Trabajos cron activos (resumen-noticias, chequeo-salud)
        └── workspace-henry/         ← Archivos de personalidad de Henry (SOUL, MEMORY)
```

---

## Verificación y Solución de Problemas

```bash
# Comprobar el estado del servicio
systemctl status openclaw
systemctl status dermaart-portal
systemctl status nginx

# Ver registros en vivo del gateway
journalctl -u openclaw -f

# Ver registros en vivo del portal
journalctl -u dermaart-portal -f

# Comprobar trabajos cron activos y próximos tiempos de ejecución
curl -s http://127.0.0.1:8000/api/cron
```

---

*Copyright © 2026 J. Christopher Westland, todos los derechos reservados*
