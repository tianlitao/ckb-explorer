require_relative "../config/environment"
require 'telegram/bot'

#token = Settings.tg_bot_token
token = '6721575566:AAHsc5bbd9QLdKLgIacOpVuC_zT-DORTfCA'
Telegram::Bot::Client.run(token) do |bot|
  bot.listen do |message|
    case message.text
    when '/start'
      bot.api.send_message(chat_id: message.chat.id, text: "<b>1、 <code>/start address</code> to turn on monitoring
2、 <code>/stop address</code> to turn off monitoring
3、 <code>/list</code> to display all monitoring addresses
4、 <code>/stop_all</code> to stop all monitoring addresses.</b>",parse_mode: 'HTML')
    when '/stop_all'
      TgBot.where(chat_id: message.chat.id).update_all(is_use: false)
      bot.api.send_message(chat_id: message.chat.id, text: "Bye, You've stopped watching all addresses")
    when '/list'
      bots = TgBot.active.where(chat_id: message.chat.id).pluck(:address_hash).map{|i| "<a href='https://nervosscan.com/addresses/#{i}'>#{i}</a>"}
      if bots.present?
        bot.api.send_message(chat_id: message.chat.id, text: "#{bots.join('
')}
<b>To stop any watch, reply: <code> /stop address </code></b>",parse_mode: 'HTML')
      else
        bot.api.send_message(chat_id: message.chat.id, text: "You have not watching any addresses.
To start any watch, reply: /start address",parse_mode: 'HTML')
      end
    else
      bot.api.send_message(chat_id: message.chat.id, text: "#{message.text}")
      if message.text.start_with?('/start ')
        hash = message.text.gsub('/start ', '').strip
        if QueryKeyUtils.valid_address?(hash)
          bot.api.send_message(chat_id: message.chat.id, text: "You've started watching address #{hash}")
          tg_bot = TgBot.find_or_initialize_by(chat_id: message.chat.id, address_hash: hash)
          tg_bot.is_use = true
          tg_bot.save if tg_bot.changed?
        elsif (hash.match?(/\A\d+\z/)) && address = Address.find_by(id: hash)
            bot.api.send_message(chat_id: message.chat.id, text: "You've started watching address #{address.address_hash}")
            tg_bot = TgBot.find_or_initialize_by(chat_id: message.chat.id, address_hash: address.address_hash)
            tg_bot.is_use = true
            tg_bot.save if tg_bot.changed?
        else
          bot.api.send_message(chat_id: message.chat.id, text: "Sorry. Address format is incorrect. Please try again.")
        end
      end
      if message.text.start_with?('/stop ')
        hash = message.text.gsub('/stop ', '').strip
        TgBot.find_by(chat_id: message.chat.id, address_hash: hash)&.update(is_use: false)
        bot.api.send_message(chat_id: message.chat.id, text: "You've stop watching address #{hash}")
      end
    end
  end
end

