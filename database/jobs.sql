-- =============================================================================
-- jobs.sql  –  Agendamento via pgAgent
-- =============================================================================
-- pgAgent armazena seus metadados no schema "pgagent" (criado pelo instalador).
-- Execute este script como superusuário com o pgAgent já instalado no servidor.
-- =============================================================================

-- ─── Job 1: Atualizar clima (todo dia às 07:00) ────────────────────────────

DO $$
DECLARE
    v_job_id  INT;
    v_step_id INT;
    v_sch_id  INT;
BEGIN

    -- Deleta job anterior se existir (idempotente)
    DELETE FROM pgagent.pga_job WHERE jobname = 'atualizar_clima_diario';

    -- Cria o job
    INSERT INTO pgagent.pga_job (
        jobjclid, jobname, jobdesc, jobhostagent, jobenabled
    ) VALUES (
        1,
        'atualizar_clima_diario',
        'Busca previsão do tempo via API OpenWeather e grava em previsao_tempo.',
        '',
        TRUE
    ) RETURNING jobid INTO v_job_id;

    -- Cria o step (SQL a executar)
    INSERT INTO pgagent.pga_jobstep (
        jstjobid, jstname, jstenabled, jstkind,
        jstcode, jstconnstr, jstdbname, jstonerror
    ) VALUES (
        v_job_id,
        'step_atualizar_clima',
        TRUE,
        's',                               -- 's' = SQL
        'SELECT utc_news.atualizar_clima();',
        '',
        'utc_news',                        -- executa o job no banco onde o schema utc_news existe
        'f'                                -- 'f' = fail on error
    ) RETURNING jstid INTO v_step_id;

    -- Cria o schedule: todo dia às 07:00
    INSERT INTO pgagent.pga_schedule (
        jscjobid, jscname, jscenabled,
        jscstart,
        jscminutes, jschours, jscweekdays, jscmonthdays, jscmonths
    ) VALUES (
        v_job_id,
        'schedule_07h',
        TRUE,
        now(),
        -- minutos  0-59  (array bool 60 elementos – TRUE na posição 0)
        ARRAY(SELECT m = 0 FROM generate_series(0,59) m),
        -- horas    0-23  (TRUE na posição 7)
        ARRAY(SELECT h = 7 FROM generate_series(0,23) h),
        -- dias da semana 0-6 (todos)
        '{true,true,true,true,true,true,true}',
        -- dias do mês 1-32 (pgagent exige array de 32 elementos para monthdays)
        ARRAY(SELECT TRUE FROM generate_series(1,32)),
        -- meses 1-12 (todos)
        '{true,true,true,true,true,true,true,true,true,true,true,true}'
    ) RETURNING jscid INTO v_sch_id;

END;
$$;


-- ─── Job 2: Envio de emails (todo dia às 08:00) ───────────────────────────

DO $$
DECLARE
    v_job_id  INT;
    v_step_id INT;
    v_sch_id  INT;
BEGIN

    DELETE FROM pgagent.pga_job WHERE jobname = 'envio_email_diario';

    INSERT INTO pgagent.pga_job (
        jobjclid, jobname, jobdesc, jobhostagent, jobenabled
    ) VALUES (
        1,
        'envio_email_diario',
        'Gera o HTML do jornal UTC e envia por email a todos os membros.',
        '',
        TRUE
    ) RETURNING jobid INTO v_job_id;

    INSERT INTO pgagent.pga_jobstep (
        jstjobid, jstname, jstenabled, jstkind,
        jstcode, jstconnstr, jstdbname, jstonerror
    ) VALUES (
        v_job_id,
        'step_enviar_emails',
        TRUE,
        's',
        'SELECT utc_news.enviar_emails(FALSE);',
        '',
        'utc_news',
        'f'
    ) RETURNING jstid INTO v_step_id;

    INSERT INTO pgagent.pga_schedule (
        jscjobid, jscname, jscenabled,
        jscstart,
        jscminutes, jschours, jscweekdays, jscmonthdays, jscmonths
    ) VALUES (
        v_job_id,
        'schedule_08h',
        TRUE,
        now(),
        ARRAY(SELECT m = 0  FROM generate_series(0,59) m),
        ARRAY(SELECT h = 8  FROM generate_series(0,23) h),
        '{true,true,true,true,true,true,true}',
        ARRAY(SELECT TRUE FROM generate_series(1,32)),
        '{true,true,true,true,true,true,true,true,true,true,true,true}'
    ) RETURNING jscid INTO v_sch_id;

END;
$$;
