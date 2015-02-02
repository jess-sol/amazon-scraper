#!/usr/bin/env ruby
require 'Mechanize'

require_relative 'Runners/ProductPageRunner'

class Scraper
    def initialize(retryCount=1)
        @retryCount = retryCount
        @retrySleep = 1/2.0
        @scrapeSleep = 1/2.0

        @urlPattern = 'http://www.amazon.com/dp/$isbn'

        @agent = Mechanize.new
        @agent.user_agent_alias = 'Windows IE 8'
    end

    def scrape(runner, isbn)
        page = @agent.get(url(isbn))

        runner.run(@agent, page)
    end

    def scrapeAll(runner, isbns)
        results = []

        isbns.each do |isbn|
            retries = 0
            begin
                scrapeResult = scrape(runner, isbn)

                data = {
                    :isbn => isbn,
                    :success => true,
                    :data => scrapeResult
                }

                yield data
            rescue Exception => e
                if (retries < @retryCount)
                    sleep(@retrySleep)
                    retries += 1
                    retry
                end
                data = {
                    :isbn => isbn,
                    :success => false,
                    :error => e.to_s
                }
                yield data
            end

            sleep(@scrapeSleep)
        end
    end

    private
    def url(isbn)
        return @urlPattern.gsub(/\$isbn/, isbn)
    end
end

# Command line runner
if (ARGV.length == 1)
    require 'awesome_print'

    scraper = Scraper.new
    runner = ProductPageRunner.new
    ap scraper.scrape(runner, ARGV[0])
elsif (ARGV.length > 0)
    listOfUrlsToScrapeFile = ARGV[0]
    outputDirectory = ARGV.length > 1 ? ARGV[1] : "output/"
    errorFile  = ARGV.length > 2 ? ARGV[2] : nil

    if (!File.exists? listOfUrlsToScrapeFile)
        puts "Error, input file not found: #{listOfUrlsToScrapeFile}"
        exit 1
    end

    puts "Scraping urls in #{listOfUrlsToScrapeFile}, " +
        "outputting results to #{outputDirectory}, " +
        "and errors to #{errorFile.nil? ? "screen" : errorFile}"

    errorStream = !errorFile.nil? ? File.open(errorFile, 'w') : $stderr

    FileUtils.mkdir(outputDirectory) unless File.directory? outputDirectory

    # Get all urls and remove empty lines
    listOfUrlsToScrape = File.readlines(listOfUrlsToScrapeFile)
    listOfUrlsToScrape.delete_if {|isbn| isbn.chomp == '' }
    listOfUrlsToScrape.map! {|isbn| isbn.strip }

    scraper = Scraper.new
    runner = ProductPageRunner.new

    def printPrepare(str)
        str.gsub(/:/, '').downcase
    end

    scraper.scrapeAll(runner, listOfUrlsToScrape) do |result|
        if (result[:success])
            puts "Retrieved #{result[:isbn]} - #{result[:data][:title]}"

            File.open(File.join(outputDirectory, "#{result[:isbn]}.txt"), 'w') do |file|
                file.puts("title: #{printPrepare result[:data][:title]}")
                file.puts("author: #{printPrepare result[:data][:author].join(', ')}")
                file.puts("description: #{printPrepare result[:data][:description]}")

                result[:data][:details].each do |detail, value|
                    if (detail == "Amazon Best Sellers Rank")
                        value.each do |ranking|
                            file.puts("ranking: #{printPrepare ranking[:ladder].last} (#{ranking[:rank]})")
                        end
                    else
                        file.puts("#{printPrepare detail}: #{printPrepare value}")
                    end
                end
            end
        else
            puts "Failed #{result[:isbn]} - #{result[:error]}"
            errorStream.puts(result[:isbn])
        end
    end

    errorStream.close unless errorStream == $stderr
        
else
    puts "Help: ruby #{__FILE__} [inputfile] [outputdirectory] [errorfile]"
    puts "inputfile - List of ISBNs to request, defaults to input."
    puts "outputdirectory - Directory to create ISBN files with their data, defaults to output/."
    puts "errorfile - List of failed to retrieve ISBNs, defaults to screen if no value is given."
    puts
    puts "ruby #{__FILE__} [isbn]"
    puts "Retrieve and print out info for isbn"
end