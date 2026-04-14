# UTC News System

## Descricao

Sistema em PostgreSQL para gerar automaticamente um boletim sobre fusos horarios (UTCs), incluindo previsao do tempo, curiosidades e materiais de apoio.

## Tecnologias

* PostgreSQL
* PL/pgSQL
* PL/Python3u
* pgAgent
* Python 3
* psycopg2
* smtplib

## Funcionalidades

* Coleta automatica de clima diretamente no banco
* Trigger com `NOTIFY` para disparar o envio de email
* Listener Python recebendo notificacoes do PostgreSQL
* Geracao de relatorio HTML
* Logs de execucao e falhas

## Arquitetura

```
API de clima -> plpython3u (atualizar_clima)
                     |
                     v
              previsao_tempo
                     |
                     v
          Trigger -> NOTIFY (utc_news_email)
                     |
                     v
         Python LISTEN -> SMTP -> Membros

pgAgent (07h) -> atualizar_clima()
```

## Como executar

### Pre-requisitos

1. PostgreSQL com `plpython3u` habilitado
2. pgAgent instalado e em execucao
3. Python 3 com dependencias instaladas via `pip install -r requirements.txt`
4. Variaveis de ambiente configuradas para o listener:
   * `UTC_NEWS_DSN`
   * `UTC_NEWS_SMTP_HOST`
   * `UTC_NEWS_SMTP_PORT`
   * `UTC_NEWS_SMTP_USER`
   * `UTC_NEWS_SMTP_PASS`
   * `UTC_NEWS_SMTP_FROM`

### Ordem dos scripts SQL

```
01 schema.sql
02 extensions.sql
03 tables.sql
04 data.sql
05 triggers.sql
06 api.sql
07 email.sql
08 jobs.sql
```

### Execucao

1. Rode os scripts SQL na ordem acima.
2. Inicie o listener Python:

```bash
python scripts/notify_email.py
```

3. Deixe o listener em execucao.
4. O pgAgent executa `atualizar_clima()` no horario programado.
5. As triggers em `previsao_tempo` disparam `NOTIFY`.
6. O listener Python recebe o evento e envia o email.

## Integrantes

* Joao Honorio Barbosa Vieira de Assis
* Bruno Santos Moraes

## Video

(Link do YouTube aqui)
