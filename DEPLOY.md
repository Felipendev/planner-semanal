# Colocar no ar — Vercel + Supabase

Tempo estimado: **20 a 30 minutos**, uma vez só.
Depois disso, atualizar é um comando (ou um `git push`).

---

## O que já está pronto na pasta

```
planner-semanal/
├── web/                  ← isto é o que vai para o ar
│   ├── index.html        (o app inteiro, 250 KB)
│   ├── manifest.json     (instalação como aplicativo)
│   ├── sw.js             (funciona offline)
│   ├── icon-192.png
│   └── icon-512.png
├── supabase/
│   └── schema.sql        (a tabela e as regras de acesso)
├── vercel.json           (configuração do deploy)
├── planner-semanal.html  (cópia local, para abrir sem internet)
├── SPEC.md
└── DEPLOY.md             (este arquivo)
```

---

## Parte 1 — Supabase (banco e login)

### 1.1 Criar o projeto
1. Entre em **supabase.com** → *New project*
2. Nome: `planner` · Região: **South America (São Paulo)** — menor latência
3. Guarde a senha do banco (você não vai precisar dela agora, mas vai um dia)
4. Aguarde ~2 minutos até o projeto ficar verde

### 1.2 Criar a tabela
1. No menu lateral: **SQL Editor** → *New query*
2. Cole todo o conteúdo de `supabase/schema.sql`
3. **Run**

Isso cria:
- `estado` — uma linha por usuário, com o JSON inteiro
- Política de acesso: cada um só enxerga a própria linha
- `estado_historico` — as **30 versões anteriores**, gravadas automaticamente a cada alteração. É a sua rede de segurança contra um merge ruim.

### 1.3 Ligar o login com Google
1. **Authentication → Sign In / Providers → Google** → ative
2. Ele pede *Client ID* e *Client Secret*. Para obtê-los:
   - Vá em **console.cloud.google.com** → crie um projeto (ou use um existente)
   - **APIs e serviços → Tela de permissão OAuth** → tipo **Externo** → preencha nome do app e seu e-mail → salve
   - **Credenciais → Criar credenciais → ID do cliente OAuth → Aplicativo da Web**
   - Em **URIs de redirecionamento autorizados**, cole a URL que o Supabase mostra na própria tela do provedor Google (algo como `https://xxxx.supabase.co/auth/v1/callback`)
   - Copie o *Client ID* e o *Client Secret* de volta para o Supabase → **Save**

### 1.4 Autorizar o endereço do site
**Authentication → URL Configuration**
- *Site URL*: a URL da Vercel (você terá na Parte 2 — volte aqui depois)
- *Redirect URLs*: adicione a mesma URL e também `http://localhost:3000` se for testar local

### 1.5 Copiar as chaves
**Project Settings → API**, anote:
- **Project URL** → `https://xxxx.supabase.co`
- **anon public** → a chave que começa com `eyJ...`

> Essas duas informações são públicas por natureza. Quem protege os dados é a política de acesso, que só permite ler a própria linha. Nunca use a chave `service_role` no app.

---

## Parte 2 — Vercel (publicar o site)

### Caminho A — GitHub (recomendado)
Cada alteração futura publica sozinha ao dar `push`.

```bash
cd "C:\Users\user\OneDrive\Documents\pessoal\workspace-felipe\planner-semanal"
git init
git add .
git commit -m "planner: primeira versão no ar"
```

1. Crie um repositório **privado** em github.com (sem README, sem .gitignore)
2. Rode o que o GitHub mostrar, algo como:
   ```bash
   git remote add origin https://github.com/SEU_USUARIO/planner.git
   git branch -M main
   git push -u origin main
   ```
3. Em **vercel.com** → *Add New → Project* → importe o repositório
4. Framework Preset: **Other**. O `vercel.json` já aponta para a pasta `web`
5. **Deploy**

### Caminho B — sem GitHub
```bash
npm i -g vercel
cd "C:\Users\user\OneDrive\Documents\pessoal\workspace-felipe\planner-semanal"
vercel --prod
```
Responda às perguntas aceitando os padrões. Para atualizar depois, rode `vercel --prod` de novo.

### Depois do deploy
Anote a URL (`https://planner-xxxx.vercel.app`) e **volte ao passo 1.4** para autorizá-la no Supabase. Sem isso o login com Google falha.

---

## Parte 3 — Conectar o app à nuvem

1. Abra a URL da Vercel
2. Clique no **segundo pontinho** na barra superior (ao lado do primeiro, que indica gravação local)
3. Cole a **Project URL** e a **chave anon**
4. **Salvar e conectar** → **Entrar com Google**

O que acontece: na primeira entrada ele envia o que já existe neste navegador. Nos aparelhos seguintes, ele baixa e **funde** com o que houver local.

### Como o conflito é resolvido
| Tipo de dado | Regra |
|---|---|
| Conclusões, água, páginas lidas, dias fechados, desafios vencidos | **União** — nada se perde, marcar nos dois aparelhos dá o mesmo resultado |
| Rotina, metas, áreas, hábitos, frases | Vence a versão mais recente |
| Recorde de sequência | Vence o maior |

Testado: 2 aparelhos marcando dias diferentes offline resultam na soma dos dois, não na substituição.

---

## Parte 4 — Instalar no celular

1. Abra a URL no **Chrome do Android** (ou Safari no iPhone)
2. Menu → **Adicionar à tela de início**
3. Abre em tela cheia, com ícone próprio, e funciona sem internet

No computador, o Chrome mostra um ícone de instalar na barra de endereço.

---

## Parte 5 — Impedir o banco de hibernar

Projeto gratuito do Supabase **pausa após 7 dias sem atividade**. Usando diariamente isso nunca acontece, mas se você viajar:

Crie `api/ping.js` na raiz do repositório:

```js
export default async function handler(req, res) {
  const r = await fetch(`${process.env.SB_URL}/rest/v1/estado?select=user_id&limit=1`, {
    headers: { apikey: process.env.SB_KEY, Authorization: `Bearer ${process.env.SB_KEY}` }
  });
  res.status(200).json({ ok: r.ok });
}
```

E acrescente ao `vercel.json`:
```json
"crons": [{ "path": "/api/ping", "schedule": "0 9 * * *" }]
```

Em **Vercel → Settings → Environment Variables**, crie `SB_URL` e `SB_KEY` com os mesmos valores da Parte 1.5.

---

## Verificação final

- [ ] Site abre pela URL da Vercel
- [ ] Login com Google entra e mostra seu e-mail no painel de Nuvem
- [ ] O segundo pontinho da barra fica **verde**
- [ ] Marcar uma atividade no computador aparece no celular após recarregar
- [ ] Notificações funcionam (⋯ → Testar som e notificação)
- [ ] Instala como aplicativo no celular
- [ ] Com o modo avião ligado, o app abre e aceita marcações

---

## Atualizar depois

**Com GitHub:** `git add . && git commit -m "ajuste" && git push` — a Vercel publica sozinha.
**Com CLI:** `vercel --prod`

Em ambos os casos, o arquivo que vai para o ar é `web/index.html`.

---

## Se algo der errado

| Sintoma | Causa provável |
|---|---|
| Login abre e volta sem entrar | A URL da Vercel não foi autorizada no passo 1.4 |
| Pontinho vermelho | Chave errada, ou o `schema.sql` não foi executado |
| Dados não aparecem no outro aparelho | Você entrou com contas Google diferentes |
| Notificação não aparece | Assistente de Foco do Windows, ou permissão negada no navegador |
| App não atualiza após deploy | Recarregue com `Ctrl+Shift+R` — o service worker guarda a versão anterior |
