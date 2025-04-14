# Модуль проверки таблиц на наличие в БД

## Пример структуры:
migrations/  
├── TableChecker.pm  
├── sql/  
│   ├── schema.sql  
│   └── another_schema.sql  
└── config.json  

## Описание:
Если есть два файла SQL: schema.sql и another_schema.sql и
эти файлы содержат операторы CREATE TABLE, то, как правило, они определяют схему вашей базы данных.

### Пример использования:

```
#!/usr/bin/env perl
use strict;
use warnings;
use TableChecker;

my $db_config = {
    host => 'localhost',
    port => 5432,
    username => 'postgres',
    password => 'password',
    dbname => 'mydb'
};

my $sql_files_dir = './sql/';

TableChecker::check_and_create_tables($db_config, $sql_files_dir);
```

### Что делает скрипт:
- Читает все .sql файлы из заданной директории.
- Извлекает имена таблиц из операторов CREATE TABLE.
- Проверяет, существует ли каждая таблица в базе данных.
- Если таблицы нет, создаёт её согласно оператору из файла.

### Примечание:
Понадобится установленный Perl-модуль File::Slurp (cpanm File::Slurp).
