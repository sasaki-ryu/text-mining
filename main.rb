require 'nokogiri'
require 'open-uri'
require 'natto'

# スクレイピング(初期取得用)
def scraping
  charset = nil
  wordHash = Hash.new{|h,k|h[k]={}}
  text_count = 1

  html = open(ARGV[0]) do |f|
    charset = f.charset
    f.read
  end
  
  doc = Nokogiri::HTML(html,charset) do |config|
    config.noblanks
  end
  
  doc.search("script").each do |script|
    script.content = "" 
  end
  
  doc.css('article').each do |elm|
    text = elm.content.gsub(/(\t|\s|\n|\r|\f|\v)/,"")
    wordHash,text_count = morphological_analysis(text)
  end
 
  tf = TF(wordHash)
  idf = IDF(wordHash,text_count)
  tf_idf = calc_TF_IDF(tf,idf)
  
  tf_idf = feature_extr(tf_idf)
end

# 形態素解析
def morphological_analysis(text)
  nm = Natto::MeCab.new
  wordHash = Hash.new{|h,k|h[k]={}}
  text_count = 1
  
  nm.parse(text) do |n|
    p n
    if text_line_match(n.feature, n.surface)
      text_count += 1
    end
    if pattern_match(n.feature, n.surface)
      wordHash[n.surface]["last_line"] = text_count
      wordHash[n.surface]["word_count"] ? wordHash[n.surface]["word_count"] += 1 : wordHash[n.surface]["word_count"] = 1 
      
      # その単語が出た行数と単語が最後に現れた行が異なる時line_countを増やす
      if wordHash[n.surface]["line_count"].nil?
        wordHash[n.surface]["line_count"] = 1
      elsif wordHash[n.surface]["last_line"] == text_count
        wordHash[n.surface]["line_count"] += 1 
      end
    end
  end

#  wordHash.sort_by {|key,val|-val["word_count"]}
  return wordHash, text_count
end

# 文章抽出
def text_line_match(feature,surface)
  unless feature.match("記号")
    return false
  end

  unless surface.match("。")
    return false
  end

  return true
end

# 品詞抽出
def pattern_match(feature,surface)
  unless feature.match("名詞")
    return false
  end

  unless surface.match(/^.{2,}$/)
    return false
  end

#  if feature.match("サ変接続")
#    return false
#  end
  
  if feature.match("数")
    return false
  end  
  true
end

#=========================
#　特徴量を抽出する関数
#  tf-idf と データの精査
#　calcでベクトル量計算
#==========================

def feature_extr(wordHash)
  wordHash.sort_by{|key,value| -value}[0..30]
end

# 特徴量抽出(局所的頻度)
def TF(wordHash)
  total = 0
  tf = Hash.new
  # 全体の語彙数をカウント
  wordHash.each{|key, value| total += value["word_count"]}
  
  wordHash.each do |key, value|
    tf[key] = value["word_count"] / total.to_f
  end

  tf
end

# 特徴量抽出(帯域的頻度)
def IDF(wordHash, text_count=1)
  idf = Hash.new

  wordHash.each do |key, value|
    idf[key] = value["line_count"] / text_count.to_f
  end
  idf
end

# 特徴量計算
def calc_TF_IDF(tf,idf)
  tf_idf = Hash.new
  tf.each do |key,value|
    tf_idf[key] = value * idf[key]
  end
  tf_idf
end

# 単語リスト登録
def create_term_list(tf_idf)
  # 特徴量が一定以上の単語を登録する
end

def csv_vector(tf_idf)
  
end
# TF-IDF cos類似度抽出
def cos_similar(tf,idf)
end

# 関連記事登録
def create_relative_list
end

scraping
