FactoryBot.define do
  factory :tg_bot do
    chat_id { "MyString" }
    address_id { 1 }
    address_hash { "MyString" }
    is_use { false }
    change_balance { "9.99" }
  end
end
