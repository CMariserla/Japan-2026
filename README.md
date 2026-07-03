# Japan 2026 Itinerary

A shared trip planner for 5 people — calendar of days, activities, stays, suggestions, and a journal. Single static `index.html`, no build step, backed by [Supabase](https://supabase.com) for auth and data.

## Stack

- Vanilla JS + `supabase-js` (loaded via CDN, no bundler)
- Supabase Postgres for data, Supabase Auth for login
- Deployed as a static site (Vercel)

## Supabase setup (one-time)

1. Create a Supabase project.
2. Run [`supabase/schema.sql`](supabase/schema.sql) in the SQL Editor. This creates the `profiles`, `days`, `activities`, `stays`, `suggestions`, `journal`, and `activity_log` tables, their RLS policies, and a trigger that turns a new `auth.users` row into a `profiles` row.
3. In **Authentication → Providers → Email**, turn off **Confirm email** (accounts use internal placeholder addresses like `username@japan2026trip.app`, not real inboxes) and turn off public sign-ups once the 5 accounts below exist.
4. Create one auth account per trip member via the sign-up endpoint, passing `username`, `display_name`, and `is_admin` in the `data` field so the trigger populates `profiles` correctly. Exactly one account should have `is_admin: true` — that person sees the Activity Log view in the app.
5. Update `SUPABASE_URL` / `SUPABASE_ANON_KEY` near the top of `index.html` if you point this at a different project.

## Local preview

Any static file server works, e.g. `python3 -m http.server` from this directory, then open `index.html`.
