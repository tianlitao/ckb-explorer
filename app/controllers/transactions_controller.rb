class TransactionsController < ViewController

  def index
  end

  def show
    @transaction = CkbTransaction.find_by_tx_hash(params[:id])
  end
end
