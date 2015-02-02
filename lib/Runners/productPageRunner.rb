class ProductPageRunner
    def run(agent, page)
        result = {
            :title => removeWhitespace(page.parser.css('#booksTitle #productTitle').text),
            :author => getAuthor(agent, page),
            :description => removeWhitespace(page.parser.css('#bookDescription_feature_div noscript').text),
            :details => getProductDetails(agent, page)
        }

        result[:missing_data] = containsAll(result, [:title, :author, :description, :details])

        result
    end

    private
    def getAuthor(agent, page)
        authors = []

        page.parser.css('#booksTitle .author > a, #booksTitle .author a.contributorNameID').each do |author|
            authors.push(removeWhitespace(author.text))
        end

        authors
    end

    def getProductDetails(agent, page)
        result = {}
        index = 0

        page.parser.css('#productDetailsTable .content > ul > li').each do |bulletpoint|
            bptext = removeWhitespace bulletpoint.text
            bpkey, bpvalue = bptext.split(/:\s+/, 2)
            next if bptext.start_with? 'Average Customer Review'

            bpvalue = parseBestSellersRank(bulletpoint) if bptext.start_with? 'Amazon Best Sellers Rank'
            bpvalue.gsub!(/ \(View shipping rates and policies\)$/, '') if bpvalue.is_a?(String)

            if (bpkey == '')
                bpkey = index
                index += 1
            end

            result[bpkey] = bpvalue
        end

        result
    end

    def parseBestSellersRank(content)
        rankings = []
        content.css('li').each do |line|
            rank = line.css('[class$="_rank"]').text[1..-1]

            ladder = []
            line.css('a').each do |ladderItem|
                ladder.push(removeWhitespace(ladderItem.text))
            end

            rankings.push({
                :rank => rank,
                :ladder => ladder
            })
        end

        rankings
    end

    def containsAll(hash, keys)
        nonexistingKeys = []
        keys.each do |key|
            nonexistingKeys.push(key) unless
            hash.has_key? key or
            hash[key].nil? or
            (hash[key].is_a(Array) and hash[key].length == 0)
        end

        nonexistingKeys
    end

    def removeWhitespace(str)
        str.gsub(/\s{3,}/, ' ').strip
    end
end