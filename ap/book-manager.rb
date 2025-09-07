require 'uri'
require 'net/http'
require 'rack/protection'
require 'sinatra'
require 'sinatra/reloader'
require 'logger'
require 'sequel'
require_relative 'modules/selfdb'
require_relative 'modules/rakuten_books'
require_relative 'secret'

SelfDB.setup DB_NAME, host: DB_HOST, user: DB_USER, password: DB_PWD
if Object.const_defined? :RAKUTEN_APP_ID
	RaktenBooksAPI.setup RAKUTEN_APP_ID
	RaktenBooksAPI.affiliateId = RAKUTEN_AFFILIATE_ID if Object.const_defined? :RAKUTEN_AFFILIATE_ID
end

PAGE_LIMIT = 50

use Rack::Session::Cookie, secret: RACK_SESSION_SECRET, max_age: 3600*24*7, same_site: 'Lax', secure: false
use Rack::Protection::AuthenticityToken
use Rack::Protection::ContentSecurityPolicy
use Rack::Protection::CookieTossing
use Rack::Protection::EscapedParams
use Rack::Protection::FormToken
use Rack::Protection::ReferrerPolicy
use Rack::Protection::RemoteReferrer
use Rack::Protection::StrictTransport
use Rack::Protection, permitted_origins: ["https://book-manager.mrz-net.org"]

logger = Logger.new 'log/sinatra.log'

before do
	logger.debug "#{env['HTTP_X_FORWARDED_FOR']} #{env['REQUEST_METHOD']} #{env['REQUEST_URI']} #{session.inspect}"

	request.script_name = '/api'
end

helpers do
	def csrf_token; Rack::Protection::AuthenticityToken.token(env['rack.session']); end
end

# 
# root
# 

get '/welcome' do
	logged_in = SelfDB::Session.check(session.id)
	user_type = !logged_in ? SelfDB::UserType::None : SelfDB::User.get(session.id)[:type]

	content_type :json
	JSON.dump({:loggedIn => logged_in, :_csrf => csrf_token, :userType => user_type})
end

post '/login' do
	SelfDB::Session.login params[:id], params[:pw], session.id
	user_type = SelfDB::User.get(session.id)[:type]

	content_type :json
	JSON.dump({:succeed => true, :_csrf => csrf_token, :userType => user_type})
rescue => e
	content_type :json
	JSON.dump({:succeed => false, :error => e.message})
end

delete '/logout' do
	result = SelfDB::Session.delete(session.id)

	content_type :json
	JSON.dump({:succeed => result == 1})
rescue => e
	content_type :json
	JSON.dump({:succeed => false})
end

get '/demo' do
	temp_user = SelfDB::User.temp_add
	logger.info "Add temp user: #{temp_user[:name]}, #{temp_user[:pw]}"

	SelfDB::Session.login temp_user[:name], temp_user[:pw], session.id

	content_type :json
	JSON.dump({:succeed => true, :_csrf => csrf_token, :userType => temp_user[:type]})
rescue => e
	content_type :json
	JSON.dump({:succeed => false, :error => e.message})
end

#
# user
#

patch '/user/register' do
	user = SelfDB::User.register session.id, params[:name], params[:pw]
	logger.info "Register user: #{user.name}, #{user.password}"

	content_type :json
	JSON.dump({:succeed => true})
rescue => e
	content_type :json
	JSON.dump({:succeed => false, :error => e.message})
end

patch '/user/name' do
	user = SelfDB::User.new session.id, params[:now]
	user.name = params[:new]
	logger.info "Change name: #{params[:new]}"

	content_type :json
	JSON.dump({:succeed => true})
rescue => e
	content_type :json
	JSON.dump({:succeed => false, :error => e.message})
end

patch '/user/password' do
	user = SelfDB::User.new session.id, params[:now]
	user.password = params[:new]
	logger.info "Change password: #{params[:new]}"

	content_type :json
	JSON.dump({:succeed => true})
rescue => e
	content_type :json
	JSON.dump({:succeed => false, :error => e.message})
end

#
# list
#

get '/list/unread' do
	content_type :json
	JSON.dump SelfDB.to_json SelfDB::User.books(session.id)
					.where(Sequel.lit('既読 != 1'))
					.where(Sequel.lit('所有 > 0'))
					.order(:発売日, :書籍名)
rescue => e
	content_type :json
	JSON.dump({:error => e.message})
end

get '/list/to-buy' do
	content_type :json
	JSON.dump SelfDB.to_json SelfDB::User.books(session.id)
					.where(Sequel.lit('既読 = 0'))
					.where(Sequel.lit('所有 = 0'))
					.where(:購入予定 => true)
					.where(Sequel.lit('発売日 <= CURRENT_DATE'))
					.order(Sequel.desc(:発売日), :書籍名)
rescue => e
	content_type :json
	JSON.dump({:error => e.message})
end

get '/list/to-buy/unpublished' do
	content_type :json
	JSON.dump SelfDB.to_json SelfDB::User.books(session.id)
					.where(Sequel.lit('既読 = 0'))
					.where(Sequel.lit('所有 = 0'))
					.where(:購入予定 => true)
					.where(Sequel.|(
						Sequel.lit('発売日 > CURRENT_DATE'),
						発売日: nil,
					))
					.order(Sequel.asc(:発売日), :書籍名)
rescue => e
	content_type :json
	JSON.dump({:error => e.message})
end

get '/list/hold' do
	content_type :json
	JSON.dump SelfDB.to_json SelfDB::User.books(session.id)
					.where(Sequel.lit('所有 = 0'))
					.where(:購入予定 => false)
					.order(Sequel.desc(:発売日), :書籍名)
rescue => e
	content_type :json
	JSON.dump({:error => e.message})
end

#
# search
#

def search(table, params)
	if params.has_key?(:isbn)
		table = table.where(Sequel[:書籍情報][:isbn] => params[:isbn])
	elsif params.has_key?(:title)
		table = table.where(Sequel.lit("書籍名 &@ ?", table.escape_like(params[:title])))
	end

	if params.has_key?(:author)
		table = table.where(Sequel.|(
			Sequel.lit("著者 &@ ?", table.escape_like(params[:author])),
			Sequel.lit("著者（読み） &@ ?", table.escape_like(params[:author])),
		))
	end

	if params.has_key?(:tag)
		table = table.where(Sequel.|(
			Sequel.like(Sequel.function(:lower, Sequel[:書籍情報][:タグ]), Sequel.function(:lower, "%#{table.escape_like(params[:tag])}%")),
			Sequel.like(Sequel.function(:lower, Sequel[:ユーザー拡張情報][:タグ]), Sequel.function(:lower, "%#{table.escape_like(params[:tag])}%")),
		))
	end

	if params.has_key?(:page)
		number = params[:page][:number].to_i - 1
		limit = params[:page][:limit].to_i
		if number < 0; number = 0; end
		if limit < 1 || limit > PAGE_LIMIT; limit = PAGE_LIMIT; end
		table = table.offset(number * limit).limit(limit)
	end

	table
end

def caching_cover(books)
	return unless File.writable?(CACHE_DIR)

	books.map {|book| 
		next unless book.has_key?(:cover)
		uri = URI.parse(book[:cover])
		ext = File.extname(uri.path)
		next unless ext == '.jpg' || ext == '.jpeg'
		cover_name = File.join(CACHE_DIR, "#{book[:isbn]}.jpg")
		next if File.exist?(cover_name)
		Thread.new(uri, cover_name) do |u, n|
			begin
				http = Net::HTTP.new(u.host, u.port)
				http.open_timeout = 5
				http.read_timeout = 10
				res = http.start {|h| h.get(u.request_uri)}
				data = res.body

				soi, app0, length, id = data[..11].unpack('S! S! S! A5')
				next unless soi == 0xD8FF && app0 == 0xE0FF && id == 'JFIF'
				next if data.size == 3185 && Digest::SHA256.hexdigest(data) == '56ef1a38d5ba7980f1a6c08926c931d0feaa12fd837e62d861373921670c3592'

				File.write(n, data)
				logger.info "caching: #{n}"
			rescue => e
				logger.error "caching error: #{n}"
			end
		end
	}.each {|th| th.join unless th.nil?}
end

def join(books, additionalBooks)
	additionalBooks.each do |book|
		books.append(book) if books.find{|v| v[:isbn] == book[:isbn]}.nil?
	end
end

def to_rakuten_params(params)
	rakuten_params = {}
	rakuten_params[:isbn] = params[:isbn] if params.has_key?(:isbn)
	rakuten_params[:title] = params[:title] if params.has_key?(:title)
	rakuten_params[:author] = params[:author] if params.has_key?(:author)
	rakuten_params[:tag] = params[:tag] if params.has_key?(:tag)
	return nil if rakuten_params.length == 0
	if params.has_key?(:page)
		number = params[:page][:number].to_i + 1
		limit = params[:page][:limit].to_i
		if number < 1; number = 1; elsif number > 100; number = 100; end
		if limit < 1 || limit > 30; limit = 30; end
		rakuten_params[:page] = number
		rakuten_params[:hits] = limit
	end
	rakuten_params
end

def order_by_release_date(books)
	books.sort!{|a, b|
		if a[:発売日].nil?
			1
		elsif b[:発売日].nil?
			-1
		else
			b[:発売日] <=> a[:発売日]
		end
	}
end

get '/search' do
	now_page = 1
	if params.has_key?(:page)
		now_page = params[:page].to_i
		params[:page] = {:number => now_page} 
	end

	only_owned = params.has_key?(:only_owned) && params[:only_owned]
	with_rakuten = params.has_key?(:with_rakuten) && params[:with_rakuten]
	target = {:coverage => true, :rakuten => with_rakuten}
	if params.has_key?(:db)
		db = params[:db];
		target[:coverage] = !db.index("c").nil?
		target[:rakuten] = !db.index("r").nil?
	end

	logger.debug("params: #{JSON.dump(params)}")

	if target[:coverage]
		coverage = Thread.new(params) {|params|
			if only_owned
				find = search SelfDB::User.books(session.id), params
			else
				find = search SelfDB::BookData.dataset, params
				find = find.left_outer_join(SelfDB::User.extra_data(session.id), [:isbn])
			end
			find = find.order(Sequel.desc(:発売日), :書籍名, Sequel[:書籍情報][:isbn])

			logger.debug("SQL: #{find.sql}")
			count = find.count
			logger.debug("coverage: #{count}")
			books = SelfDB.to_json(find.limit(PAGE_LIMIT))
			[books, count, (count / PAGE_LIMIT.to_f).ceil]
		}
	end
	if RaktenBooksAPI.setup? && target[:rakuten]
		rakuten_params = to_rakuten_params params
		unless rakuten_params.nil?
			rakuten = Thread.new(rakuten_params) {|params|
				meta = {}
				books = RaktenBooksAPI.get(params, :responseMeta => meta)
				logger.debug("rakuten: #{JSON.dump(meta)}")
				[books, meta[:count], meta[:pageCount]]
			}
		end
	end

	meta = {:page => now_page, :coverage => nil, :rakuten => nil}
	unless coverage.nil?
		coverage = coverage.value
		coverage_books = coverage[0]
		meta[:coverage] = {:count => coverage[1], :pages => coverage[2]}
	end
	unless rakuten.nil?
		rakuten = rakuten.value 
		rakuten_books = rakuten[0]
		meta[:rakuten] = {:count => rakuten[1], :pages => rakuten[2]}
	end

	books = []
	join books, coverage_books unless coverage_books.nil?
	join books, rakuten_books unless rakuten_books.nil?

	caching_cover books

	content_type :json
	JSON.dump({
		:books => order_by_release_date(books),
		:meta => meta,
	})
rescue => e
	content_type :json
	JSON.dump({:error => e.message})
end

#
# book
#

put '/book/register' do
	SelfDB::Book.register(session.id, params)

	content_type :json
	JSON.dump({:secceed => true})
rescue => e
	content_type :json
	JSON.dump({:secceed => false, :error => e.message})
end

patch '/book/:isbn' do
	result = SelfDB::Book.update(session.id, params)

	content_type :json
	JSON.dump({:secceed => !result.nil?})
rescue => e
	content_type :json
	JSON.dump({:secceed => false, :error => e.message})
end

delete '/book/:isbn' do
	result = SelfDB::Book.delete(session.id, params[:isbn])

	content_type :json
	JSON.dump({:secceed => result == 1})
rescue => e
	content_type :json
	JSON.dump({:succeed => false})
end
