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

get '/' => sub {
    my $self = shift;
    $self->render(text => 'Hello World!');
};

# Эндпоинт регистрации
post '/register' => sub {
    my $self = shift;

    my $login = $self->param('login') // '';
    my $email = $self->param('email') // '';
    my $password = $self->param('password') // '';
    my $trio = $self->req->json;

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

    # TODO: debug disable
    my $json_data = $self->req->json;
    if (defined $json_data){
        print("\n|||" . $json_data . "|||\n");
    }

    # Забираем параметры из запроса
    my $email = $self->param('email') // '';
    my $password = $self->param('password') // '';

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

    $dbh->do("INSERT INTO user_auths (refresh_token, refresh_token_date_start, user_id) VALUES (?, NOW(), ?)", undef, $refresh_token, $user_id);

    my $cookie_access = Mojo::Cookie::Response->new;
    $cookie_access->name('access_token');
    $cookie_access->value($access_token);
    $cookie_access->domain("$config->{'domain'}");
    $cookie_access->path('/');
    $cookie_access->expires(time + 3600);
    $cookie_access->httponly(0);
    # $cookie->secure($bool);

    my $cookie_refresh = Mojo::Cookie::Response->new;
    $cookie_refresh->name('refresh_token');
    $cookie_refresh->value($refresh_token);
    $cookie_refresh->domain("$config->{'domain'}");
    $cookie_refresh->path('/');
    $cookie_refresh->expires(time + 172800);
    # $cookie_refresh->httponly(1);
    # $cookie->secure($bool);

    #$self->cookie(access_token => 'token', {domain => 'example.com', expires => time + 60} );
    #$self->session(user => 'кот');

    $self->cookie(secret => 'v.petrenko', {secure => 1, httponly => 1, path => '/auth', domain => 'localhost', expires => time + 60});


    #$self->res->cookie($cookie_refresh);
    $self->app->log->debug("cookie: $cookie_access");

    return $self->render(json => {message => 'Authenticated successfully'}, status => 200);
};


app->start('daemon', '-l', 'http://*:3000');