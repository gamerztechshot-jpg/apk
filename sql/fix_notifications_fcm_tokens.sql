-- Fix: ensure fcm_tokens is never NULL when no token row exists
begin;

create or replace function public.fetch_fcm_tokens(p_user_id uuid, p_app text)
returns text[]
language sql
stable
as $$
  select coalesce(
    (
      select fcm_tokens
      from public.user_fcm_tokens
      where user_id = p_user_id and app = p_app
    ),
    '{}'::text[]
  )
$$;

create or replace function public.insert_notification(
  p_user_id uuid,
  p_role text,
  p_app text,
  p_title text,
  p_body text,
  p_data jsonb default '{}'::jsonb,
  p_entity_type text default null,
  p_entity_id text default null
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tokens text[];
begin
  v_tokens := coalesce(public.fetch_fcm_tokens(p_user_id, p_app), '{}'::text[]);

  insert into public.notifications (
    recipient_user_id, recipient_role, app,
    title, body, data, entity_type, entity_id, fcm_tokens
  ) values (
    p_user_id, p_role, p_app,
    p_title, p_body, p_data, p_entity_type, p_entity_id, v_tokens
  );
end;
$$;

commit;
