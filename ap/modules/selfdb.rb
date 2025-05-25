require 'sequel'
require 'date'
require 'digest'

module SelfDB
	module UserType
		None = -1,
		Regular = 0,
		Temp = 1
	end

	class << self
		def setup(db_name, user: nil, password: nil, host: 'localhost')
			options = {}
			options[:user] = user unless user.nil?
			options[:password] = password unless password.nil?
			options[:host] = host unless host.nil?
			db = Sequel.postgres(db_name, **options)

			db.create_table? :ユーザー情報 do
				primary_key :uid
				String :name, text: true, unique: true, null: false
				String :password, text: true, null: false
				Date :register, null: false
				Integer :type, null: false, default: UserType::Regular
			end

			module_eval %{
				class Users < Sequel::Model :ユーザー情報
					plugin :validation_helpers
					one_to_many :セッション

					def validate
						super
					  	validates_presence [:name, :password, :register]
						validates_unique [:name]
						validates_type String, [:name, :password]
						validates_type Date, [:register]
						validates_type [Integer, NilClass], [:type]
					end

					def to_s; to_json.to_s; end
					def to_json; {:name => name, :password => password, :register => register, :type => type}; end
				end
			}

			db.create_table? :セッション do
				String :sid, text: true, unique: true, null: false
				foreign_key :uid, :ユーザー情報, on_delete: :cascade
				DateTime :expires, null: false
				primary_key [:sid, :uid]
			end

			module_eval %{
				class Sessions < Sequel::Model :セッション
					plugin :validation_helpers
					unrestrict_primary_key
					many_to_one :ユーザー情報

					def validate
						super
						validates_presence [:sid, :uid, :expires]
						validates_unique [:sid]
						validates_type String, [:sid]
						validates_type DateTime, [:expires]
					end

					def to_s; to_json.to_s; end
					def to_json; {:sid => sid, :uid => uid, :expires => expires}; end
				end
			}

			db.create_table? :書籍情報 do
				Decimal :isbn, null: false
				String :書籍名, text: true
				String :レーベル, text: true
				String :著者, text: true
				String :著者（読み）, text: true
				String :価格, text: true
				String :判型, text: true
				String :ページ数, text: true
				String :出版社, text: true
				Date :発売日
				String :説明, text: true
				String :タグ, text: true
				Date :created_at, null: false
				Date :modified_at, null: false, default: Sequel::CURRENT_DATE
				primary_key [:isbn]
			end

			db.run 'CREATE EXTENSION IF NOT EXISTS pgroonga';
			db.run 'CREATE INDEX IF NOT EXISTS pgroonga_書籍名_index ON 書籍情報 USING pgroonga (書籍名)';
			db.run 'CREATE INDEX IF NOT EXISTS pgroonga_著者_index ON 書籍情報 USING pgroonga (著者)';
			db.run 'CREATE INDEX IF NOT EXISTS pgroonga_著者（読み）_index ON 書籍情報 USING pgroonga (著者（読み）)';
			
			db.create_function :new_bookdata, %{
				BEGIN
					IF NEW.created_at IS NULL THEN
						NEW.created_at = CURRENT_DATE;
					END IF;
					RETURN NEW;
				END;
			}, :language => :plpgsql, :returns => :trigger, :replace => true
			db.drop_trigger :書籍情報, :new_bookdata_trigger, :if_exists => true
			db.create_trigger :書籍情報, :new_bookdata_trigger, :new_bookdata, :events => :insert, :each_row => true
			
			db.create_function :update_bookdata, %{
				BEGIN
					IF OLD.書籍名 = NEW.書籍名
					AND OLD.レーベル = NEW.レーベル
					AND OLD.著者 = NEW.著者
					AND OLD.著者（読み） = NEW.著者（読み）
					AND OLD.価格 = NEW.価格
					AND OLD.判型 = NEW.判型
					AND OLD.ページ数 = NEW.ページ数
					AND OLD.出版社 = NEW.出版社
					AND OLD.発売日 = NEW.発売日
					AND OLD.説明 = NEW.説明
					AND OLD.タグ = NEW.タグ
					THEN
						RETURN NULL;
					END IF;

					NEW.modified_at = CURRENT_DATE;
					RETURN NEW;
				END;
			}, :language => :plpgsql, :returns => :trigger, :replace => true
			db.drop_trigger :書籍情報, :update_bookdata_trigger, :if_exists => true
			db.create_trigger :書籍情報, :update_bookdata_trigger, :update_bookdata, :events => :update, :each_row => true
			
			module_eval %{
				class BookData < Sequel::Model :書籍情報
					plugin :validation_helpers
					one_to_many :ユーザー拡張情報

					def validate
						super
						validates_presence [:isbn]
						validates_type Decimal, [:isbn]
						validates_type [String, NilClass], [:書籍名, :レーベル, :著者, :著者（読み）, :価格, :判型, :ページ数, :出版社, :説明, :タグ]
						validates_type [Date, NilClass], [:発売日, :created_at, :modified_at]
					end

					def to_s; to_json.to_s; end
					def to_json
						{
							:isbn => isbn,
							:書籍名 => 書籍名,
							:レーベル => レーベル,
							:著者 => 著者,
							:著者（読み） => 著者（読み）,
							:価格 => 価格,
							:判型 => 判型,
							:ページ数 => ページ数,
							:出版社 => 出版社,
							:発売日 => 発売日,
							:説明 => 説明,
							:タグ => タグ,
							:created_at => created_at,
							:modified_at => modified_at,
						}
					end
				end
			}
			
			db.create_table? :ユーザー拡張情報 do
				foreign_key :uid, :ユーザー情報, on_delete: :cascade
				foreign_key :isbn, :書籍情報, on_delete: :restrict
				Date :登録日
				Date :読了日
				Integer :既読, null: false, default: 0         # 0:未読,1:既読,2:未読了
				Integer :所有, null: false, default: 0         # 0:未所有,1:所有,2:借物,3:貸出中,4:売却済
				TrueClass :購入予定, null: false, default: false # false:なし,true:あり
				Integer :評価, null: false, default: 0         # 0:未評価,1~5:評価
				String :貸出先, text: true
				String :タグ, text: true
				String :コメント, text: true
				primary_key [:uid, :isbn]
			end

			module_eval %{
				class UserBooks < Sequel::Model :ユーザー拡張情報
					plugin :validation_helpers
					unrestrict_primary_key
					many_to_one :ユーザー情報
					many_to_one :書籍情報

					def validate
						super
						validates_presence [:uid, :isbn]
						validates_type [Date, NilClass], [:登録日, :読了日]
						validates_type [Integer, NilClass], [:既読, :所有, :評価]
						validates_type [TrueClass, NilClass], [:購入予定]
						validates_type [String, NilClass], [:貸出先, :タグ, :コメント]
					end

					def to_s; to_json.to_s; end
					def to_json
						{
							:uid => uid,
							:isbn => isbn,
							:登録日 => 登録日,
							:読了日 => 読了日,
							:既読 => 既読,
							:所有 => 所有,
							:購入予定 => 購入予定,
							:評価 => 評価,
							:貸出先 => 貸出先,
							:タグ => タグ,
							:コメント => コメント,
						}
					end
				end
			}

			db
		end

		def to_json(table)
			table.map do |book|
				core = {
					:isbn => book[:isbn].to_i,
					:from => -1,
					:書籍名 => book[:書籍名].to_s,
					:レーベル => book[:レーベル].to_s,
					:著者 => book[:著者].to_s,
					:著者（読み） => book[:著者（読み）].to_s,
					:価格 => book[:価格].to_i,
					:判型 => book[:判型].to_s,
					:ページ数 => book[:ページ数].to_i,
					:出版社 => book[:出版社].to_s,
					:発売日 => book[:発売日].to_s,
					:説明 => book[:説明].to_s,
				}
				if book[:uid].nil?
					core[:cover] = "https://cover.openbd.jp/#{book[:isbn].to_i}.jpg"
				else
					core = core.merge({
						:from => 0,
						:登録日 => book[:登録日].to_s,
						:読了日 => book[:読了日].to_s,
						:既読 => book[:既読].to_i,
						:所有 => book[:所有].to_i,
						:購入予定 => book[:購入予定],
						:評価 => book[:評価].to_i,
						:貸出先 => book[:貸出先].to_s,
						:コメント => book[:コメント].to_s,
						:タグ => book[:タグ].to_s,
					})
				end
				core.delete_if{|k,v| v.nil? || v.class == String && v.empty?}
			end
		end

		def pw2digest(pw, salt); Digest::MD5.hexdigest("#{pw.to_s}@#{salt.to_s}"); end
		# hash = Digest::SHA256.hexdigest("#{pw.to_s}@#{result[:register].to_s}")
	end

	module Session
		class << self
			def login(id, pw = nil, sid = nil)
				user = Users.where(:name => id.to_s).first
				raise 'アカウント名かパスワードが間違っています' if user.nil?
		
				hash = SelfDB::pw2digest(pw, user[:register])
				raise 'アカウント名かパスワードが間違っています' unless user[:password] == hash

				add(sid, user[:uid])
			end

			def add(sid = nil, uid = nil)
				sid = Digest::SHA512::hexdigest(DateTime.now.to_s) if sid.nil?
				today = DateTime.now
				Sessions.dataset.insert_conflict(
					constraint: :セッション_pkey,
					update: {:expires => today}
				).insert(sid: sid.to_s, uid: uid.to_i, expires: today)
				sid
			end

			def get(sid)
				session = Sessions.where(sid: sid.to_s).first
				raise 'セッションが見つかりません' if session.nil?
				session
			end

			def clear(); Sessions.dataset.delete; end
			def delete(sid); Sessions.where(sid: sid.to_s).delete; end
			def check(sid); !Sessions.where(sid: sid.to_s).first.nil?; end
		end
	end

	class User
		def initialize(sid, pw = nil)
			@sid = sid
			authn(pw) unless pw.nil?
		end

		def authn(pw)
			user = User::get(@sid)
			hash = SelfDB::pw2digest(pw, user[:register])
			raise 'パスワードが間違っています' unless user[:password] == hash
			@user = user
		end

		def name=(new_name)
			raise 'No auth.' if @user.nil?
			raise 'Invalid name.' if new_name.empty? || new_name[0] == '#'
			Users[@user[:uid]].update(:name => new_name, :type => UserType::Regular)
		end

		def password=(new_pw)
			raise 'No auth.' if @user.nil?
			raise 'Invalid password.' if new_pw.empty?
			hash = SelfDB::pw2digest(new_pw, @user[:register])
			Users[@user[:uid]].update(:password => hash, :type => UserType::Regular)
		end

		def remove()
			raise 'No auth.' if @user.nil?
			Users[@user[:uid]].destroy
		end

		class << self
			def register(sid, name, pw)
				session = Session.get(sid)
				user = Users[session[:uid]]
				raise 'ユーザーが見つかりません' if user.nil?
				raise 'お試しユーザーではありません' if user.type != UserType::Temp
				user.name = name
				user.password = SelfDB::pw2digest(pw, user.register)
				user.type = UserType::Regular
				user.save
				user
			end

			def add(name, pw, type: UserType::Regular)
				today = Date.today
				hash = SelfDB::pw2digest(pw, today)
				user = Users.new(name: name, password: hash, register: today, type: type)
				raise 'ユーザーが追加できません' unless user.valid?
				user.save
			end

			def temp_add
				temp_name = "##{Time.now.strftime("%s%L").to_i.to_s(16)}"
				temp_pw = Digest::MD5::digest(temp_name).unpack("C*")
				loop do
					half = temp_pw.length / 2
					break if half < 4
					high = temp_pw[...half]
					low = temp_pw[half..]
					temp_pw = [*0...half].map {|i| high[i] ^ low[i]}
				end
				temp_pw = temp_pw.pack("C*").unpack("H*")[0]
				temp_type = UserType::Temp
				add temp_name, temp_pw, type: temp_type
				{:name => temp_name, :pw => temp_pw, :type => temp_type}
			end

			def remove(name); Users.where(:name => name).destroy; end
			def check(name); !Users.where(:name => name).first.nil?; end

			def get(sid)
				session = Session.get(sid)
				user = Users[session[:uid]]
				raise 'ユーザーが見つかりません' if user.nil?
				user
			end
		
			def books(sid)
				session = Session.get(sid)
				base_table = BookData.join(UserBooks.where(:uid => session[:uid]), isbn: :isbn)
				raise '情報が見つかりません' if base_table.nil?
				base_table
			end

			def extra_data(sid)
				session = Session.get(sid)
				UserBooks.where(:uid => session[:uid])
			end
		end
	end

	module Book
		class << self
			def register(sid, params)
				isbn = params[:isbn]
				register_core isbn, params
	
				session = Session.get(sid)
				ex_data = UserBooks.new(
					:uid => session[:uid],
					:isbn => isbn,
					:登録日 => Date.today,
					:購入予定 => true,
				)
				raise '書籍情報が追加できません' unless ex_data.valid?
				ex_data.save
			end
	
			def update(sid, params)
				columns = {}
				columns[:既読] = params[:既読] if params.has_key?(:既読)
				columns[:所有] = params[:所有] if params.has_key?(:所有)
				columns[:貸出先] = params[:貸出先] if params.has_key?(:貸出先)
				columns[:購入予定] = params[:購入予定] if params.has_key?(:購入予定)
				columns[:評価] = params[:評価] if params.has_key?(:評価)
				columns[:タグ] = params[:タグ] if params.has_key?(:タグ)
				columns[:コメント] = params[:コメント] if params.has_key?(:コメント)
				columns[:読了日] = Date.today if columns.has_key?(:既読) && columns[:既読] == 1
				ex_data(sid, params[:isbn]).update(columns)
			end

			def delete(sid, isbn); ex_data(sid, isbn).delete; end

			def register_core(isbn, params, update: false)
				basic = {:isbn => isbn}
				basic[:書籍名] = params[:書籍名] if params.has_key?(:書籍名)
				basic[:レーベル] = params[:レーベル] if params.has_key?(:レーベル)
				basic[:著者] = params[:著者] if params.has_key?(:著者)
				basic[:著者（読み）] = params[:著者（読み）] if params.has_key?(:著者（読み）)
				basic[:価格] = params[:価格] if params.has_key?(:価格) && params[:価格] != 0
				basic[:判型] = params[:判型] if params.has_key?(:判型)
				basic[:ページ数] = params[:ページ数] if params.has_key?(:ページ数) && params[:ページ数] != 0
				basic[:出版社] = params[:出版社] if params.has_key?(:出版社)
				basic[:発売日] = params[:発売日] if params.has_key?(:発売日)

				_, year, month = */^c?(?<year>[12][0-9]{3})[-\/]?(?<month>[0-9]{1,2})?$/.match(basic[:発売日])
				if year.nil? or !month.nil? and (month.to_i == 0 or month.to_i > 12)
					basic.delete(:発売日)
				else
					basic[:発売日] = year.dup
					if month.nil?
						basic[:発売日] << "-01"
					else
						basic[:発売日] << "-#{month}"
					end
					basic[:発売日] << "-01"
				end

				if update
					BookData.dataset.insert_conflict(:constraint => :書籍情報_pkey, :update => basic, :update_where => {Sequel[:書籍情報][:isbn] => isbn}).insert basic
				else
					BookData.dataset.insert_conflict.insert basic
				end
			end

			private
	
			def ex_data(sid, isbn)
				session = Session.get(sid)
				base_table = UserBooks.where(:uid => session[:uid]).where(:isbn => isbn)
				raise '情報が見つかりません' if base_table.nil?
				base_table
			end
		end
	end
end