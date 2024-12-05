class TelegramBot
  include Sidekiq::Worker
  require 'telegram/bot'
  sidekiq_options queue: "telegram"
  def perform(address_id, change_balance)
    address = Address.find_by(id: address_id)
    bot = Telegram::Bot::Client.new('6721575566:AAHsc5bbd9QLdKLgIacOpVuC_zT-DORTfCA')
    address.tg_bots.active.each do |tg_bot|
      bot.api.send_message(chat_id: tg_bot.chat_id, text: "Address: <a href='https://nervosscan.com/addresses/#{tg_bot.address_hash}'>#{tg_bot.address_hash}</a>
Change Amount: #{change_balance.to_f/10**8}CKB", parse_mode: 'HTML') if (change_balance.to_f/10**8).abs > 1000000
    end
  end

end