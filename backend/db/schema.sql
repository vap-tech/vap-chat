CREATE TABLE IF NOT EXISTS users (
    user_id SERIAL PRIMARY KEY,
    login TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS user_logins (
    email TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL,
    is_verified BOOLEAN DEFAULT FALSE,
    user_id INTEGER REFERENCES users(user_id),
    CONSTRAINT user_login_pkey PRIMARY KEY (email, user_id)
);

CREATE TABLE IF NOT EXISTS user_auth (
    refresh_token TEXT PRIMARY KEY,
    refresh_date_start TIMESTAMP WITH TIME ZONE NOT NULL,
    user_id INTEGER REFERENCES users(user_id)
);

CREATE TABLE IF NOT EXISTS user_profiles (
    user_id INTEGER PRIMARY KEY REFERENCES users(user_id),
    user_name TEXT,
    org_name TEXT,
    department TEXT,
    position TEXT
);

CREATE TABLE IF NOT EXISTS user_images (
    user_id INTEGER REFERENCES users(user_id),
    avatar TEXT,
    foto TEXT
);

CREATE TABLE IF NOT EXISTS groups (
    group_id SERIAL PRIMARY KEY,
    owner INTEGER REFERENCES users(user_id),
    is_private BOOLEAN NOT NULL,
    pin_message TEXT,
    logo TEXT
);

CREATE TABLE IF NOT EXISTS messages (
    message_id SERIAL PRIMARY KEY,
    from_user INTEGER REFERENCES users(user_id),
    header TEXT NOT NULL,
    body TEXT NOT NULL,
    to_user INTEGER REFERENCES users(user_id),
    to_group INTEGER REFERENCES groups(group_id)
);

CREATE TABLE IF NOT EXISTS images (
    image_id SERIAL PRIMARY KEY,
    data BYTEA
);