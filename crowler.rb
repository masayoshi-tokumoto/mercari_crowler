require 'open-uri'
require 'nokogiri'
require 'parallel'

print "keyword: "
keyword = gets.gsub(/(\r\n?|\n)/,"")
checked_keyword = keyword.gsub(/\s|　/,"")

if checked_keyword.empty?
  puts "キーワードを入力してください。"
  return
end

uri = "https://www.mercari.com/jp/search/?keyword=#{keyword}"
doc = Nokogiri.HTML(open(uri))
price_ranges = []
price_range_option = []

doc.css(".search-price option").each_with_index do |e, index|
  unless index == 0
    price_ranges << e.content.gsub(/\s|　/,"").split("~")
    price_range_option << "#{index}:#{e.content.gsub(/\s|　/,"")}"
  end
end

puts "選択してください"
puts "------------------------------------"
puts price_range_option
puts "------------------------------------"

price_range_number = gets.to_i

unless 0 < price_range_number && price_range_number <= price_range_option.count
  puts "選択肢の番号の中から1つ選んでください。"
  return
end

price_range_index = price_range_number - 1

price_min = price_ranges[price_range_index].first
price_max = price_ranges[price_range_index].count == 2 ? price_ranges[price_range_index].last : nil

page_num = 1
result_count = 0

if price_max.nil?
  uri = "https://www.mercari.com/jp/search/?page=#{page_num}&keyword=#{keyword}&status_on_sale=1&price_min=#{price_min}"
else
  uri = "https://www.mercari.com/jp/search/?page=#{page_num}&keyword=#{keyword}&status_on_sale=1&price_min=#{price_min}&price_max=#{price_max}"
end

puts "検索中・・・"

loop do
  doc = Nokogiri.HTML(open(uri))
  page_nums = doc.css(".pager-cell").text
  last_page_num = page_nums.gsub(/\s/, "").split("").last || 1

  result = Parallel.map(doc.css(".items-box-body")) do |e|
    p [e.css(".items-box-name").text, e.css(".items-box-price").text.gsub(/\s|¥|,/, "")]
  end

  result_count += result.compact.count

  if page_num == last_page_num.to_i
    break
  end

  page_num += 1
end

puts "検索結果#{result_count}件"
