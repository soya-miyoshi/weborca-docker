#!/usr/bin/ruby3.0
# coding : utf-8

require 'optparse'

BACKUP_SUFIX = "_backup"
TEMP_SUFIX = "_temp"

ERRFILE = "/tmp/jma-receipt_db_check.log"

UTF8MJ = [
 ["\xE2\x80\x94","\xE2\x80\x95"],
 ["\xE3\x80\x9C","\xEF\xBD\x9E"],
 ["\xE2\x80\x96","\xE2\x88\xA5"],
 ["\xE2\x88\x92","\xEF\xBC\x8D"],
 ["\xC2\xA2","\xEF\xBF\xA0"],
 ["\xC2\xA3","\xEF\xBF\xA1"],
 ["\xC2\xAC","\xEF\xBF\xA2"],
 ["\xC2\xA5","\xEF\xBF\xA5"],
 ["\x3F","\xE2\x88\x91"],
 ["\xE2\x80\xBE","\xEF\xBF\xA3"]
]

# UTF-8 (半角カナ) → UTF-8f(全角カナ)
UTF8KANA = [
 ["\xEF\xBD\xA1","\xE3\x80\x82"],
 ["\xEF\xBD\xA2","\xE3\x80\x8C"],
 ["\xEF\xBD\xA3","\xE3\x80\x8D"],
 ["\xEF\xBD\xA4","\xE3\x80\x81"],
 ["\xEF\xBD\xA5","\xE3\x83\xBB"],
 ["\xEF\xBD\xA6","\xE3\x83\xB2"],
 ["\xEF\xBD\xA7","\xE3\x82\xA1"],
 ["\xEF\xBD\xA8","\xE3\x82\xA3"],
 ["\xEF\xBD\xA9","\xE3\x82\xA5"],
 ["\xEF\xBD\xAA","\xE3\x82\xA7"],
 ["\xEF\xBD\xAB","\xE3\x82\xA9"],
 ["\xEF\xBD\xAC","\xE3\x83\xA3"],
 ["\xEF\xBD\xAD","\xE3\x83\xA5"],
 ["\xEF\xBD\xAE","\xE3\x83\xA7"],
 ["\xEF\xBD\xAF","\xE3\x83\x83"],
 ["\xEF\xBD\xB0","\xE3\x83\xBC"],
 ["\xEF\xBD\xB1","\xE3\x82\xA2"],
 ["\xEF\xBD\xB2","\xE3\x82\xA4"],
 ["\xEF\xBD\xB3","\xE3\x82\xA6"],
 ["\xEF\xBD\xB4","\xE3\x82\xA8"],
 ["\xEF\xBD\xB5","\xE3\x82\xAA"],
 ["\xEF\xBD\xB6","\xE3\x82\xAB"],
 ["\xEF\xBD\xB7","\xE3\x82\xAD"],
 ["\xEF\xBD\xB8","\xE3\x82\xAF"],
 ["\xEF\xBD\xB9","\xE3\x82\xB1"],
 ["\xEF\xBD\xBA","\xE3\x82\xB3"],
 ["\xEF\xBD\xBB","\xE3\x82\xB5"],
 ["\xEF\xBD\xBC","\xE3\x82\xB7"],
 ["\xEF\xBD\xBD","\xE3\x82\xB9"],
 ["\xEF\xBD\xBE","\xE3\x82\xBB"],
 ["\xEF\xBD\xBF","\xE3\x82\xBD"],
 ["\xEF\xBE\x80","\xE3\x82\xBF"],
 ["\xEF\xBE\x81","\xE3\x83\x81"],
 ["\xEF\xBE\x82","\xE3\x83\x84"],
 ["\xEF\xBE\x83","\xE3\x83\x86"],
 ["\xEF\xBE\x84","\xE3\x83\x88"],
 ["\xEF\xBE\x85","\xE3\x83\x8A"],
 ["\xEF\xBE\x86","\xE3\x83\x8B"],
 ["\xEF\xBE\x87","\xE3\x83\x8C"],
 ["\xEF\xBE\x88","\xE3\x83\x8D"],
 ["\xEF\xBE\x89","\xE3\x83\x8E"],
 ["\xEF\xBE\x8A","\xE3\x83\x8F"],
 ["\xEF\xBE\x8B","\xE3\x83\x92"],
 ["\xEF\xBE\x8C","\xE3\x83\x95"],
 ["\xEF\xBE\x8D","\xE3\x83\x98"],
 ["\xEF\xBE\x8E","\xE3\x83\x9B"],
 ["\xEF\xBE\x8F","\xE3\x83\x9E"],
 ["\xEF\xBE\x90","\xE3\x83\x9F"],
 ["\xEF\xBE\x91","\xE3\x83\xA0"],
 ["\xEF\xBE\x92","\xE3\x83\xA1"],
 ["\xEF\xBE\x93","\xE3\x83\xA2"],
 ["\xEF\xBE\x94","\xE3\x83\xA4"],
 ["\xEF\xBE\x95","\xE3\x83\xA6"],
 ["\xEF\xBE\x96","\xE3\x83\xA8"],
 ["\xEF\xBE\x97","\xE3\x83\xA9"],
 ["\xEF\xBE\x98","\xE3\x83\xAA"],
 ["\xEF\xBE\x99","\xE3\x83\xAB"],
 ["\xEF\xBE\x9A","\xE3\x83\xAC"],
 ["\xEF\xBE\x9B","\xE3\x83\xAD"],
 ["\xEF\xBE\x9C","\xE3\x83\xAF"],
 ["\xEF\xBE\x9D","\xE3\x83\xB3"]
]
def createdb_utf8(dbconnoption, dbname)
  system("createdb #{dbconnoption} -lC -Ttemplate0 -EUTF-8 #{dbname}")
end

def createdb_eucjp(dbconnoption, dbname)
  system("createdb #{dbconnoption} -lC -Ttemplate0 -EEUC-JP #{dbname}")
end

def failerr(str)
  str.encode('UTF-8', :undef => :replace, :invalid => :replace, :replace => "☒")
end

def checkdb(dbconnoption, dbname, toeuc, lcheck)
  checkcode = "EUC-JIS-2004"
  if toeuc
    checkcode = "ISO-2022-JP"
  end
  err_file = open(ERRFILE,"w")
  err_count = 0
  sql = "SELECT pg_encoding_to_char(encoding), datcollate, datctype FROM pg_database WHERE datname = '#{dbname}';"
  result = `psql #{dbconnoption} template1 -A -t -c \"#{sql}\"`
  encoding,collate,ctype = result.chomp.split('|')
  printf("データベース [%s]\n", dbname)
  printf("エンコーディング [%s]\n",encoding)
  printf("ロケール [%s] [%s]\n",collate, ctype)
  printf("\n")
  if ("C" == collate) and ("C" == ctype)
    if encoding == "UTF8"
      printf("OK: 拡張漢字有効\n")
    elsif encoding == "EUC_JP"
      printf("OK: 拡張漢字無効\n")
    else
      printf("encodingが不明です。処理を中止します\n")
      exit 1
    end
  else
    printf("ロケールが C 以外です。ロケールをCで作成し直すことを推奨します。\n")
  end
  printf("\n")
  exit 0 if lcheck
  table_name = ""
  if toeuc  && encoding == "UTF8"
    printf("データベースがEUC-JPに変換可能かチェックします...\n")
  else
    printf("データベースに不正な文字が入っていないかチェックします...\n")
  end
  if encoding == "UTF8"
    regexp = UTF8MJ.map {|i,j| j}.join("|")
    IO.popen("pg_dump #{dbconnoption} #{dbname}", "r+") {|pipe|
      while line = pipe.gets
        if /^COPY (\S+)/ =~ line
          table_name = $1
        end
        begin
          if toeuc
            UTF8MJ.each {|i,j|
              line.gsub!(Regexp.new(j),i)
            }
            line.gsub!(/\xE2\x80\x94/, "\x22\x12")
          end
          if line =~ Regexp.new(regexp)
            err_file.printf("TABLENAME: #{table_name}\n")
            err_file.printf("#{failerr(line)}\n")
            err_file.printf("ERROR1: %s〓%s%s\n", $~.pre_match, $~, $~.post_match)
            err_count += 1
          end
          line.encode( checkcode, "UTF-8")
        rescue Encoding::UndefinedConversionError => ex
          err_file.printf("TABLENAME: #{table_name}\n")
          err_file.printf("#{failerr(line)}\n")
          err_file.printf("ERROR2: %s〓%s (%s)\n", ex.error_char, ex.message, ex.class)
          err_count += 1
        rescue Encoding::InvalidByteSequenceError => ex
          err_file.printf("TABLENAME: #{table_name}\n")
          err_file.printf("#{failerr(line)}\n")
          err_file.printf("ERROR2: 〓%s (%s)\n", ex.message, ex.class)
          err_count += 1
        end
      end
    }
  elsif encoding == "EUC_JP"
    IO.popen("pg_dump #{dbconnoption} #{dbname}", "r+") {|pipe|
      pipe.set_encoding("EUC-JP")
      while line = pipe.gets
        if /^COPY (\S+)/ =~ line
          table_name = $1
        end
        begin
          line.encode('UTF-8', 'EUC-JP')
        rescue Encoding::UndefinedConversionError => ex
          err_file.printf("TABLENAME: #{table_name}\n")
          s = ex.error_char
          s.force_encoding('ASCII-8BIT')
          s.gsub!(/\x8F\xF4\xFB/n, "\xFC\xE2".force_encoding('ASCII-8BIT'))
          s.force_encoding('CP51932')
          err_file.printf("#{failerr(line)}\n")
          err_file.printf("ERROR2: %s〓%s (%s)\n", failerr(s), ex.message, ex.class)
          err_count += 1
        rescue Encoding::InvalidByteSequenceError => ex
          err_file.printf("TABLENAME: #{table_name}\n")
          err_file.printf("#{failerr(line)}\n")
          err_file.printf("ERROR2: 〓%s (%s)\n", ex.message, ex.class)
          err_count += 1
        end
      end
    }
  end
  printf("\n")
  if err_count > 0
    printf("ERROR: データベースに不正な文字がありました\n")
    printf("ERROR: #{ERRFILE} を参照して修正する必要があります\n")
  else
    printf("OK: 不正な文字はありませんでした\n")
  end
end

def dropdb(dbconnoption, dbname)
  system("dropdb #{dbconnoption}, #{dbname}")
end

def dbexist?(dbconnoption, dbname)
  sql = "SELECT count(*) FROM pg_database WHERE datname = '#{dbname}';"
  result = `psql #{dbconnoption} template1 -A -t -c \"#{sql}\"`
  return true if result.chomp.to_i == 1
end

def other_session?(dbconnoption, dbname)
  sql = "SELECT count(*) FROM pg_stat_activity WHERE datname = \'#{dbname}\';"
  result = `psql #{dbconnoption} template1 -A -t -c \"#{sql}\"`
  return true if result.chomp.to_i > 0
end

def renamedb(dbconnoption, oldname,newname)
  sql = "ALTER DATABASE #{oldname} RENAME TO #{newname};"
  puts "psql #{dbconnoption} template1 -A -c \"#{sql}\""
  system("psql #{dbconnoption} template1 -A -c \"#{sql}\"")
end

def dump_restore(dbconnoption, oldname, newname)
  begin
    restore = IO.popen("psql #{dbconnoption} --set ON_ERROR_STOP=on #{newname}", "w")
    IO.popen("pg_dump #{dbconnoption} -EUTF-8 #{oldname}", "r+") {|pipe|
      while line = pipe.gets
        next if line =~ /^COMMENT ON EXTENSION plpgsql IS /
        # UTF-8(MS) → UTF-8(JISX0213)
        UTF8MJ.each {|i,j|
          line.gsub!(Regexp.new(j),i)
        }
        UTF8KANA.each {|i,j|
          line.gsub!(Regexp.new(i),j)
        }
        restore.puts line
      end
    }
    restore.close_write
  rescue
    restore.flush
    restore.close
    puts "ERROR:", $!
    exit
  end
end

def dump_restore_utf8ms(dbconnoption, oldname, newname)
  begin
    restore = IO.popen("psql #{dbconnoption} --set ON_ERROR_STOP=on #{newname}", "w")
    IO.popen("pg_dump #{dbconnoption} -EUTF-8 #{oldname}", "r+") {|pipe|
      while line = pipe.gets
        next if line =~ /^COMMENT ON EXTENSION plpgsql IS /
        # UTF-8(JISX0213) → UTF-8(MS)
        UTF8MJ.each {|i,j|
          line.gsub!(Regexp.new(i),j)
        }
        restore.puts line
      end
    }
    restore.close_write
  rescue => ex
    restore.flush
    restore.close_write
    puts "ERROR: #{ex}"
    exit
  end
end

if $0 == __FILE__
  orcadb = "orca"
  host = nil
  port = nil
  dbuser = nil
  tempdb = nil
  backupdb = nil
  toeuc = nil
  check = nil
  lcheck = nil
  clean = nil

  opt = OptionParser.new
  opt.banner = "Usage: #{File.basename($0)} -[hpUetlucw] [-d DB name] [-b Backup name]"
  opt.on('-h','--host HOSTNAME','データベースホスト') {|value|
    host = value
  }
  opt.on('-p','--port PORT','データベースポート') {|value|
    port = value
  }
  opt.on('-U','--username USERNAME','データベースユーザー名') {|value|
    dbuser = value
  }
  opt.on('-d','--db DB name','対象データベース名(デフォルト orca)') {|value|
    orcadb = value
  }
  opt.on('-b','--back Backup name', 'バックアップデータベース名') {|value|
    backupdb = value
  }
  opt.on('-u', '--utf8','UTF-8へ変換（デフォルト)') {|value|
    toeuc = false
  }
  opt.on('-e', '--euc','EUC-JPへ変換') {|value|
    toeuc = true
  }
  opt.on('-t', '--test','データベースのチェック') {|value|
    check = true
  }
  opt.on('-l', '--locale','データベースのロケールチェック') {|value|
    check = true
    lcheck = true
  }
  opt.on('-c', '--clean','変換後元データベースの削除') {|value|
    clean = true
  }
  opt.on('-w', '') {|value|
  }
  opt.parse!(ARGV)

  dbconnoption = "-w "
  dbconnoption += "-h #{host} " if host
  dbconnoption += "-p #{port} " if port
  dbconnoption += "-U #{dbuser} " if dbuser
  tempdb = orcadb + TEMP_SUFIX
  backupdb = orcadb + BACKUP_SUFIX if backupdb.nil?

  if !dbexist?(dbconnoption, orcadb)
    puts "ERROR: データベース #{orcadb} がありません"
    exit 1
  end

  if check
    checkdb(dbconnoption, orcadb, toeuc, lcheck)
    exit 0
  end

  if !other_session?(dbconnoption, orcadb).nil?
    puts "ERROR: データベース #{orcadb} に接続しているアプリケーションを終了してから実行してください。"
    exit 1
  end

  count = 1
  temptempdb = tempdb
  while dbexist?(dbconnoption, tempdb)
    tempdb = temptempdb + "_" + count.to_s
    count += 1
  end

  count = 1
  tempbackup = backupdb
  while dbexist?(dbconnoption, backupdb)
    backupdb = tempbackup + "_" + count.to_s
    count += 1
  end

  if toeuc
    createdb_eucjp(dbconnoption, tempdb)
    dump_restore_utf8ms(dbconnoption, orcadb, tempdb)
  else
    createdb_utf8(dbconnoption, tempdb)
    dump_restore(dbconnoption, orcadb, tempdb)
  end
  renamedb(dbconnoption, orcadb, backupdb)
  renamedb(dbconnoption, tempdb, orcadb)
  if clean
    dropdb(dbconnoption, backupdb)
  end
  puts "OK"
end
