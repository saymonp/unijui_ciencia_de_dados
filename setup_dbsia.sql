-- ==============================================================================
-- TRABALHO 3 - ANÁLISE DE DADOS DO SIASUS (IJUÍ/RS)
-- Script Completo de Criação, Carga e Estruturação do Banco `dbsia` (Docker)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. CRIAÇÃO DO BANCO DE DADOS (REINÍCIO LIMPO)
-- ------------------------------------------------------------------------------
DROP DATABASE IF EXISTS dbsia;
CREATE DATABASE dbsia 
  CHARACTER SET latin1 
  COLLATE latin1_swedish_ci;

USE dbsia;

-- ------------------------------------------------------------------------------
-- 2. CRIAÇÃO DAS TABELAS (DDL)
-- ------------------------------------------------------------------------------

-- 2.1 Tabela Central de Produção Ambulatorial (PARS)
CREATE TABLE pars (
    pa_coduni CHAR(7),
    pa_gestao CHAR(6),
    pa_condic CHAR(2),
    pa_ufmun CHAR(6),
    pa_regct CHAR(4),
    pa_incout CHAR(4),
    pa_incurg CHAR(4),
    pa_tpups CHAR(2),
    pa_tippre CHAR(2),
    pa_mn_ind CHAR(1),
    pa_cnpjcpf VARCHAR(14),
    pa_cnpjmnt VARCHAR(14),
    pa_cnpj_cc VARCHAR(14),
    pa_mvm CHAR(6),
    pa_cmp CHAR(6),
    pa_proc_id CHAR(10),
    pa_tpfin CHAR(2),
    pa_subfin CHAR(4),
    pa_nivcpl CHAR(1),
    pa_docorig CHAR(1),
    pa_autoriz VARCHAR(13),
    pa_cnsmed VARCHAR(15),
    pa_cbocod CHAR(6),
    pa_motsai CHAR(2),
    pa_obito CHAR(1),
    pa_encerr CHAR(1),
    pa_perman CHAR(1),
    pa_alta CHAR(1),
    pa_transf CHAR(1),
    pa_cidpri CHAR(4),
    pa_cidsec CHAR(4),
    pa_cidcas CHAR(4),
    pa_catend CHAR(2),
    pa_idade CHAR(3),
    pa_flidade CHAR(1),
    pa_sexo CHAR(1),
    pa_racacor CHAR(2),
    pa_munpcn CHAR(6),
    pa_qtdpro DECIMAL(11,0),
    pa_qtdapr DECIMAL(11,0),
    pa_valpro DECIMAL(20,2),
    pa_valapr DECIMAL(20,2),
    pa_ufdif CHAR(1),
    pa_mndif CHAR(1),
    INDEX idx_pa_ufmun (pa_ufmun),
    INDEX idx_pa_coduni (pa_coduni),
    INDEX idx_pa_proc_id (pa_proc_id),
    INDEX idx_pa_cbocod (pa_cbocod),
    INDEX idx_pa_cidpri (pa_cidpri),
    INDEX idx_pa_munpcn (pa_munpcn),
    INDEX idx_pa_mvm (pa_mvm)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- 2.2 Tabela de Estabelecimentos (CADGERRS)
CREATE TABLE cadgerrs (
    cnes VARCHAR(7) PRIMARY KEY,
    fantasia VARCHAR(100),
    nome VARCHAR(100)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- 2.3 Tabela de Procedimentos Ambulatoriais (procedimentos - TB_SIGTAW)
CREATE TABLE procedimentos (
    ip_cod VARCHAR(10) PRIMARY KEY,
    ip_dscr VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- 2.4 Tabela de Ocupações Profissionais (cbo - CBO)
CREATE TABLE cbo (
    cbo VARCHAR(6) PRIMARY KEY,
    ds_cbo VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- 2.5 Tabela de Diagnósticos (cid - S_CID)
CREATE TABLE cid (
    cd_cod VARCHAR(4) PRIMARY KEY,
    cd_descr VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- 2.6 Tabela de Municípios (tb_municip)
CREATE TABLE tb_municip (
    co_municip VARCHAR(6) PRIMARY KEY,
    ds_nome VARCHAR(100)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ------------------------------------------------------------------------------
-- 3. CARGA EM LOTE DOS ARQUIVOS CSV (DML)
-- ------------------------------------------------------------------------------

-- 3.1 Tabela Central PARS (62 colunas no CSV -> 44 mapeadas, separador ',')
LOAD DATA INFILE '/var/lib/mysql-files/PARS2606a.csv'
INTO TABLE pars
CHARACTER SET latin1
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
    pa_coduni, pa_gestao, pa_condic, pa_ufmun, pa_regct, pa_incout, pa_incurg,
    pa_tpups, pa_tippre, pa_mn_ind, pa_cnpjcpf, pa_cnpjmnt, pa_cnpj_cc, pa_mvm,
    pa_cmp, pa_proc_id, pa_tpfin, pa_subfin, pa_nivcpl, pa_docorig, pa_autoriz,
    pa_cnsmed, pa_cbocod, pa_motsai, pa_obito, pa_encerr, pa_perman, pa_alta,
    pa_transf, pa_cidpri, pa_cidsec, pa_cidcas, pa_catend, pa_idade,
    @ignorar, @ignorar, -- Ignora IDADEMIN e IDADEMAX
    pa_flidade, pa_sexo, pa_racacor, pa_munpcn,
    @v_qtdpro, @v_qtdapr, @v_valpro, @v_valapr,
    pa_ufdif, pa_mndif,
    -- Ignora as 16 colunas finais (PA_DIF_VAL até PA_VL_CRD)
    @ignorar, @ignorar, @ignorar, @ignorar, @ignorar, @ignorar, @ignorar, @ignorar,
    @ignorar, @ignorar, @ignorar, @ignorar, @ignorar, @ignorar, @ignorar, @ignorar
)
SET
    pa_qtdpro = NULLIF(TRIM(@v_qtdpro), ''),
    pa_qtdapr = NULLIF(TRIM(@v_qtdapr), ''),
    pa_valpro = NULLIF(TRIM(@v_valpro), ''),
    pa_valapr = NULLIF(TRIM(@v_valapr), '');

-- 3.2 Estabelecimentos CADGERRS (22 colunas no CSV, separador ',')
LOAD DATA INFILE '/var/lib/mysql-files/CADGERRS.csv'
IGNORE INTO TABLE cadgerrs
CHARACTER SET latin1
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    cnes,         -- 1. CNES
    @ignorar,     -- 2. CPF_CNPJ
    fantasia,     -- 3. FANTASIA
    nome,         -- 4. RAZ_SOCI
    -- 5..22. Ignora as 18 colunas restantes
    @ignorar, @ignorar, @ignorar, @ignorar, @ignorar, @ignorar,
    @ignorar, @ignorar, @ignorar, @ignorar, @ignorar, @ignorar,
    @ignorar, @ignorar, @ignorar, @ignorar, @ignorar, @ignorar
);

-- 3.3 Procedimentos TB_SIGTAW (2 colunas no CSV, separador ',')
LOAD DATA INFILE '/var/lib/mysql-files/TB_SIGTAW.csv'
IGNORE INTO TABLE procedimentos
CHARACTER SET latin1
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(ip_cod, ip_dscr);

-- 3.4 Ocupações CBO (2 colunas no CSV, separador ',')
LOAD DATA INFILE '/var/lib/mysql-files/CBO.csv'
IGNORE INTO TABLE cbo
CHARACTER SET latin1
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(cbo, ds_cbo);

-- 3.5 Diagnósticos S_CID (9 colunas no CSV, separador ',')
LOAD DATA INFILE '/var/lib/mysql-files/S_CID.csv'
IGNORE INTO TABLE cid
CHARACTER SET latin1
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    cd_cod,       -- 1. CD_COD
    @ignorar,     -- 2. OPC (*)
    @ignorar,     -- 3. CAT
    @ignorar,     -- 4. SUBCAT
    cd_descr,     -- 5. CD_DESCR
    -- 6..9. Ignora as 4 colunas restantes
    @ignorar, @ignorar, @ignorar, @ignorar
);

-- 3.6 Municípios tb_municip (24 colunas no CSV, separador ';')
LOAD DATA INFILE '/var/lib/mysql-files/tb_municip.csv'
IGNORE INTO TABLE tb_municip
CHARACTER SET latin1
FIELDS TERMINATED BY ';'
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    co_municip,                       -- 1. CO_MUNICIP
    @ignorar, @ignorar, @ignorar,     -- 2..4. CO_MUNICDV, CO_STATUS, CO_TIPO
    ds_nome,                          -- 5. DS_NOME
    -- 6..24. Ignora as 19 colunas restantes
    @ignorar, @ignorar, @ignorar, @ignorar, @ignorar,
    @ignorar, @ignorar, @ignorar, @ignorar, @ignorar,
    @ignorar, @ignorar, @ignorar, @ignorar, @ignorar,
    @ignorar, @ignorar, @ignorar, @ignorar
);

-- ------------------------------------------------------------------------------
-- 4. DIMENSÃO TEMPORAL (DIMTEMPO - 2008 a 2030)
-- ------------------------------------------------------------------------------
CREATE TABLE dimtempo (
    anomes CHAR(6) PRIMARY KEY,
    ano INT NOT NULL,
    mes INT NOT NULL,
    anobi VARCHAR(10) NOT NULL,
    anotri VARCHAR(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

INSERT INTO dimtempo (anomes, ano, mes, anobi, anotri)
WITH RECURSIVE meses AS (
    SELECT DATE('2008-01-01') AS dt
    UNION ALL
    SELECT DATE_ADD(dt, INTERVAL 1 MONTH)
    FROM meses
    WHERE dt < '2030-12-01'
)
SELECT 
    DATE_FORMAT(dt, '%Y%m') AS anomes,
    YEAR(dt) AS ano,
    MONTH(dt) AS mes,
    CONCAT(YEAR(dt), '-B', CEIL(MONTH(dt) / 2)) AS anobi,
    CONCAT(YEAR(dt), '-T', QUARTER(dt)) AS anotri
FROM meses;

-- ------------------------------------------------------------------------------
-- 5. CRIAÇÃO DA VIEW pa_ijui (Filtro e Junções para Ijuí - IBGE 431020)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW pa_ijui AS
SELECT
    -- 1. DIMENSÃO TEMPORAL
    dt.ano AS Ano,
    dt.mes AS Mes,
    dt.anobi AS AnoBimestre,
    dt.anotri AS AnoTrimestre,

    -- 2. ESTABELECIMENTO DE SAÚDE (usa razão social caso fantasia esteja vazio)
    COALESCE(NULLIF(TRIM(ca.fantasia), ''), ca.nome) AS Estabelecimento,

    -- 3. PROCEDIMENTO AMBULATORIAL
    pro.ip_dscr AS Procedimento,

    -- 4. OCUPAÇÃO PROFISSIONAL
    cb.ds_cbo AS Ocupacao,

    -- 5. PERFIL DEMOGRÁFICO
    pa.pa_sexo,
    pa.pa_idade,

    -- 6. DIAGNÓSTICO PRINCIPAL
    pa.pa_cidpri,
    cid.cd_descr AS Diagnostico,

    -- 7. MUNICÍPIO DO ESTABELECIMENTO
    mun_est.ds_nome AS MunicipioEstabelecimento,

    -- 8. MUNICÍPIO DO PACIENTE
    mun_pac.ds_nome AS MunicipioPaciente,

    -- 9. PRODUÇÃO AMBULATORIAL
    pa.pa_qtdpro,
    pa.pa_qtdapr,

    -- 10. VALORES FINANCEIROS
    pa.pa_valpro,
    pa.pa_valapr

FROM pars AS pa
LEFT JOIN cadgerrs AS ca         ON pa.pa_coduni  = ca.cnes
LEFT JOIN procedimentos AS pro   ON pa.pa_proc_id = pro.ip_cod
LEFT JOIN cbo AS cb              ON pa.pa_cbocod  = cb.cbo
LEFT JOIN cid                    ON pa.pa_cidpri  = cid.cd_cod
LEFT JOIN tb_municip AS mun_est  ON pa.pa_ufmun  = mun_est.co_municip
LEFT JOIN tb_municip AS mun_pac  ON pa.pa_munpcn = mun_pac.co_municip
LEFT JOIN dimtempo AS dt         ON pa.pa_mvm     = dt.anomes
WHERE pa.pa_ufmun = '431020';

-- ------------------------------------------------------------------------------
-- 6. CONSULTAS DE VALIDAÇÃO FINAL
-- ------------------------------------------------------------------------------
SELECT 'pars' AS tabela, COUNT(*) AS registros FROM pars
UNION ALL SELECT 'cadgerrs', COUNT(*) FROM cadgerrs
UNION ALL SELECT 'procedimentos', COUNT(*) FROM procedimentos
UNION ALL SELECT 'cbo', COUNT(*) FROM cbo
UNION ALL SELECT 'cid', COUNT(*) FROM cid
UNION ALL SELECT 'tb_municip', COUNT(*) FROM tb_municip
UNION ALL SELECT 'pa_ijui (VIEW)', COUNT(*) FROM pa_ijui;

SELECT * FROM pa_ijui WHERE Diagnostico IS NOT NULL LIMIT 5;