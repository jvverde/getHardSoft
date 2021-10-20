#http://ramblingcookiemonster.github.io/SQLite-and-PowerShell/
#https://mrpanas.com/powershell-and-sqlite/

param(
	$database=(Invoke-Generate "database-???-###.db")
)


Import-Module PSSQLite

$Query = "CREATE TABLE IF NOT EXISTS NAMES (
	Fullname VARCHAR(20) PRIMARY KEY,
	Surname TEXT,
	Givenname TEXT,
	Birthdate DATETIME)"

    Invoke-SqliteQuery -Query $Query -DataSource $database

# We have a database, and a table, let's view the table info
    Invoke-SqliteQuery -DataSource $Database -Query "PRAGMA table_info(NAMES)"
	
