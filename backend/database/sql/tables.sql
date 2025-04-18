CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    login TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS user_auths (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    refresh_token TEXT,
    refresh_token_date_start TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE TABLE IF NOT EXISTS user_logins (
    id SERIAL PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL,
    is_verified BOOLEAN DEFAULT FALSE,
    user_id INTEGER REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS user_images (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    icon INTEGER REFERENCES images(id)
);

CREATE TABLE IF NOT EXISTS user_messages (
    id SERIAL PRIMARY KEY,
    from_user INTEGER REFERENCES users(id),
    to_user INTEGER REFERENCES users(id),
    body TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS user_photos (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    photo INTEGER REFERENCES images(id)
);

CREATE TABLE IF NOT EXISTS user_profiles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    first_name TEXT,
    last_name TEXT,
    org_name TEXT,
    department TEXT,
    position TEXT
);

CREATE TABLE IF NOT EXISTS groups (
    id SERIAL PRIMARY KEY,
    owner INTEGER REFERENCES users(id),
    logo INTEGER REFERENCES images(id),
    is_private BOOLEAN NOT NULL
);

CREATE TABLE IF NOT EXISTS group_messages (
    id SERIAL PRIMARY KEY,
    from_user INTEGER REFERENCES users(id),
    to_group INTEGER REFERENCES groups(id),
    body TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS group_pin_messages (
    id SERIAL PRIMARY KEY,
    group_id INTEGER REFERENCES groups(id),
    pin_message INTEGER REFERENCES group_messages(id)
);

CREATE TABLE IF NOT EXISTS images (
    id SERIAL PRIMARY KEY,
    data BYTEA
);