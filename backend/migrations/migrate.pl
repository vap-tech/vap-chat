#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

use JSON qw(decode_json);
use lib 'migrations';
use TableChecker;

# Загрузка конфигураций
my $config = decode_json do { local (@ARGV, $/) = ('config/config.json'); <> };

# Приводим к нужному виду
my $db_config = {
    host => $config->{'database'}{'host'},
    port => 5432,
    username => $config->{'database'}{'username'},
    password => $config->{'database'}{'password'},
    dbname => $config->{'database'}{'dbname'}
};

my $sql_files_dir = './migrations/sql/';

TableChecker::check_and_create_tables($db_config, $sql_files_dir);