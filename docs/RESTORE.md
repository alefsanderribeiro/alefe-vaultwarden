# Restaurar Backup do Vaultwarden

## Pré-requisitos

- Docker e Docker Compose instalados
- Backup `.tar.gz` em `~/Documentos/Mega/alefe-vaultwarden-backup/`

## Passos

1. **Parar os containers** (se estiverem rodando):
   ```bash
   cd ~/vaultwarden
   docker compose down
   ```

2. **Fazer backup do diretório atual** (opcional, mas recomendado):
   ```bash
   mv vw-data vw-data-old
   ```

3. **Criar diretório limpo**:
   ```bash
   mkdir vw-data
   ```

4. **Extrair o backup**:
   ```bash
   tar -xzf ~/Documentos/Mega/alefe-vaultwarden-backup/vw-<DATA>.tar.gz -C vw-data/
   ```

5. **Verificar integridade do banco**:
   ```bash
   sqlite3 vw-data/db.sqlite3 "PRAGMA integrity_check;"
   ```
   Deve retornar `ok`.

6. **Ajustar permissões**:
   ```bash
   chmod -R 700 vw-data
   ```

7. **Iniciar os containers**:
   ```bash
   docker compose up -d
   ```

8. **Verificar logs**:
   ```bash
   docker compose logs vaultwarden --tail=20
   ```

9. **Testar acesso**:
   ```
   https://servidor-ubuntu-home.tail2f0857.ts.net
   ```

> ⚠️ Após restaurar, crie uma nova conta admin na interface web e verifique se todas as senhas estão acessíveis.
