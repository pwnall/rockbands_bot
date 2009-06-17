# :nodoc: Rocker extensions for the bank.
class Rocker

  # Drives the player to deposit money in the bank.
  #
  # Returns true for success, false for failure.
  def deposit_to_bank!(cash)
    page = _post_page 'bank.php', :depositAmount => cash.to_s,
                                  :action => 'Deposit'
    _page_indicates_success? page
  end
  
  # Drives the player to withdraw money from the bank.
  #
  # Returns true for success, false for failure.
  def withdraw_from_bank!(cash)
    page = _post_page 'bank.php', :withdrawAmount => cash.to_s,
                                  :action => 'Withdraw'
    _page_indicates_success? page
  end

  # Parses bank information out of the bank page.
  def _parse_bank(source_page)
    root = source_page.root
    bank_cash = root.css('.cash').inner_text.gsub(/K/, '000').
                                             gsub(/\D/, '').to_i
    { :bank_cash => bank_cash }
  end
  
  # Retrieves the player's bank page.
  def _bank_page
    _get_page 'bank.php'
  end
end
