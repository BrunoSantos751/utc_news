# 🌍 UTC News System

## 📌 Descrição

Sistema desenvolvido em PostgreSQL para geração automatizada de relatórios sobre fusos horários (UTCs), incluindo previsão do tempo e informações geográficas.

## ⚙️ Tecnologias

* PostgreSQL
* PL/pgSQL
* PL/Python3u (`plpython3u`)
* pgAgent (agendamento de jobs)
* API OpenWeatherMap (consumida via `urllib` no PL/Python3)
* smtplib (envio de email via PL/Python3)

## 🚀 Funcionalidades

* Consumo de API de clima diretamente no banco via PL/Python3
* Triggers para geração de logs
* Jobs automáticos agendados com pgAgent
* Geração de relatórios em HTML
* Envio automático de emails via SMTP

## 🧠 Arquitetura

```
API OpenWeather → plpython3u (atualizar_clima)
                       ↓
               PostgreSQL / previsao_tempo
                       ↓
                Trigger → Logs
                       ↓
          pgAgent (07h) ──→ atualizar_clima()
          pgAgent (08h) ──→ enviar_emails()  → SMTP → Membros
```

## ▶️ Como executar

### Pré-requisitos

1. PostgreSQL com `plpython3u` habilitado (requer Python 3 linkado ao pg)
2. **pgAgent** instalado e o serviço `pgagent` em execução no servidor
   * No pgAdmin: *Tools → pgAgent Jobs* ou instale via pacote do sistema
3. Credenciais SMTP configuradas em `email.sql` e chave OpenWeather em `api.sql`

### Ordem de execução dos scripts

```
01  schema.sql
02  extensions.sql
03  tables.sql
04  data.sql
05  triggers.sql
06  api.sql
07  email.sql
08  jobs.sql        ← requer pgAgent instalado
```

## 👥 Integrantes

* João Honorio Barbosa Vieira de Assis
* Bruno Santos Moraes

## 📹 Vídeo

(Link do YouTube aqui)
