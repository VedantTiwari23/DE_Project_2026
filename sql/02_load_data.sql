-- =====================================================================
-- Netflix DBMS Project: Seed Data Loading Script (CP1)
-- Phase 2: \copy statements in dependency order
-- =====================================================================

SET search_path TO netflix;

-- 1. Plans (independent)
\copy plans FROM 'seed_data/plans.csv' WITH (FORMAT csv, HEADER true)

-- 2. Accounts (references plans)
\copy accounts FROM 'seed_data/accounts.csv' WITH (FORMAT csv, HEADER true)

-- 3. Profiles (references accounts)
\copy profiles FROM 'seed_data/profiles.csv' WITH (FORMAT csv, HEADER true)

-- 4. Genres (independent)
\copy genres FROM 'seed_data/genres.csv' WITH (FORMAT csv, HEADER true)

-- 5. Titles (independent)
\copy titles FROM 'seed_data/titles.csv' WITH (FORMAT csv, HEADER true)

-- 6. Title Genres (references titles, genres)
\copy title_genres FROM 'seed_data/title_genres.csv' WITH (FORMAT csv, HEADER true)

-- 7. Episodes (references titles)
\copy episodes FROM 'seed_data/episodes.csv' WITH (FORMAT csv, HEADER true)

-- 8. Viewing Activity (references profiles, titles, episodes)
\copy viewing_activity FROM 'seed_data/viewing_activity.csv' WITH (FORMAT csv, HEADER true)

-- 9. Ratings (references profiles, titles)
\copy ratings FROM 'seed_data/ratings.csv' WITH (FORMAT csv, HEADER true)

-- 10. My List (references profiles, titles)
\copy my_list FROM 'seed_data/my_list.csv' WITH (FORMAT csv, HEADER true)

-- 11. Invoices (references accounts)
\copy invoices FROM 'seed_data/invoices.csv' WITH (FORMAT csv, HEADER true)

-- Update statistics for query planner
ANALYZE;
