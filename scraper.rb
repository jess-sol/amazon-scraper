#!/usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__), 'lib')

require 'scraper'

# Print single scraped page's contents
if (ARGV.length == 1)
    require 'awesome_print'

    scraper = Scraper.new
    runner = ProductPageRunner.new
    ap scraper.scrape(runner, ARGV[0])

# Go through input file, output to directory
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

    scraper = Scraper.new(retrySleep = 2, retryCount = 3)
    runner = ProductPageRunner.new

    def printPrepare(str)
        str.gsub(/:/, '').downcase
    end

    scraper.scrapeAll(runner, listOfUrlsToScrape) do |result|
        if (result[:success])
            if (result[:data][:missing_data].length == 0)
                puts "Retrieved #{result[:isbn]} - #{result[:data][:title]}"
            else
                puts "Retrieved #{result[:isbn]} Partially Invalid, missing #{nonexistingKeys.join(", ")} - #{result[:data][:title]}"
                errorStream.puts(result[:isbn])
            end

            File.open(File.join(outputDirectory, "#{result[:isbn]}"), 'a') do |file|
                file.puts("#amazon")
                file.puts("isbn: #{printPrepare result[:isbn]}")
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

# Output Help    
else
    puts "Help: ruby #{__FILE__} [inputfile] [outputdirectory] [errorfile]"
    puts "inputfile - List of ISBNs to request, defaults to input."
    puts "outputdirectory - Directory to create ISBN files with their data, defaults to output/."
    puts "errorfile - List of failed to retrieve ISBNs, defaults to screen if no value is given."
    puts
    puts "ruby #{__FILE__} [isbn]"
    puts "Retrieve and print out info for isbn"
end