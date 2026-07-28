# 📊 Job Postings Analytics — SQL Project

A SQL analytics project on real-world job market data, exploring skill demand, salary trends, hiring patterns, and skill co-occurrence using window functions, CTEs, and multi-table joins.

**Dataset:** [LinkedIn Job Postings (Kaggle)](https://www.kaggle.com/datasets/arshkon/linkedin-job-postings) — 120k+ real job postings scraped from LinkedIn.

## 🎯 What this project does

- Normalizes raw job-posting data into a relational schema (postings, companies, skills, job-skill mapping)
- Answers real hiring-market questions with pure SQL: skill demand, salary benchmarks, co-occurring skills, top hiring companies, location trends
- Demonstrates window functions (`RANK`, running totals), CTEs, self-joins, and correlated subqueries — not just basic `SELECT`/`JOIN`

## 🗂️ Schema

```
companies (24,473 rows)
├── company_id PK
├── name, description, company_size, state, country, city, zip_code, address, url

skills (35 rows)
├── skill_abr PK
├── skill_name

postings (123,849 rows)
├── job_id PK
├── company_id FK → companies
├── title, location, max_salary, min_salary, med_salary, pay_period, views

job_skills (205,778 rows)
├── job_id FK → postings
├── skill_abr FK → skills
```

## 🛠️ Tech Stack

| Tool | Purpose |
|---|---|
| SQLite | Database engine (single-file, zero setup) |
| Python / pandas | Data cleaning and loading |
| SQL | All analysis — window functions, CTEs, joins |

## 🚀 How to Run

```bash
git clone https://github.com/hullsbot/job-postings-sql-analytics
cd job-postings-sql-analytics

# The database is included pre-built (job_postings.db).
# To rebuild from scratch instead:
pip install pandas
python load_data.py   # requires companies.csv, skills.csv, postings_trimmed.csv, job_skills.csv

# Run any analytical query
sqlite3 job_postings.db < queries.sql
```

## 📈 Key Insights

- **IT, Sales, and Management** together account for ~32% of all skill demand across postings
- **Marketing, Product Management, and Legal** roles have the highest average max salaries among skill categories (~$180K–$251K)
- **Management + Manufacturing** is the most common skill pairing (15,938 co-occurrences), likely reflecting operations/plant-manager roles
- Posting views don't scale simply with company size — the smallest companies (size bucket 1) actually average *more* views per posting (24.6) than several mid-size buckets

## 🔍 Sample Query — Skill Demand with Cumulative Market Share

```sql
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
```

**Output (top 3):**

| skill_name | demand | running_total | cumulative_pct |
|---|---|---|---|
| Information Technology | 25,256 | 25,256 | 12.3% |
| Sales | 21,193 | 46,449 | 22.6% |
| Management | 20,385 | 66,834 | 32.5% |

## 📁 Project Structure

```
job-postings-sql-analytics/
│
├── schema.sql          # Table definitions + indexes
├── load_data.py        # Loads CSVs into SQLite, handles referential integrity
├── queries.sql          # 10 analytical queries (window functions, CTEs, self-joins)
├── job_postings.db      # Pre-built SQLite database
└── README.md
```

## 📚 Data Source

Job postings, company, and skills data from the [LinkedIn Job Postings dataset](https://www.kaggle.com/datasets/arshkon/linkedin-job-postings) on Kaggle.

## 👤 Author

Suhani — [@hullsbot](https://github.com/hullsbot)
B.Tech Electronics & Communication Engineering, NIT Delhi
