## Arquivos

Os arquivos base do banco de dados [Google Drive do Projeto](https://drive.google.com/drive/folders/1G-m2BnLk3mtyv06tDmo52uQ_zmWfeWLe?usp=sharing)

* `dados/` Pasta contendo os arquivos.
* `docker-compose.yaml` Container do banco de dados.
* `setup_dbsia.sql` Script SQL para criação das tabelas, esquemas e estrutura inicial do banco.

## Configurar e Executar

### 1. Baixar os arquivos
Arquivos: [link do Google Drive](https://drive.google.com/drive/folders/1G-m2BnLk3mtyv06tDmo52uQ_zmWfeWLe?usp=sharing) e coloque no diretório `dados`.

### 2. Iniciar o container
```bash
docker compose up -d
```

### 3. Conexão
MYSQL_ROOT_PASSWORD: rootpassword

MYSQL_DATABASE: dbsia

MYSQL_USER: dbsia_user

MYSQL_PASSWORD: dbsia_password

### 4. Script de configuração
```text
setup_dbsia.sql
```

```bash
Get-Content .\setup_dbsia.sql | docker exec -i mysql_dbsia mysql -u root -prootpassword
```

### Executar os script NESTA ORDEM:
```bash
Get-Content .\04-gera-dimtempo-mysql.sql | docker exec -i mysql_dbsia mysql -u root -prootpassword
```
```bash
Get-Content .\view.sql | docker exec -i mysql_dbsia mysql -u root -prootpassword
 ```

 Se deu tudo certo:

 ```bash
 SELECT * FROM pa_ijui LIMIT 10;
 ```