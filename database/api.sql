CREATE OR REPLACE FUNCTION atualizar_clima()
RETURNS VOID AS $$
import urllib.request
import urllib.parse
import json

cidades = plpy.execute("SELECT id, cidade FROM utc_news.utc")

for cidade in cidades:
    cidade_enc = urllib.parse.quote(cidade['cidade'])
    url = f"http://pt.wttr.in/{cidade_enc}?format=j1"

    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=10) as resp:
            dados = json.loads(resp.read().decode('utf-8'))

        clima = dados['current_condition'][0]['lang_pt'][0]['value']
        temp  = int(dados['current_condition'][0]['temp_C'])

        plan = plpy.prepare(
            """
            INSERT INTO utc_news.previsao_tempo (utc_id, descricao, temperatura, data_previsao)
            VALUES ($1, $2, $3, CURRENT_DATE)
            ON CONFLICT (utc_id, data_previsao)
            DO UPDATE SET
                descricao = EXCLUDED.descricao,
                temperatura = EXCLUDED.temperatura
            """,
            ["int", "text", "int"]
        )
        plpy.execute(plan, [cidade['id'], clima, temp])

    except Exception as e:
        msg_erro = f"Erro ao buscar clima para {cidade['cidade']}: {e}"
        plpy.warning(msg_erro)
        plan_log = plpy.prepare("INSERT INTO utc_news.logs (mensagem) VALUES ($1)", ["text"])
        plpy.execute(plan_log, [msg_erro])

$$ LANGUAGE plpython3u;
