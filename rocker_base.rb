require 'rubygems'
require 'nokogiri'
require 'mechanize'
require 'yaml'


# The automated RockBands live player driver.
class Rocker
  # Create an automated player driver.
  #
  # The required options are:
  #   udid:: the iPhone / iPod's UDID, which identifies the player
  #   pf:: security parameter; computation method TBR (SHA-256 / AES-256?)
  #
  # The options can also be a file name or an IO stream. In that case, YAML will
  # be used to read the options from the file or stream. 
  def initialize(options)
    # Accept a file name, and treat it as a YML file.
    if options.respond_to? :to_str
      options = File.open(options, 'r') { |f| YAML.load f } 
    end
    # Accept a stream, and read the YML options from there.
    if options.kind_of? IO
      options = YAML.load options
    end    
    @user_udid = options[:udid] || options['udid']
    @user_pf =  options[:pf] || options['pf']
    
    @agent = WWW::Mechanize.new
    @agent.user_agent = self.class.user_agent
    _login    
  end

  # A value for User-Agent: accepected by the game server.
  def self.user_agent
    'Mozilla/5.0 ' +
        '(iPhone; U; CPU iPhone OS 3_0 like Mac OS X; en-us) ' + 
        'AppleWebKit/528.18 (KHTML, like Gecko) Mobile/7A312g'
  end
  
  # The host URI for the game server.
  def self.host
    'http://rol.storm8.com'
  end  
  
  # Fetches a page from the game server.
  def _get_page(page_name, parameters = {})
    attempts = 5
    loop do
      begin
        return @agent.get(File.join(self.class.host, page_name), parameters)
      rescue
        attempts -= 1
        raise if attempts == 0
      end
    end
  end

  # Extracts a nonce needed by the server to process state-changing requests. 
  #
  # The nonces depend on the form that needs to be submitted. Therefore, the
  # page_or_page_name argument should either have a Mechanize page to parse,
  # or a string containing the relative URL of a page containing the form to be
  # submitted. If the argument is a string, it can be followed by a hash of
  # parameters that works similarly to _get_page.  
  def _get_form_nonce(page_or_page_name, args = {})
    if page_or_page_name.kind_of? String
      page = _get_page page_or_page_name, args
    else
      page = page_or_page_name
    end
    match_data = /formNonce=([^&"]*)(\&|\")/.match page.body
    match_data[1]
  end

  # Logs into the game, to get the player cookie.
  #
  # This is called in initialize, and should not be called directly.
  def _login
    _get_page 'index.php', :version => '1.0', :udid => @user_udid,
                           :pf => @user_pf, :pnum => '', :model => 'iPhone'
  end
  
  # Retrieves the player's home page.
  def _home_page
    _get_page 'home.php', :promote => ''
  end
  
  # True if the page indicates that the previous action succeeded, false if
  # the page indicates the action failed.
  def _page_indicates_success?(page)
    return true if page.root.css('.messageBoxSuccess').length > 0
    return false if page.root.css('.messageBoxFail').length > 0
    return nil
  end
  
  
  # Retrieves the players' battle page.
  def _battle_page
    _get_page 'fight.php', :promote => ''  
  end  
end
