require 'sinatra'
require 'curb'
require 'nokogiri'
require 'mediawiki/butt'
require 'dotenv'
require 'open-uri'
require_relative 'lib/modshields_helper'

Dotenv.load

helpers ModShieldsHelper

MEDIAWIKI = MediaWiki::Butt.new('https://ftb.gamepedia.com/api.php', assertion: :bot)
MEDIAWIKI.login(ENV['WIKIUSER'], ENV['WIKIPASS'])

before do
  content_type('image/svg+xml')
  response.headers['Cache-Control'] = 'no-cache'
end

get '/wiki' do
  article = params[:article]
  content = MEDIAWIKI.get_text(article)
  ret = ''
  if content.nil?
    ret = Curl.get('https://img.shields.io/badge/wiki-0%25-red.svg').body_str
  else
    pagelinks = MEDIAWIKI.get_all_links_in_page(article)
    all_links = pagelinks.size
    red_links = redlinks(pagelinks)
    unless MEDIAWIKI.get_text("Template:Navbox #{article}/content").nil?
      links = MEDIAWIKI.get_all_links_in_page("Template:Navbox #{article}/content")
      all_links += links.size
      red_links += redlinks(links)
    end
    p "red #{red_links} all #{all_links}"

    percent = (((all_links - red_links) / all_links.to_f) * 100).to_i
    p percent

    color =
      if percent.zero?
        'red'
      elsif percent <= 25
        'orange'
      elsif percent <= 50
        'yellow'
      elsif percent <= 75
        'yellowgreen'
      elsif percent <= 100
        'green'
      end
    ret = Curl.get("https://img.shields.io/badge/wiki-#{percent}%25-#{color}.svg").body_str
  end

  ret
end

get '/totaldl' do
  id = params[:id]
  url = url(id)
  begin
    response = File.read(open(url))
  rescue OpenURI::HTTPError
    halt(400, Curl.get('https://img.shields.io/badge/downloads-invalid-lightgrey.svg').body_str)
  end

  html = Nokogiri::HTML(response, &:noblanks)
  index = 0
  html.css('.info-label').each_with_index do |label, i|
    index = i if label.children.text.strip == 'Total Downloads'
  end
  downloads = html.css('.info-data')[index].children.text

  Curl.get("https://img.shields.io/badge/downloads-#{downloads}-blue.svg").body_str
end

# Commented out because this is not available on CurseForge, just Curse. In other words I'm lazy.
# get '/monthlydl' do
#
# end

get '/latestversion' do
  id = params[:id]
  mcversion = params[:mcversion]
  url = url(id)
  begin
    response = File.read(open(url))
  rescue OpenURI::HTTPError
    halt(400, Curl.get('https://img.shields.io/badge/mod version-invalid-lightgrey.svg').body_str)
  end

  html = Nokogiri::HTML(response, &:noblanks)
  index = 0
  unless mcversion.nil?
    html.css('.e-sidebar-subheader').each_with_index do |h4, i|
      index = i if mcversion =~ /#{h4.children.text.strip.gsub('Minecraft ', '')}/
    end
  end

  # This is fun. /me hopes he never has to touch this again.
  vers = html.css('.cf-recentfiles')[index].children[0].children[3].children[3].children[1].children[0].text.split('-')[-1].gsub!(/\.(jar|zip)/, '')

  Curl.get("https://img.shields.io/badge/mod version-#{vers}-blue.svg").body_str
end
