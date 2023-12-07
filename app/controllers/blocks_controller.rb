class BlocksController < ViewController
  def index

  end

  def show
    @block = Block.where("number = ? or block_hash = ?", params[:id], params[:id]).last
    @transactions = @block.ckb_transactions.order('id desc').page(params[:page]).per(10)
  end

end
