CREATE OR REPLACE FUNCTION log_previsao()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO utc_news.logs (mensagem)
    VALUES ('Nova previsao para UTC ID: ' || NEW.utc_id);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_log_previsao ON utc_news.previsao_tempo;

CREATE TRIGGER trigger_log_previsao
AFTER INSERT ON utc_news.previsao_tempo
FOR EACH ROW
EXECUTE FUNCTION log_previsao();

CREATE OR REPLACE FUNCTION notificar_envio_email()
RETURNS TRIGGER AS $$
DECLARE
    payload JSONB;
    utc_id_ref INT;
    previsao_id_ref INT;
    data_ref DATE;
BEGIN
    utc_id_ref := COALESCE(NEW.utc_id, OLD.utc_id);
    previsao_id_ref := COALESCE(NEW.id, OLD.id);
    data_ref := COALESCE(NEW.data_previsao, OLD.data_previsao);

    payload := jsonb_build_object(
        'operacao', TG_OP,
        'tabela', TG_TABLE_NAME,
        'utc_id', utc_id_ref,
        'previsao_id', previsao_id_ref,
        'data_previsao', data_ref,
        'registrado_em', CURRENT_TIMESTAMP
    );

    PERFORM pg_notify('utc_news_email', payload::text);

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_notificar_envio_email ON utc_news.previsao_tempo;

CREATE TRIGGER trigger_notificar_envio_email
AFTER INSERT OR UPDATE OR DELETE ON utc_news.previsao_tempo
FOR EACH ROW
EXECUTE FUNCTION notificar_envio_email();
