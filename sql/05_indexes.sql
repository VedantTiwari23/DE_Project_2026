-- Phase 4: Index definitions
-- Applied to database netflix_db

SET search_path TO netflix;

-- Required for R05 wildcard ILIKE '%love%' search
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- R01: Continue watching row. Partial index because we only care about unfinished streams
CREATE INDEX idx_viewing_unfinished 
ON viewing_activity (profile_id, title_id, started_at DESC) 
INCLUDE (episode_id, duration_watched_sec)
WHERE NOT completed;

-- R03, R09, R18: Date range filters on viewing_activity. Covering index to avoid heap lookups
CREATE INDEX idx_viewing_started_covering 
ON viewing_activity (started_at) 
INCLUDE (title_id, profile_id, device_type, duration_watched_sec, completed);

-- R19, R09: Foreign key lookup from titles to viewing activity for view counts and aggregates
CREATE INDEX idx_viewing_title_started 
ON viewing_activity (title_id, started_at);

-- R13: Anti-join index to quickly check if an episode was ever watched
CREATE INDEX idx_viewing_episodes_watched 
ON viewing_activity (episode_id) 
WHERE episode_id IS NOT NULL;

-- R14, R16: Profile-based viewing timeline lookups
CREATE INDEX idx_viewing_profile_timeline 
ON viewing_activity (profile_id, started_at DESC) 
INCLUDE (title_id);

-- R23: Deep pagination on recent activity (ORDER BY started_at DESC OFFSET ...)
CREATE INDEX idx_viewing_started_desc 
ON viewing_activity (started_at DESC) 
INCLUDE (view_id, profile_id, title_id, episode_id);

-- R10: Sign in query matches case-insensitively using lower(email)
CREATE INDEX idx_accounts_email_lower 
ON accounts (lower(email)) 
INCLUDE (account_id, plan_id, status);

-- R15, W04: Revenue report and monthly billing only process active accounts
CREATE INDEX idx_accounts_active_plan 
ON accounts (plan_id) 
WHERE status = 'ACTIVE';

-- R12: Retention report looks up cancelled accounts by cancellation date
CREATE INDEX idx_accounts_cancelled 
ON accounts (cancelled_on, signup_date) 
WHERE status = 'CANCELLED';

-- R21: Dunning query checks accounts on hold with overdue billing date
CREATE INDEX idx_accounts_on_hold 
ON accounts (next_billing_date) 
INCLUDE (account_id, email) 
WHERE status = 'ON_HOLD';

-- R05: Trigram GIN index for substring search on title names
CREATE INDEX idx_titles_name_trgm 
ON titles USING gin (name gin_trgm_ops);

-- R04: Filter kids comedy titles by maturity rating and sort by newest additions
CREATE INDEX idx_titles_maturity_added 
ON titles (maturity_rating, added_on DESC) 
INCLUDE (name, title_type);

-- R22: Last chance to watch queries titles leaving soon
CREATE INDEX idx_titles_leaving 
ON titles (leaving_on) 
INCLUDE (title_id, name) 
WHERE leaving_on IS NOT NULL;

-- R19: Filter for Netflix originals in catalogue
CREATE INDEX idx_titles_originals 
ON titles (title_id, name) 
WHERE is_netflix_original;

-- R04, R09, R25: Reverse lookup from genre to titles (PK only indexes title_id -> genre_id)
CREATE INDEX idx_title_genres_genre 
ON title_genres (genre_id, title_id);

-- R06: Fetch My List for a specific profile sorted by recently added
CREATE INDEX idx_my_list_profile 
ON my_list (profile_id, added_at DESC) 
INCLUDE (title_id);

-- R20: Monthly top added titles in My List
CREATE INDEX idx_my_list_added 
ON my_list (added_at, title_id);

-- R17: Aggregate ratings per title for originals vs licensed
CREATE INDEX idx_ratings_title 
ON ratings (title_id, rating);

-- R11, W05: Failed invoice retry queue and dunning updates
CREATE INDEX idx_invoices_failed 
ON invoices (billing_period_start, account_id) 
INCLUDE (amount_inr) 
WHERE status = 'FAILED';

-- R24, R16: Profile lookups by account
CREATE INDEX idx_profiles_account 
ON profiles (account_id, created_at) 
INCLUDE (profile_id, profile_name, is_kids, maturity_limit);

-- R14: Compliance query only scans kids profiles
CREATE INDEX idx_profiles_kids 
ON profiles (profile_id, maturity_limit) 
WHERE is_kids;

ANALYZE;
