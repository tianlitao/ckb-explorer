class HomeController < ViewController
  def index
    @blocks = Block.recent.limit(10).select(:id, :miner_hash, :number, :timestamp, :reward, :ckb_transactions_count, :live_cell_changes, :updated_at)
    @daily_static = DailyStatistic.last
    @static_info = StatisticInfo.default
    @transactions = CkbTransaction.tx_committed.recent.normal.limit(10)
  end
end
