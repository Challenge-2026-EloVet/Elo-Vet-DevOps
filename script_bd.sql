/*
  Banco de dados relacionado à API Java - Elo Vet (java-sprint3)
  Sprint 3 - DevOps Tools & Cloud Computing

  Este script documenta a DDL das tabelas do banco PostgreSQL (PaaS) criado
  pelo script 02-create-postgres.sh. O schema é criado automaticamente pela
  própria aplicação na primeira subida (Flyway + Hibernate ddl-auto=update),
  então rodar este arquivo manualmente é opcional — ele serve como registro
  documentado da estrutura (tabelas, colunas, chave primária, relacionamentos)
  exigido pela entrega.

  Tabelas usadas na demonstração de CRUD completo (Inclusão, Alteração,
  Exclusão e Consulta) desta entrega: elo_pet e elo_veterinario.
  As demais tabelas abaixo fazem parte do restante do domínio da aplicação
  (fluxo de planos de cuidado / follow-up) e são incluídas aqui apenas para
  documentar o schema completo em uso.
*/

-- ============================================================
-- T_USERS — usuários da API (autenticação/autorização, JWT)
-- ============================================================
CREATE TABLE IF NOT EXISTS users (
    id_usuario   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome_usuario VARCHAR(255) NOT NULL UNIQUE,
    email        VARCHAR(255),
    senha_hash   VARCHAR(255) NOT NULL,
    tipo_usuario INTEGER NOT NULL -- enum ordinal: 0=ADMIN, 1=USER, 2=VETERINARIO, 3=RESPONSAVEL
);

COMMENT ON TABLE  users IS 'Usuários que autenticam na API (login/JWT).';
COMMENT ON COLUMN users.id_usuario   IS 'Chave primária.';
COMMENT ON COLUMN users.nome_usuario IS 'Login usado na autenticação.';
COMMENT ON COLUMN users.tipo_usuario IS 'Papel do usuário (ADMIN/USER/VETERINARIO/RESPONSAVEL), guardado como ordinal do enum.';


-- ============================================================
-- ELO_PET — CORE (tabela 1 do CRUD desta entrega)
-- ============================================================
CREATE TABLE IF NOT EXISTS elo_pet (
    id_pet            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome              VARCHAR(255) NOT NULL,
    especie           VARCHAR(255) NOT NULL,
    raca              VARCHAR(255),
    sexo              CHAR(1),               -- 'M', 'F' ou 'N'
    data_nascimento   DATE,
    idade_aproximada  INTEGER,
    flag_castrado     BOOLEAN,
    foto              BYTEA
);

COMMENT ON TABLE  elo_pet IS 'Cadastro dos pets atendidos (tabela CORE da solução).';
COMMENT ON COLUMN elo_pet.id_pet           IS 'Chave primária.';
COMMENT ON COLUMN elo_pet.flag_castrado    IS 'Indica se o pet é castrado.';
COMMENT ON COLUMN elo_pet.foto             IS 'Foto do pet (binário), opcional.';


-- ============================================================
-- ELO_VETERINARIO — CORE (tabela 2 do CRUD desta entrega)
-- Relacionada a USERS via id_usuario (1 veterinário = 1 usuário de login)
-- ============================================================
CREATE TABLE IF NOT EXISTS elo_veterinario (
    id_veterinario   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome_completo    VARCHAR(255) NOT NULL,
    cpf              VARCHAR(11) NOT NULL,
    rg               VARCHAR(20),
    data_nascimento  DATE,
    crmv             VARCHAR(30) NOT NULL,
    telefone         VARCHAR(20),
    id_usuario       BIGINT,
    CONSTRAINT fk_veterinario_usuario
        FOREIGN KEY (id_usuario) REFERENCES users (id_usuario)
);

COMMENT ON TABLE  elo_veterinario IS 'Cadastro dos veterinários da clínica (tabela CORE da solução).';
COMMENT ON COLUMN elo_veterinario.id_veterinario IS 'Chave primária.';
COMMENT ON COLUMN elo_veterinario.crmv           IS 'Registro profissional do veterinário (CRMV).';
COMMENT ON COLUMN elo_veterinario.id_usuario     IS 'Chave estrangeira para users.id_usuario (login do veterinário).';


-- ============================================================
-- Demais tabelas do domínio (fluxo de planos de cuidado / follow-up)
-- Não fazem parte do CRUD demonstrado nesta entrega, documentadas por
-- completude do schema real em uso pela aplicação.
-- ============================================================
CREATE TABLE IF NOT EXISTS care_plan (
    id                 BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    veterinary_id      BIGINT,
    pet_id             BIGINT NOT NULL,
    pet_owner_id       BIGINT,
    created_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by_user_id BIGINT,
    status             VARCHAR(20) NOT NULL,
    notes              TEXT
);
COMMENT ON TABLE care_plan IS 'Plano de cuidados gerado pelo veterinário para um pet/tutor.';

CREATE TABLE IF NOT EXISTS care_plan_item (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    care_plan_id  BIGINT NOT NULL,
    title         VARCHAR(255) NOT NULL,
    description   TEXT,
    due_date      DATE,
    status        VARCHAR(20) NOT NULL DEFAULT 'PENDING'
);
COMMENT ON TABLE care_plan_item IS 'Itens (checklist) de um plano de cuidados.';

CREATE TABLE IF NOT EXISTS notification (
    id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    target_user_id BIGINT,
    care_plan_id   BIGINT,
    type           VARCHAR(50),
    payload        TEXT,
    sent_at        TIMESTAMP
);
COMMENT ON TABLE notification IS 'Notificações simuladas enviadas ao tutor.';

CREATE TABLE IF NOT EXISTS follow_up_log (
    id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    care_plan_item_id BIGINT,
    action            VARCHAR(50),
    performed_by      BIGINT,
    performed_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    note              TEXT
);
COMMENT ON TABLE follow_up_log IS 'Histórico de ações realizadas sobre um item de plano de cuidados.';


-- ============================================================
-- Dados de exemplo (opcional — o ideal é inserir via API para a
-- demonstração de CRUD do vídeo, e usar este SELECT só para conferência)
-- ============================================================
-- INSERT INTO elo_veterinario (nome_completo, cpf, crmv) VALUES ('Dra. Ana Silva', '12345678901', 'CRMV-1001');
-- INSERT INTO elo_pet (nome, especie, raca) VALUES ('Thor', 'Cachorro', 'Golden Retriever');

-- SELECT * FROM elo_pet;
-- SELECT * FROM elo_veterinario;
