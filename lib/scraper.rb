require 'Mechanize'

require_relative 'Runners/ProductPageRunner'

class Scraper
    def initialize(retryCount=1, retrySleep=0.5, scrapeSleep=0.5)
        @retryCount = retryCount
        @retrySleep = retrySleep
        @scrapeSleep = scrapeSleep

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