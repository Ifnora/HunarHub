-- HunarHub Pakistan V1 Database
-- PostgreSQL

CREATE TABLE app_users (
    id BIGSERIAL PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(30),
    password_hash TEXT NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'student'
        CHECK (role IN ('student', 'admin')),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX app_users_email_unique
ON app_users (LOWER(email));

CREATE TABLE user_profiles (
    user_id BIGINT PRIMARY KEY REFERENCES app_users(id) ON DELETE CASCADE,
    city VARCHAR(100),
    country VARCHAR(100) DEFAULT 'Pakistan',
    education JSONB NOT NULL DEFAULT '[]',
    skills JSONB NOT NULL DEFAULT '[]',
    experience JSONB NOT NULL DEFAULT '[]',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE job_categories (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE job_sources (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    website_url TEXT NOT NULL,
    source_type VARCHAR(30) NOT NULL
        CHECK (source_type IN ('api', 'rss', 'permitted_web', 'manual')),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    fetch_settings JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE jobs (
    id BIGSERIAL PRIMARY KEY,
    source_id BIGINT REFERENCES job_sources(id),
    category_id BIGINT REFERENCES job_categories(id),
    external_id VARCHAR(255),
    title VARCHAR(255) NOT NULL,
    employer VARCHAR(255),
    location VARCHAR(255),
    country VARCHAR(100),
    description TEXT,
    qualification TEXT,
    experience TEXT,
    salary_information TEXT,
    official_apply_url TEXT NOT NULL,
    deadline TIMESTAMPTZ,
    status VARCHAR(20) NOT NULL DEFAULT 'pending'
        CHECK (status IN (
            'pending', 'approved', 'published',
            'rejected', 'expired'
        )),
    collected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_verified_at TIMESTAMPTZ,
    reviewed_by BIGINT REFERENCES app_users(id),
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (source_id, external_id)
);

CREATE INDEX jobs_status_deadline_idx
ON jobs(status, deadline);

CREATE INDEX jobs_category_idx
ON jobs(category_id);

CREATE TABLE saved_jobs (
    user_id BIGINT REFERENCES app_users(id) ON DELETE CASCADE,
    job_id BIGINT REFERENCES jobs(id) ON DELETE CASCADE,
    saved_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, job_id)
);

CREATE TABLE applications (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    job_id BIGINT NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    application_date TIMESTAMPTZ,
    status VARCHAR(30) NOT NULL DEFAULT 'saved'
        CHECK (status IN (
            'saved', 'applied', 'interview',
            'rejected', 'offered', 'withdrawn'
        )),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, job_id)
);

CREATE TABLE cvs (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    cv_type VARCHAR(30) NOT NULL
        CHECK (cv_type IN (
            'fresh_graduate', 'experienced', 'banking'
        )),
    template_name VARCHAR(100),
    content JSONB NOT NULL DEFAULT '{}',
    pdf_storage_key TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE preparation_categories (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL UNIQUE,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE questions (
    id BIGSERIAL PRIMARY KEY,
    category_id BIGINT NOT NULL
        REFERENCES preparation_categories(id),
    question_text TEXT NOT NULL,
    question_type VARCHAR(20) NOT NULL DEFAULT 'mcq'
        CHECK (question_type IN ('mcq', 'written')),
    options JSONB NOT NULL DEFAULT '[]',
    correct_answer JSONB,
    explanation TEXT,
    difficulty VARCHAR(20) DEFAULT 'medium'
        CHECK (difficulty IN ('easy', 'medium', 'hard')),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE tests (
    id BIGSERIAL PRIMARY KEY,
    category_id BIGINT NOT NULL
        REFERENCES preparation_categories(id),
    title VARCHAR(200) NOT NULL,
    description TEXT,
    duration_minutes INTEGER,
    is_published BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE test_questions (
    test_id BIGINT REFERENCES tests(id) ON DELETE CASCADE,
    question_id BIGINT REFERENCES questions(id),
    question_order INTEGER NOT NULL,
    marks NUMERIC(6,2) NOT NULL DEFAULT 1,
    PRIMARY KEY (test_id, question_id),
    UNIQUE (test_id, question_order)
);

CREATE TABLE test_attempts (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    test_id BIGINT NOT NULL REFERENCES tests(id),
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    score NUMERIC(8,2),
    total_marks NUMERIC(8,2),
    status VARCHAR(20) NOT NULL DEFAULT 'in_progress'
        CHECK (status IN ('in_progress', 'completed', 'abandoned'))
);

CREATE TABLE test_answers (
    id BIGSERIAL PRIMARY KEY,
    attempt_id BIGINT NOT NULL
        REFERENCES test_attempts(id) ON DELETE CASCADE,
    question_id BIGINT NOT NULL REFERENCES questions(id),
    submitted_answer JSONB,
    marks_awarded NUMERIC(6,2),
    answered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (attempt_id, question_id)
);

CREATE TABLE job_fetch_runs (
    id BIGSERIAL PRIMARY KEY,
    source_id BIGINT NOT NULL REFERENCES job_sources(id),
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    status VARCHAR(20) NOT NULL DEFAULT 'running'
        CHECK (status IN ('running', 'success', 'failed')),
    jobs_found INTEGER NOT NULL DEFAULT 0,
    jobs_added INTEGER NOT NULL DEFAULT 0,
    error_message TEXT
);

CREATE TABLE admin_activity (
    id BIGSERIAL PRIMARY KEY,
    admin_id BIGINT REFERENCES app_users(id),
    action VARCHAR(150) NOT NULL,
    entity_type VARCHAR(100),
    entity_id BIGINT,
    details JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Initial general career categories
INSERT INTO job_categories (name) VALUES
('Banking'),
('Information Technology'),
('Finance and Accounting'),
('Government'),
('Private Sector'),
('Administration'),
('International Jobs'),
('Internships');

-- General interview and test preparation categories
INSERT INTO preparation_categories (name, description) VALUES
('General Job Interviews', 'Preparation for interviews across professions'),
('HR Interviews', 'Human resources interview preparation'),
('English Communication', 'English language and communication'),
('Aptitude Tests', 'Numerical and analytical aptitude'),
('Reasoning Tests', 'Logical and verbal reasoning'),
('General Knowledge', 'General knowledge and current affairs'),
('Computer and IT Basics', 'Basic computer and IT knowledge'),
('Professional and Technical MCQs', 'Profession-specific technical questions'),
('Banking Preparation', 'Optional banking interview and test preparation');
