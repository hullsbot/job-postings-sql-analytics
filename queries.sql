-- ============================================================
-- Analytical Queries — Job Postings Database
-- Each query answers a specific business/insight question.
-- ============================================================

-- ------------------------------------------------------------
-- 1. Top 10 most in-demand skills overall
-- ------------------------------------------------------------
SELECT s.skill_name, COUNT(*) AS demand
FROM job_skills js
JOIN skills s ON js.skill_abr = s.skill_abr
GROUP BY s.skill_name
ORDER BY demand DESC
LIMIT 10;


-- ------------------------------------------------------------
-- 2. Rank skills within each pay_period by demand (window function)
--    Shows which skills dominate hourly vs yearly roles
-- ------------------------------------------------------------
SELECT pay_period, skill_name, demand, rnk
FROM (
    SELECT
        p.pay_period,
        s.skill_name,
        COUNT(*) AS demand,
        RANK() OVER (PARTITION BY p.pay_period ORDER BY COUNT(*) DESC) AS rnk
    FROM postings p
    JOIN job_skills js ON p.job_id = js.job_id
    JOIN skills s ON js.skill_abr = s.skill_abr
    WHERE p.pay_period IS NOT NULL
    GROUP BY p.pay_period, s.skill_name
)
WHERE rnk <= 3
ORDER BY pay_period, rnk;


-- ------------------------------------------------------------
-- 3. Average salary (yearly-normalized) by top 10 skills
--    Only using YEARLY postings with a known salary for clean comparison
-- ------------------------------------------------------------
SELECT
    s.skill_name,
    ROUND(AVG(p.med_salary), 0) AS avg_med_salary,
    ROUND(AVG(p.max_salary), 0) AS avg_max_salary,
    COUNT(*) AS num_postings
FROM postings p
JOIN job_skills js ON p.job_id = js.job_id
JOIN skills s ON js.skill_abr = s.skill_abr
WHERE p.pay_period = 'YEARLY'
  AND p.max_salary IS NOT NULL
GROUP BY s.skill_name
ORDER BY avg_max_salary DESC
LIMIT 10;


-- ------------------------------------------------------------
-- 4. Skill co-occurrence: pairs of skills that appear together most often
--    (self-join on job_skills to find pairs within the same posting)
-- ------------------------------------------------------------
SELECT
    s1.skill_name AS skill_a,
    s2.skill_name AS skill_b,
    COUNT(*) AS co_occurrences
FROM job_skills js1
JOIN job_skills js2
    ON js1.job_id = js2.job_id
    AND js1.skill_abr < js2.skill_abr   -- avoid duplicate/mirrored pairs
JOIN skills s1 ON js1.skill_abr = s1.skill_abr
JOIN skills s2 ON js2.skill_abr = s2.skill_abr
GROUP BY s1.skill_name, s2.skill_name
ORDER BY co_occurrences DESC
LIMIT 10;


-- ------------------------------------------------------------
-- 5. Companies posting the most jobs (hiring volume leaderboard)
-- ------------------------------------------------------------
SELECT
    c.name,
    c.state,
    c.country,
    COUNT(*) AS num_postings
FROM postings p
JOIN companies c ON p.company_id = c.company_id
GROUP BY c.company_id, c.name, c.state, c.country
ORDER BY num_postings DESC
LIMIT 10;


-- ------------------------------------------------------------
-- 6. Company-size buckets vs average views per posting
--    (do bigger companies get more visibility per posting?)
-- ------------------------------------------------------------
SELECT
    c.company_size,
    COUNT(*) AS num_postings,
    ROUND(AVG(p.views), 1) AS avg_views
FROM postings p
JOIN companies c ON p.company_id = c.company_id
WHERE c.company_size IS NOT NULL
  AND p.views IS NOT NULL
GROUP BY c.company_size
ORDER BY c.company_size;


-- ------------------------------------------------------------
-- 7. Top locations by number of postings, with rank
-- ------------------------------------------------------------
SELECT
    location,
    COUNT(*) AS num_postings,
    RANK() OVER (ORDER BY COUNT(*) DESC) AS location_rank
FROM postings
GROUP BY location
ORDER BY num_postings DESC
LIMIT 10;


-- ------------------------------------------------------------
-- 8. Skill "scarcity" — skills that appear in relatively few postings
--    (niche/oversaturated check — bottom of the demand list)
-- ------------------------------------------------------------
SELECT s.skill_name, COUNT(*) AS demand
FROM job_skills js
JOIN skills s ON js.skill_abr = s.skill_abr
GROUP BY s.skill_name
ORDER BY demand ASC
LIMIT 10;


-- ------------------------------------------------------------
-- 9. Running total of postings per skill, ordered by demand
--    (CTE + window function — cumulative share of total market)
-- ------------------------------------------------------------
WITH skill_demand AS (
    SELECT s.skill_name, COUNT(*) AS demand
    FROM job_skills js
    JOIN skills s ON js.skill_abr = s.skill_abr
    GROUP BY s.skill_name
)
SELECT
    skill_name,
    demand,
    SUM(demand) OVER (ORDER BY demand DESC) AS running_total,
    ROUND(100.0 * SUM(demand) OVER (ORDER BY demand DESC) /
          SUM(demand) OVER (), 1) AS cumulative_pct
FROM skill_demand
ORDER BY demand DESC;


-- ------------------------------------------------------------
-- 10. Companies with above-average postings AND above-average avg views
--     (CTE combining two aggregate conditions — "high volume, high interest")
-- ------------------------------------------------------------
WITH company_stats AS (
    SELECT
        c.company_id,
        c.name,
        COUNT(*) AS num_postings,
        AVG(p.views) AS avg_views
    FROM postings p
    JOIN companies c ON p.company_id = c.company_id
    WHERE p.views IS NOT NULL
    GROUP BY c.company_id, c.name
)
SELECT *
FROM company_stats
WHERE num_postings > (SELECT AVG(num_postings) FROM company_stats)
  AND avg_views > (SELECT AVG(avg_views) FROM company_stats)
ORDER BY num_postings DESC
LIMIT 10;
