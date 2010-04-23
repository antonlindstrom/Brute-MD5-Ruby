#!/usr/bin/ruby

#require 'digest/md5'
require 'rubygems'
require 'sqlite3'


def database_print
		database = "hash_table.db"

    if !File.exists?(database)
    	puts "Database does not exist!"
		else
      db = SQLite3::Database.new(database)
    end

		#db.get_first_value("SELECT plain FROM hashes")

		#db.get_first_value("SELECT plain FROM hashes ORDER BY id ASC LIMIT 1")
		db.results_as_hash = true
  	db.execute( "SELECT * FROM hashes" ) do |row|
    	puts "#{row['hash']} #{row['plain']}"
  	end

end

database_print
