class HomeController < ViewController
  def index
    @blocks = Block.recent.limit(10).select(:id, :miner_hash, :number, :timestamp, :reward, :ckb_transactions_count, :live_cell_changes, :updated_at)
    @daily_static = DailyStatistic.last
    @static_info = StatisticInfo.default
    @transactions = CkbTransaction.tx_committed.recent.normal.limit(10)
  end

  def search
    query_key = params[:q]
    if QueryKeyUtils.integer_string?(query_key)
      if @block = Block.where("number = ? or block_hash = ?", query_key, query_key).first
        redirect_to block_path(@block.number)
      end
    elsif QueryKeyUtils.valid_hex?(query_key)
      if @block = Block.where("number = ? or block_hash = ?", query_key, query_key).first
        redirect_to block_path(@block.number)
      end
      if @transaction =  CkbTransaction.cached_find(query_key)
        redirect_to transaction_path(@transaction.tx_hash)
      end
      if @address = Address.cached_find(query_key)
        redirect_to address_path(@address.address_hash)
      end
    elsif QueryKeyUtils.valid_address?(query_key)
      if @address = Address.cached_find(query_key)
        redirect_to address_path(@address.address_hash)
      end
    end
  end

end
