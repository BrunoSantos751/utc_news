CREATE OR REPLACE FUNCTION log_previsao()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO utc_news.logs (mensagem)
    VALUES ('Nova previsão para UTC ID: ' || NEW.utc_id);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_log_previsao ON utc_news.previsao_tempo;

CREATE TRIGGER trigger_log_previsao
AFTER INSERT ON utc_news.previsao_tempo
FOR EACH ROW
EXECUTE FUNCTION log_previsao();
