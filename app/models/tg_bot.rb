class TgBot < ApplicationRecord
  scope :active, -> { where(is_use: true) }
  before_create do
    self.address_id = Address.find_by_address_hash(self.address_hash)&.id
  end
end

# == Schema Information
#
# Table name: tg_bots
#
#  id             :bigint           not null, primary key
#  chat_id        :string
#  address_id     :integer
#  address_hash   :string
#  is_use         :boolean          default(TRUE)
#  change_balance :decimal(30, )
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_tg_bots_on_address_hash              (address_hash)
#  index_tg_bots_on_address_id                (address_id)
#  index_tg_bots_on_chat_id                   (chat_id)
#  index_tg_bots_on_chat_id_and_address_hash  (chat_id,address_hash) UNIQUE
#
