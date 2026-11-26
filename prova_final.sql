CREATE TABLE jogadores (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    senha VARCHAR(100) NOT NULL,
    ativo BOOLEAN NOT NULL
);


CREATE TABLE modalidades (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL,
    categoria VARCHAR(50) NOT NULL
);


CREATE TABLE torneios (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    data_inicio DATE NOT NULL,
    data_fim DATE NOT NULL,

    CHECK (data_fim >= data_inicio)
);


CREATE TABLE partidas (
    id SERIAL PRIMARY KEY,
    titulo VARCHAR(100) NOT NULL,
    data_agendamento DATE NOT NULL,
    status VARCHAR(30) NOT NULL,
    jogador_id INT NOT NULL,
    modalidade_id INT NOT NULL,
    torneio_id INT NOT NULL,
    data_criacao TIMESTAMP NOT NULL,

    FOREIGN KEY (jogador_id) REFERENCES jogadores(id),
    FOREIGN KEY (modalidade_id) REFERENCES modalidades(id),
    FOREIGN KEY (torneio_id) REFERENCES torneios(id),

    CHECK (status IN ('Agendada', 'Em andamento', 'Finalizada'))
);


CREATE TABLE historico_partidas (
    id SERIAL PRIMARY KEY,
    partida_id INT NOT NULL,
    data_registro TIMESTAMP NOT NULL,
    descricao VARCHAR(100) NOT NULL,

    FOREIGN KEY (partida_id) REFERENCES partidas(id)
);

INSERT INTO jogadores (nome, email, senha, ativo)
VALUES
('Pedro', 'pedro@gmail.com', '123', TRUE),
('Lucas', 'lucas@gmail.com', '123', TRUE),
('Joao', 'joao@gmail.com', '123', TRUE);


INSERT INTO modalidades (nome, categoria)
VALUES
('Valorant', 'FPS'),
('Minecraft', 'Sobrevivencia'),
('FIFA', 'Esporte');


INSERT INTO torneios (nome, data_inicio, data_fim)
VALUES
('Torneio 1', '2026-12-01', '2026-12-05'),
('Torneio 2', '2026-12-06', '2026-12-10'),
('Torneio 3', '2026-12-11', '2026-12-15');

CREATE OR REPLACE FUNCTION validar_partida()
RETURNS TRIGGER AS $$
DECLARE
    jogador_ativo BOOLEAN;
BEGIN

    SELECT ativo INTO jogador_ativo
    FROM jogadores
    WHERE id = NEW.jogador_id;

    IF jogador_ativo IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION 'Jogador inativo!';
    END IF;

    NEW.data_criacao = CURRENT_TIMESTAMP;

    RETURN NEW;

END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_partida
BEFORE INSERT ON partidas
FOR EACH ROW
EXECUTE FUNCTION validar_partida();

CREATE OR REPLACE FUNCTION registrar_historico()
RETURNS TRIGGER AS $$
BEGIN

    INSERT INTO historico_partidas
    (partida_id, data_registro, descricao)
    VALUES
    (NEW.id, CURRENT_TIMESTAMP, 'Partida cadastrada');

    RETURN NEW;

END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_historico_partida
AFTER INSERT ON partidas
FOR EACH ROW
EXECUTE FUNCTION registrar_historico();

INSERT INTO partidas
(titulo, data_agendamento, status, jogador_id, modalidade_id, torneio_id, data_criacao)
VALUES
('Final Valorant', '2026-12-02', 'Agendada', 1, 1, 1, CURRENT_TIMESTAMP),
('Final Minecraft', '2026-12-07', 'Agendada', 2, 2, 2, CURRENT_TIMESTAMP),
('Final FIFA', '2026-12-12', 'Agendada', 3, 3, 3, CURRENT_TIMESTAMP);

CREATE VIEW vw_painel_principal AS
SELECT
    jogadores.nome,
    partidas.titulo,
    modalidades.categoria,
    partidas.data_agendamento,
    partidas.status

FROM partidas

INNER JOIN jogadores
ON partidas.jogador_id = jogadores.id

INNER JOIN modalidades
ON partidas.modalidade_id = modalidades.id;

CREATE OR REPLACE FUNCTION fn_buscar_jogadores(termo TEXT)
RETURNS TABLE (
    id INT,
    nickname VARCHAR(50),
    email VARCHAR(100)
)
AS $$
BEGIN

    RETURN QUERY
    SELECT
        jogadores.id,
        jogadores.nome,
        jogadores.email
    FROM jogadores
    WHERE jogadores.nome ILIKE '%' || termo || '%'
    OR jogadores.email ILIKE '%' || termo || '%';

END;
$$ LANGUAGE plpgsql;

CREATE VIEW vw_cronograma_partidas AS
SELECT
    partidas.titulo,
    partidas.status,
    partidas.data_agendamento,
    partidas.data_agendamento - CURRENT_DATE AS dias_restantes,
    jogadores.nome

FROM partidas

INNER JOIN jogadores
ON partidas.jogador_id = jogadores.id

ORDER BY partidas.data_agendamento ASC; 

SELECT * FROM jogadores;

SELECT * FROM modalidades;

SELECT * FROM torneios;

SELECT * FROM partidas;

SELECT * FROM historico_partidas;

SELECT * FROM vw_painel_principal;

SELECT * FROM fn_buscar_jogadores('Pedro');

SELECT * FROM vw_cronograma_partidas;