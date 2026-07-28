-- ============================================================
-- Job Postings Analytics Database Schema
-- Source: LinkedIn Job Postings dataset (Kaggle)
-- ============================================================

DROP TABLE IF EXISTS job_skills;
DROP TABLE IF EXISTS postings;
DROP TABLE IF EXISTS skills;
DROP TABLE IF EXISTS companies;

-- ------------------------------------------------------------
-- Companies
-- ------------------------------------------------------------
CREATE TABLE companies (
    company_id   INTEGER PRIMARY KEY,
    name         TEXT,
    description  TEXT,
    company_size INTEGER,
    state        TEXT,
    country      TEXT,
    city         TEXT,
    zip_code     TEXT,
    address      TEXT,
    url          TEXT
);

-- ------------------------------------------------------------
-- Skills lookup
-- ------------------------------------------------------------
CREATE TABLE skills (
    skill_abr  TEXT PRIMARY KEY,
    skill_name TEXT NOT NULL
);

-- ------------------------------------------------------------
-- Job postings (core fact table)
-- ------------------------------------------------------------
CREATE TABLE postings (
    job_id      INTEGER PRIMARY KEY,
    title       TEXT NOT NULL,
    location    TEXT,
    company_id  INTEGER,
    max_salary  REAL,
    min_salary  REAL,
    med_salary  REAL,
    pay_period  TEXT,
    views       INTEGER,
    FOREIGN KEY (company_id) REFERENCES companies(company_id)
);

-- ------------------------------------------------------------
-- Job <-> Skill mapping (many-to-many)
-- ------------------------------------------------------------
CREATE TABLE job_skills (
    job_id     INTEGER,
    skill_abr  TEXT,
    PRIMARY KEY (job_id, skill_abr),
    FOREIGN KEY (job_id) REFERENCES postings(job_id),
    FOREIGN KEY (skill_abr) REFERENCES skills(skill_abr)
);

-- ------------------------------------------------------------
-- Indexes for common query patterns
-- ------------------------------------------------------------
CREATE INDEX idx_postings_company ON postings(company_id);
CREATE INDEX idx_postings_location ON postings(location);
CREATE INDEX idx_job_skills_skill ON job_skills(skill_abr);
CREATE INDEX idx_companies_state ON companies(state);
