CREATE OR REPLACE FUNCTION gerar_html()
RETURNS TEXT AS $$
DECLARE
    html TEXT := '
    <div style="font-family: Arial, sans-serif; color: #1f2937; line-height: 1.5;">
        <h1 style="color: #0f172a;">Jornal UTC - Edicao da Manha</h1>
        <p>Boletim preparado para a apresentacao da manha no jornal local da Gazeta AL, com destaques de cinco UTCs do mundo, panorama climatico do dia e material de apoio visual para a equipe.</p>
        <p>O objetivo deste resumo e apoiar a fala dos integrantes com contexto geografico, curiosidades e referencias de imagem e video sobre cada regiao.</p>
        <hr style="border: none; border-top: 1px solid #d1d5db; margin: 20px 0;">
    ';
    linha RECORD;
BEGIN
    FOR linha IN
        SELECT 
            u.utc, u.pais, u.cidade,
            p.descricao AS clima, p.temperatura,
            i.descricao AS info, i.curiosidade, i.imagem_url, i.video_url
        FROM utc_news.utc u
        JOIN (
            SELECT DISTINCT ON (utc_id)
                utc_id, descricao, temperatura, data_previsao, id
            FROM utc_news.previsao_tempo
            WHERE data_previsao = CURRENT_DATE
            ORDER BY utc_id, data_previsao DESC, id DESC
        ) p ON u.id = p.utc_id
        JOIN utc_news.info_utc i ON u.id = i.utc_id
        ORDER BY u.utc
    LOOP

        html := html ||
        '<h2 style="margin-top: 0; color: #0f172a;">' || linha.utc || ' - ' || linha.cidade || '</h2>' ||
        '<p><b>Regiao:</b> ' || linha.pais || '</p>' ||
        '<p><b>Destaque para a apresentacao:</b> ' || linha.info || '</p>' ||
        '<p><b>Curiosidade:</b> ' || linha.curiosidade || '</p>' ||
        '<p><b>Previsao do tempo de hoje:</b> ' || linha.clima || 
        ' (' || linha.temperatura || ' C)</p>' ||
        '<p><b>Imagem da regiao:</b></p>' ||
        '<img src="' || linha.imagem_url || '" alt="Imagem de ' || linha.cidade || '" style="display: block; width: 100%; max-width: 640px; margin: 12px 0;">' ||
        '<p><b>Video de apoio:</b> <a href="' || linha.video_url || '">assistir video</a></p>' ||
        '<hr style="border: none; border-top: 1px solid #d1d5db; margin: 20px 0;">';

    END LOOP;

    html := html || '</div>';

    RETURN html;
END;
$$ LANGUAGE plpgsql;
