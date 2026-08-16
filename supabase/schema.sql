-- ═══════════════════════════════════════════════════════════
-- Planner — esquema mínimo
--
-- Um documento JSON por usuário. Toda a agregação acontece no
-- cliente sobre ~20 KB, então um schema relacional não traria
-- ganho: traria manutenção. Se um dia precisar de consulta no
-- servidor, dá para normalizar sem perder o histórico.
-- ═══════════════════════════════════════════════════════════

create table if not exists public.estado (
  user_id       uuid primary key references auth.users(id) on delete cascade,
  dados         jsonb       not null default '{}'::jsonb,
  atualizado_em timestamptz not null default now()
);

alter table public.estado enable row level security;

-- Cada um enxerga e escreve apenas a própria linha.
drop policy if exists "estado proprio" on public.estado;
create policy "estado proprio" on public.estado
  for all
  using      (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Carimbo de atualização sempre pelo servidor, nunca pelo cliente:
-- relógio de aparelho não é confiável para resolver conflito.
create or replace function public.touch_estado()
returns trigger language plpgsql as $$
begin
  new.atualizado_em = now();
  return new;
end $$;

drop trigger if exists t_touch_estado on public.estado;
create trigger t_touch_estado
  before insert or update on public.estado
  for each row execute function public.touch_estado();

-- Rede de segurança: guarda as últimas versões antes de cada
-- gravação, para o caso de um merge ruim apagar algo.
create table if not exists public.estado_historico (
  id            bigserial primary key,
  user_id       uuid        not null references auth.users(id) on delete cascade,
  dados         jsonb       not null,
  gravado_em    timestamptz not null default now()
);
alter table public.estado_historico enable row level security;
drop policy if exists "historico proprio" on public.estado_historico;
create policy "historico proprio" on public.estado_historico
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create index if not exists estado_hist_user_idx
  on public.estado_historico (user_id, gravado_em desc);

create or replace function public.arquiva_estado()
returns trigger language plpgsql as $$
begin
  if TG_OP = 'UPDATE' and old.dados is distinct from new.dados then
    insert into public.estado_historico (user_id, dados) values (old.user_id, old.dados);
    -- mantém as 30 versões mais recentes
    delete from public.estado_historico
     where user_id = old.user_id
       and id not in (
         select id from public.estado_historico
          where user_id = old.user_id
          order by gravado_em desc
          limit 30);
  end if;
  return new;
end $$;

drop trigger if exists t_arquiva_estado on public.estado;
create trigger t_arquiva_estado
  before update on public.estado
  for each row execute function public.arquiva_estado();
