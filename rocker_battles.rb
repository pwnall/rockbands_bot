# :nodoc: Rocker extensions for the bank.
class Rocker
  # Drives the player to battle another player.
  #
  # The opponent's id should be indicated in player_id.
  #
  # Returns true for success, false for failure.
  def battle!(player)
    page = _get_page 'fight.php', :action => 'fight',
                                  :rivalId => player[:player_id].to_s,
                                  :formNonce => _get_form_nonce('fight.php')
    _page_indicates_success? page
  end
  
  # Fetches a bunch of enemies via the battles page.
  def fetch_bunch_of_enemies!
    _parse_battles _battles_page
  end
  
  # Parses bank information out of the bank page.
  def _parse_battles(source_page)
    root = source_page.root
    player_table = source_page.root.css('table.fightTable')
    battles = []
    player_table.css('tr').each do |tr|
      battleLink = tr.css('td.fightMobster a')
      battle = { :name => battleLink.inner_text,
                 :band_size => tr.css('td.fightMobSize').inner_text.
                                  gsub(/\D/, '').to_i }
      battle[:player_id] = battleLink.attr('href').gsub(/\D/, '').to_i
      
      battles << battle
    end
    battles
  end
  
  # Retrieves the player's bank page.
  def _battles_page
    _get_page 'fight.php'
  end  
end