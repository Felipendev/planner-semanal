# Colocar no ar — Vercel + Supabase

Tempo estimado: **15 minutos** pelo caminho recomendado, uma vez só.
Depois disso, publicar uma alteração é um duplo clique.

**Ordem:** Supabase (1.1 a 1.3) → Vercel (2.1 e 2.2) → voltar ao Supabase (1.4) → conectar o app (parte 3).
O retorno ao 1.4 existe porque a URL da Vercel só nasce na parte 2.

---

## O que já está pronto na pasta

```
planner-semanal/
├── web/                  ← isto é o que vai para o ar
│   ├── index.html        (o app inteiro, 250 KB)
│   ├── config.js         (URL e chave do Supabase — preencha uma vez)
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
├── corrigir-autor.bat    (se a Vercel recusar o commit)
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

> ⚠ **O erro mais comum do guia inteiro está aqui.**
> O endereço precisa incluir **`https://`**. Sem isso o Supabase trata o valor
> como um caminho interno e o link do e-mail volta com
> `{"error": "requested path is invalid"}`.

**No Supabase → Authentication → URL Configuration:**

| Campo | Valor |
|---|---|
| **Site URL** | `https://planner-semanal-sand.vercel.app` |
| **Redirect URLs** → *Add URL* | `https://planner-semanal-sand.vercel.app` |

Errado × certo:

```
✗  planner-semanal-sand.vercel.app          (vira caminho dentro do Supabase)
✗  https://planner-semanal-sand.vercel.app/ (a barra final às vezes atrapalha)
✓  https://planner-semanal-sand.vercel.app
```

**Como saber o endereço exato:** abra o app publicado, clique no botão
**Conectar** da barra superior. A janela mostra o endereço correto num quadro,
com botão de **copiar**. É exatamente esse que deve ir nos dois campos.

Depois de salvar, **peça um link novo** — o anterior fica inválido.

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

### 2.3 Se a Vercel recusar o deploy

Mensagem: *"the commit author did not have contributing access… Hobby Plan does
not support collaboration for private repositories"*.

**O que aconteceu:** o e-mail que assinou o commit não é o da sua conta do
GitHub. No plano gratuito, a Vercel só constrói commits do próprio dono quando
o repositório é privado.

Duas saídas — a primeira é a recomendada.

#### Saída 1 — acertar o e-mail do commit *(mantém o repositório privado)*

1. Abra **github.com/settings/emails**
2. Copie o e-mail marcado como **Primary**
   - Se estiver ligado *"Keep my email addresses private"*, copie o endereço no
     formato `12345678+Felipendev@users.noreply.github.com` que aparece ali
3. Duplo clique em **`corrigir-autor.bat`**
4. Cole o e-mail quando ele pedir

O script reescreve o autor do commit e reenvia. A Vercel dispara um build novo
sozinha em seguida.

#### Saída 2 — tornar o repositório público

O código não guarda segredo nenhum: a URL e a chave do Supabase são digitadas
por você no app e ficam no seu navegador, nunca no repositório. Seus dados
pessoais estão fora pelo `.gitignore`.

1. **github.com/Felipendev/planner-semanal** → *Settings*
2. Role até **Danger Zone** → *Change repository visibility* → **Public**

A restrição da Vercel some, porque ela vale só para repositórios privados.

> Preferi a Saída 1 no guia porque não há razão para expor o repositório —
> mas a Saída 2 é segura e resolve em 30 segundos.

### 2.4 Voltar ao Supabase
**Copie a URL da Vercel e volte ao passo 1.4** para autorizá-la em
*Authentication → URL Configuration*. Sem isso o login não conclui.

### 2.5 Publicar alterações depois
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

Digite seu e-mail e clique em **Enviar acesso por e-mail**. Você recebe uma
mensagem com **duas formas** de entrar:

**a) Clicar no link** — abre o app já autenticado.

**b) Código de 6 dígitos** — copie o código do e-mail, cole no segundo campo da
janela e clique em **Entrar**.

> O código existe por um motivo prático: alguns servidores de e-mail
> *pré-visitam* os links das mensagens por segurança, e como o link do Supabase
> é de uso único, ele já chega gasto. Quando isso acontece você vê
> `otp_expired` mesmo tendo acabado de recebê-lo. O código não tem esse problema.
>
> Se o seu e-mail só mostrar o link e não o código, dá para incluí-lo:
> **Supabase → Authentication → Emails → Magic Link**, e acrescente
> `{{ .Token }}` ao corpo da mensagem.

Ambos valem por **1 hora** e só podem ser usados **uma vez**.

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

## Parte 3.6 — Deixar todo aparelho já configurado *(recomendado)*

Por padrão, cada navegador guarda a URL e a chave separadamente — ou seja, você
teria que digitar aquela chave enorme no celular também. Duas formas de evitar.

### Forma 1 — link pronto *(imediato, sem publicar nada)*

No computador já conectado: **Nuvem → Configurar outro aparelho → Copiar link**.

Mande esse link para você mesmo por WhatsApp e abra no celular. Ele chega
configurado; só falta entrar com o e-mail.

> O link carrega a chave pública — a mesma que já está dentro do site. Sem
> login ele não abre dado nenhum.

### Forma 2 — embutir no site *(definitivo)*

Abra **`web/config.js`** e preencha com os mesmos dois valores do passo 1.5:

```js
window.PLANNER_CFG = {
  url: "https://smhpomzcsucyriacmncz.supabase.co",
  key: "sb_publishable_..."
};
```

Rode o **`atualizar.bat`**. A partir daí, **qualquer aparelho que abrir o site
já vem configurado** — inclusive um celular novo, ou o navegador de outra
pessoa. Basta fazer login.

É assim que a maioria dos aplicativos Supabase funciona: a chave pública vive
dentro do código. A segurança está na política do banco, não no segredo da chave.

---

## Parte 4 — Instalar no celular

1. Abra a URL no **Chrome do Android** (ou Safari no iPhone)
2. Menu → **Adicionar à tela de início**
3. Abre em tela cheia, com ícone próprio, e funciona sem internet
4. Toque no botão **Conectar** e entre com o mesmo e-mail do computador

No computador, o Chrome mostra um ícone de instalar na barra de endereço.

### Se o celular estiver com uma versão antiga

O app guarda uma cópia local para funcionar offline, e às vezes ela demora a
ser trocada. Duas formas de forçar:

**Pelo próprio app:** botão **Nuvem** → **Buscar atualização**. Ele limpa a
cópia guardada e recarrega. A janela mostra a **versão instalada** naquele
aparelho — dá para comparar com a do computador.

**Na mão:** Chrome do Android → ⋮ → *Configurações do site* → *Limpar dados*,
ou desinstalar e reinstalar o atalho.

> Quando você publica uma versão nova, os aparelhos que já estiverem abertos
> recebem um aviso: *"Versão nova disponível. Clique para atualizar"*.

### Quando os dados aparecem no outro aparelho

O envio é **automático**, cerca de 2 segundos depois de qualquer alteração.
Você não precisa salvar nada.

A busca acontece:
- ao abrir o app
- **ao voltar para ele** (trocar de aba, desbloquear o celular)
- a cada minuto com o app aberto
- ao recuperar a conexão

Se quiser forçar: **Nuvem → Sincronizar agora**.

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
| `requested path is invalid` | O **Site URL** foi salvo sem `https://` — passo 1.4 |
| `otp_expired` logo após receber | O link foi consumido pelo antivírus do e-mail. Use o **código de 6 dígitos** |
| Botão da nuvem vermelho | Chave errada, ou o `schema.sql` não foi executado |
| Dados não aparecem no outro aparelho | Você entrou com contas Google diferentes |
| Notificação não aparece | Assistente de Foco do Windows, ou permissão negada no navegador |
| App não atualiza após deploy | **Nuvem → Buscar atualização**, ou `Ctrl+Shift+R` no computador |
| Celular com versão diferente do PC | Compare em **Nuvem → Versão instalada aqui** e use *Buscar atualização* |
| Marcou no PC e não aparece no celular | Volte ao app no celular (ele busca ao ganhar foco) ou use *Sincronizar agora* |
| Celular pede URL e chave de novo | Normal: a configuração é por navegador. Use *Configurar outro aparelho* ou preencha `web/config.js` |
| Vercel recusa: *commit author did not have contributing access* | E-mail do commit diferente do GitHub — rode `corrigir-autor.bat` (passo 2.3) |
