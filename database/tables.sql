CREATE TABLE membros (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100),
    email VARCHAR(100)
);

CREATE TABLE utc (
    id SERIAL PRIMARY KEY,
    utc VARCHAR(10),
    pais VARCHAR(150),
    cidade VARCHAR(100)
);

CREATE TABLE previsao_tempo (
    id SERIAL PRIMARY KEY,
    utc_id INT REFERENCES utc(id),
    descricao VARCHAR(100),
    temperatura INT,
    data_previsao DATE DEFAULT CURRENT_DATE,
    CONSTRAINT uq_previsao_tempo_utc_data UNIQUE (utc_id, data_previsao)
);

CREATE TABLE info_utc (
    id SERIAL PRIMARY KEY,
    utc_id INT REFERENCES utc(id),
    descricao TEXT,
    curiosidade TEXT,
    imagem_url TEXT,
    video_url TEXT
);

CREATE TABLE logs (
    id SERIAL PRIMARY KEY,
    mensagem TEXT,
    data_log TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
