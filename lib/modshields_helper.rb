module ModShieldsHelper
  # @return [String] The project URL for the shim.
  def url(id)
    "http://minecraft.curseforge.com/projects/#{id}?cookieTest=1"
  end

  # Gets all of the redlinks within the given array of page titles.
  # @param links [Array<String>] All page titles.
  # @return [Integer] The number of red links.
  def redlinks(links)
    titles = links.join('|')
    params = {
      titles: titles,
      action: 'query',
      prop: 'revisions',
      rvprop: 'content'
    }
    response = MEDIAWIKI.post(params)
    red_links = 0
    response['query']['pages'].each do |_, hash|
      next if hash['ns'] != 0
      red_links += 1 if hash.key?('missing')
    end
    return red_links
  end
end
