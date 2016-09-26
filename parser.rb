# Joseph Barlow
# Ruby USM Parser

$visitedCounter = 0

require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'open_uri_redirections'

# Class for storing website information
class Website
	def initialize(http, words, total)
		@site_http=http
		@site_words=words
		@total_words=total
	end

	def title
		@site_http
	end

	def words
		@site_words
	end

	def total
		@total_words
	end
end

# Function for collecting words (returns Website class)
def wordCollector(pageName)
	wordHash = Hash.new 0
	words = Array.new

	currentPage = Nokogiri::HTML(open(pageName, :allow_redirections => :safe))
	pageText = currentPage.css('p').to_s
	words = pageText.split(/\W+|\d/)
	words.each do |string|
	   wordHash[string] += 1
	end
	return Website.new(pageName, wordHash, words.length)
end

# Function for collecting links
def linkCollector(pageName)
	urls = Array.new
	str = "http://www.usm.edu"

	# Collects links from page
	begin
		currentPage = Nokogiri::HTML(open(pageName, 'User-Agent' => 'ruby', :allow_redirections => :safe))
	rescue OpenURI::HTTPError => e
    	puts "Can't access #{ pageName }"
    	puts e.message
		puts
    end
    $visitedCounter += 1
	links = currentPage.css("a")
	links.each do |link|
		if link['href'] =~ /science-technology/ and link['href'] !~ /staff|faculty|jpg|pdf/
			if link['href'] !~ /www.usm.edu/
				urls.push(str + link['href'])
			else
				urls.push(link['href'])
			end
		end
	end
	return urls
end

# Main Program
pageList = Array.new
siteList = Array.new
visitedList = Array.new
currentUrls = Array.new
linkHash = Hash.new 0
totalWords = Hash.new 0
totalWordDocs = Hash.new 0

txtCount = 1
totalWordCount = 0
pageList = ["http://www.usm.edu/science-technology"]

# Visits sites, collects links, and collects words
while pageList.empty? == false do
	pageList.each do |pageName|
		visitedList.push(pageName)
		siteList.push(wordCollector(pageName))
		currentUrls = linkCollector(pageName)
		currentUrls.each do |string|
			linkHash[string] += 1
		end
		pageList += currentUrls
		pageList.uniq
		currentUrls.clear
		pageList = pageList - visitedList
	end
end
puts "Pages Visited: " + $visitedCounter.to_s
puts "Visited List Length: " + visitedList.length.to_s

# Creates link histogram
linkHist = File.open("link_histogram.txt", "w")
linkHash.each do |key, value|
	linkHist.puts(key.to_s + " => " + value.to_s)
end
linkHist.close

# Calculates total word list across all selected sites
siteList.each do |site|
	site.words.each do |key, value|
		totalWords[key] += value
		totalWordCount += value
		totalWordDocs[key] += 1
	end
end

# Calculates TF-IDF for pages
siteList.each do |site|
	tempFile = File.open("#{txtCount}.txt", "w")
	tempHashArray = Array.new
	tempHash = Hash.new 0
	tempSortHash = Hash.new 0
	tempFile.puts(site.title)
	tempFile.puts("")
	site.words.each do |key, value|
		tf = value.to_f/site.total.to_f
		idf = Math.log(Math::E**(visitedList.length.to_f/totalWordDocs.fetch(key).to_f))
		tempHash[key] = (tf*idf)
	end
	tempSortHash = tempHash.sort_by {|key, value| value}.reverse.to_h
	tempSortHash.each do |key, value|
		tempFile.puts (key.to_s + " => " + value.to_s)
	end
	tempFile.close
	tempHash.clear
	tempSortHash.clear
	txtCount += 1
end

# Calculates TF-IDF for global
tempFile = File.open("global.txt", "w")
tempHashArray = Array.new
tempHash = Hash.new 0
tempFile.puts("Global")
tempFile.puts("")
totalWords.each do |key, value|
	tf = value.to_f/totalWordCount.to_f
	idf = Math.log(Math::E**(visitedList.length.to_f/totalWordDocs.fetch(key).to_f))
	tempHash[key] = (tf*idf)
end
tempSortHash = tempHash.sort_by {|key, value| value}.reverse.to_h
tempSortHash.each do |key, value|
	tempFile.puts (key.to_s + " => " + value.to_s)
end
tempFile.close
