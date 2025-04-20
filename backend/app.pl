#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use JSON qw(decode_json encode_json);
use DBI;
use Redis;
use Mojolicious::Lite;
use Mojo::Cookie::Response;
use Digest::MD5 qw(md5_hex);
use lib 'lib';
use Token;

# Загрузка конфигураций
my $config = decode_json do { local (@ARGV, $/) = ('config/config.json'); <> };

# Подключение к базе данных
my $dsn = "DBI:Pg:dbname=$config->{'database'}{'dbname'};host=$config->{'database'}{'host'}";
my $dbh = DBI->connect($dsn, $config->{'database'}{'username'}, $config->{'database'}{'password'});

# Подключение к Redis
my $redis = Redis->new(server => "$config->{'redis'}{'host'}:$config->{'redis'}{'port'}");

# Настройка приложения
app->secrets(['Qwerty123Qwerty123']);
# app->plugin('CORS');

get '/register' => sub {
    my $self = shift;
    $self->render(text => 'Hello World!');
};

# Эндпоинт регистрации
post '/register' => sub {
    my $self = shift;

    my $login = $self->param('name') // '';
    my $email = $self->param('email') // '';
    my $password = $self->param('password') // '';

    my $trio = $self->req->json;
    if (defined($trio)){
        $self->app->log->debug('json print:');
        for (keys(%$trio)){
            $self->app->log->debug("key: $_","value: " . %$trio{$_});
        }
        $login = %$trio{'login'};
        $email = %$trio{'email'};
        $password = %$trio{'password'}
    }

    unless ($login && $email && $password) {
        return $self->render(json => {error => 'All fields are required'}, status => 400);
    }

    if ($email !~ /@/) {
        return $self->render(json => {error => 'Invalid email format'}, status => 400);
    }

    my $md5_pass = md5_hex($password);

    eval {
        $dbh->do("INSERT INTO users (login) VALUES (?)", undef, $login);
        my $user_id = $dbh->last_insert_id(undef, undef, 'users', 'user_id');
        $dbh->do("INSERT INTO user_logins (email, password, user_id) VALUES (?, ?, ?)", undef, lc($email), $md5_pass, $user_id);

        # TODO: send email
        #send_confirmation_email(lc($email));

        return $self->render(json => {message => 'User registered successfully'}, status => 201);
    };
    if ($@) {
        warn "Error inserting into database: $@\n";
        return $self->render(json => {error => 'An error occurred during registration'}, status => 500);
    }
};

# Эндпоинт аутентификации
post '/auth' => sub {
    my $self = shift;

    # Забираем параметры из запроса
    my $email = $self->param('email') // '';
    my $password = $self->param('password') // '';

    my $duo = $self->req->json;
    if (defined($duo)){
        $self->app->log->debug('json print auth:');
        for (keys(%$duo)){
            $self->app->log->debug("key: $_","value: " . %$duo{$_});
        }
        $email = %$duo{'email'};
        $password = %$duo{'password'}
    }

    # Если не предоставлены, отказываем
    unless ($email && $password) {
        return $self->render(json => {error => 'Email and password are required'}, status => 400);
    }

    # Ищем user_id в табличке user_logins по email и password
    my $md5_pass = md5_hex($password);
    my $sth = $dbh->prepare("SELECT user_id FROM user_logins WHERE email = ? AND password = ?");
    $sth->execute(lc($email), $md5_pass);
    my $user_id = $sth->fetchrow_array();

    # Если данные в базе не нашлись
    if (!defined $user_id) {
        return $self->render(json => {error => 'Invalid credentials'}, status => 401);
    }

    # генерируем токены
    my $access_token = Token::generate_access_token($user_id);
    my $refresh_token = Token::generate_refresh_token($user_id);

    $redis->set("access_token:$user_id", $access_token, 'EX', 3600);

    # Если больше 3 авторизованных устройств, сбрасываем авторизацию на всех
    my $select_stmt = 'SELECT COUNT(*) FROM user_auths WHERE user_id = ?';
    my $sth_select = $dbh->prepare($select_stmt);
    $sth_select->execute($user_id);

    my $num_tokens = $sth_select->fetchrow_array();

    if ($num_tokens >= 3) {
        my $delete_stmt = "DELETE FROM user_auths WHERE user_id = ?";
        my $sth_delete = $dbh->prepare($delete_stmt);
        $sth_delete->execute($user_id);
    }

    # Добавляем текущую авторизацию в БД
    $dbh->do("INSERT INTO user_auths (refresh_token, refresh_token_date_start, user_id) VALUES (?, NOW(), ?)",
        undef, $refresh_token, $user_id);

    # Ставим куку access_token
    $self->cookie(
        access_token => $access_token,
            {
                domain => $config->{'domain'},
                path => '/',
                expires => time + 3600,
                httponly => 0,
                secure => 1
            }
    );

    # Ставим куку refresh_token
    $self->cookie(
        refresh_token => $refresh_token,
            {
                domain => $config->{'domain'},
                path => '/',
                expires => time + 172800,
                httponly => 1,
                secure => 1
            }
    );

    # Рендерим response
    return $self->render(json => {message => 'Authenticated successfully'}, status => 200);
};

# Стартуем
app->start('daemon', '-l', 'http://*:3001');