"""
Loads the LinkedIn Job Postings CSVs into a SQLite database
using the schema defined in schema.sql.

Expects these files in the same folder:
    - schema.sql
    - companies.csv
    - skills.csv
    - postings_trimmed.csv
    - job_skills.csv
"""

import sqlite3
import pandas as pd

DB_PATH = "job_postings.db"

# ------------------------------------------------------------
# 1. Create schema
# ------------------------------------------------------------
conn = sqlite3.connect(DB_PATH)
with open("schema.sql", "r") as f:
    conn.executescript(f.read())
print("Schema created.")

# ------------------------------------------------------------
# 2. Load companies
# ------------------------------------------------------------
companies = pd.read_csv("companies.csv")
companies.to_sql("companies", conn, if_exists="append", index=False)
print(f"Loaded {len(companies):,} companies.")

# ------------------------------------------------------------
# 3. Load skills
# ------------------------------------------------------------
skills = pd.read_csv("skills.csv")
skills.to_sql("skills", conn, if_exists="append", index=False)
print(f"Loaded {len(skills):,} skills.")

# ------------------------------------------------------------
# 4. Load postings
#    - drop rows with a company_id that has no match in companies
#      (keeps referential integrity clean for FK-style joins)
# ------------------------------------------------------------
postings = pd.read_csv("postings_trimmed.csv")

valid_company_ids = set(companies["company_id"])
postings["company_id"] = postings["company_id"].where(
    postings["company_id"].isin(valid_company_ids), None
)

postings = postings[
    ["job_id", "title", "location", "company_id",
     "max_salary", "min_salary", "med_salary", "pay_period", "views"]
]
postings.to_sql("postings", conn, if_exists="append", index=False)
print(f"Loaded {len(postings):,} postings.")

# ------------------------------------------------------------
# 5. Load job_skills
#    - drop rows referencing a job_id or skill_abr not in our tables
# ------------------------------------------------------------
job_skills = pd.read_csv("job_skills.csv")

valid_job_ids = set(postings["job_id"])
valid_skill_abrs = set(skills["skill_abr"])

job_skills = job_skills[
    job_skills["job_id"].isin(valid_job_ids)
    & job_skills["skill_abr"].isin(valid_skill_abrs)
].drop_duplicates()

job_skills.to_sql("job_skills", conn, if_exists="append", index=False)
print(f"Loaded {len(job_skills):,} job-skill mappings.")

conn.commit()
conn.close()
print("\nDone. Database saved as job_postings.db")
