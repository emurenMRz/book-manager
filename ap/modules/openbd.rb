require 'uri'
require 'json'
require 'net/http'

module OpenBD
	OPENDB_ORIGIN = "http://api.openbd.jp"

	class << self
		def get(isbn)
			raise 'ISBN13のみ指定できます' if isbn.to_s.match('[0-9]{13}(,[0-9]{13})*').nil?

			uri = URI.parse "#{OPENDB_ORIGIN}/v1/get?isbn=#{isbn}"
			book_data = JSON.parse(Net::HTTP.get(uri), symbolize_names: true)

			# pp book_data

			return [json2book(book_data)] if book_data.class == 'Hash'
			book_data.map {|data| json2book(data) unless data.nil?}.delete_if{|v| v.nil?}
		end

		def coverage; JSON.parse Net::HTTP.get URI.parse "#{OPENDB_ORIGIN}/v1/coverage"; end

		def gets(isbn)
			raise 'ISBN13の配列を指定できます' unless isbn.class == Array

			total = 0
			succeed = 0
			uri = URI.parse "#{OPENDB_ORIGIN}/v1/get"
			http = Net::HTTP.new uri.host, uri.port
			# http.set_debug_output $stderr
			http.start do |conn|
				isbn.each_slice(10000).each do |group|
					total += group.length
					res = conn.post(uri.path, "isbn=#{group.join ','}")
					next unless res.code[0].to_i == 2
					book_data = JSON.parse res.body, symbolize_names: true
					if book_data.class == 'Hash'
						yield [json2book(book_data)]
					else
						yield book_data.map {|data| json2book(data) unless data.nil?}.delete_if{|v| v.nil?}
					end
					succeed += group.length
				end
			end

			{:succeed => succeed, :total => total}
		end

		private
		
		def json2book(data)
			onix = data[:onix]
			descriptive_detail = onix[:DescriptiveDetail]
			title = descriptive_detail[:TitleDetail][:TitleElement]
			contributor = descriptive_detail[:Contributor]

			{
				:isbn => onix[:RecordReference].to_i,
				:from => -1,
				:書籍名 => title[:TitleText][:content],
				:part => part_number(title),
				:レーベル => label(descriptive_detail[:Collection]),
				:著者 => authors(contributor),
				:著者（読み） => authors(contributor, :collationkey),
				:価格 => prices(onix[:ProductSupply][:SupplyDetail][:Price]).to_i,
				:判型 => genre(descriptive_detail[:Subject]),
				:ページ数 => pages(descriptive_detail),
				:出版社 => publisher(data),
				:発売日 => publish_date(data),
				:説明 => description(data),
				:cover => cover(data),
			}.delete_if{|k,v| v.nil? || v.class == String && v.empty?}
		end

		def part_number(title)
			return nil unless title.has_key?(:PartNumber)
			title[:PartNumber].tr('０-９', '0-9').to_i
		end

		def genre(subject)
			return nil if subject.nil?
			table = {
				1 => "文芸",
				2 => "新書",
				3 => "社会一般",
				4 => "資格・試験",
				5 => "ビジネス",
				6 => "スポーツ・健康",
				7 => "趣味・実用",
				9 => "ゲーム、",
				10 => "芸能・タレント",
				11 => "テレビ・映画化",
				12 => "芸術",
				13 => "哲学・宗教",
				14 => "歴史・地理",
				15 => "社会科学",
				16 => "教育、",
				17 => "自然科学",
				18 => "医学",
				19 => "工業・工学",
				20 => "コンピュータ",
				21 => "語学・辞事典",
				22 => "学参",
				23 => "児童図書、",
				24 => "ヤングアダルト",
				29 => "新刊セット",
				30 => "全集",
				31 => "文庫",
				36 => "コミック文庫",
				41 => "コミックス(欠番扱)",
				42 => "コミックス(雑誌扱)",
				43 => "コミックス(書籍)",
				44 => "コミックス(廉価版)",
				51 => "ムック",
			}
			id = subject.detect {|v| v[:SubjectSchemeIdentifier] == '79'}
			table[id[:SubjectCode].to_i] unless id.nil?
		end

		def pages(descriptive_detail)
			return nil unless descriptive_detail.has_key?(:Extent)
			descriptive_detail[:Extent].each do |extent|
				next unless extent.has_key?(:ExtentValue)
				next unless extent.has_key?(:ExtentType) && extent[:ExtentType] == '11'
				next unless extent.has_key?(:ExtentUnit) && extent[:ExtentUnit] == '03'
				return extent[:ExtentValue].to_i
			end
		end

		def label(collection)
			title_detail = collection[:TitleDetail] unless collection.nil?
			element = title_detail[:TitleElement] unless title_detail.nil?
			return nil if element.nil?
			element.map {|c| c[:TitleText][:content]}.join "、"
		end

		def authors(contributor, type = :content)
			table = {
				:A01 => '著・文・その他',
				:A03 => '脚本',
				:A06 => '作曲',
				:B01 => '編集',
				:B20 => '監修',
				:B06 => '翻訳',
				:A12 => 'イラスト',
				:A38 => '原著',
				:A10 => '企画・原案',
				:A08 => '写真',
				:A21 => '解説',
				:E07 => '朗読',
			}
			contributor.map {|c|
				if type == :content
					r = c[:ContributorRole].map {|role| table[role.to_sym] }
					"#{c[:PersonName][type]}／#{r.join("・")}"
				else
					c[:PersonName][type]
				end
			}.join "、"
		end

		def prices(price)
			return nil if price.nil? || price.empty?
			(price[0][:PriceAmount].to_i * 1.1).ceil
		end

		def publisher(data)
			publising_detail = data[:onix][:PublishingDetail]
			return publising_detail[:Publisher][:PublisherName] if publising_detail.has_key?(:Publisher)
			return publising_detail[:Imprint][:ImprintName] if publising_detail.has_key?(:Imprint)
			data[:Summary][:publisher]
		end
		
		def publish_date(data)
			publising_detail = data[:onix][:PublishingDetail]
			return publising_detail[:PublishingDate][0][:Date].gsub(/([0-9]{4})([0-9]{2})([0-9]{2})/, '\1-\2-\3') if publising_detail.has_key?(:PublishingDate)
			data[:Summary][:pubdate]
		end

		def description(data)
			colloateral_detail = data[:onix][:CollateralDetail]
			return nil unless colloateral_detail.has_key?(:TextContent)
			for_online = colloateral_detail[:TextContent].detect {|tc| tc[:TextType] == "03" && tc[:ContentAudience] == "00"}
			return for_online[:Text] unless for_online.nil?
			for_shop = colloateral_detail[:TextContent].detect {|tc| tc[:TextType] == "02" && tc[:ContentAudience] == "00"}
			return for_shop[:Text] unless for_shop.nil?
		end

		def cover(data)
			collateral_detail = data[:onix][:CollateralDetail]
			if collateral_detail.has_key?(:SupportingResource)
				collateral_detail[:SupportingResource].each do |res|
					next unless res[:ResourceContentType] == "01"
					return res[:ResourceVersion][0][:ResourceLink]
				end
			end
		   data[:summary][:cover]
		end
	end
end