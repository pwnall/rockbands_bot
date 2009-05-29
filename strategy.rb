require 'rocker'

rocker = File.open('player.yml', 'r') { |f| Rocker.new f }

STDOUT.sync = true

def print_stats(stats)
  print("Energy #{'%4d' % stats[:energy]} Cash #{'%6d' % stats[:cash] } " +
        "Bank #{'%8d' % stats[:bank_cash]} " +
        "Confidence #{'%4d' % stats[:confidence]} " +
        "Stamina #{'%2d' % stats[:stamina]}\n")  
end

while true
  rocker.refresh_stats!
  stats = rocker.stats
  print_stats stats
  
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
  end
  
  
  # If we have enough confidence and stamina to fight, we should fight.
  # If we fight, we have nothing to lose. If others fight us instead, we can
  # lose cash.
  while stats[:stamina] > 0 and stats[:confidence] >= 27
    enemies = rocker.fetch_bunch_of_enemies!
    enemy = enemies.sort_by { |e| e[:band_size] }.first
    print "Battling #{enemy[:name]} (#{enemy[:band_size]})..."
    print(rocker.battle!(enemy) ? "win\n" : "fail\n")
    rocker.refresh_stats!
    print_stats stats
  end
  

  # If we have more than $1,000 out in the open, deposit the difference in the
  # bank. This limits exposure to attacks.
  rocker.refresh_stats!
  stats = rocker.stats
  if stats[:cash] > 1000
    deposit_cash = stats[:cash] - 1000
    print "Current cash #{stats[:cash]} exceeding 1000\n"
    print "Depositing #{deposit_cash} to bank..."
    print(rocker.deposit_to_bank!(deposit_cash) ? "win\n" : "fail\n")
  end
  
  
  # Wake up every ~ 2min30sec, since energy increases once every 5min.
  sleep_time = 150 + 40 * (rand - 0.5)  # +/- 20sec, so it's not regular.
  print "Sleeping #{'%.1f' % sleep_time}s..."
  sleep sleep_time
  print "done\n"
end
