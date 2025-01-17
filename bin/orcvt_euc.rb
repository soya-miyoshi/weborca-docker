#!/usr/bin/ruby3.0
# coding : euc-jp
Encoding.default_external = "euc-jp"
#require "jcode"

# 半角英数字記号 -> 全角変換(EUC) script for ORCA
# 
#       対象項目に半角か全角のカタカナが存在する場合、混在する半角カタ
#       カナ、半角英数字および記号を全角に変換する
#
#     パラメータファイル /home/orca/ORCADC.PARA [ $file_path_name ]
#              ( csvファイルは原本を ファイル名_org として保存します )
#     対象項目番号 16,17,18,19,20 [ $tgt_csv_no ] ( 入力コード１〜５ )
# 01/08/22 by 山本
# 01/11/05 by 山本 bug fix

#$KCODE = "euc"

$file_path_name = ARGV[0]
$tgt_csv_no = [16,17,18,19,20]

def h2z(buf)
  # 半角->全角 変換テーブル ============================================
  # (半角スペースはデリミタとして使用するので登録できません)
  str1 = "" ; str2 = ""
  str1 = str1 + 'ｶﾞ ｷﾞ ｸﾞ ｹﾞ ｺﾞ ｻﾞ ｼﾞ ｽﾞ ｾﾞ ｿﾞ ﾀﾞ ﾁﾞ ﾂﾞ ﾃﾞ ﾄﾞ ﾊﾞ ﾋﾞ ﾌﾞ ﾍﾞ ﾎﾞ ｳﾞ '
  str2 = str2 + 'ガギグゲゴザジズゼゾダヂヅデドバビブベボヴ'
  str1 = str1 + 'ﾊﾟ ﾋﾟ ﾌﾟ ﾍﾟ ﾎﾟ ｧ ｨ ｩ ｪ ｫ ｬ ｭ ｮ ｯ ｰ ﾞ ﾟ '
  str2 = str2 + 'パピプペポァィゥェォャュョッー゛゜'
  str1 = str1 + 'ｱ ｲ ｳ ｴ ｵ ｶ ｷ ｸ ｹ ｺ ｻ ｼ ｽ ｾ ｿ ﾀ ﾁ ﾂ ﾃ ﾄ ﾅ ﾆ ﾇ ﾈ ﾉ '
  str2 = str2 + 'アイウエオカキクケコサシスセソタチツテトナニヌネノ'
  str1 = str1 + 'ﾊ ﾋ ﾌ ﾍ ﾎ ﾏ ﾐ ﾑ ﾒ ﾓ ﾔ ﾕ ﾖ ﾗ ﾘ ﾙ ﾚ ﾛ ﾜ ｦ ﾝ '
  str2 = str2 + 'ハヒフヘホマミムメモヤユヨラリルレロワヲン'
  str1 = str1 + 'a b c d e f g h i j k l m n o p q r s t u v w x y z '
  str2 = str2 + 'ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚ'
  str1 = str1 + 'A B C D E F G H I J K L M N O P Q R S T U V W X Y Z '
  str2 = str2 + 'ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ'
  str1 = str1 + '0 1 2 3 4 5 6 7 8 9 '
  str2 = str2 + '０１２３４５６７８９'
  str1 = str1 + '\! " # \$ % & \' \( \) \* \+ , - \. / : ; < = > \? @ \[ \\\\ ] \^ _ ` \{ \| } ~ '
  str2 = str2 + '！”＃＄％＆’（）＊＋，−．／：；＜＝＞？＠［￥］＾＿‘｛｜｝〜'

  frm = str1.split(" ")
  to  = str2.split("")

  i = 0
  frm.each{|s|
#   print s ; print ',' ; puts to[i]
    buf.gsub!(s,to[i])
    i = i + 1
  }
  return buf
end

# パラメータファイルから入力ファイル名をセットする
def set_in_f(idct)
  # パラメータファイルの存在確認
  if !File.exists?($file_path_name)
    print "ERR: no file [ " + $file_path_name + " ]\n"
    exit
  end
  open($file_path_name,"r") do |f|
    while buf = f.gets
      if /^#{idct}/ =~ buf.chop!
        buf.gsub!(idct,"")
        buf.gsub!(/(,T)$/,"")
        return buf
      end
    end
  end
end

#----- Main -------------------------------------------------
cnt = 0 ; lcnt = 0
# 入力ファイル名のセット
in_file = set_in_f('@01-5:')
# ファイルの存在確認
if !File.exists?(in_file)
  print "ERR: no file [ " + in_file + " ]\n"
  exit
end

# ファイル原本を別名で保存(copy)し入力ファイルとする
out_file = in_file
in_file = in_file + "_org"
`cp #{out_file} #{in_file}`

# 入力、出力ファイルをそれぞれオープン
open(in_file,"r") do |f|
  open(out_file,"w") do |f2|

    # 入力ファイルから1行読み込み
    while buf = f.gets
      lcnt = lcnt + 1
      ary = Array.new
      # 行末の改行コードを削除
      buf.chop!
      # デリミタをカンマとし配列にセット（０オリジン）
#     print "[IN-ARY] => " + buf + "\n"
      ary = buf.split(",",-1)

      # 対象項目についてのみ処理
      flg = false
      $tgt_csv_no.each{|s|
        # 半角か全角のカタカナが存在すればメソッド h2z(String) で変換
        if /[ｦ-ﾟァ-ヴー゛゜]/e =~ ary[s-1]
          ary[s-1] = h2z(String(ary[s-1])) ; flg = true
        end
      }
      cnt = cnt + 1 if flg

      # 配列をカンマデリミタで文字列に結合
      buf = ary.join(",")
#     print "[OUT-ARY]=> " + buf + "\n"
#     puts "-----------------------------------------------------------------------"
      # 文字列を出力ファイルに書き込み
      f2.puts buf
    end
  end
end
printf("**(orcvt_euc.rb)**  convert CSV file [ %s (%d lines) ]\n",out_file,lcnt)
#----- Script end -------------------------------------------
