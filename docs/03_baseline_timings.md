# Phase 3 Deliverable: Baseline Query Timings (CP2)

## 1. Benchmark Environment
- **Hardware:** MacBook Pro M4 2024
- **Operating System:** macOS (Darwin 27.0.0 aarch64)
- **Database Engine:** PostgreSQL 18.6 (Homebrew)
- **Dataset Size:** 200,401 viewing events, 25,000 accounts, 75,000 profiles, 3,000 titles, 20,000 episodes, 133,057 invoices (Clean Seed Dataset)
- **Measurement Tool:** `./benchmarks/run_benchmark.sh netflix_db baseline` (3 runs per query with `EXPLAIN (ANALYZE, BUFFERS)`, write queries wrapped in `BEGIN ... ROLLBACK`)

---

## 2. Baseline Timing Table (All 30 Queries)

| SQL Query | Type | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Average (ms) |
|---|---|---:|---:|---:|---:|
| R01: "Continue Watching" row: latest unfinished viewing per title for profile 7043 | READ | 17.909 | 11.637 | 8.580 | 12.709 |
| R02: Title page: seasons of series 2909 with episode counts | READ | 0.359 | 0.061 | 0.072 | 0.164 |
| R03: "Top 10 in India today" row: most-watched titles on 30 June 2026 | READ | 14.542 | 9.500 | 8.598 | 10.880 |
| R04: Genre row for kids profile: Comedy titles rated U or UA7, newest additions first | READ | 1.563 | 1.256 | 1.486 | 1.435 |
| R05: Search: titles whose name contains "love" | READ | 2.417 | 1.950 | 2.332 | 2.233 |
| R06: "My List" row for profile 7393 | READ | 0.119 | 0.113 | 0.082 | 0.105 |
| R07: Autoplay: next episode of series 2909 after season 1 episode 4 | READ | 0.125 | 0.039 | 0.053 | 0.072 |
| R08: Insights: binge sessions in June 2026 (3+ episodes of one series by one profile on one day) | READ | 23.196 | 14.122 | 11.182 | 16.167 |
| R09: Content analytics: completion rate per genre (2026) | READ | 32.706 | 30.139 | 60.706 | 41.184 |
| R10: Sign-in: find the account by email, ignoring case | READ | 3.063 | 3.623 | 3.188 | 3.291 |
| R11: Payments: active accounts whose June 2026 invoice failed (retry list) | READ | 9.280 | 9.016 | 9.236 | 9.177 |
| R12: Retention: cancellations per month in 2026 and average tenure (days) of those accounts | READ | 1.685 | 1.721 | 1.632 | 1.679 |
| R13: Content team: episodes of series 2523 that nobody has watched | READ | 21.987 | 20.842 | 24.849 | 22.559 |
| R14: Compliance: kids profiles that watched titles above their maturity limit | READ | 26.506 | 23.431 | 68.456 | 39.464 |
| R15: Finance: active accounts and monthly recurring revenue per plan | READ | 7.010 | 5.141 | 4.958 | 5.703 |
| R16: Account sharing check: accounts with more profiles watching in same hour than plan streams | READ | 134.731 | 208.149 | 207.306 | 183.395 |
| R17: Content strategy: share of "LOVE" ratings for Netflix Originals vs licensed titles | READ | 6.302 | 5.830 | 5.765 | 5.966 |
| R18: Device analytics: viewing hours per device per month in 2026 | READ | 29.836 | 28.559 | 28.833 | 29.076 |
| R19: Originals report: total views and most recent view of every Netflix Original | READ | 6417.859 | 6828.978 | 6642.541 | 6629.793 |
| R20: Marketing: 10 titles added to the most My Lists in June 2026 | READ | 2.747 | 3.123 | 2.918 | 2.929 |
| R21: Payments: accounts on hold whose billing date has already passed | READ | 1.218 | 1.240 | 1.269 | 1.242 |
| R22: "Last chance to watch" row: licensed titles leaving in July 2026 | READ | 0.168 | 0.150 | 0.215 | 0.178 |
| R23: Support console: all viewing activity, newest first, page 6,001 (25 per page) | READ | 41.782 | 38.399 | 38.228 | 39.470 |
| R24: "Who's watching?" screen: profiles of account 1409 | READ | 1.836 | 1.782 | 1.797 | 1.805 |
| R25: "More like this": titles sharing at least 2 genres with series 2909 | READ | 0.697 | 0.667 | 0.670 | 0.678 |
| W01: Player: profile 7043 starts episode S1E5 of series 2909 | WRITE | 0.441 | 0.494 | 0.340 | 0.425 |
| W02: "+ My List": profile 7043 adds series 2523 | WRITE | 0.493 | 0.957 | 0.865 | 0.772 |
| W03: Account settings: account 1409 downgrades to the STANDARD plan | WRITE | 0.742 | 0.948 | 0.579 | 0.756 |
| W04: Monthly billing run: create July 2026 invoices for every active account | WRITE | 85.795 | 76.606 | 83.832 | 82.078 |
| W05: Dunning: put active accounts whose latest invoice failed on hold | WRITE | 12.503 | 11.815 | 13.493 | 12.604 |
| **Total (sum of all 30)** | | **6899.617** | **7340.288** | **7234.061** | **7157.989** |

---

## 3. Query Execution Plan Analysis & Scan Types

Below is the query plan breakdown detailing scan nodes and why each query is fast or slow in the baseline schema:

- **R01 (12.71 ms):** `Seq Scan on viewing_activity | Index Scan using titles_pkey on titles`
  - *Why:* Scans all 200,401 rows of `viewing_activity` to filter by `profile_id = 7043 AND NOT completed` because no index on `(profile_id, completed)` exists.
- **R02 (0.16 ms):** `Index Scan using uq_episode_series_season_num on episodes`
  - *Why fast:* The candidate unique key constraint `(title_id, season_no, episode_no)` automatically created an index on `title_id` leading the key.
- **R03 (10.88 ms):** `Seq Scan on viewing_activity | Index Scan using titles_pkey on titles`
  - *Why:* Filter on `started_at` date range forces a full sequential scan across 200,401 viewing records.
- **R04 (1.44 ms):** `Seq Scan on titles | Seq Scan on title_genres | Seq Scan on genres`
  - *Why:* Filtering `genre_name = 'Comedy'` and joining `title_genres` requires multiple small sequential scans without foreign key indexes.
- **R05 (2.23 ms):** `Seq Scan on titles`
  - *Why:* `ILIKE '%love%'` performs a full table scan because standard B-trees cannot optimize leading wildcards (requires `pg_trgm` GIN index).
- **R06 (0.11 ms):** `Index Scan using my_list_pkey on my_list | Index Scan using titles_pkey on titles`
  - *Why fast:* `my_list_pkey` is `(profile_id, title_id)`, so filtering by `profile_id = 7393` utilizes the primary key index directly.
- **R07 (0.07 ms):** `Index Scan using uq_episode_series_season_num on episodes`
  - *Why fast:* Fast index seek using the composite unique index on `(title_id, season_no, episode_no)`.
- **R08 (16.17 ms):** `Seq Scan on viewing_activity`
  - *Why:* Full sequential scan of `viewing_activity` to filter `started_at >= '2026-06-01'` and `episode_id IS NOT NULL`.
- **R09 (41.18 ms):** `Seq Scan on viewing_activity | Seq Scan on title_genres | Seq Scan on genres`
  - *Why:* Scans `viewing_activity` and performs hash joins with `title_genres` without joining indexes.
- **R10 (3.29 ms):** `Seq Scan on accounts`
  - *Why:* `lower(email)` evaluates sequentially on all 25,000 accounts because `accounts.email` index is case-sensitive (needs an expression index).
- **R11 (9.18 ms):** `Seq Scan on invoices | Seq Scan on accounts`
  - *Why:* Scans 133,057 invoices to find `status = 'FAILED'` and joins accounts sequentially without an index on `(status, billing_period_start)`.
- **R12 (1.68 ms):** `Seq Scan on accounts`
  - *Why:* Scans all 25,000 accounts to filter `status = 'CANCELLED'`.
- **R13 (22.56 ms):** `Index Scan using uq_episode_series_season_num on episodes | Seq Scan on viewing_activity`
  - *Why:* The `NOT IN (SELECT episode_id FROM viewing_activity)` executes a full sequential scan on `viewing_activity` (and handles NULLs inefficiently).
- **R14 (39.46 ms):** `Seq Scan on viewing_activity | Seq Scan on profiles | Seq Scan on titles`
  - *Why:* Three-way join between viewing activity, profiles, and titles performs multiple sequential scans without foreign key indexes.
- **R15 (5.70 ms):** `Seq Scan on accounts | Seq Scan on plans`
  - *Why:* Scans all accounts to filter `status = 'ACTIVE'` and group by plan.
- **R16 (183.40 ms):** `Seq Scan on viewing_activity | Seq Scan on profiles | Seq Scan on accounts | Seq Scan on plans`
  - *Why:* Extremely heavy 4-table join and grouping across 200,401 viewing records by hour without indexes on foreign keys.
- **R17 (5.97 ms):** `Seq Scan on ratings | Seq Scan on titles`
  - *Why:* Full sequential scan of 33,900 ratings joined to titles.
- **R18 (29.08 ms):** `Seq Scan on viewing_activity`
  - *Why:* Full sequential scan of 200,401 viewing events to filter dates and group by month and device.
- **R19 (6629.79 ms — Slowest Query):** `Seq Scan on titles | Seq Scan on viewing_activity`
  - *Why:* **Massive bottleneck.** For every Netflix Original title, it executes two independent correlated scalar subqueries (`count(*)` and `max(started_at)`), causing repeated full table scans over 200,401 viewing rows.
- **R20 (2.93 ms):** `Seq Scan on my_list | Seq Scan on titles`
  - *Why:* Filter on `added_at` date range forces a full scan of 59,992 `my_list` rows.
- **R21 (1.24 ms):** `Seq Scan on accounts`
  - *Why:* Scans all accounts to find `status = 'ON_HOLD'` and expired billing dates.
- **R22 (0.18 ms):** `Seq Scan on titles`
  - *Why fast:* Small table (3,000 rows), so in-memory sequential scan is very fast despite lacking an index on `leaving_on`.
- **R23 (39.47 ms):** `Seq Scan on viewing_activity`
  - *Why:* Scans and sorts 200,401 records by `started_at DESC` to skip 150,000 rows for pagination without an index on `started_at`.
- **R24 (1.81 ms):** `Seq Scan on profiles`
  - *Why:* Scans 75,000 profiles to filter by `account_id = 1409` because foreign key `account_id` has no secondary index.
- **R25 (0.68 ms):** `Seq Scan on title_genres | Index Only Scan using title_genres_pkey on title_genres`
  - *Why fast:* Small join using the composite primary key index on `title_genres`.
- **W01 (0.43 ms):** `Index Scan using uq_episode_series_season_num on episodes`
  - *Why fast:* Target episode lookup uses the series/season/episode unique index before single row insertion.
- **W02 (0.77 ms):** `(no scan)`
  - *Why fast:* Direct key insert with `ON CONFLICT` handled by `my_list_pkey`.
- **W03 (0.76 ms):** `Seq Scan on plans | Index Scan using accounts_pkey on accounts`
  - *Why fast:* Updates account by primary key `account_id = 1409`.
- **W04 (82.08 ms):** `Seq Scan on accounts | Seq Scan on plans`
  - *Why:* Bulk generates and inserts ~22,000 July invoices for all active accounts, scanning accounts and verifying foreign keys.
- **W05 (12.60 ms):** `Seq Scan on accounts | Seq Scan on invoices`
  - *Why:* Scans accounts and checks `EXISTS` against invoices without an index on `(account_id, billing_period_start, status)`.

---

## 4. Top 5 Slowest Queries Identified for Phase 4 Optimization

1. **R19 (6,629.79 ms):** Correlated scalar subqueries on `viewing_activity` for every Netflix Original title.
2. **R16 (183.40 ms):** Account sharing aggregation across `viewing_activity`, `profiles`, `accounts`, and `plans`.
3. **W04 (82.08 ms):** Monthly billing batch insert across all active accounts.
4. **R09 (41.18 ms):** Completion percentage per genre with full scans of viewing activity and genre mappings.
5. **R23 (39.47 ms):** Deep offset pagination (`OFFSET 150000`) over viewing activity ordered by `started_at DESC`.
