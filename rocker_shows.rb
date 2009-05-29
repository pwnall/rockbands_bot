# :nodoc: Rocker extensions for shows.
class Rocker
  # The shows that the player can perform.
  def shows
    refresh_shows! if @shows.nil?
    @shows
  end
  
  # Refreshes the cached list of shows that the player can perform.
  def refresh_shows!
    @shows = _shows
  end

  # Drives the player to perform the given show.
  #
  # Returns a boolean value indicating whether the action was successful.
  def perform_show(show)
    nonce = _get_form_nonce 'shows.php', :promote => '', :cat => '11'
    page = _get_page show[:page], :formNonce => nonce
    _page_indicates_success? page
  end  

  # Fetches the shows that the player can perform.
  def _shows
    shows = []
    ['11', '12', '13', '14'].each do |category|
      shows += _parse_shows _shows_page(category)
    end
    shows
  end
  
  # Parses the shows out of a page.
  def _parse_shows(source_page)
    shows_table = source_page.root.css('table.missionTable')
    shows = []
    shows_table.css('tr').each do |tr|
      show = {}
      show[:name] = tr.css('.missionName').inner_text
      cash_range = tr.css('.cash').inner_text.split('-')
      show[:cash_min] = cash_range[0].gsub(/\D/, '').to_i
      show[:cash_max] = cash_range[1].gsub(/\D/, '').to_i
      show[:experience] = tr.css('.missionDetails div:last-child').
                             inner_text.gsub(/\D/, '').to_i
      show[:page] = tr.css('.missionAction a').attr('href').
                       gsub(/formNonce\=[^&]*\&/, '').gsub(/^\//, '')
      
      show[:energy], show[:members] = 0, 1
      tr.css('.missionReq div').each do |div|
        if /nergy: / =~ div.inner_text 
          show[:energy] = div.inner_text.gsub(/\D/, '').to_i
        end
        if /embers: / =~ div.inner_text 
          show[:members] = div.inner_text.gsub(/\D/, '').to_i
        end
      end
      
      show[:equipment] = []
      tr.css('.equipmentRequiredQty').each do |div|
        show[:equipment].push :quant => div.inner_text.gsub(/\D/, '').to_i
      end
      tr.css('.equipmentReqItemPic').each_with_index do |div, i|
        show[:equipment][i][:id] = div.inner_html.gsub(/\D/, '').to_i
      end
      
      shows << show
    end
    shows
  end 

  # Retrieves the players' shows page.
  def _shows_page(category = nil)
    _get_page 'shows.php', :promote => '', :cat => category
  end
end
