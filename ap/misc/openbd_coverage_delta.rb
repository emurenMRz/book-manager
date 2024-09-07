#!/usr/bin/env ruby

require 'json'
require 'uri'
require 'net/http'

ADD_FILE = "#{__dir__}/add.json"
REMOVE_FILE = "#{__dir__}/remove.json"
COVERAGE_FILE = "#{__dir__}/coverage.json"

OPENDB_ORIGIN = "http://api.openbd.jp"

puts 'read old coverage...'
old_coverage = File.exist?(COVERAGE_FILE) ? JSON.parse(File.read(COVERAGE_FILE)) : []
puts 'load now coverage...'
now_coverage = JSON.parse(Net::HTTP.get(URI.parse("#{OPENDB_ORIGIN}/v1/coverage")))

module Flag
	NONE = 0x0
	OLD = 0x1
	NOW = 0x2
	BOTH = OLD | NOW
end

puts 'comparing...'
coverage = {}
old_coverage.each do |isbn|
	puts "duplication old: #{isbn}" if coverage.has_key?(isbn)
	coverage[isbn] = Flag::OLD
end
now_coverage.each do |isbn|
	has_key = coverage.has_key?(isbn)
	puts "duplication now: #{isbn}" if has_key && (coverage[isbn] & Flag::NOW) != 0
	coverage[isbn] = Flag::NONE unless has_key
	coverage[isbn] |= Flag::NOW
end

coverage.delete_if{|k, v| v == Flag::BOTH}

add = coverage.select{|k, v| v == Flag::NOW}.keys.map{|v| v.to_i}
remove = coverage.select{|k, v| v == Flag::OLD}.keys.map{|v| v.to_i}
puts "add: #{add.length}, remove: #{remove.length}"

if ARGV[0] != '-dry'
	if add.length > 0
		puts 'output add...'
		uri = URI.parse "#{OPENDB_ORIGIN}/v1/get?isbn=#{add.join(',')}"
		books = JSON.parse(Net::HTTP.get(uri))
		books = [books] if books.class == 'Hash'
		File.write(ADD_FILE, JSON.dump(books))
	end
	if remove.length > 0
		puts 'output remove...'
		File.write(REMOVE_FILE, JSON.dump(remove))
	end
	if add.length > 0 || remove.length > 0
		puts 'output coverage...'
		File.write(COVERAGE_FILE, JSON.dump(now_coverage))
	end
end
