#!/usr/bin/ruby3.0
# coding:utf-8

require 'sqlite3'
require 'json'
require 'pp'
require 'securerandom'

@monsql_cmd = ENV['MONSQL'] || "/usr/lib/panda/bin/monsql"
@directory = ENV['LDDIRECTORY'] || "/usr/lib/jma-receipt/lddef/directory"
STDERR.puts @directory

def monsql(command)
  STDERR.puts command
  json = `#{@monsql_cmd} -c "#{command}" -o JSON -dir #{@directory}`
  status = $?
  ret = nil
  begin
    ret = JSON.parse(json)
  rescue Exception
  end
  [status,ret]
end

def converted?
  status,ret = monsql("SELECT * FROM tbl_plugin_meta WHERE name = 'convert'")
  unless status.exitstatus == 0
    STDERR.puts "monsql error"
    exit 1
  end
  !ret.empty?
end

def convert_database(dbpath,force)
  unless force
    if converted?
      STDERR.puts "already converted; exit"
      exit 0
    end
  end

  begin
    db = SQLite3::Database.new(dbpath)
    db.type_translation = true
    sql = <<-EOS
      SELECT 
        name,
        version,
        description,
        vendor,
        date,
        url,
        install,
        link,
        available 
      FROM control;
    EOS
    rows = db.execute(sql)
    rows.each do |row|
      row[4] = "#{$1}-#{$2}-#{$3}" if %r|(\d{4})(\d{2})(\d{2})| =~ row[4]
      begin
        row[2].encode!('utf-8','euc-jp')
      rescue Exception
        row[2] = ''
      end
      sql = <<-EOS
        INSERT INTO tbl_plugin 
        VALUES (
          '#{row[0]}',
          '#{row[1]}',
          '#{row[2]}',
          '#{row[3]}',
          '#{row[4]}',
          '#{row[5]}',
          '#{row[6]}',
          '#{row[7]}',
          '#{row[8]}');
      EOS
      STDERR.puts sql
      monsql(sql)
    end
  rescue Exception => ex
    STDERR.puts "old db error dbfile:#{dbpath}"
    STDERR.puts ex.backtrace
  end
  unless converted?
    monsql("INSERT INTO tbl_plugin_meta VALUES('convert','done')")
  end
end

force = false
ARGV.each do |a| force = true if a == '-f' end

dbpath = ENV['PACKAGEDB'] || "/var/lib/jma-receipt/plugin/package.db"
STDERR.puts dbpath
convert_database(dbpath,force)
