# :nodoc: Rocker extensions dealing with player stats
class Rocker
  # The player's statistics (e.g. cash, health, energy).
  def stats(source_page = nil)
    refresh_stats! if @stats.nil?
    @stats
  end

  # Refreshes the cached player statistics.
  def refresh_stats!(source_page = nil)
    @stats ||= {}
    if source_page
      @stats.merge! _parse_stats(source_page)
    else
      page = _bank_page
      @stats.merge! _parse_stats(page)
      @stats.merge! _parse_bank(page)
    end
  end
  
  # Parses the player's statistics out of a page.
  def _parse_stats(source_page)
    root = source_page.root
    statistics = {}
    [[:cash, '#currentCash'], [:level, '#levelFrontTopArea']].each do |rule|
      statistics[rule[0]] = root.css(rule[1]).inner_text.gsub(/\D/, '').to_i
    end
    [[:energy, '#currentEnergy'], [:confidence, '#currentHealth'],
     [:stamina, '#currentStamina']].each do |rule|
      if root.css(rule[1]).length >= 0
        statistics[rule[0]] = root.css(rule[1]).inner_text.gsub(/\D/, '').to_i
        statistics[:"max_#{rule[0]}"] = root.css(rule[1]).first.parent.
                                             inner_text.split('/').last.
                                             gsub(/\D/, '').to_i
      else
        statistics[rule[0]], statistics[:"max_#{rule[0]}"] = 0, 0        
      end
    end
    experience = root.css('.levelBarBottomArea').inner_text.split('/')
    statistics[:experience] = experience[0].gsub(/\D/, '').to_i
    statistics[:exp_threshold] = experience[1].gsub(/\D/, '').to_i
    
    statistics
  end
end
