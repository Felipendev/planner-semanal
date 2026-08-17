# Colocar no ar — Vercel + Supabase

Tempo estimado: **15 minutos** pelo caminho recomendado, uma vez só.
Depois disso, publicar uma alteração é um duplo clique.

**Ordem:** Supabase (partes 1.1 a 1.3) → Vercel (parte 2) → voltar ao Supabase (1.4) → conectar o app (parte 3).
O retorno ao 1.4 existe porque a URL da Vercel só nasce na parte 2.

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
├── publicar.bat          (primeira publicação — duplo clique)
├── atualizar.bat         (publicar alterações depois)
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

### 1.3 Escolher como você vai entrar

> **Tudo aqui é no navegador.** Nenhum comando, nenhum terminal.

Há dois caminhos. Comece pelo A — leva um minuto e resolve o seu caso.

---

#### Caminho A — link por e-mail *(recomendado, sem configuração)*

Você digita seu e-mail no app, recebe um link, clica, e está dentro.
Não precisa do Google Cloud, não precisa criar credencial nenhuma.

**No painel do Supabase:**
1. Menu lateral → **Authentication**
2. Aba **Sign In / Providers**
3. Localize **Email** na lista → confirme que está **habilitado** (vem ligado por padrão)
4. Pronto. Não há mais nada a fazer aqui.

> Em cada aparelho novo você pede o link uma vez. Depois a sessão fica salva.
> Para dois aparelhos, isso acontece duas vezes na vida.

---

#### Caminho B — entrar com o Google *(opcional)*

Só vale se você quiser o botão "Entrar com Google". Exige criar credenciais
em **outro site**, o Google Cloud. São duas abas do navegador conversando.

**Aba 1 — Supabase** (`supabase.com`, seu projeto)
1. **Authentication → Sign In / Providers → Google** → ligue a chave
2. A tela vai mostrar um endereço em **Callback URL**, algo como
   `https://xxxx.supabase.co/auth/v1/callback`
3. **Copie esse endereço.** Deixe esta aba aberta.

**Aba 2 — Google Cloud** (`console.cloud.google.com`)
4. No topo, ao lado do logo, clique no seletor de projeto → **Novo projeto** → nome `planner` → **Criar**
5. Menu ☰ → **APIs e serviços** → **Tela de permissão OAuth**
   - Tipo: **Externo** → **Criar**
   - Nome do app: `Planner` · E-mail de suporte: o seu · E-mail do desenvolvedor: o seu
   - **Salvar e continuar** nas telas seguintes até o fim
6. Menu ☰ → **APIs e serviços** → **Credenciais**
   - **+ Criar credenciais** → **ID do cliente OAuth**
   - Tipo de aplicativo: **Aplicativo da Web**
   - Em **URIs de redirecionamento autorizados** → **+ Adicionar URI** →
     **cole aqui o endereço que você copiou no passo 3**
   - **Criar**
7. Aparece uma janela com **ID do cliente** e **Chave secreta do cliente**. Copie os dois.

**Volte à Aba 1 — Supabase**
8. Cole o **ID do cliente** em *Client ID* e a **chave secreta** em *Client Secret*
9. **Save**

> Se o login depois abrir e voltar sem entrar, quase sempre é o passo 1.4 abaixo
> que ficou faltando.

---

### 1.4 Autorizar o endereço do site

**No Supabase → Authentication → URL Configuration:**
- **Site URL**: a URL da Vercel (você só terá na Parte 2 — **volte aqui depois do deploy**)
- **Redirect URLs** → *Add URL*: a mesma URL da Vercel

Sem isso, o link do e-mail e o login do Google levam para o lugar errado.

### 1.5 Copiar as duas chaves

São **dois valores** que você vai colar no app na Parte 3. Deixe um bloco de
notas aberto para guardá-los.

#### Onde ficam

No painel do seu projeto no Supabase, há dois caminhos:

**Caminho rápido:** botão **Connect**, no topo da página, ao lado do nome do
projeto. Abre uma janela com os valores prontos para copiar.

**Caminho completo:**
1. Ícone de **engrenagem** (⚙ *Project Settings*), no rodapé do menu lateral
2. Na coluna que abrir, clique em **API Keys**

#### Valor 1 — Project URL

Fica em **Project Settings → General**, ou na mesma tela de API.
Formato: `https://abcdefghijkl.supabase.co`

> É o endereço do seu projeto. Copie inteiro, sem barra no final.

#### Valor 2 — a chave pública

A tela de **API Keys** tem **duas abas**. Você pode usar qualquer uma das duas
— o app aceita ambas. Pegue a que aparecer para você:

| Aba | O que copiar | Como começa |
|---|---|---|
| **Publishable and secret API keys** (nova) | **Publishable key** | `sb_publishable_...` |
| **Legacy API keys** | a chave **`anon`** / *public* | `eyJhbGciOi...` |

Se a aba nova estiver vazia, clique em **Create new API keys** e copie a
*Publishable key*.

#### ⚠ O que NÃO copiar

Na mesma tela existem a **Secret key** (`sb_secret_...`) e a **`service_role`**.
Essas duas **ignoram todas as regras de segurança** do banco — quem tiver uma
delas lê e apaga tudo. Elas nunca entram no app.

O próprio planner recusa essas chaves se você colar por engano.

#### Por que a chave pública pode ficar exposta

Ela vai dentro do site, então qualquer pessoa consegue lê-la — e tudo bem.
Ela só diz *"sou um visitante deste projeto"*. Quem decide o que cada visitante
enxerga é a política que você criou no passo 1.2, que só libera a linha do
próprio usuário logado. Sem login, ela não abre nada.

#### Conferindo

Você deve ter anotado algo assim:

```
Project URL:  https://xxxxxxxxxxxx.supabase.co
Chave:        sb_publishable_xxxxxxxxxxxxxxxxxxxx
              (ou eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...)
```

Guarde — é o que você vai colar na **Parte 3**.

---

## Parte 2 — Vercel (publicar o site)

### 2.1 Enviar o código para o GitHub
Dê **duplo clique em `publicar.bat`** na pasta do projeto.

Ele cria o repositório local, faz o commit e envia para
`github.com/Felipendev/planner-semanal`. Se pedir login, autorize na janela
do navegador que abrir.

> Se o repositório no GitHub já tiver um README, o script avisa e mostra os
> dois comandos para resolver.
> Se acusar erro de permissão, feche o VSCode e qualquer terminal aberto na
> pasta e rode de novo — é o OneDrive segurando arquivos.

### 2.2 Publicar na Vercel
1. Entre em **vercel.com** → *Add New* → *Project*
2. Conecte sua conta do GitHub e **importe** `planner-semanal`
3. Framework Preset: **Other** — não mexa em mais nada,
   o `vercel.json` já aponta para a pasta `web`
4. **Deploy**

Em cerca de 40 segundos ele mostra a URL, algo como
`https://planner-semanal.vercel.app`.

### 2.3 Voltar ao Supabase
**Copie a URL da Vercel e volte ao passo 1.4** para autorizá-la em
*Authentication → URL Configuration*. Sem isso o login não conclui.

### Publicar alterações depois
Duplo clique em **`atualizar.bat`**. Ele sincroniza `planner-semanal.html`
com `web/index.html`, pergunta uma descrição e envia. A Vercel republica sozinha.

---

## Parte 3 — Conectar o app à nuvem

### 3.1 Abrir e achar o botão

Abra a URL da Vercel no computador.

Na **barra superior**, à direita, entre o relógio de foco e os botões
*Fechar dia* / *Novo*, existem **dois botões arredondados com texto**:

```
   ( • Local )   ( • Conectar )
        ↑              ↑
   onde os dados    a nuvem — é
   ficam gravados   neste que você clica
   neste computador
```

O botão **Conectar** fica **piscando em âmbar** enquanto a nuvem não estiver
ligada. Assim que você abrir o site publicado, aparece também um aviso no
rodapé: *"Site no ar. Falta ligar a nuvem para usar no celular"* — clicar
nesse aviso abre a mesma tela.

> Em tela estreita (celular) os botões mostram só a bolinha colorida,
> para caber. No computador aparecem com texto.

### 3.2 Colar as chaves

Clicando em **Conectar**, abre a janela **Nuvem**. Preencha:

| Campo | Valor (você anotou no passo 1.5) |
|---|---|
| **URL do projeto Supabase** | `https://xxxx.supabase.co` |
| **Chave pública do projeto** | `sb_publishable_...` ou `eyJhbGciOi...` |

Clique em **Salvar e conectar**.

> Se você colar por engano a chave *secret* ou *service_role*, o app recusa
> e explica qual pegar. É proposital.

### 3.3 Entrar na conta

A mesma janela passa a mostrar duas opções:

- **Receber link por e-mail** — digite seu e-mail → abra a caixa de entrada →
  clique no link. Ele traz você de volta ao app já autenticado.
  *(Se não chegar em 1 minuto, veja o lixo eletrônico.)*
- **Entrar com Google** — só funciona se você fez o Caminho B do passo 1.3.

### 3.4 Conferir

O botão da barra deve ficar **verde escrito "Nuvem"**. Passando o mouse:
*"Sincronizado. Suas marcações aparecem em qualquer aparelho."*

Estados possíveis do botão:

| Aparência | Significado |
|---|---|
| âmbar piscando · **Conectar** | nuvem não configurada |
| âmbar · **Entrar** | configurada, falta fazer login |
| âmbar · **Enviando** | mandando alterações agora |
| verde · **Nuvem** | tudo sincronizado |
| vermelho · **Erro** | clique para ver o motivo |

### 3.5 O que acontece com seus dados

Na primeira entrada, o app **envia** o que já existe neste navegador.
Nos aparelhos seguintes, ele **baixa e funde** com o que houver local.

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
| Link do e-mail não chega | Verifique o lixo eletrônico. O Supabase gratuito envia poucos e-mails por hora |
| Botão da nuvem vermelho | Chave errada, ou o `schema.sql` não foi executado |
| Dados não aparecem no outro aparelho | Você entrou com contas Google diferentes |
| Notificação não aparece | Assistente de Foco do Windows, ou permissão negada no navegador |
| App não atualiza após deploy | Recarregue com `Ctrl+Shift+R` — o service worker guarda a versão anterior |
