#!/usr/bin/ruby

require 'rubygems'
require 'sqlite3'


def database_print
    database = "hash_table.db"

    if !File.exists?(database)
      puts "Database does not exist!"
    else
      db = SQLite3::Database.new(database)
    end

    db.results_as_hash = true
    db.execute( "SELECT * FROM hashes" ) do |row|
      puts "#{row['hash']} #{row['plain']}"
    end

end

database_print
