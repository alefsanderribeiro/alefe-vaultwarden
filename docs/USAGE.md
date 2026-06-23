# Guia de Uso - Vaultwarden para a Família

## O que é?

Vaultwarden é um gerenciador de senhas. Ele armazena logins, senhas, cartões e notas de forma segura, acessível de qualquer dispositivo na rede Tailscale.

## Acesso

- **URL**: https://servidor-ubuntu-home.tail2f0857.ts.net
- **Requer**: Tailscale conectado no dispositivo

## Primeiro Acesso

1. Abra o link acima no navegador
2. Clique em **"Create Account"**
3. Preencha: **Email** (seu email real) e **Master Password** (sua senha mestra — **não perca!**)
4. Verifique o email (link de confirmação)
5. Faça login

## Apps Recomendados

Cada pessoa instala o app **Bitwarden** (não Vaultwarden) nos dispositivos:

- **Android**: [Bitwarden na Play Store](https://play.google.com/store/apps/details?id=com.x8bit.bitwarden)
- **iOS**: [Bitwarden na App Store](https://apps.apple.com/app/bitwarden/id1137397744)
- **Desktop**: [Bitwarden Desktop](https://bitwarden.com/download/)
- **Navegador**: Extensão Bitwarden (Chrome, Firefox, Edge)

### Configurar o App

1. Abra o Bitwarden
2. Settings → **Self-hosted environment** (ou "Servidor próprio")
3. URL do servidor: `https://servidor-ubuntu-home.tail2f0857.ts.net`
4. Faça login com email e senha mestra

## Dicas de Segurança

- **Senha Mestra**: Escolha uma senha forte e única. Sem anotá-la em lugar nenhum.
- **Anotação de Emergência**: Anote a senha mestra em papel e guarde em local seguro (cofre físico).
- **2FA**: Ative autenticação de dois fatores na conta admin.
- **Logout**: Sempre faça logout em dispositivos compartilhados.

## Manutenção

| Tarefa | Frequência | Como |
|--------|-----------|------|
| Backup automático | Diário (cron) | `./scripts/backup.sh` |
| Verificar logs | Semanal | `docker compose logs vaultwarden --tail=30` |
| Atualizar imagem | Mensal | `docker compose pull && docker compose up -d` |

## Senha Mestra Perdida?

**Não há recuperação.** Se perder a senha mestra, os dados são irrecuperáveis. Nesse caso:

1. Pare os containers: `docker compose down`
2. Delete o banco: `rm -rf vw-data/`
3. Reinicie: `docker compose up -d`
4. Crie uma nova conta
5. Restaure de um backup (se tiver a senha mestra antiga)

## Suporte

Caso algo não funcione, verifique os logs:
```bash
docker compose logs vaultwarden
```
