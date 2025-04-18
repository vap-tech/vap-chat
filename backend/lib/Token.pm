package Token;
use strict;
use warnings FATAL => 'all';
use JSON qw( decode_json );
use JSON::WebToken;


# Загрузка конфигураций
my $config = decode_json do { local (@ARGV, $/) = ('./config/config.json'); <> };
my $secret_key = "$config->{'jwt'}{'secret_key'}";  # извлекаем секретный ключ

sub generate_access_token {
    my ($user_id) = @_;

    # Создание payload для JWT
    my %payload = (
        iss => "$config->{'domain'}",          # Изготовитель
        exp => time + 3600,                    # Время истечения срока действия (через час)
        iat => time,                           # Время выпуска
        jti => rand(),                         # Уникальный идентификатор токена
        sub => $user_id,                       # Идентификатор пользователя
    );

    # Генерация JWT-токена
    my $token = JSON::WebToken->encode(\%payload, $secret_key, 'HS256');

    return $token;
}

sub generate_refresh_token {
    my ($user_id) = @_;

    # Payload для JWT
    my %payload = (
        iss => "$config->{'domain'}",         # Издатель токена
        exp => time + 604800,                 # Срок действия (например, неделя)
        iat => time,                          # Время выдачи токена
        jti => rand(),                        # Уникальный идентификатор токена
        sub => $user_id,                      # Пользователь
    );

    # Генерация JWT
    my $jwt = JSON::WebToken->encode(\%payload, $secret_key, 'HS256');

    return $jwt;
}

sub verify_refresh_token {
    my $jwt = @_;

    my $payload = {};
    my $result = eval {
        $payload = JSON::WebToken->decode($jwt, $secret_key, ['HS256'], {});
        1;  # Возврат истинного значения при успехе
    };

    if (!defined $result) {
        warn "Error decoding JWT: $@\n";
        return undef;
    }

    return $payload;
}

sub update_tokens {
    my ($refresh_token) = @_;

    # Проверяем refresh-токен
    my $payload = verify_refresh_token($refresh_token);
    unless (defined $payload) {
        return {error => 'Invalid refresh token'};
    }

    # Генерируем новый access-токен
    my $access_token = generate_access_token($payload->{sub});

    # Генерируем новый refresh-токен
    my $new_refresh_token = generate_refresh_token($payload->{sub});

    return {
        access_token => $access_token,
        refresh_token => $new_refresh_token,
    };
}

1;
