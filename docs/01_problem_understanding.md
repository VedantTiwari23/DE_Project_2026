# Problem Understanding

## Project Overview

This project focuses on designing and optimizing a PostgreSQL database for a Netflix-like streaming platform. The database supports user management, content discovery, viewing activity, subscriptions, billing, and analytics.

The objective is to understand the business requirements and identify the database operations that need performance improvements.

## P1 – Home Screen Performance

**Business Requirement:**

The platform needs to load personalized home-screen sections such as Continue Watching, Top 10, My List, and genre-based recommendations quickly.

**Stakeholders:**
- Netflix members
- Personalization team
- UI team

**Classification:** Customer-facing / Real-time

**Assumptions:**
- Home-screen queries are executed frequently.
- Users expect personalized results with minimal delay.

## P2 – Title Pages, Autoplay and Search Performance

**Business Requirement:**

Users should be able to search for titles, open title details, and automatically play the next episode without unnecessary delays.

**Stakeholders:**
- Netflix members
- Playback team
- Search team

**Classification:** Customer-facing / Real-time

**Assumptions:**
- Title searches and episode lookups are frequent operations.
- Search results should be returned quickly.

## P3 – Login and Profile Switching Performance

**Business Requirement:**

Users should be able to log in using their email and switch between profiles associated with their account quickly.

**Stakeholders:**
- Netflix members
- Identity and authentication team

**Classification:** Customer-facing / Real-time

**Assumptions:**
- Email lookup and profile retrieval are frequent operations.
- Account and profile information should be accessible with low latency.

## P4 – Unwatched Episodes Report

**Business Requirement:**

The content strategy team needs an accurate list of episodes that users have not watched.

**Stakeholders:**
- Content strategy team
- Content analytics team

**Classification:** Reporting / Analytics

**Assumptions:**
- Viewing activity must be correctly associated with episodes.
- Missing or incorrect viewing records can affect report accuracy.

## P5 – Billing and Payment Operations

**Business Requirement:**

The platform needs to process subscription changes, payment retries, invoice generation, and account billing operations efficiently.

**Stakeholders:**
- Finance team
- Billing and payments team
- Netflix members

**Classification:** Mixed – Real-time operations and Batch processing

**Assumptions:**
- Payment retries and subscription changes require timely processing.
- Monthly invoice generation can be performed as a batch operation.

## P6 – Kids Compliance and Account Sharing

**Business Requirement:**

The platform needs to identify content that violates kids-profile restrictions and detect suspicious account-sharing activity.

**Stakeholders:**
- Parents and guardians
- Compliance team
- Account security team

**Classification:** Reporting / Analytics

**Assumptions:**
- Profile maturity settings must be respected.
- Viewing activity across profiles and devices can help identify suspicious usage patterns.

## P7 – Analytics Query Performance and Data Growth

**Business Requirement:**

The content analytics team needs to execute large analytical queries efficiently as viewing activity grows significantly.

**Stakeholders:**
- Content analytics team
- Data engineering team

**Classification:** Reporting / Analytics

**Assumptions:**
- Viewing activity is expected to grow approximately 20 times.
- Query performance should remain acceptable as the database grows.

## P8 – Revenue, Churn and Activity Reports

**Business Requirement:**

The finance and support teams need reports related to subscription revenue, cancellations, customer tenure, and viewing activity.

**Stakeholders:**
- Finance team
- Customer support team
- Business analytics team

**Classification:** Mixed – Real-time operations and Reporting / Analytics

**Assumptions:**
- Historical subscription and invoice records are required for accurate reports.
- Analytical queries may involve large joins and aggregations.

## Conclusion

The eight business problems cover both customer-facing operations and analytical workloads.

The database design must support efficient data retrieval, reliable relationships, accurate reporting, and future scalability.