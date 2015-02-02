class Scraper

end

# Command line runner
if (ARGV.length > 0)
    listOfUrlsToScrapeFile = ARGV[0]
    outputFile = ARGV.length > 1 ? ARGV[1] : 'output.txt'
    errorFile  = ARGV.length > 2 ? ARGV[2] : 'error.txt'

    puts "Scraping urls in #{listOfUrlsToScrapeFile}, outputting results to #{outputFile}, and errors to #{errorFile}"

    listOfUrlsToScrape = File.readlines(listOfUrlsToScrapeFile)
    outputStream = File.open(outputFile, 'w');
    errorStream = File.open(errorFile, 'w');

    
end