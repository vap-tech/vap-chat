#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

# cpanm !!!!
use Mojolicious::Lite;
use Mojolicious::Plugin::OpenAPI;

# Подключаем плагин OpenAPI
app->plugin(OpenAPI => {
    url => '/swagger.json',
    spec => {
        openapi => '3.0.0',
        info => {
            title => 'My App API',
            version => '1.0.0',
            description => 'RESTful API for managing users, groups, and more.',
        },
        servers => [
            { url => 'http://localhost:3000/api/v1' },
        ],
        paths => {},
        components => {
            securitySchemes => {
                bearerAuth => {
                    type => 'http',
                    scheme => 'bearer',
                    bearerFormat => 'JWT',
                },
            },
        },
    },
});

# существующий код приложения похоже тут будет

start '3000';

# Определение маршрутов и методов API внутри блока paths. Например, для маршрута /register:
app->plugin(OpenAPI => {
    ...
    paths => {
        '/register' => {
            post => {
                summary => 'Register a new user',
                requestBody => {
                    content => {
                        'application/json' => {
                            schema => {
                                type => 'object',
                                properties => {
                                    login => { type => 'string' },
                                    email => { type => 'string' },
                                    password => { type => 'string' },
                                },
                                required => ['login', 'email', 'password'],
                            },
                        },
                    },
                },
                responses => {
                    '201' => {
                        description => 'User registered successfully',
                        content => {
                            'application/json' => {
                                schema => {
                                    type => 'object',
                                    properties => {
                                        message => { type => 'string' },
                                    },
                                },
                            },
                        },
                    },
                    '400' => {
                        description => 'Bad Request',
                        content => {
                            'application/json' => {
                                schema => {
                                    type => 'object',
                                    properties => {
                                        error => { type => 'string' },
                                    },
                                },
                            },
                        },
                    },
                },
            },
        },
    },
});

# Запуск Swagger UI
app->routes->get('/docs/*doc' => sub {
    my $c = shift;
    $c->render_static('index.html');
})->name('docs')->under('/docs');
# UI будет по адресу /docs

# Создать папку public/docs и поместить туда файлы Swagger UI.
# скачать: https://github.com/swagger-api/swagger-ui/releases.