package TableChecker;

use strict;
use warnings;
use Exporter 'import';
use DBI;
use File::Slurp qw(read_file);

our @EXPORT_OK = qw(check_and_create_tables);

sub check_and_create_tables {
    my ($db_config, $sql_files_dir) = @_;

    # Соединение с базой данных
    my $dbh = connect_to_db($db_config);

    # Чтение всех SQL-файлов из указанной директории
    opendir(my $dh, $sql_files_dir) || die "Cannot open directory '$sql_files_dir': $!";
    while (readdir($dh)) {
        next unless /\.sql$/i;  # Берём только файлы с расширением .sql
        my $filename = $_;
        print "Processing file: $filename\n";

        my $content = read_file("$sql_files_dir/$filename") || die "Can't read file $filename: $!";

        # Разделяем файл на отдельные CREATE TABLE инструкции
        my @statements = split(/;\s*\n/, $content);

        foreach my $statement (@statements) {
            next unless $statement =~ m/^\s*create\s+table/i;

            # Парсим имя таблицы из оператора CREATE TABLE
            my ($table_name) = $statement =~ /^\s*create\s+table\s+(.*?)\s*/i;
            chomp $table_name;

            # Проверяем существование таблицы
            if (!check_table_exists($dbh, $table_name)) {
                print "Creating table: $table_name\n";
                execute_sql($dbh, $statement);
            } else {
                print "Table exists: $table_name\n";
            }
        }
    }
    closedir($dh);

    $dbh->disconnect();
}

sub connect_to_db {
    my ($config) = @_;
    my $dsn = "DBI:Pg:dbname=".$config->{dbname}.";host=".$config->{host}.";port=".$config->{port};
    my $dbh = DBI->connect($dsn, $config->{username}, $config->{password})
        or die "Could not connect to the database: ", DBI->errstr;
    return $dbh;
}

sub check_table_exists {
    my ($dbh, $table_name) = @_;
    my $sth = $dbh->prepare(qq[
        SELECT COUNT(*) AS count
        FROM information_schema.tables
        WHERE table_name = ?
    ]);
    $sth->execute($table_name);
    my ($count) = $sth->fetchrow_array();
    return $count > 0;
}

sub execute_sql {
    my ($dbh, $sql) = @_;
    my $sth = $dbh->prepare($sql);
    $sth->execute()
        or die "Failed to execute SQL statement: ".$sth->errstr."\n".$sql;
}

1;