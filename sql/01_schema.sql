-- =====================================================================
-- Netflix Movie & Series Streaming Database
-- Phase 2: Schema definition (sql/01_schema.sql)
-- Target: PostgreSQL 15+
-- =====================================================================

DROP SCHEMA IF EXISTS netflix CASCADE;
CREATE SCHEMA netflix;
SET search_path TO netflix;

-- 1. Subscription Plans
CREATE TABLE plans (
    plan_id             INTEGER PRIMARY KEY,
    plan_name           VARCHAR(50) NOT NULL UNIQUE CHECK (plan_name IN ('MOBILE', 'BASIC', 'STANDARD', 'PREMIUM')),
    monthly_price_inr   NUMERIC(8, 2) NOT NULL CHECK (monthly_price_inr >= 0),
    max_streams         INTEGER NOT NULL CHECK (max_streams > 0),
    max_resolution      VARCHAR(10) NOT NULL CHECK (max_resolution IN ('480p', '720p', '1080p', '4K')),
    has_ads             BOOLEAN NOT NULL DEFAULT FALSE
);

-- 2. Customer Accounts
CREATE TABLE accounts (
    account_id          INTEGER PRIMARY KEY,
    email               VARCHAR(255) NOT NULL UNIQUE,
    phone               VARCHAR(20),
    country_code        VARCHAR(10) NOT NULL,
    plan_id             INTEGER NOT NULL REFERENCES plans(plan_id) ON DELETE RESTRICT,
    signup_date         DATE NOT NULL,
    status              VARCHAR(20) NOT NULL CHECK (status IN ('ACTIVE', 'CANCELLED', 'ON_HOLD')),
    cancelled_on        DATE,
    next_billing_date   DATE,
    CONSTRAINT chk_account_cancellation CHECK (status <> 'CANCELLED' OR cancelled_on IS NOT NULL),
    CONSTRAINT chk_account_cancel_after_signup CHECK (cancelled_on IS NULL OR cancelled_on >= signup_date),
    CONSTRAINT chk_account_billing_after_signup CHECK (next_billing_date IS NULL OR next_billing_date >= signup_date)
);

-- 3. Profiles per Account
CREATE TABLE profiles (
    profile_id          INTEGER PRIMARY KEY,
    account_id          INTEGER NOT NULL REFERENCES accounts(account_id) ON DELETE CASCADE,
    profile_name        VARCHAR(100) NOT NULL,
    is_kids             BOOLEAN NOT NULL DEFAULT FALSE,
    maturity_limit      VARCHAR(10) NOT NULL CHECK (maturity_limit IN ('U', 'UA7', 'UA13', 'UA16', 'A')),
    language            VARCHAR(50) NOT NULL DEFAULT 'English',
    created_at          TIMESTAMPTZ NOT NULL,
    CONSTRAINT chk_profile_kids_limit CHECK (NOT is_kids OR maturity_limit IN ('U', 'UA7'))
);

-- 4. Genres
CREATE TABLE genres (
    genre_id            INTEGER PRIMARY KEY,
    genre_name          VARCHAR(50) NOT NULL UNIQUE CHECK (length(trim(genre_name)) > 0)
);

-- 5. Titles (Movies & Series)
CREATE TABLE titles (
    title_id            INTEGER PRIMARY KEY,
    title_type          VARCHAR(10) NOT NULL CHECK (title_type IN ('MOVIE', 'SERIES')),
    name                VARCHAR(255) NOT NULL,
    release_year        INTEGER NOT NULL CHECK (release_year BETWEEN 1900 AND 2100),
    maturity_rating     VARCHAR(10) NOT NULL CHECK (maturity_rating IN ('U', 'UA7', 'UA13', 'UA16', 'A')),
    original_language   VARCHAR(50) NOT NULL,
    runtime_min         INTEGER,
    is_netflix_original BOOLEAN NOT NULL DEFAULT FALSE,
    added_on            DATE NOT NULL,
    leaving_on          DATE,
    CONSTRAINT chk_title_runtime_by_type CHECK (
        (title_type = 'MOVIE' AND runtime_min IS NOT NULL AND runtime_min > 0) OR
        (title_type = 'SERIES' AND runtime_min IS NULL)
    ),
    CONSTRAINT chk_title_original_never_leaves CHECK (NOT is_netflix_original OR leaving_on IS NULL),
    CONSTRAINT chk_title_leaving_after_added CHECK (leaving_on IS NULL OR leaving_on >= added_on)
);

-- 6. Title Genres (Many-to-Many Bridge)
CREATE TABLE title_genres (
    title_id            INTEGER NOT NULL REFERENCES titles(title_id) ON DELETE CASCADE,
    genre_id            INTEGER NOT NULL REFERENCES genres(genre_id) ON DELETE RESTRICT,
    PRIMARY KEY (title_id, genre_id)
);

-- 7. Episodes (Series Content)
CREATE TABLE episodes (
    episode_id          INTEGER PRIMARY KEY,
    title_id            INTEGER NOT NULL REFERENCES titles(title_id) ON DELETE CASCADE,
    season_no           INTEGER NOT NULL CHECK (season_no > 0),
    episode_no          INTEGER NOT NULL CHECK (episode_no > 0),
    episode_title       VARCHAR(255) NOT NULL,
    runtime_min         INTEGER NOT NULL CHECK (runtime_min > 0),
    release_date        DATE NOT NULL,
    CONSTRAINT uq_episode_series_season_num UNIQUE (title_id, season_no, episode_no)
);

-- 8. Viewing Activity
CREATE TABLE viewing_activity (
    view_id             BIGINT PRIMARY KEY,
    profile_id          INTEGER NOT NULL REFERENCES profiles(profile_id) ON DELETE CASCADE,
    title_id            INTEGER NOT NULL REFERENCES titles(title_id) ON DELETE CASCADE,
    episode_id          INTEGER REFERENCES episodes(episode_id) ON DELETE CASCADE,
    started_at          TIMESTAMPTZ NOT NULL,
    duration_watched_sec INTEGER NOT NULL CHECK (duration_watched_sec >= 0),
    device_type         VARCHAR(20) NOT NULL CHECK (device_type IN ('TV', 'MOBILE', 'TABLET', 'LAPTOP')),
    completed           BOOLEAN NOT NULL DEFAULT FALSE
);

-- 9. User Ratings
CREATE TABLE ratings (
    profile_id          INTEGER NOT NULL REFERENCES profiles(profile_id) ON DELETE CASCADE,
    title_id            INTEGER NOT NULL REFERENCES titles(title_id) ON DELETE CASCADE,
    rating              VARCHAR(20) NOT NULL CHECK (rating IN ('LOVE', 'THUMBS_UP', 'THUMBS_DOWN')),
    rated_at            TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (profile_id, title_id)
);

-- 10. Watchlist (My List)
CREATE TABLE my_list (
    profile_id          INTEGER NOT NULL REFERENCES profiles(profile_id) ON DELETE CASCADE,
    title_id            INTEGER NOT NULL REFERENCES titles(title_id) ON DELETE CASCADE,
    added_at            TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (profile_id, title_id)
);

-- 11. Invoices
CREATE TABLE invoices (
    invoice_id          BIGINT PRIMARY KEY,
    account_id          INTEGER NOT NULL REFERENCES accounts(account_id) ON DELETE CASCADE,
    billing_period_start DATE NOT NULL CHECK (EXTRACT(DAY FROM billing_period_start) = 1),
    amount_inr          NUMERIC(8, 2) NOT NULL CHECK (amount_inr >= 0),
    status              VARCHAR(20) NOT NULL CHECK (status IN ('PAID', 'FAILED', 'REFUNDED')),
    paid_at             TIMESTAMPTZ,
    CONSTRAINT chk_invoice_failed_unpaid CHECK (status <> 'FAILED' OR paid_at IS NULL)
);
