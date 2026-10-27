-- 효투의 돈달력 / Supabase SQL Editor에서 실행
-- 1) 아래 이메일을 실제 로그인할 Google 이메일로 바꾼 뒤 전체 실행.
-- 2) Authentication > Providers > Google 설정은 별도로 필요합니다.
begin;
create table if not exists public.ledger_allowed_users (
  email text primary key check(email=lower(email))
);
alter table public.ledger_allowed_users enable row level security;
revoke all on public.ledger_allowed_users from anon, authenticated;
grant select on public.ledger_allowed_users to authenticated;
drop policy if exists "read own allowlist" on public.ledger_allowed_users;
create policy "read own allowlist" on public.ledger_allowed_users for select to authenticated
using (email=lower(auth.jwt()->>'email'));
-- ★ 이 한 줄의 이메일을 바꾸세요. 비밀번호나 Google Client Secret은 넣지 마세요.
insert into public.ledger_allowed_users(email) values (lower('YOUR_GOOGLE_EMAIL@gmail.com'))
on conflict(email) do nothing;

create table if not exists public.ledger_documents (
  owner_id uuid primary key references auth.users(id) on delete cascade,
  payload jsonb not null,
  revision bigint not null default 1 check(revision>0),
  updated_at timestamptz not null default now(),
  constraint ledger_schema check(coalesce(jsonb_typeof(payload)='object' and payload->>'schema'='1'
    and jsonb_typeof(payload->'entries')='array' and jsonb_typeof(payload->'categories')='array'
    and jsonb_typeof(payload->'repeats')='array' and jsonb_typeof(payload->'reviewedPeriods')='array'
    and octet_length(payload::text)<=30000000,false))
);
alter table public.ledger_documents enable row level security;
revoke all on public.ledger_documents from anon,authenticated;
grant select,insert,update on public.ledger_documents to authenticated;
drop policy if exists "owner reads ledger" on public.ledger_documents;
drop policy if exists "owner creates ledger" on public.ledger_documents;
drop policy if exists "owner updates ledger" on public.ledger_documents;
create policy "owner reads ledger" on public.ledger_documents for select to authenticated
using (owner_id=auth.uid() and exists(select 1 from public.ledger_allowed_users where email=lower(auth.jwt()->>'email')));
create policy "owner creates ledger" on public.ledger_documents for insert to authenticated
with check (owner_id=auth.uid() and exists(select 1 from public.ledger_allowed_users where email=lower(auth.jwt()->>'email')));
create policy "owner updates ledger" on public.ledger_documents for update to authenticated
using (owner_id=auth.uid() and exists(select 1 from public.ledger_allowed_users where email=lower(auth.jwt()->>'email')))
with check (owner_id=auth.uid() and exists(select 1 from public.ledger_allowed_users where email=lower(auth.jwt()->>'email')));

create or replace function public.save_ledger(expected_revision bigint,new_payload jsonb)
returns bigint language plpgsql security invoker set search_path=public as $$
declare result_revision bigint;
begin
 if auth.uid() is null or not exists(select 1 from public.ledger_allowed_users where email=lower(auth.jwt()->>'email')) then
  raise exception '이 계정은 허용되지 않았어요. setup.sql의 로그인 이메일을 확인해 주세요.';
 end if;
 if expected_revision=0 then
  insert into public.ledger_documents(owner_id,payload,revision) values(auth.uid(),new_payload,1)
  on conflict(owner_id) do nothing returning revision into result_revision;
 else
  update public.ledger_documents set payload=new_payload,revision=revision+1,updated_at=now()
  where owner_id=auth.uid() and revision=expected_revision returning revision into result_revision;
 end if;
 if result_revision is null then raise exception 'revision_conflict';end if;
 return result_revision;
end $$;
revoke all on function public.save_ledger(bigint,jsonb) from public,anon;
grant execute on function public.save_ledger(bigint,jsonb) to authenticated;
commit;
