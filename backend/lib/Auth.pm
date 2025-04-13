package MyApp::Auth;
use warnings FATAL => 'all';
use JSON::WebToken;
use Crypt::Random qw(random_bytes_hex);

sub generate_access_token {
    my ($user_id) = @_;

    # Генерация секретного ключа для подписи JWT
    my $secret_key = "your_secret_key_here";  # Заменить на реальный секретный ключ

    # Создание payload для JWT
    my %payload = (
        iss => "example.com",                  # Изготовитель
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
    # Генерируем случайный токен длиной 32 байта
    my $random_bytes = random_bytes_hex(32);

    return $random_bytes;
}

1;

__END__;

# Секретный ключ: Ключевое значение, которое должно оставаться конфиденциальным.
# Оно используется для подписания токена и предотвращения подделки.
# Payload: Содержит информацию о пользователе и метаданные токена, такие как время истечения срока действия.
# Генерация токена: Токен создается путем шифрования payload с использованием алгоритма HS256 и секретного ключа.

# Crypt::Random: для генерации криптографически безопасного случайного числа.
# Длина 32 байта (или 64 символа в шестнадцатеричном формате) обеспечивает достаточную энтропию для защиты от атак методом подбора.

# импорт:
# use MyApp::Auth qw(generate_access_token);
# use MyApp::Auth qw(generate_refresh_token);