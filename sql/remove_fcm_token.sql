-- Remove a specific FCM token for the current user and app
begin;

create or replace function public.remove_fcm_token(p_app text, p_token text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_existing text[];
  v_filtered text[];
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    return false;
  end if;
  if p_token is null or length(trim(p_token)) = 0 then
    return false;
  end if;
  if p_app not in ('user','pat','admin') then
    return false;
  end if;

  select fcm_tokens into v_existing
  from public.user_fcm_tokens
  where user_id = v_user_id and app = p_app;

  if v_existing is null then
    return true;
  end if;

  select array_agg(t) into v_filtered
  from unnest(v_existing) as t
  where t is not null and t <> p_token;

  update public.user_fcm_tokens
  set fcm_tokens = coalesce(v_filtered, '{}'::text[]),
      updated_at = now()
  where user_id = v_user_id and app = p_app;

  return true;
end;
$$;

revoke all on function public.remove_fcm_token(text, text) from public;
grant execute on function public.remove_fcm_token(text, text) to authenticated, service_role;

commit;
