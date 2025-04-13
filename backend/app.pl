use strict;
use warnings;
use Mojolicious::Lite;
use JSON qw(decode_json encode_json);
use DBI;
use Redis;
use MIME::Base64;
use Digest::MD5 qw(md5_hex);
use Mail::Sender;

# Загрузка конфигураций
my $config = decode_json do { local (@ARGV, $/) = ('config/config.json'); <> };

# Подключение к базе данных
my $dsn = "DBI:Pg:dbname=$config->{'database'}{'dbname'};host=$config->{'database'}{'host'}";
my $dbh = DBI->connect($dsn, $config->{'database'}{'username'}, $config->{'database'}{'password'});

# Подключение к Redis
my $redis = Redis->new(server => "$config->{'redis'}{'host'}:$config->{'redis'}{'port'}");

# Настройка приложения
app->secrets(['supersecret']);
app->plugin('CORS');

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

        send_confirmation_email(lc($email));

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

    my $email = $self->param('email') // '';
    my $password = $self->param('password') // '';

    unless ($email && $password) {
        return $self->render(json => {error => 'Email and password are required'}, status => 400);
    }

    my $md5_pass = md5_hex($password);

    my $sth = $dbh->prepare("SELECT user_id FROM user_logins WHERE email = ? AND password = ?");
    $sth->execute(lc($email), $md5_pass);
    my ($user_id) = $sth->fetchrow_array();

    if (!$user_id) {
        return $self->render(json => {error => 'Invalid credentials'}, status => 401);
    }

    my $access_token = generate_access_token($user_id);
    my $refresh_token = generate_refresh_token($user_id);

    $redis->set("access_token:$user_id", $access_token, 'EX', 1800); # 30 minutes expiration

    $dbh->do("INSERT INTO user_auth (refresh_token, refresh_date_start, user_id) VALUES (?, NOW(), ?)", undef, $refresh_token, $user_id);

    $self->res->cookies->{access_token} = {value => $access_token, domain => 'vap-chat.v-petrenko.ru', path => '/api/v1/auth'};
    $self->res->cookies->{refresh_token} = {value => $refresh_token, domain => 'vap-chat.v-petrenko.ru', path => '/api/v1/auth', httponly => 1};

    return $self->render(json => {message => 'Authenticated successfully'}, status => 200);
};

# Обновление токена
post '/refresh_auth' => sub {
    my $self = shift;

    my $refresh_token = $self->req->headers->cookie('refreshToken')->value;
    my $user_id = $self->req->headers->cookie('userId')->value;

    unless ($refresh_token && $user_id) {
        return $self->render(json => {error => 'Refresh token or user ID not found in cookies'}, status => 400);
    }

    my $sth = $dbh->prepare("SELECT * FROM user_auth WHERE refresh_token = ? AND user_id = ?");
    $sth->execute($refresh_token, $user_id);
    my ($found_refresh_token, $refresh_date_start) = $sth->fetchrow_array();

    if (!$found_refresh_token) {
        return $self->render(json => {error => 'Refresh token not found'}, status => 404);
    }

    if (time() > str2time($refresh_date_start) + 172800) {
        return $self->render(json => {error => 'Refresh token expired'}, status => 401);
    }

    my $new_access_token = generate_access_token($user_id);
    my $new_refresh_token = generate_refresh_token($user_id);

    $redis->set("access_token:$user_id", $new_access_token, 'EX', 1800); # 30 minutes expiration

    $dbh->do("UPDATE user_auth SET refresh_token = ?, refresh_date_start = NOW() WHERE user_id = ?", undef, $new_refresh_token, $user_id);

    $self->res->cookies->{access_token} = {value => $new_access_token, domain => 'vap-chat.v-petrenko.ru', path => '/api/v1/auth'};
    $self->res->cookies->{refresh_token} = {value => $new_refresh_token, domain => 'vap-chat.v-petrenko.ru', path => '/api/v1/auth', httponly => 1};

    return $self->render(json => {message => 'Tokens refreshed successfully'}, status => 200);
};

# Изменение пароля
post '/change_password' => sub {
    my $self = shift;

    my $old_password = $self->param('oldPassword') // '';
    my $new_password = $self->param('newPassword') // '';
    my $user_id = $self->req->headers->cookie('userId')->value;

    unless ($old_password && $new_password && length($new_password) >= 6) {
        return $self->render(json => {error => 'Old password or new password missing or invalid'}, status => 400);
    }

    my $access_token = $redis->get("access_token:$user_id");
    unless ($access_token) {
        return $self->render(json => {error => 'Access token not found'}, status => 403);
    }

    my $md5_old_pass = md5_hex($old_password);
    my $md5_new_pass = md5_hex($new_password);

    my $sth = $dbh->prepare("SELECT user_id FROM user_logins WHERE user_id = ? AND password = ?");
    $sth->execute($user_id, $md5_old_pass);
    my ($found_user_id) = $sth->fetchrow_array();

    if (!$found_user_id) {
        return $self->render(json => {error => 'Incorrect old password'}, status => 401);
    }

    $dbh->do("UPDATE user_logins SET password = ? WHERE user_id = ?", undef, $md5_new_pass, $user_id);

    notify_password_change($user_id);

    return $self->render(json => {message => 'Password changed successfully'}, status => 200);
};

# Редактирование профиля
post '/edit_profile' => sub {
    my $self = shift;

    my $user_id = $self->req->headers->cookie('userId')->value;
    my $user_name = $self->param('userName') // '';
    my $org_name = $self->param('orgName') // '';
    my $department = $self->param('department') // '';
    my $position = $self->param('position') // '';

    my $access_token = $redis->get("access_token:$user_id");
    unless ($access_token) {
        return $self->render(json => {error => 'Access token not found'}, status => 403);
    }

    foreach my $field ($user_name, $org_name, $department, $position) {
        next unless defined $field;
        unless ($field =~ /^[a-zA-Z0-9\s]+$/) {
            return $self->render(json => {error => 'Field contains invalid characters'}, status => 400);
        }
    }

    $dbh->do("UPDATE user_profiles SET user_name = ?, org_name = ?, department = ?, position = ? WHERE user_id = ?", undef, $user_name, $org_name, $department, $position, $user_id);

    return $self->render(json => {message => 'Profile updated successfully'}, status => 200);
};

# Загрузка изображений
post '/upload_image' => sub {
    my $self = shift;

    my $user_id = $self->req->headers->cookie('userId')->value;
    my $avatar_data = $self->param('avatarData') // '';
    my $foto_data = $self->param('fotoData') // '';

    my $access_token = $redis->get("access_token:$user_id");
    unless ($access_token) {
        return $self->render(json => {error => 'Access token not found'}, status => 403);
    }

    my $decoded_avatar = decode_base64($avatar_data);
    my $decoded_foto = decode_base64($foto_data);

    my $sth = $dbh->prepare("INSERT INTO images (data) VALUES (?) RETURNING image_id");
    $sth->execute($decoded_avatar);
    my ($avatar_id) = $sth->fetchrow_array();

    $sth->execute($decoded_foto);
    my ($foto_id) = $sth->fetchrow_array();

    $dbh->do("INSERT INTO user_images (user_id, avatar, foto) VALUES (?, ?, ?)", undef, $user_id, $avatar_id, $foto_id);

    return $self->render(json => {message => 'Images uploaded successfully'}, status => 200);
};

# CRUD для сообщений
# Создание сообщения
post '/messages' => sub {
    my $self = shift;

    my $user_id = $self->req->headers->cookie('userId')->value;
    my $header = $self->param('header') // '';
    my $body = $self->param('body') // '';
    my $to_user = $self->param('toUser') // '';
    my $to_group = $self->param('toGroup') // '';

    my $access_token = $redis->get("access_token:$user_id");
    unless ($access_token) {
        return $self->render(json => {error => 'Access token not found'}, status => 403);
    }

    $dbh->do("INSERT INTO messages (from_user, header, body, to_user, to_group) VALUES (?, ?, ?, ?, ?)", undef, $user_id, $header, $body, $to_user, $to_group);

    return $self->render(json => {message => 'Message created successfully'}, status => 201);
};

# Получение списка сообщений
get '/messages' => sub {
    my $self = shift;

    my $user_id = $self->req->headers->cookie('userId')->value;

    my $access_token = $redis->get("access_token:$user_id");
    unless ($access_token) {
        return $self->render(json => {error => 'Access token not found'}, status => 403);
    }

    my $sth = $dbh->prepare("SELECT * FROM messages WHERE from_user = ? OR to_user = ?");
    $sth->execute($user_id, $user_id);
    my $messages = $sth->fetchall_arrayref({});

    return $self->render(json => $messages, status => 200);
};

# Удаление сообщения
delete '/messages/:id' => sub {
    my $self = shift;

    my $user_id = $self->req->headers->cookie('userId')->value;
    my $message_id = $self->stash('id');

    my $access_token = $redis->get("access_token:$user_id");
    unless ($access_token) {
        return $self->render(json => {error => 'Access token not found'}, status => 403);
    }

    $dbh->do("DELETE FROM messages WHERE message_id = ? AND from_user = ?", undef, $message_id, $user_id);

    return $self->render(json => {message => 'Message deleted successfully'}, status => 204);
};

# CRUD для групп
# Создание группы
post '/groups' => sub {
    my $self = shift;

    my $user_id = $self->req->headers->cookie('userId')->value;
    my $is_private = $self->param('isPrivate') // '';
    my $pin_message = $self->param('pinMessage') // '';
    my $logo = $self->param('logo') // '';

    my $access_token = $redis->get("access_token:$user_id");
    unless ($access_token) {
        return $self->render(json => {error => 'Access token not found'}, status => 403);
    }

    $dbh->do("INSERT INTO groups (owner, is_private, pin_message, logo) VALUES (?, ?, ?, ?)", undef, $user_id, $is_private, $pin_message, $logo);

    return $self->render(json => {message => 'Group created successfully'}, status => 201);
};

# Получение списка групп
get '/groups' => sub {
    my $self = shift;

    my $user_id = $self->req->headers->cookie('userId')->value;

    my $access_token = $redis->get("access_token:$user_id");
    unless ($access_token) {
        return $self->render(json => {error => 'Access token not found'}, status => 403);
    }

    my $sth = $dbh->prepare("SELECT * FROM groups WHERE owner = ?");
    $sth->execute($user_id);
    my $groups = $sth->fetchall_arrayref({});

    return $self->render(json => $groups, status => 200);
};

# Удаление группы
delete '/groups/:id' => sub {
    my $self = shift;

    my $user_id = $self->req->headers->cookie('userId')->value;
    my $group_id = $self->stash('id');

    my $access_token = $redis->get("access_token:$user_id");
    unless ($access_token) {
        return $self->render(json => {error => 'Access token not found'}, status => 403);
    }

    $dbh->do("DELETE FROM groups WHERE group_id = ? AND owner = ?", undef, $group_id, $user_id);

    return $self->render(json => {message => 'Group deleted successfully'}, status => 204);
};

# CRUD для изображений пользователей
# Получение изображений пользователя
get '/user_images' => sub {
    my $self = shift;

    my $user_id = $self->req->headers->cookie('userId')->value;

    my $access_token = $redis->get("access_token:$user_id");
    unless ($access_token) {
        return $self->render(json => {error => 'Access token not found'}, status => 403);
    }

    my $sth = $dbh->prepare("SELECT * FROM user_images WHERE user_id = ?");
    $sth->execute($user_id);
    my $images = $sth->fetchall_arrayref({});

    return $self->render(json => $images, status => 200);
};

# Обновление изображений пользователя
put '/user_images' => sub {
    my $self = shift;

    my $user_id = $self->req->headers->cookie('userId')->value;
    my $avatar_data = $self->param('avatarData') // '';
    my $foto_data = $self->param('fotoData') // '';

    my $access_token = $redis->get("access_token:$user_id");
    unless ($access_token) {
        return $self->render(json => {error => 'Access token not found'}, status => 403);
    }

    my $decoded_avatar = decode_base64($avatar_data);
    my $decoded_foto = decode_base64($foto_data);

    my $sth = $dbh->prepare("UPDATE user_images SET avatar = ?, foto = ? WHERE user_id = ?");
    $sth->execute($decoded_avatar, $decoded_foto, $user_id);

    return $self->render(json => {message => 'User images updated successfully'}, status => 200);
};

# Верификация пользователя
post '/verify' => sub {
    my $self = shift;

    my $verification_code = $self->param('verificationCode') // '';

    unless ($verification_code) {
        return $self->render(json => {error => 'Verification code not provided'}, status => 400);
    }

    my $sth = $dbh->prepare("SELECT user_id FROM user_logins WHERE verification_code = ?");
    $sth->execute($verification_code);
    my ($user_id) = $sth->fetchrow_array();

    if (!$user_id) {
        return $self->render(json => {error => 'Invalid verification code'}, status => 400);
    }

    $dbh->do("UPDATE user_logins SET is_verified = TRUE WHERE user_id = ?", undef, $user_id);

    return $self->render(json => {message => 'User verified successfully'}, status => 200);
};

# Повторная отправка письма подтверждения
post '/resend_verification_email' => sub {
    my $self = shift;

    my $email = $self->param('email') // '';

    unless ($email) {
        return $self->render(json => {error => 'Email not provided'}, status => 400);
    }

    my $sth = $dbh->prepare("SELECT user_id FROM user_logins WHERE email = ? AND is_verified = FALSE");
    $sth->execute(lc($email));
    my ($user_id) = $sth->fetchrow_array();

    if (!$user_id) {
        return $self->render(json => {error => 'User not found or already verified'}, status => 400);
    }

    resend_verification_email($email);

    return $self->render(json => {message => 'Verification email resent successfully'}, status => 200);
};

start '3000';