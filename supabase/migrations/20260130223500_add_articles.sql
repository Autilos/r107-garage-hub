-- Create articles table
create table if not exists articles (
  id uuid default gen_random_uuid() primary key,
  slug text not null unique,
  title text not null,
  description text,
  content text,
  image_url text,
  seo_title text,
  seo_description text,
  is_published boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Add RLS policies
alter table articles enable row level security;

-- Grant access to the table
grant select on table articles to anon, authenticated;
grant insert, update, delete on table articles to service_role;

create policy "Articles are viewable by everyone if published"
  on articles for select
  using (is_published = true or (auth.jwt() ->> 'email') in (select email from auth.users where is_admin(auth.uid())));

create policy "Articles are insertable by admins only"
  on articles for insert
  with check (is_admin(auth.uid()));

create policy "Articles are updatable by admins only"
  on articles for update
  using (is_admin(auth.uid()));

create policy "Articles are deletable by admins only"
  on articles for delete
  using (is_admin(auth.uid()));

-- Add initial content
insert into articles (slug, title, description, content, seo_title, seo_description, is_published, image_url)
values (
  'historia-mercedes-r107-c107',
  'Pancerna elegancja – Historia Mercedes R107 i C107',
  'Jak Mercedes R107 i C107 zdefiniowały luksus na dwie dekady. Poznaj historię ikony lat 70. i 80.',
  '... pełna treść artykułu ...',
  'Pancerna elegancja – Historia Mercedes R107 i C107',
  'Jak Mercedes R107 i C107 zdefiniowały luksus na dwie dekady. Poznaj historię ikony lat 70. i 80.',
  true,
  '/images/pancerna-elegancja.png'
);