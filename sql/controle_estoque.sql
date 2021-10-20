


create database admin;
use admin;

CREATE TABLE admin.departamentos (
id_departamento integer NOT NULL PRIMARY KEY AUTO_INCREMENT,
nome VARCHAR(250) NOT NULL,
localizacao varchar(100),
fisico tinyint(1) NOT NULL DEFAULT 1,
criado timestamp(3) NOT NULL default current_timestamp(3),
atualizado timestamp(3) NOT NULL default current_timestamp(3) ON UPDATE current_timestamp(3)
);


CREATE TABLE admin.usuarios (
id_usuario integer NOT NULL PRIMARY KEY AUTO_INCREMENT,
nome_completo VARCHAR(250) NOT NULL,
email VARCHAR(25) NOT NULL,
situacao tinyint NOT NULL DEFAULT 0,
criado timestamp(3) NOT NULL default current_timestamp(3),
atualizado timestamp(3) NOT NULL default current_timestamp(3) ON UPDATE current_timestamp(3),
departamento_id integer NOT NULL,
KEY idx_email(email),
KEY idx_departamento(departamento_id),
constraint fk_usuarios_departamentos foreign key (departamento_id) references departamentos(id_departamento)
);


create table admin.gestao_departamentos (
gestor integer not null,
departamento_id integer not null,
criado timestamp(3) NOT NULL default current_timestamp(3),
atualizado timestamp(3) NOT NULL default current_timestamp(3) ON UPDATE current_timestamp(3),
PRIMARY KEY (gestor, departamento_id),
UNIQUE KEY (departamento_id),
CONSTRAINT fk_gestao_departamentos_departamentos foreign key (departamento_id) references departamentos(id_departamento),
CONSTRAINT fk_departamentos_usuarios foreign key (gestor) references usuarios(id_usuario)
);


/* 
SELECT 
d.nome, d.localizacao, gd.atualizado Gestao_atualizada, u.nome_completo, u.situacao
FROM departamentos d
INNER JOIN gestao_departamentos gd ON d.id_departamento = dg.departamento_id
INNER JOIN usuarios u ON gd.gestor = u.id_usuario
WHERE
d.fisico = 0;
*/

create database estoque;
use estoque;

create table estoque.material (
id_material integer not null auto_increment primary key,
nome varchar(255) NOT NULL,
unidade smallint not null default 0,
tipo integer NOT NULL default 0, -- 0 para material, 1 para EPI
criado timestamp(3) NOT NULL default current_timestamp(3),
INDEX idx_criado(criado),
INDEX idx_nome(nome)
);

create table estoque.lote (
id_lote integer not null auto_increment primary key,
controle varchar(30) null, -- nota fiscal? registro de compra? fornecedor?
validade_ca date null,
tipo integer NOT NULL default 0, -- 0 para material, 1 para EPI
criado  timestamp(3) NOT NULL default current_timestamp(3),
INDEX idx_validade_ca (validade_ca)
);

/*

  FLUXO BÁSICO situacao_material
1) Somente com um lote existente e um material pré cadastrado pode-se inserir uma situacao_material
2) É necessário especificar a quantidade para inserir uma situacao.
3) Quando é criada a linha, entende-se que há o material no estoque
4) A aplicação poderá ou não permitir update para aumentar a quantidade de material na tabela situacao_material. Ou pode exigir um novo lote.

- Cada linha aqui, é a existência de material em estoque. Ou seja, para retirar do estoque, é inserida uma linha na tabela movimentação e atualizada a tabela situacao_material.
- A quantidade é reduzida pela movimentacao
- a coluna atualizado é atualizada automaticamente

*/

create table estoque.situacao_material (
lote_id  integer not null,
material_id integer not null,
quantidade double precision not null,
localizacao varchar(100),
criado timestamp(3) NOT NULL default current_timestamp(3),
atualizado timestamp(3) NOT NULL default current_timestamp(3) ON UPDATE current_timestamp(3),
PRIMARY KEY (material_id,lote_id),
INDEX idx_atualizado(atualizado),
INDEX idx_quantidade(quantidade),
INDEX idx_lote(lote_id),
CONSTRAINT fk_situacao_material_material foreign key (material_id) references material(id_material),
CONSTRAINT fk_situacao_material_lote foreign key (lote_id) references lote(id_lote)
);

/*
  FLUXO BÁSICO historico_material
1) QUANDO Um lote é adicionado na situacao_material, ele é automaticamente copiado para a tabela historico_material
2) A linha na tabela historico_material terá a quantidade original da entrada
3) Quando um lote tem sua quantidade atualizada para zero, ele é removido da situacao_material e atualizado na historico_material.

*/

create table estoque.historico_material (
lote_id  integer not null,
material_id integer not null,
localizacao varchar(100),
quantidade double precision not null,
criado timestamp(3) NOT NULL default current_timestamp(3),
zerado timestamp(3) NULL,
PRIMARY KEY (material_id,lote_id),
INDEX idx_lote(lote_id),
INDEX idx_criado(criado),
INDEX idx_zerado(zerado)
);


DELIMITER $$

CREATE TRIGGER trg_situacao_material_ai
    AFTER INSERT
    ON situacao_material
    FOR EACH ROW
BEGIN

  INSERT INTO estoque.historico_material
  (
  lote_id,
  material_id,
  localizacao,
  quantidade,
  criado,
  zerado
  ) VALUES
  (NEW.lote_id,
   NEW.material_id,
   NEW.quantidade,
   NEW.criado,
   NULL);


END$$

CREATE TRIGGER trg_situacao_material_au
    AFTER UPDATE
    ON situacao_material
    FOR EACH ROW
BEGIN
 
  IF (NEW.quantidade = 0) THEN
    UPDATE estoque.historico_material
	SET zerado=NEW.atualizado
	WHERE
	lote_id = NEW.lote_id
	AND material_id = NEW.material_id;
  END IF;

END$$

DELIMITER;

create table estoque.pessoa (
id_pessoa int not null auto_increment primary key,
nome_completo varchar(255) NOT NULL,
funcao varchar(255) NULL,
criado timestamp(3) NOT NULL default current_timestamp(3),
atualizado timestamp(3) NOT NULL default current_timestamp(3) ON UPDATE current_timestamp(3),
INDEX idx_criado(criado),
INDEX idx_nome_completo(nome_completo)
);

create table estoque.movimentacao (
id_movimentacao BIGINT NOT NULL auto_increment primary key,
pessoa_id int not null,
lote_id  integer not null,
material_id integer not null,
quantidade double precision NOT NULL,
localizacao varchar(100) null,
criado timestamp(3) NOT NULL default current_timestamp(3),
atualizado timestamp(3) NOT NULL default current_timestamp(3) ON UPDATE current_timestamp(3),
INDEX idx_criado(criado),
INDEX idx_material(material_id),
INDEX idx_lote(lote_id),
INDEX idx_pesssoa(pessoa_id),
CONSTRAINT fk_movimentacao_pessoa foreign key (pessoa_id) references pessoa(id_pessoa),	
CONSTRAINT fk_movimentacao_material foreign key (material_id) references material(id_material),
CONSTRAINT fk_movimentacao_lote foreign key (lote_id) references lote(id_lote)
);
 





