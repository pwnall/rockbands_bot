# :nodoc: Rocker extensions for promotions.
class Rocker
  # The promotions that the player can buy.
  def promotions
    refresh_promotions! if @promotions.nil?
    @promotions
  end
  
  # Refreshes the cached list of promotions that the player can perform.
  def refresh_promotions!
    @promotions = _promotions
  end  
  
  # Fetches the shows that the player can perform.
  def _promotions
    _parse_promotions _promotions_page
  end
  
  # Drives the player to buy the given promotion.
  #
  # Returns a boolean value indicating whether the action was successful.
  def buy_promotion(promo)
    page = _get_page promo[:buy_page]
    _page_indicates_success? page
  end  
  
  # Parses the promotions out of a page.
  def _parse_promotions(source_page)
    promo_tables = source_page.root.css('table.reTable')
    promos = []
    promo_tables.each do |table|
      promo = {}
      promo[:cash] = table.css('.reInfo .cash').inner_text.gsub(/\D/, '').to_i
      promo[:cost] = table.css('.reBuyAction .cash').inner_text.
                                                       gsub(/\D/, '').to_i
      promo[:name] = table.css('.reName').inner_text
      promo[:buy_page] = table.css('.reBuyAction a').attr('href')
      sell_link = table.css('.reSellAction a')      
      promo[:sell_page] = sell_link.attr('href') if sell_link.length > 0
      promo[:id] = table.css('.rePic img').attr('src').gsub(/.*\//, '').
                         gsub(/\D/, '').to_i
      promos << promo
    end

    promos
  end 

  # Retrieves the players' promotions page.
  def _promotions_page(category = nil)
    _get_page 'investment.php'
  end
end
