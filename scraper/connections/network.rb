class Network
  def self.get_parsed_source(url)
    agent = Mechanize.new
    agent.user_agent_alias = 'Mac Safari'
    page_source = agent.get(url).body
    doc = Nokogiri.parse(page_source)
    doc
  end
end
