#!/usr/bin/ruby

require 'digest/md5'
require 'rubygems'
require 'sqlite3'

class Brute
  
  def initialize(with_db = false)
    @with_db = with_db
    @maxchar = 10
    @chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    
    db_init("hash_table.db") if @with_db
  end
  
  def break(password)
    @password = password
    
    if @with_db
      return true if db_check
    end
    
    threads = []
    
    for i in (0..@maxchar)
      threads << Thread.new(i) do |n| 
        recurse(n, 0, "")
      end  
    end
    threads.each {|thr| thr.join}
  end
  
  def checkPassword(pass)
    pass_hash = Digest::MD5.hexdigest(pass)
    db_insert(pass_hash, pass) if @with_db
    if pass_hash == @password
      puts "Secret (#@password) is: #{pass}"
      @found = true
    end
  end
  
  def recurse(width, position, baseString)
    return true if @found
    for i in (0..@chars.length)
      if (position < width - 1)
        recurse(width, position + 1, "#{baseString}#{@chars[i]}")
      end
      checkPassword("#{baseString}#{@chars[i]}")
    end
  end

  ##
  # SQLite Database
  # It will take longer time to crack hashes with the database but
  # will go faster when it is in the database.
  ##
  def db_init (database)
    if !File.exists?(database) 
      @db = SQLite3::Database.new(database)
      @db.execute "CREATE TABLE hashes (id INTEGER PRIMARY KEY, hash TEXT UNIQUE, plain TEXT);"
      @db.execute "REPLACE INTO hashes (hash, plain) VALUES (0, 0)"
    else
      @db = SQLite3::Database.new(database)
    end
  end

  def db_check
    plain = @db.get_first_value("SELECT plain FROM hashes WHERE hash = ?", @password)
    
    if plain
      puts "Secret (#@password) is: #{plain}"
      return true 
    else
      return false
    end
  end

  def db_insert(hash, plain)
    begin
      exists_in_db = @db.get_first_value("SELECT count(*) FROM hashes WHERE hash = ?", hash)
      #puts "#{hash} - #{plain} #{exists_in_db}"
      if exists_in_db.to_i < 1
        @db.execute("INSERT INTO hashes (hash, plain) VALUES ('#{hash}', '#{plain}')")
        #puts "Committing insert: #{hash} - #{plain}"
      end
    rescue
      puts "Whoops, something went wrong with the DB."
    end
  end
  
end

##
# MAIN
##

if ARGV.size > 0 
  usr_hash = ARGV[0]
else
  usr_hash = "47bce5c74f589f4867dbd57e9ca9f808"
  #47bce5c74f589f4867dbd57e9ca9f808 aaa
end

t = Time.now
puts "Starting at #{t}"

trap("INT") do
  puts ""
  exit
end

m = Brute.new()
m.break(usr_hash)

te = Time.now
puts "Time: #{te-t}s"