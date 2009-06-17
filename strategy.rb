require 'rocker'

rocker = File.open('player.yml', 'r') { |f| Rocker.new f }

STDOUT.sync = true

def print_stats(stats)
  print("Energy #{'%4d' % stats[:energy]} Cash #{'%6d' % stats[:cash] } " +
        "Bank #{'%8d' % stats[:bank_cash]} " +
        "Confidence #{'%4d' % stats[:confidence]} " +
        "Stamina #{'%2d' % stats[:stamina]}\n")  
end

def perform_best_show(rocker)
  stats = rocker.stats
  # Out of the shows the player could possibly perform, get the show that
  # optimizes cash.
  # The solution is the show with the best expected cash per energy unit (the
  # ratio of expected cash to energy cost).
  show = rocker.shows.select { |s| s[:energy] <= stats[:max_energy] }.
                      sort_by { |s| -(s[:cash_min] + s[:cash_max]) /
                                    s[:energy] }.first
  print "Aiming show: #{show[:name]} +#{(show[:cash_min]+show[:cash_max])/2} " +
        "-#{show[:energy]}\n"
  
  if show[:energy] <= stats[:energy]
    print "Performing show..."
    print(rocker.perform_show(show) ? "win\n" : "fail\n")
    rocker.refresh_stats!
  end
end

def fight_while_possible(rocker)
  stats = rocker.stats
  # If we have enough confidence and stamina to fight, we should fight.
  # If we fight, we have nothing to lose. If others fight us instead, we can
  # lose cash.
  while stats[:stamina] > 0 and stats[:confidence] >= 27
    enemies = rocker.fetch_bunch_of_enemies!
    enemy = enemies.sort_by { |e| e[:band_size] }.first
    print "Battling #{enemy[:name]} (#{enemy[:band_size]})..."
    print(rocker.battle!(enemy) ? "win\n" : "fail\n")
    rocker.refresh_stats!
    stats = rocker.stats
    print_stats stats
  end
end

def deposit_all_except(cash_allowance, rocker)
  # If we have more than $1,000 out in the open, deposit the difference in the
  # bank. This limits exposure to attacks.
  stats = rocker.stats
  if stats[:cash] > cash_allowance
    deposit_cash = stats[:cash] - cash_allowance
    print "Current cash #{stats[:cash]} exceeding #{cash_allowance}\n"
    print "Depositing #{deposit_cash} to bank..."
    print(rocker.deposit_to_bank!(deposit_cash) ? "win\n" : "fail\n")
    rocker.refresh_stats!
  end  
end

def maintain_revenue_margin(desired_margin, rocker)
  stats = rocker.stats
  loop do
    # TODO(costan): get stats, check margin
    break
    
    promo = rocker.promotions.sort_by { |p| p[:cost] / p[:cash] }.first
    print "Aiming promotion #{promo[:name]} +#{promo[:cash]} -#{promo[:cost]}\n"
    
    if stats[:cash] < promo[:cost]
      # Do we have the money in the bank?
      if stats[:bank_cash] + stats[:cash] >= promo[:cost]
        withdraw_cash = promo[:cost] - stats[:cash]
        print "Withdrawing #{withdraw_cash}..."
        print(rocker.withdraw_from_bank!(withdraw_cash) ? "win\n" : "fail\n")        
      else
        break  # Done acquiring promotions.
      end
    end
    
    print "Buying promotion..."
    print(rocker.buy_promotion(promo) ? "win\n" : "fail\n")
    
    rocker.refresh_stats!
    stats = rocker.stats
    print_stats stats
    rocker.refresh_promotions!
  end
end

while true
  rocker.refresh_stats!
  print_stats rocker.stats
  
  perform_best_show rocker
  fight_while_possible rocker
  deposit_all_except 1000, rocker
  maintain_revenue_margin 0.5, rocker
  
  # Wake up every ~ 2min30sec, since energy increases once every 5min.
  sleep_time = 150 + 40 * (rand - 0.5)  # +/- 20sec, so it's not regular.
  print "Sleeping #{'%.1f' % sleep_time}s..."
  sleep sleep_time
  print "done\n"
end
