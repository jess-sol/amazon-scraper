require 'Mechanize'

require_relative 'Runners/ProductPageRunner'

class Scraper
    def initialize(retryCount=1)
        @retryCount = retryCount
        @retrySleep = 1/2.0
        @scrapeSleep = 1/2.0

        @urlPattern = 'http://www.amazon.com/dp/$isbn'
        @userAgentAlias = 'Windows IE 8'
    end

    def scrape(runner, isbn)
        agent = Mechanize.new
        agent.user_agent_alias = @userAgentAlias
        page = agent.get(url(isbn))

        runner.run(agent, page)
    end

    def scrapeAll(runner, isbns)
        results = []

        isbns.each do |isbn|
            retries = 0
            begin
                result = scrape(runner, isbn)
                result[:isbn] = isbn

                yield result
            rescue Exception => e
                puts "ERRROR #{e}"
                if (retries < @retryCount)
                    sleep(@retrySleep)
                    retries += 1
                    retry
                end
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

    scraper.scrapeAll(runner, listOfUrlsToScrape) do |result|
        puts result.inspect
    end
else
    puts "Help: ruby Scraper.rb [inputfile] [outputdirectory] [errorfile]"
    puts "inputfile - List of ISBNs to request, defaults to input."
    puts "outputdirectory - Directory to create ISBN files with their data, defaults to output/."
    puts "errorfile - List of failed to retrieve ISBNs, defaults to screen if no value is given."
    puts
    puts "ruby Scraper.rb [isbn]"
    puts "Retrieve and print out info for isbn"
end