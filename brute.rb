#!/usr/bin/ruby

require 'digest/md5'
require 'rubygems'
require 'sqlite3'

class Brute
  
  def initialize(with_db)
    
    @maxchar = 14  
    @chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    
    db_init("hash_table.db") if with_db

    @with_db = with_db  
    
  end

  def crack (password)

    @password = password
    @found = false
    
    if @with_db
      return true if db_check
    end

    for i in (0..@maxchar)
      return true if @found
      recurse(i, 0, "")
    end
  end

  def recurse (width, pos, plain)
    for i in (0..@chars.length)
      return true if @found
      tmp_pass = "#{plain}#{@chars[i]}"
      if pos < width-1
        recurse(width, pos+1, "#{tmp_pass}")
      end
      check(tmp_pass)
    end
  end
  
  def check (pass)
    pass_hash = Digest::MD5.hexdigest(pass)
    db_insert(pass_hash, pass) if @with_db
    if @password == pass_hash
      puts "Secret (#@password) is: #{pass}"
      @found = true
      return true
    end
  end

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
end

t = Time.now
puts "Starting at #{t}"

trap("INT") do
  exit
end

c = Brute.new(true)
c.crack(usr_hash)

te = Time.now
puts "Time: #{te-t}s"
