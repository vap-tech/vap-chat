# vap-chat

Структура проекта

project/  
├── app.pl            # Основной файл приложения  
├── lib/              # Библиотеки и модули  
│   └── MyApp.pm       # Модуль приложения  
├── t/                # Тесты  
│   └── test.pl        # Примеры тестов  
├── database/               # SQL схемы и миграции  
│   └── tables/     # SQL таблиц  
├── config/           # Конфигурационные файлы  
│   └── config.json    # Файл конфигурации  
├── Dockerfile        # Файл сборки образа Docker  
├── docker-compose.yml# Файл оркестрации Docker Compose  
└── README.md          # Описание проекта  

$self->app->log->debug("Hello World!");