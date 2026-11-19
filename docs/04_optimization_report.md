# Optimization Report (Phase 4 / CP3)

## 1. Overview

In this phase, we optimized the 30 queries from the benchmark workload against our PostgreSQL database (`netflix_db`).
The original baseline ran the full workload in **7,157.99 ms**. After adding 21 indexes and rewriting 5 queries to fix non-sargable expressions, eliminate correlated subqueries, and resolve a NULL logic bug, total runtime dropped to **369.13 ms** (a **94.8% reduction / 19.4× faster**).

The single biggest bottleneck was **R19**, which previously took **6,629.79 ms** by itself (over 92% of total execution time) due to correlated scalar subqueries executing full table scans over 200,401 viewing rows. Rewriting R19 into a single `LEFT JOIN` with `GROUP BY` reduced its runtime to **16.41 ms** (a 404× speedup).

We also uncovered and fixed the bug in **R13**, where the original query returned 0 rows because `NOT IN` fails when subquery results contain NULLs.

---

## 2. Optimization Results Table

| Query | Before (ms) | Problem found in the plan | Optimization applied | After (ms) | Improvement | Same result? |
|:---|---:|:---|:---|---:|---:|:---:|
| R01 | 12.709 | Seq Scan on 200k viewing rows checking profile_id and completed | Partial index idx_viewing_unfinished (WHERE NOT completed) | 0.101 | 99.2% (125.8x) | Yes |
| R02 | 0.164 | Index scan on candidate key; already fast | No changes needed (uses uq_episode_series_season_num) | 0.083 | 49.4% (2.0x) | Yes |
| R03 | 10.880 | Seq scan on viewing_activity for 1-day date range | Covering index idx_viewing_started_desc (Index Only Scan) | 1.816 | 83.3% (6.0x) | Yes |
| R04 | 1.435 | Seq scan on title_genres and titles without reverse genre index | Reverse index idx_title_genres_genre + idx_titles_maturity_added | 1.279 | 10.9% (1.1x) | Yes |
| R05 | 2.233 | Seq scan on titles because ILIKE "%love%" cannot use standard B-tree | GIN trigram index idx_titles_name_trgm using pg_trgm | 0.419 | 81.2% (5.3x) | Yes |
| R06 | 0.105 | Index scan on PK; already fast | Covering index idx_my_list_profile | 0.128 | -21.9% | Yes |
| R07 | 0.072 | Index scan on candidate key; already fast | No changes needed (uses uq_episode_series_season_num) | 0.061 | 15.3% (1.2x) | Yes |
| R08 | 16.167 | Seq scan on viewing_activity filtering started_at and episode_id | Covering index idx_viewing_started_desc | 17.485 | -8.2% | Yes |
| R09 | 41.184 | EXTRACT(YEAR FROM started_at) = 2026 prevented index usage | Rewrote date range + covering index idx_viewing_started_covering | 18.852 | 54.2% (2.2x) | Yes |
| R10 | 3.291 | Seq scan on 25k accounts evaluating lower(email) | Expression index idx_accounts_email_lower | 0.093 | 97.2% (35.4x) | Yes |
| R11 | 9.177 | Seq scan on 133k invoices filtering status = FAILED and billing date | Partial index idx_invoices_failed (WHERE status = FAILED) | 4.984 | 45.7% (1.8x) | Yes |
| R12 | 1.679 | EXTRACT(YEAR FROM cancelled_on) = 2026 prevented index usage | Rewrote date range + partial index idx_accounts_cancelled | 1.021 | 39.2% (1.6x) | Yes |
| R13 | 22.559 | NOT IN with NULLs returned 0 rows (wrong answer) + seq scan | Rewrote to NOT EXISTS to fix NULL bug + idx_viewing_episodes_watched | 0.155 | 99.3% (145.5x) | Fixed bug (8 rows) |
| R14 | 39.464 | 3-table join between viewing activity, profiles, and titles with no indexes | Partial index idx_profiles_kids + idx_viewing_profile_timeline | 27.971 | 29.1% (1.4x) | Yes |
| R15 | 5.703 | Seq scan on accounts filtering status = ACTIVE | Partial index idx_accounts_active_plan | 4.740 | 16.9% (1.2x) | Yes |
| R16 | 183.395 | 4-table join and hourly grouping across all viewing activity | Added FK indexes idx_profiles_account and idx_viewing_profile_timeline | 128.005 | 30.2% (1.4x) | Yes |
| R17 | 5.966 | Seq scan on ratings table joined to titles | Composite index idx_ratings_title on (title_id, rating) | 6.321 | -6.0% | Yes |
| R18 | 29.076 | started_at::date prevented index range scan | Rewrote sargable date filter + idx_viewing_started_desc | 21.310 | 26.7% (1.4x) | Yes |
| R19 | 6629.793 | Correlated subqueries ran 600+ full table scans over viewing activity | Rewrote to LEFT JOIN + GROUP BY and added idx_viewing_title_started | 16.409 | 99.8% (404.0x) | Yes |
| R20 | 2.929 | Seq scan on my_list filtering added_at date range | Composite index idx_my_list_added on (added_at, title_id) | 1.841 | 37.1% (1.6x) | Yes |
| R21 | 1.242 | Seq scan on accounts filtering ON_HOLD and next_billing_date | Partial index idx_accounts_on_hold | 0.430 | 65.4% (2.9x) | Yes |
| R22 | 0.178 | Seq scan on titles filtering leaving_on range | Partial index idx_titles_leaving | 0.161 | 9.6% (1.1x) | Yes |
| R23 | 39.470 | Seq scan and sort of 200k rows to OFFSET 150000 | Covering index idx_viewing_started_desc (Index Only Scan) | 22.252 | 43.6% (1.8x) | Yes |
| R24 | 1.805 | Seq scan on profiles filtering by account_id | Covering index idx_profiles_account on (account_id, created_at) | 0.074 | 95.9% (24.4x) | Yes |
| R25 | 0.678 | Self-join on title_genres without reverse genre_id index | Reverse index idx_title_genres_genre on (genre_id, title_id) | 0.987 | -45.6% | Yes |
| W01 | 0.425 | Target episode lookup by unique key before insert | Index lookup on episodes before insert | 1.759 | -313.9% | Yes |
| W02 | 0.772 | Single row insert with ON CONFLICT | Direct PK conflict check | 2.306 | -198.7% | Yes |
| W03 | 0.756 | Single row update by primary key | PK lookup on accounts | 0.851 | -12.6% | Yes |
| W04 | 82.078 | Bulk insert of 22k invoices scanning active accounts | Active accounts filtered with partial index | 74.848 | 8.8% (1.1x) | Yes |
| W05 | 12.604 | Seq scan on accounts and invoices for EXISTS check | EXISTS check accelerated by idx_invoices_failed | 12.391 | 1.7% (1.0x) | Yes |
| **Total** | **7157.989** | | | **369.133** | **94.8% (19.4x)** | Yes |

---

## 3. The R13 NULL Bug

In Phase 1, Problem statement P4 noted that the content strategy report for unwatched episodes always returned an empty result. 

### Why the original query failed
The original query was written as:
```sql
SELECT e.episode_id, e.season_no, e.episode_no
FROM episodes e
WHERE e.title_id = 2523
  AND e.episode_id NOT IN (SELECT v.episode_id FROM viewing_activity v);
```
In SQL, `NOT IN` expands to a chain of inequalities connected by `AND`:
`e.episode_id <> v1 AND e.episode_id <> v2 AND ... AND e.episode_id <> NULL`

Because `viewing_activity` stores viewing records for movies as well as series, `episode_id` is NULL for movies (93,056 rows in the dataset). When any value in the subquery is NULL, `e.episode_id <> NULL` evaluates to `UNKNOWN`. Under three-valued logic, `TRUE AND UNKNOWN` is `UNKNOWN`, so the `WHERE` clause always filters out every row.

### The fix
We rewrote the query using `NOT EXISTS`:
```sql
SELECT e.episode_id, e.season_no, e.episode_no
FROM episodes e
WHERE e.title_id = 2523
  AND NOT EXISTS (
      SELECT 1 FROM viewing_activity v
      WHERE v.episode_id = e.episode_id
  );
```
`NOT EXISTS` tests whether a matching row exists in the subquery, which uses two-valued Boolean logic. It ignores NULLs and correctly returns the **8 unwatched episodes** of series 2523.
We also added a partial index `idx_viewing_episodes_watched` on `viewing_activity (episode_id) WHERE episode_id IS NOT NULL`, allowing PostgreSQL to perform a Nested Loop Anti Join in **0.16 ms** instead of doing a 22 ms sequential scan.

---

## 4. Top 5 Query Plan Improvements

### 1. R19: Netflix Originals Performance Report (6,629.79 ms → 16.41 ms)
- **Before:** The query had two correlated scalar subqueries (`count(*)` and `max(started_at)`) in the SELECT clause. For each of the 610 Netflix Original titles, PostgreSQL performed two sequential scans across all 200,401 rows of `viewing_activity`, resulting in over 1,200 sequential scans and 2.11 million buffer hits.
- **After:** Rewritten to `LEFT JOIN viewing_activity v ON v.title_id = t.title_id GROUP BY t.title_id, t.name`, supported by `idx_viewing_title_started`. PostgreSQL now executes a single Hash Right Join between the filtered originals and viewing activity, dropping buffer hits to 1,747 and execution time by 404×.

### 2. R13: Unwatched Episodes (22.56 ms → 0.16 ms)
- **Before:** Hashed SubPlan on `viewing_activity` scanning 200,401 rows to build a hash table, which evaluated to UNKNOWN due to NULLs. Execution took 22 ms and produced 0 rows.
- **After:** Nested Loop Anti Join using `idx_viewing_episodes_watched`. PostgreSQL probes the partial index only for the 31 episodes of series 2523, taking 0.16 ms and returning the 8 actual unwatched episodes.

### 3. R01: Continue Watching Row (12.71 ms → 0.10 ms)
- **Before:** Parallel sequential scan on `viewing_activity` filtering on `profile_id = 7043 AND NOT completed`, scanning over 100,000 rows per worker.
- **After:** Index Only Scan using partial index `idx_viewing_unfinished` (`WHERE NOT completed`). Since completed records are excluded from the index, the query only reads 1 index page and finds the target row in 0.10 ms.

### 4. R10: Case-Insensitive Email Login (3.29 ms → 0.09 ms)
- **Before:** Sequential scan on `accounts` testing `lower(email) = 'arjun.chopra1409@yahoo.com'` across 25,000 rows because standard B-trees on `email` are case-sensitive.
- **After:** Expression index `idx_accounts_email_lower` on `lower(email)`. The planner switches to an Index Scan that finds the account in 0.09 ms.

### 5. R24: Account Profile Switching (1.81 ms → 0.07 ms)
- **Before:** Sequential scan on `profiles` filtering by `account_id = 1409` and sorting by `created_at`.
- **After:** Index Only Scan using `idx_profiles_account` on `(account_id, created_at)`. Both the filter and sort order are satisfied directly from the index.

---

## 5. Index Storage & Table Sizes

Measured using `pg_relation_size`:

| Table Name | Index Name | Index Size | Table Size | % of Table |
|:---|:---|---:|---:|---:|
| `viewing_activity` | `idx_viewing_started_covering` | 9,720 kB | 14 MB | 70.0% |
| `viewing_activity` | `idx_viewing_started_desc` | 9,720 kB | 14 MB | 70.0% |
| `viewing_activity` | `idx_viewing_profile_timeline` | 7,960 kB | 14 MB | 57.3% |
| `viewing_activity` | `idx_viewing_title_started` | 6,192 kB | 14 MB | 44.6% |
| `viewing_activity` | `idx_viewing_unfinished` | 3,912 kB | 14 MB | 28.2% |
| `profiles` | `idx_profiles_account` | 3,792 kB | 4,864 kB | 78.0% |
| `accounts` | `idx_accounts_email_lower` | 2,504 kB | 2,528 kB | 99.1% |
| `my_list` | `idx_my_list_profile` | 2,400 kB | 2,632 kB | 91.2% |
| `my_list` | `idx_my_list_added` | 1,856 kB | 2,632 kB | 70.5% |
| `viewing_activity` | `idx_viewing_episodes_watched` | 1,136 kB | 14 MB | 8.2% |
| `ratings` | `idx_ratings_title` | 480 kB | 2,048 kB | 23.4% |
| `titles` | `idx_titles_name_trgm` | 256 kB | 304 kB | 84.2% |
| `profiles` | `idx_profiles_kids` | 240 kB | 4,864 kB | 4.9% |
| `accounts` | `idx_accounts_on_hold` | 240 kB | 2,528 kB | 9.5% |
| `titles` | `idx_titles_maturity_added` | 208 kB | 304 kB | 68.4% |
| `invoices` | `idx_invoices_failed` | 168 kB | 8,864 kB | 1.9% |
| `accounts` | `idx_accounts_active_plan` | 160 kB | 2,528 kB | 6.3% |
| `title_genres` | `idx_title_genres_genre` | 152 kB | 216 kB | 70.4% |
| `accounts` | `idx_accounts_cancelled` | 88 kB | 2,528 kB | 3.5% |
| `titles` | `idx_titles_originals` | 48 kB | 304 kB | 15.8% |
| `titles` | `idx_titles_leaving` | 32 kB | 304 kB | 10.5% |

Total index overhead on `viewing_activity` is ~38 MB compared to the 14 MB base table. This is justified by the fact that `viewing_activity` is read heavily across 9 different core queries, and covering indexes allow queries like R01, R03, and R23 to completely bypass the heap.

---

## 6. Write Overhead

Maintaining secondary indexes adds write latency during `INSERT` and `UPDATE` operations because each new row must be written to multiple B-tree leaf blocks:

- **W01 (Player stream start):** Increased from `0.43 ms` to `1.76 ms`. With 5 secondary indexes on `viewing_activity`, single-row inserts take ~1.3 ms longer. In production, 1.7 ms is well within the acceptable threshold for video player initialisation.
- **W02 (Add to My List):** Increased from `0.77 ms` to `2.31 ms` due to the two indexes on `my_list`.
- **W03 (Plan downgrade):** Stayed flat at `0.85 ms` (was `0.76 ms`) since `accounts` updates by PK only update affected indexes.
- **W04 (Monthly billing batch):** Stayed around `74.85 ms` (improved slightly from `82.08 ms` because the active accounts query uses `idx_accounts_active_plan`).

The minor 1–2 ms write overhead on single-row user actions is an acceptable trade-off for saving over 6,700 ms on read workloads.

---

## 7. Queries That Could Not Be Sped Up Much

1. **R16 (128.01 ms):** This query detects account sharing by grouping 200,401 viewing records by account, date-hour, and plan limit. Because it aggregates the entire dataset across 4 joins, PostgreSQL still needs to scan and hash-aggregate substantial data. Further improvement would require pre-aggregated summary tables or time-series rollup tables.
2. **R02, R06, R07:** These queries were already executing in under `0.2 ms` in the baseline schema because primary and unique keys were already indexed by default. The small timing differences between benchmark runs are normal variations in CPU cache and thread scheduling.
