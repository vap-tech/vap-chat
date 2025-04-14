#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

use TableChecker;

# Загрузка конфигураций
my $config = decode_json do { local (@ARGV, $/) = ('config/config.json'); <> };

# Подключение к базе данных
my $db_config = "DBI:Pg:dbname=$config->{'database'}{'dbname'};
           host=$config->{'database'}{'host'};
           $config->{'database'}{'username'};
           $config->{'database'}{'password'}";

my $sql_files_dir = './sql/';

TableChecker::check_and_create_tables($db_config, $sql_files_dir);