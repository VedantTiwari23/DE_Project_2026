# Database Schema Design

## 1. Database Overview

The project uses PostgreSQL to design a relational database for a Netflix-like streaming platform.

The database manages the following major areas:

- Subscription plans and accounts
- User profiles
- Movies and TV series
- Genres and episodes
- Viewing activity
- User ratings and personal watchlists
- Subscription invoices

The database is designed to maintain data consistency through primary keys, foreign keys, unique constraints, NOT NULL constraints, and CHECK constraints.

The schema is intended to support both customer-facing queries and analytical workloads.

## 2. Database Tables

The database consists of 11 main tables. Each table stores information about a specific entity or relationship in the streaming platform.

### 2.1 plans

The `plans` table stores subscription plan information.

| Column | Description |
|---|---|
| plan_id | Unique identifier for each subscription plan |
| plan_name | Name of the subscription plan |
| monthly_price_inr | Monthly subscription price in INR |
| max_streams | Maximum number of simultaneous streams |
| max_resolution | Maximum supported video resolution |
| has_ads | Indicates whether advertisements are included |

**Primary Key:** `plan_id`

### 2.2 accounts

The `accounts` table stores customer account information.

| Column | Description |
|---|---|
| account_id | Unique identifier for each account |
| email | Customer email address |
| phone | Customer phone number |
| country_code | Country code of the account |
| plan_id | Subscription plan associated with the account |
| signup_date | Date when the account was created |
| status | Current account status |
| cancelled_on | Date when the subscription was cancelled |
| next_billing_date | Next scheduled billing date |

**Primary Key:** `account_id`

**Foreign Key:** `plan_id` references `plans(plan_id)`.

### 2.3 profiles

The `profiles` table stores individual user profiles belonging to an account.

| Column | Description |
|---|---|
| profile_id | Unique identifier for each profile |
| account_id | Account to which the profile belongs |
| profile_name | Name of the profile |
| is_kids | Indicates whether the profile is a kids profile |
| maturity_limit | Maximum content maturity level allowed |
| language | Preferred profile language |
| created_at | Date and time when the profile was created |

**Primary Key:** `profile_id`

**Foreign Key:** `account_id` references `accounts(account_id)`.

### 2.4 genres

The `genres` table stores the different content genres available on the platform.

| Column | Description |
|---|---|
| genre_id | Unique identifier for each genre |
| genre_name | Name of the genre |

**Primary Key:** `genre_id`

### 2.5 titles

The `titles` table stores information about movies and TV series.

| Column | Description |
|---|---|
| title_id | Unique identifier for each title |
| title_type | Type of content (MOVIE or SERIES) |
| name | Name of the movie or series |
| release_year | Year of release |
| maturity_rating | Content maturity rating |
| original_language | Original language of the content |
| runtime_min | Runtime of the movie in minutes |
| is_netflix_original | Indicates whether the content is a Netflix Original |
| added_on | Date when the content was added to the platform |
| leaving_on | Date when the content leaves the platform, if applicable |

**Primary Key:** `title_id`

The `runtime_min` column is NULL for TV series in the supplied dataset because the runtime of individual episodes is stored in the `episodes` table.

### 2.6 title_genres

The `title_genres` table represents the many-to-many relationship between titles and genres.

A title can belong to multiple genres, and one genre can be associated with multiple titles.

| Column | Description |
|---|---|
| title_id | Identifier of the title |
| genre_id | Identifier of the genre |

**Composite Primary Key:** `(title_id, genre_id)`

**Foreign Keys:**
- `title_id` references `titles(title_id)`.
- `genre_id` references `genres(genre_id)`.

### 2.7 episodes

The `episodes` table stores episode-level information for TV series.

| Column | Description |
|---|---|
| episode_id | Unique identifier for each episode |
| title_id | Series to which the episode belongs |
| season_no | Season number |
| episode_no | Episode number within the season |
| episode_title | Name of the episode |
| runtime_min | Runtime of the episode in minutes |
| release_date | Episode release date |

**Primary Key:** `episode_id`

**Foreign Key:** `title_id` references `titles(title_id)`.

A combination of `title_id`, `season_no`, and `episode_no` can also be treated as a candidate unique key.

### 2.8 viewing_activity

The `viewing_activity` table stores user viewing history and playback activity.

| Column | Description |
|---|---|
| view_id | Unique identifier for each viewing record |
| profile_id | Profile that watched the content |
| title_id | Title being watched |
| episode_id | Episode being watched, if applicable |
| started_at | Date and time when playback started |
| duration_watched_sec | Total duration watched in seconds |
| device_type | Device used for watching |
| completed | Indicates whether the content was completed |

**Primary Key:** `view_id`

**Foreign Keys:**
- `profile_id` references `profiles(profile_id)`.
- `title_id` references `titles(title_id)`.
- `episode_id` references `episodes(episode_id)`.

The `episode_id` column is nullable because movie viewing records do not require an episode identifier.

### 2.9 ratings

The `ratings` table stores user ratings for titles.

| Column | Description |
|---|---|
| profile_id | Profile that submitted the rating |
| title_id | Title being rated |
| rating | Rating value such as LOVE, THUMBS_UP or THUMBS_DOWN |
| rated_at | Date and time when the rating was submitted |

**Composite Primary Key:** `(profile_id, title_id)`

**Foreign Keys:**
- `profile_id` references `profiles(profile_id)`.
- `title_id` references `titles(title_id)`.

The composite primary key ensures that a profile has at most one rating record for a particular title.

### 2.10 my_list

The `my_list` table stores titles added by users to their personal watchlists.

| Column | Description |
|---|---|
| profile_id | Profile that added the title |
| title_id | Title added to the list |
| added_at | Date and time when the title was added |

**Composite Primary Key:** `(profile_id, title_id)`

**Foreign Keys:**
- `profile_id` references `profiles(profile_id)`.
- `title_id` references `titles(title_id)`.

### 2.11 invoices

The `invoices` table stores subscription billing and payment information.

| Column | Description |
|---|---|
| invoice_id | Unique identifier for each invoice |
| account_id | Account associated with the invoice |
| billing_period_start | Starting date of the billing period |
| amount_inr | Invoice amount in INR |
| status | Payment status |
| paid_at | Date and time when payment was made |

**Primary Key:** `invoice_id`

**Foreign Key:** `account_id` references `accounts(account_id)`.

## 3. Primary Key and Foreign Key Relationships

Primary keys uniquely identify records in each table. Foreign keys establish relationships between related tables and help maintain referential integrity.

### 3.1 Primary Keys

The proposed primary keys are:

| Table | Primary Key |
|---|---|
| plans | plan_id |
| accounts | account_id |
| profiles | profile_id |
| genres | genre_id |
| titles | title_id |
| title_genres | (title_id, genre_id) |
| episodes | episode_id |
| viewing_activity | view_id |
| ratings | (profile_id, title_id) |
| my_list | (profile_id, title_id) |
| invoices | invoice_id |

### 3.2 Foreign Keys

| Child Table | Foreign Key | Referenced Table |
|---|---|---|
| accounts | plan_id | plans(plan_id) |
| profiles | account_id | accounts(account_id) |
| title_genres | title_id | titles(title_id) |
| title_genres | genre_id | genres(genre_id) |
| episodes | title_id | titles(title_id) |
| viewing_activity | profile_id | profiles(profile_id) |
| viewing_activity | title_id | titles(title_id) |
| viewing_activity | episode_id | episodes(episode_id) |
| ratings | profile_id | profiles(profile_id) |
| ratings | title_id | titles(title_id) |
| my_list | profile_id | profiles(profile_id) |
| my_list | title_id | titles(title_id) |
| invoices | account_id | accounts(account_id) |

These relationships ensure that records refer to existing parent records.

## 4. NULL Values and Constraints

NULL values are used when information is optional or not applicable.

The supplied CSV dataset contains NULL values in the following columns:

| Table | Column | NULL Rows | Explanation |
|---|---|---:|---|
| accounts | phone | 4,888 | Phone number is not available for some accounts |
| accounts | cancelled_on | 22,021 | Cancellation date is not available for many accounts |
| accounts | next_billing_date | 2,979 | Next billing date is not available for some accounts |
| titles | runtime_min | 1,000 | Series-level runtime is not stored in this column |
| titles | leaving_on | 2,738 | Leaving date is not available for many titles |
| viewing_activity | episode_id | 93,056 | Movie viewing records do not require an episode ID |
| invoices | paid_at | 4,764 | Payment timestamp is unavailable for some invoices |

These columns should allow NULL values where the business rules permit missing or non-applicable information.

### 4.1 Proposed Constraints

The following constraints can be applied to maintain data integrity:

- **PRIMARY KEY:** Ensures that each record has a unique identifier.
- **FOREIGN KEY:** Ensures that related records exist in referenced tables.
- **NOT NULL:** Used for mandatory attributes such as IDs, names, and required dates.
- **UNIQUE:** Can be applied to attributes such as email addresses and plan names, where the business rules require uniqueness.
- **CHECK:** Can validate values such as non-negative prices, positive stream limits, valid title types, and valid account statuses.

Examples of useful CHECK constraints include:

- `monthly_price_inr >= 0`
- `max_streams > 0`
- `title_type IN ('MOVIE', 'SERIES')`
- `status IN ('ACTIVE', 'CANCELLED', 'ON_HOLD')`
- `duration_watched_sec >= 0`
- `runtime_min > 0` when a runtime value is present.

These are proposed database constraints and should be implemented after confirming the project's business rules.

## 5. Functional Dependencies

Functional dependencies describe how one or more attributes determine other attributes in a relation.

The main functional dependencies in the proposed schema are:

| Table | Functional Dependency |
|---|---|
| plans | plan_id → plan_name, monthly_price_inr, max_streams, max_resolution, has_ads |
| accounts | account_id → email, phone, country_code, plan_id, signup_date, status, cancelled_on, next_billing_date |
| profiles | profile_id → account_id, profile_name, is_kids, maturity_limit, language, created_at |
| genres | genre_id → genre_name |
| titles | title_id → title_type, name, release_year, maturity_rating, original_language, runtime_min, is_netflix_original, added_on, leaving_on |
| title_genres | (title_id, genre_id) → no additional non-key attributes |
| episodes | episode_id → title_id, season_no, episode_no, episode_title, runtime_min, release_date |
| viewing_activity | view_id → profile_id, title_id, episode_id, started_at, duration_watched_sec, device_type, completed |
| ratings | (profile_id, title_id) → rating, rated_at |
| my_list | (profile_id, title_id) → added_at |
| invoices | invoice_id → account_id, billing_period_start, amount_inr, status, paid_at |

These functional dependencies help identify candidate keys and evaluate normalization.

## 6. Normalization

Normalization is the process of organizing database tables to reduce data redundancy and avoid insertion, update, and deletion anomalies.

The proposed database design follows the principles of relational normalization.

### 6.1 First Normal Form (1NF)

A table satisfies First Normal Form when:

- Every column contains atomic values.
- Each row can be uniquely identified.
- There are no repeating groups or multi-valued attributes within a single cell.

The proposed tables store individual values in their columns. For example, genres are stored separately in the `genres` table and connected to titles using `title_genres`.

Therefore, the design follows 1NF.

### 6.2 Second Normal Form (2NF)

A table satisfies Second Normal Form when:

- It is already in 1NF.
- Every non-key attribute depends on the whole candidate key.
- There are no partial dependencies on a part of a composite key.

The tables `ratings`, `my_list`, and `title_genres` use composite primary keys.

In `ratings`, the rating and timestamp depend on the complete combination of `profile_id` and `title_id`.

In `my_list`, the added timestamp depends on the complete combination of `profile_id` and `title_id`.

The `title_genres` table contains only the two columns that together form its composite key.

Therefore, these tables do not have partial dependencies based on their proposed keys.

### 6.3 Third Normal Form (3NF)

A table satisfies Third Normal Form when:

- It is already in 2NF.
- Non-key attributes do not depend transitively on the primary key through other non-key attributes.

The proposed schema separates entities into independent tables.

For example:

- Subscription plan details are stored in `plans`, while account information is stored in `accounts`.
- Profile information is stored in `profiles`, separately from account information.
- Genre details are stored in `genres`, separately from titles.
- Episode information is stored in `episodes`, separately from series-level title information.

This reduces unnecessary duplication of descriptive information and helps prevent update anomalies.

The proposed design is intended to satisfy 3NF, subject to confirmation of all business-rule functional dependencies.

## 7. Redundant Data Analysis

Redundant data means storing information that can be derived from other attributes or related records.

The following areas require attention:

### 7.1 Viewing Completion Status

The `viewing_activity` table contains both `duration_watched_sec` and `completed`.

The completion status may be related to the watched duration and the runtime of the movie or episode.

However, `completed` may also represent an application-level playback decision. Therefore, it should not be removed without confirming the business rules.

### 7.2 Invoice Amount and Subscription Plan Price

The `invoices` table stores `amount_inr`, while the `plans` table stores `monthly_price_inr`.

These values may be equal for a normal billing period, but invoice amounts should be stored separately because historical invoice amounts must remain unchanged even if subscription prices change later.

### 7.3 Title and Episode Information

The `episodes` table stores `title_id`, which identifies the parent series.

The `viewing_activity` table also stores `title_id` along with `episode_id`.

For episode viewing records, the title can potentially be obtained through the episode's parent title. Both identifiers should be checked for consistency so that an episode cannot accidentally be associated with a different title.

The `title_id` in viewing activity can still be useful for direct title-level queries and analytics.

## 8. Relationships Between Tables

The major relationships in the database are:

1. One subscription plan can be associated with many accounts.
2. One account can have multiple user profiles.
3. One title can belong to multiple genres.
4. One genre can be associated with multiple titles.
5. One TV series can contain multiple episodes.
6. One profile can have many viewing activity records.
7. One title can appear in many viewing activity records.
8. One profile can rate multiple titles.
9. One profile can add multiple titles to their personal list.
10. One account can have multiple invoices.

The `title_genres` table implements the many-to-many relationship between titles and genres.

The `ratings` and `my_list` tables also use composite keys to represent profile-to-title relationships.

## 9. Conclusion

The proposed database schema organizes the streaming platform's data into 11 related tables.

Primary keys provide unique identification, while foreign keys maintain relationships between entities.

Normalization helps reduce unnecessary redundancy and maintain consistency. NULL handling and integrity constraints further improve the reliability of the database.

The resulting relational design provides a foundation for customer-facing operations, subscription management, content management, viewing history, and analytical queries.