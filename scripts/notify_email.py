import json
import os
import select
import smtplib
import time
from pathlib import Path
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

import psycopg2
import psycopg2.extras
from dotenv import load_dotenv
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT


load_dotenv(Path(__file__).resolve().parent.parent / ".env", override=True)


CHANNEL = os.getenv("UTC_NEWS_NOTIFY_CHANNEL", "utc_news_email")
QUIET_SECONDS = float(os.getenv("UTC_NEWS_NOTIFY_DEBOUNCE_SECONDS", "2.0"))

DB_DSN = os.getenv(
    "UTC_NEWS_DSN",
    "dbname=utc_news user=postgres password=123 host=localhost port=5432",
)

SMTP_HOST = os.getenv("UTC_NEWS_SMTP_HOST", "smtp.gmail.com")
SMTP_PORT = int(os.getenv("UTC_NEWS_SMTP_PORT", "587"))
SMTP_USER = os.getenv("UTC_NEWS_SMTP_USER", "")
SMTP_PASS = os.getenv("UTC_NEWS_SMTP_PASS", "")
SMTP_FROM = os.getenv("UTC_NEWS_SMTP_FROM", SMTP_USER)
EMAIL_SUBJECT = os.getenv("UTC_NEWS_EMAIL_SUBJECT", "Jornal UTC - Manha")


def write_log(conn, message):
    with conn.cursor() as cur:
        cur.execute("INSERT INTO utc_news.logs (mensagem) VALUES (%s)", (message,))
    conn.commit()


def fetch_html(conn):
    with conn.cursor() as cur:
        cur.execute("SELECT utc_news.gerar_html() AS html")
        row = cur.fetchone()
        return row[0]


def fetch_members(conn):
    with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
        cur.execute("SELECT nome, email FROM utc_news.membros ORDER BY nome")
        return cur.fetchall()


def connect_db(dsn):
    try:
        return psycopg2.connect(dsn)
    except UnicodeDecodeError as exc:
        raise RuntimeError(
            "Falha ao abrir a conexao PostgreSQL por problema de codificacao. "
            "Verifique o valor de UTC_NEWS_DSN e a senha do banco."
        ) from exc


def send_emails(db_conn):
    html_body = fetch_html(db_conn)
    membros = fetch_members(db_conn)

    if not membros:
        raise RuntimeError("Nenhum membro cadastrado na tabela utc_news.membros")

    if not SMTP_USER or not SMTP_PASS:
        raise RuntimeError("Credenciais SMTP nao configuradas nas variaveis de ambiente")

    enviados = 0

    with smtplib.SMTP(SMTP_HOST, SMTP_PORT, timeout=30) as server:
        server.ehlo()
        server.starttls()
        server.ehlo()
        server.login(SMTP_USER, SMTP_PASS)

        for membro in membros:
            msg = MIMEMultipart("alternative")
            msg["Subject"] = EMAIL_SUBJECT
            msg["From"] = SMTP_FROM or SMTP_USER
            msg["To"] = membro["email"]
            msg.attach(MIMEText(html_body, "html", "utf-8"))

            server.sendmail(SMTP_FROM or SMTP_USER, [membro["email"]], msg.as_string())
            enviados += 1
            print(f"Email enviado para {membro['nome']} <{membro['email']}>")

    write_log(
        db_conn,
        f"Envio de email concluido com sucesso. Total de destinatarios: {enviados}",
    )


def main():
    db_conn = connect_db(DB_DSN)
    db_conn.set_session(autocommit=True)

    listener = connect_db(DB_DSN)
    listener.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)

    pending_payloads = []
    last_event_at = None

    with listener.cursor() as cur:
        cur.execute(f"LISTEN {CHANNEL}")

    print(f"Listener ativo no canal {CHANNEL}. Aguardando notificacoes...")

    try:
        while True:
            has_data = select.select([listener], [], [], 0.5)[0]

            if has_data:
                listener.poll()
                while listener.notifies:
                    notify = listener.notifies.pop(0)
                    payload = notify.payload
                    try:
                        parsed = json.loads(payload) if payload else {}
                    except json.JSONDecodeError:
                        parsed = {"raw": payload}

                    pending_payloads.append(parsed)
                    last_event_at = time.monotonic()
                    print(f"Notificacao recebida: {parsed}")

            if pending_payloads and last_event_at is not None:
                elapsed = time.monotonic() - last_event_at
                if elapsed >= QUIET_SECONDS:
                    try:
                        send_emails(db_conn)
                    except Exception as exc:
                        error_message = f"Falha ao enviar emails: {exc}"
                        print(error_message)
                        write_log(db_conn, error_message)
                    else:
                        print(
                            f"Processo de email finalizado apos {len(pending_payloads)} notificacoes."
                        )
                    finally:
                        pending_payloads.clear()
                        last_event_at = None

    except KeyboardInterrupt:
        print("Listener encerrado pelo usuario.")
    finally:
        listener.close()
        db_conn.close()


if __name__ == "__main__":
    main()
