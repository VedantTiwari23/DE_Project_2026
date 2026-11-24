

-- ─────────────────────────────────────────────────────────────────────
-- STEP 0: Safety guard — do not run twice
-- ─────────────────────────────────────────────────────────────────────
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'netflix'
          AND c.relname  = 'viewing_activity_partitioned'
          AND c.relkind  = 'p'
    ) THEN
        RAISE NOTICE 'viewing_activity_partitioned already exists – skipping.';
    END IF;
END;
$$;


    view_id              BIGINT        NOT NULL,
    profile_id           INTEGER       NOT NULL REFERENCES profiles(profile_id)  ON DELETE CASCADE,
    title_id             INTEGER       NOT NULL REFERENCES titles(title_id)      ON DELETE CASCADE,
    episode_id           INTEGER                REFERENCES episodes(episode_id)  ON DELETE CASCADE,
    started_at           TIMESTAMPTZ   NOT NULL,
    duration_watched_sec INTEGER       NOT NULL CHECK (duration_watched_sec >= 0),
    device_type          VARCHAR(20)   NOT NULL CHECK (device_type IN ('TV','MOBILE','TABLET','LAPTOP')),
    completed            BOOLEAN       NOT NULL DEFAULT FALSE,
    -- Partition key (started_at) must be part of the primary key
    PRIMARY KEY (view_id, started_at)
) PARTITION BY RANGE (started_at);

COMMENT ON TABLE viewing_activity_partitioned IS
  'Range-partitioned replica of viewing_activity, one partition per calendar month. '
  'Partition key: started_at. PK is (view_id, started_at) per PostgreSQL partitioning rules.';

──────────────────────────────────────────

-- 2024
CREATE TABLE viewing_activity_2024_01 PARTITION OF viewing_activity_partitioned
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
CREATE TABLE viewing_activity_2024_02 PARTITION OF viewing_activity_partitioned
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');
CREATE TABLE viewing_activity_2024_03 PARTITION OF viewing_activity_partitioned
    FOR VALUES FROM ('2024-03-01') TO ('2024-04-01');
CREATE TABLE viewing_activity_2024_04 PARTITION OF viewing_activity_partitioned
    FOR VALUES FROM ('2024-04-01') TO ('2024-05-01');
CREATE TABLE viewing_activity_2024_05 PARTITION OF viewing_activity_partitioned
    FOR VALUES FROM ('2024-05-01') TO ('2024-06-01');
CREATE TABLE viewing_activity_2024_06 PARTITION OF viewing_activity_partitioned
    FOR VALUES FROM ('2024-06-01') TO ('2024-07-01');
CREATE TABLE viewing_activity_2024_07 PARTITION OF viewing_activity_partitioned
    FOR VALUES FROM ('2024-07-01') TO ('2024-08-01');
CREATE TABLE viewing_activity_2024_08 PARTITION OF viewing_activity_partitioned
    FOR VALUES FROM ('2024-08-01') TO ('2024-09-01');
CREATE TABLE viewing_activity_2024_09 PARTITION OF viewing_activity_partitioned
    FOR VALUES FROM ('2024-09-01') TO ('2024-10-01');
CREATE TABLE viewing_activity_2024_10 PARTITION OF viewing_activity_partitioned
    FOR VALUES FROM ('2024-10-01') TO ('2024-11-01');
CREATE TABLE viewing_activity_2024_11 PARTITION OF viewing_activity_partitioned
    FOR VALUES FROM ('2024-11-01') TO ('2024-12-01');
CREATE TABLE viewing_activity_2024_12 PARTITION OF viewing_activity_partitioned
    FOR VALUES FROM ('2024-12-01') TO ('2025-01-01');

-- 2025
CREATE TABLE viewing_activity_2025_01 PARTITION OF viewing_activity_partitioned
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
CREATE TABLE viewing_activity_2025_02 PARTITION OF viewing_activity_partitioned
    FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');
CREATE TABLE viewing_activity_2025_03 PARTITION OF viewing_activity_partitioned
    FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');
CREATE TABLE viewing_activity_2025_04 PARTITION OF viewing_activity_partitioned
    FOR VALUES FROM ('2025-04-01') TO ('2025-05-01');
CREATE TABLE viewing_activity_2025_05 PARTITION OF viewing_activity_partitioned
    FOR VALUES FROM ('2025-05-01') TO ('2025-06-01');
CREATE TABLE viewing_activity_2025_06 PARTITION OF viewing_activity_partitioned
    FOR VALUES FROM ('2025-06-01') TO ('2025-07-01');
CREATE TABLE viewing_activity_2025_07 PARTITION OF viewing_activity_partitioned
    FOR VALUES FROM ('2025-07-01') TO ('2025-08-01');
CREATE TABLE viewing_activity_2025_08 PARTITION OF viewing_activity_partitioned
    FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');
CREATE TABLE viewing_activity_2025_09 PARTITION OF viewing_activity_partitioned
    FOR VALUES FROM ('2025-09-01') TO ('2025-10-01');
CREATE TABLE viewing_activity_2025_10 PARTITION OF viewing_activity_partitioned
    FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');
CREATE TABLE viewing_activity_2025_11 PARTITION OF viewing_activity_partitioned
    FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');
CREATE TABLE viewing_activity_2025_12 PARTITION OF viewing_activity_partitioned
    FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');

-- 2026
CREATE TABLE viewing_activity_2026_01 PARTITION OF viewing_activity_partitioned
    FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
CREATE TABLE viewing_activity_2026_02 PARTITION OF viewing_activity_partitioned
    FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
CREATE TABLE viewing_activity_2026_03 PARTITION OF viewing_activity_partitioned
    FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
CREATE TABLE viewing_activity_2026_04 PARTITION OF viewing_activity_partitioned
    FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');
CREATE TABLE viewing_activity_2026_05 PARTITION OF viewing_activity_partitioned
    FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');
CREATE TABLE viewing_activity_2026_06 PARTITION OF viewing_activity_partitioned
    FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');
CREATE TABLE viewing_activity_2026_07 PARTITION OF viewing_activity_partitioned
    FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');
CREATE TABLE viewing_activity_2026_08 PARTITION OF viewing_activity_partitioned
    FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');
CREATE TABLE viewing_activity_2026_09 PARTITION OF viewing_activity_partitioned
    FOR VALUES FROM ('2026-09-01') TO ('2026-10-01');
CREATE TABLE viewing_activity_2026_10 PARTITION OF viewing_activity_partitioned
    FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');
CREATE TABLE viewing_activity_2026_11 PARTITION OF viewing_activity_partitioned
    FOR VALUES FROM ('2026-11-01') TO ('2026-12-01');
CREATE TABLE viewing_activity_2026_12 PARTITION OF viewing_activity_partitioned
    FOR VALUES FROM ('2026-12-01') TO ('2027-01-01');

-- DEFAULT partition for future data (2027+)
CREATE TABLE viewing_activity_default PARTITION OF viewing_activity_partitioned DEFAULT;

-- R01: Continue watching — partial covering index (WHERE NOT completed)
CREATE INDEX idx_vap_unfinished
ON viewing_activity_partitioned (profile_id, title_id, started_at DESC)
INCLUDE (episode_id, duration_watched_sec)
WHERE NOT completed;

-- R03, R23, R18: Date-range scans and deep pagination
CREATE INDEX idx_vap_started_desc
ON viewing_activity_partitioned (started_at DESC)
INCLUDE (view_id, profile_id, title_id, episode_id, device_type,
         duration_watched_sec, completed);

-- R09: Completion rate by genre — covering index for sargable date range
CREATE INDEX idx_vap_started_covering
ON viewing_activity_partitioned (started_at)
INCLUDE (title_id, profile_id, device_type, duration_watched_sec, completed);

-- R19: Originals report — join probe from titles to viewing
CREATE INDEX idx_vap_title_started
ON viewing_activity_partitioned (title_id, started_at);

-- R13: Anti-join probe on episode_id (excludes movie NULLs)
CREATE INDEX idx_vap_episodes_watched
ON viewing_activity_partitioned (episode_id)
WHERE episode_id IS NOT NULL;

-- R14, R16: Per-profile timeline scans
CREATE INDEX idx_vap_profile_timeline
ON viewing_activity_partitioned (profile_id, started_at DESC)
INCLUDE (title_id);

EXPLAIN
SELECT title_id, count(DISTINCT profile_id) AS viewers
FROM viewing_activity_partitioned
WHERE started_at >= '2026-06-30' AND started_at < '2026-07-01'
GROUP BY title_id;


EXPLAIN
SELECT title_id, completed
FROM viewing_activity_partitioned
WHERE started_at >= '2026-01-01' AND started_at < '2027-01-01';
