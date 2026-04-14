-- =============================================================================
-- jobs.sql - Agendamento via pgAgent
-- =============================================================================
-- O pgAgent continua responsavel apenas pela atualizacao do clima.
-- O envio de emails sai do banco e passa a ser feito por um listener Python
-- conectado ao canal NOTIFY criado em triggers.sql.
-- =============================================================================

DO $$
DECLARE
    v_job_id  INT;
    v_step_id INT;
    v_sch_id  INT;
BEGIN

    DELETE FROM pgagent.pga_job WHERE jobname = 'atualizar_clima_diario';

    INSERT INTO pgagent.pga_job (
        jobjclid, jobname, jobdesc, jobhostagent, jobenabled
    ) VALUES (
        1,
        'atualizar_clima_diario',
        'Busca previsao do tempo via API e grava em previsao_tempo.',
        '',
        TRUE
    ) RETURNING jobid INTO v_job_id;

    INSERT INTO pgagent.pga_jobstep (
        jstjobid, jstname, jstenabled, jstkind,
        jstcode, jstconnstr, jstdbname, jstonerror
    ) VALUES (
        v_job_id,
        'step_atualizar_clima',
        TRUE,
        's',
        'SELECT utc_news.atualizar_clima();',
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
        'schedule_07h',
        TRUE,
        now(),
        ARRAY(SELECT m = 0 FROM generate_series(0,59) m),
        ARRAY(SELECT h = 7 FROM generate_series(0,23) h),
        '{true,true,true,true,true,true,true}',
        ARRAY(SELECT TRUE FROM generate_series(1,32)),
        '{true,true,true,true,true,true,true,true,true,true,true,true}'
    ) RETURNING jscid INTO v_sch_id;

END;
$$;
