# Planner — Especificação de Execução

**Versão:** 2.0 · **Data:** 07/08/2026
**Estado atual:** aplicação single-file funcional, em uso diário desde 03/08/2026
**Objetivo desta versão:** colocar no ar e transformar o planner em um assistente que conversa

---

## 1. Onde estamos

O `planner-semanal.html` já resolve o problema central: tornar visível o tempo investido
e impedir que 180 dias passem sem deixar rastro. Ele tem calendário com validação de
realismo, planos A/B/C, pomodoro, dieta, compras, Protocolo 180 e detecção de padrões.

O que falta não é funcionalidade. É **estar acessível de qualquer lugar** e **deixar de
ser passivo**. Hoje o sistema espera ser consultado. Ele precisa começar a falar.

### 1.1 Princípios que não se negociam

| # | Princípio | Consequência prática |
|---|-----------|----------------------|
| P1 | O histórico é imutável | Nenhuma migração pode reescrever horas já registradas |
| P2 | Um dia ruim ainda conta | Nada que introduza tudo-ou-nada |
| P3 | A agenda tem que caber no dia | Toda mudança passa pelo validador de realismo |
| P4 | O sono é a última coisa a ceder | Nenhum replanejamento come as 8h |
| P5 | O assistente propõe, nunca impõe | Toda sugestão exige um aceite explícito |
| P6 | Silêncio é pior que atrito | Dado faltando gera cobrança visível |

---

## 2. Épico A — Hospedagem

**Por quê:** você depende do notebook. O celular é onde a vida acontece.

### A1 · Publicar como site estático
- **Como** Felipe, **quero** abrir o planner por um endereço na web, **para** usá-lo no celular.
- **Cenário feliz**
  - **Dado** que o `planner-semanal.html` está no repositório
  - **Quando** o deploy na Vercel conclui
  - **Então** o app abre em `https://<dominio>` idêntico ao local
- **Cenário file:// resolvido**
  - **Dado** que hoje o navegador bloqueia gravação em arquivo por causa do `file://`
  - **Quando** o app roda sob `https://`
  - **Então** a File System Access API funciona e o salvamento automático deixa de depender de gambiarra
- **Critérios:** Lighthouse ≥ 90 · abre em ≤ 2s em 4G · nenhum recurso externo além de fontes do sistema

### A2 · Instalar como aplicativo (PWA)
- **Dado** que abri o site no celular
- **Quando** escolho "Adicionar à tela de início"
- **Então** ele abre em tela cheia, sem barra de navegador, com ícone próprio
- **E** funciona offline com os dados já carregados
- **Critérios:** manifest + service worker · testado em Android e iOS · ícone 512px

### A3 · Dados na nuvem (Supabase)
- **Dado** que marco uma atividade no celular
- **Quando** abro o notebook em seguida
- **Então** a marcação já está lá
- **Cenário sem internet**
  - **Dado** que estou na praia sem sinal
  - **Quando** marco o surf como concluído e registro páginas
  - **Então** tudo é gravado localmente e sobe sozinho quando a conexão volta
- **Cenário conflito**
  - **Dado** que marquei a mesma atividade no celular e no notebook
  - **Então** a união prevalece; marcar duas vezes não desmarca
- **Critérios:** RLS ativa em todas as tabelas · nenhuma linha de outro usuário acessível ·
  outbox sobrevive a fechar o app · migração do JSON atual sem perder uma hora sequer (P1)

### A4 · Cron diário
- **Dado** que o projeto Supabase gratuito pausa após 7 dias sem atividade
- **Quando** o cron da Vercel roda de madrugada
- **Então** o banco recebe um toque e nunca hiberna

---

## 3. Épico B — O assistente que conversa

**Por quê:** você pediu um sistema que faça perguntas e traga ideias. Um painel que só
mostra números vira paisagem em três semanas. Um sistema que pergunta continua vivo.

### 3.1 Regras de conduta do assistente

| # | Regra |
|---|-------|
| B-R1 | Fala no máximo **uma vez por dia**, salvo cobrança de dado faltando |
| B-R2 | Toda fala traz **evidência** ("nos últimos 14 dias…"), nunca palpite |
| B-R3 | Toda fala termina em **uma pergunta ou uma ação de um clique** |
| B-R4 | Nunca altera nada sozinho — proposta aceita explicitamente (P5) |
| B-R5 | Não elogia sem motivo. Reconhecimento vale quando é raro |
| B-R6 | Não moraliza. Aponta o dado e devolve a decisão |
| B-R7 | Respeita o Sábado: nada de cobrança entre sexta 18h e sábado 18h |

### B1 · Revisão semanal *(domingo, no bloco "Planejar a semana")*
- **Dado** que é domingo e existe pelo menos uma semana de registro
- **Quando** abro o planner
- **Então** o assistente abre um resumo curto: o que subiu, o que caiu, e **uma pergunta**
- **Exemplo:** *"Treino fechou 92% e leitura 41%. A leitura só falha nos blocos da manhã.
  Quer testar movê-la para a noite por 7 dias?"* → `[Testar] [Deixar como está]`

### B2 · Checkpoint de 30 dias *(dias 30, 60, 90, 120, 150, 180)*
- **Dado** que fecho um bloco de 30 dias do protocolo
- **Então** o assistente mostra o bloco inteiro e projeta o próximo
- **E** pergunta se alguma meta mudou de prioridade
- **Exemplo:** *"Primeiro terço fechado: 23 de 30 dias cumpridos, 64h investidas.
  No ritmo atual você chega ao dia 180 com 380h. Alguma área deveria pesar mais no próximo bloco?"*

### B3 · A parede das três semanas
- **Dado** que estou entre os dias 18 e 25 do protocolo
- **E** minha taxa dos últimos 5 dias caiu mais de 20 pontos em relação aos 10 anteriores
- **Então** o assistente nomeia o fenômeno em vez de cobrar
- **Exemplo:** *"Essa queda costuma chegar por volta da terceira semana — é o ponto onde
  a maioria abandona. Você não precisa do plano A agora. Quer rodar uma semana no plano B?"*

### B4 · Excesso de plano mínimo
- **Dado** que usei o plano C em 4 dos últimos 7 dias
- **Então** o assistente pergunta se é fase ou se o plano A está grande demais
- **E** oferece rebaixar permanentemente atividades de nível Completo

### B5 · Dado faltando
- **Dado** que faz 3 dias que não registro páginas, **e** o livro está ativo
- **Então** o assistente pergunta: *"O livro travou, ou o horário da leitura não está funcionando?"*
- **Ações:** `[Registrar agora] [Mudar o horário] [Trocar de livro]`
- **Mesma regra** para água abaixo de 50% da meta por 3 dias seguidos

### B6 · Meta sem número
- **Dado** que uma meta financeira está sem custo ou sem data há mais de 7 dias
- **Então** o assistente cobra: *"México ainda está sem valor. Sem ele eu não consigo te dizer
  quanto guardar por mês — e a meta continua sendo desejo, não plano."*

### B7 · Ideias que ele traz sozinho *(máx. 1 por semana)*
- Sugerir **desafio** puxado do padrão real: *"Você não treina na sexta há 4 semanas.
  Que tal '4 sextas seguidas treinando' como próximo desafio?"*
- Sugerir **novo livro** quando faltam ≤ 20 páginas
- Sugerir **encolher meta semanal** de uma área cumprida abaixo de 50% por 3 semanas
- Sugerir **subir a meta** de uma área acima de 120% por 3 semanas
- Lembrar de **gravar vídeo** quando um marco é batido

### B8 · Diálogo de viagem / imprevisto
- **Dado** que marco 3+ dias seguidos como folga
- **Então** o assistente pergunta se é viagem
- **E** se sim, recalcula o impacto no Protocolo 180 e mostra a nova data de chegada de cada meta

---

## 4. Épico C — Ajustes fechados nesta versão

Todos implementados e testados. Ficam registrados como referência de comportamento.

| ID | Comportamento | Verificação |
|----|---------------|-------------|
| C1 | Rótulo de leitura explica o número acumulado, os dias de registro e a média | ✅ |
| C2 | Protocolo 180 compacto no topo do Início, com atalho para a tela cheia | ✅ |
| C3 | Projeção do 180 com coluna "Diferença" em vez de barra ambígua | ✅ |
| C4 | Gráficos por horário usam o horário **efetivo** do bloco, com o que foi movido | ✅ |
| C5 | Detecção de padrões por área × faixa horária e área × dia da semana | ✅ |
| C6 | Semana de teste: aplica, mede, e devolve manter/voltar | ✅ |
| C7 | Countdown circular do desafio no Início; ausência de desafio é cobrada | ✅ |
| C8 | Faixa de cobrança quando faltam ≤ 20 páginas para fechar o livro | ✅ |
| C9 | Frase do dia em destaque âmbar | ✅ |
| C10 | "Comecei tarde": replaneja o dia, respeita fixos e protege o sono (P4) | ✅ |
| C11 | Semana com 78px por hora, blocos legíveis | ✅ |

### C10 em detalhe — cenários testados
- **30 min de atraso** → tudo cabe, termina 16:58
- **1h30 de atraso** → tudo cabe, sobra 2h16 antes de dormir
- **4h de atraso** → plano A não cabe; sistema propõe cortar nível Completo
- **5h de atraso** → propõe plano mínimo, **cortando 5 atividades e nenhuma essencial**
- **Sempre** → compromissos fixos não são atropelados (0 sobreposições geradas)

---

## 5. Ordem de execução

| Fase | Entrega | Pronto quando |
|------|---------|---------------|
| **F1** | A1 + A2 — site no ar e instalável | Abre no celular em tela cheia |
| **F2** | A3 — Supabase, auth e sync offline-first | Marca na praia, aparece no notebook |
| **F3** | A4 + importação do JSON atual | Nenhuma hora perdida na migração |
| **F4** | B1 + B5 + B6 — o assistente começa a falar | Uma fala útil por semana, com evidência |
| **F5** | B2 + B3 + B4 — os diálogos de risco | Intervenção na parede das 3 semanas |
| **F6** | B7 + B8 — ideias e viagem | Uma sugestão por semana, aceita ou recusada |

F1 é independente e entrega valor sozinha. F4 pode rodar sem F2 (o assistente lê dados locais).

---

## 6. Em aberto

1. **"A cada mês…"** — sua mensagem cortou nessa frase. O que acontece a cada mês?
   Meu palpite é o checkpoint de 30 dias (B2), mas confirme.
2. **Domínio próprio** — vale ~R$40/ano e faz diferença no celular. Quer?
3. **Notificações push** — o aviso de 10 min antes hoje só funciona com o app aberto.
   Push real exige service worker + permissão. Vale depois de F2.
