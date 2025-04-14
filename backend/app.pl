#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use JSON qw(decode_json encode_json);
use DBI;
use Mojolicious::Lite -signatures;
use Digest::MD5 qw(md5_hex);

# Загрузка конфигураций
my $config = decode_json do { local (@ARGV, $/) = ('config/config.json'); <> };

# Подключение к базе данных
my $dsn = "DBI:Pg:dbname=$config->{'database'}{'dbname'};host=$config->{'database'}{'host'}";
my $dbh = DBI->connect($dsn, $config->{'database'}{'username'}, $config->{'database'}{'password'});

# Настройка приложения
app->secrets(['Qwerty123Qwerty123']);
# app->plugin('CORS');

get '/' => sub ($c) {
  $c->render(text => 'Hello World!');
};

# Эндпоинт регистрации
post '/register' => sub {
    my $self = shift;

    my $login = $self->param('login') // '';
    my $email = $self->param('email') // '';
    my $password = $self->param('password') // '';

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


app->start('daemon', '-l', 'http://*:3000');