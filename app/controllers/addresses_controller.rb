class AddressesController < ViewController

  def index
    @addresses = Address.visible.where("balance > 0").order(balance: :desc).page(params[:page]).per(10)
    @all_count = Address.visible.where("balance > 0").count
    @ten_sum = Address.visible.where("balance > 0").order(balance: :desc).limit(10).pluck(:balance).sum
    @hun_sum = Address.visible.where("balance > 0").order(balance: :desc).limit(100).pluck(:balance).sum
    @thou_sum = Address.visible.where("balance > 0").order(balance: :desc).limit(1000).pluck(:balance).sum
    @all_supply = Address.visible.where("balance > 0").sum(:balance)
  end

  def show
    @address = Address.find_by_address_hash(params[:id])
    @transactions = @address.ckb_transactions.order('id desc').page(params[:page]).per(10)
  end
end
