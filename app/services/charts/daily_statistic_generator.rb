module Charts
  class DailyStatisticGenerator
    def initialize(datetime = nil, from_scratch = false)
      raise "datetime must be a Time" if datetime.present? && !datetime.is_a?(Time)

      @datetime = datetime
      @from_scratch = from_scratch
    end

    def call
      Rails.logger.info "Generating daily statistics for #{to_be_counted_date}"
      daily_ckb_transactions_count = transactions_in_current_period.recent.count
      return if daily_ckb_transactions_count.zero?

      daily_statistic = ::DailyStatistic.find_or_create_by!(created_at_unixtimestamp: to_be_counted_date.to_i)
      daily_statistic.from_scratch = from_scratch
      daily_statistic.reset!(updated_attrs)

      daily_statistic
    rescue Exception => e
      NewRelic::Agent.notice_error(e.message)
    end

    private

    attr_reader :datetime, :from_scratch

    def updated_attrs
      # next attrs were generated by before attrs, so they should have an order to reset
      established_order = %i{
        total_depositors_count daily_dao_depositors_count dao_depositors_count unclaimed_compensation claimed_compensation deposit_compensation total_dao_deposit circulating_supply circulation_ratio
      }
      others = %i{
        block_timestamp transactions_count addresses_count daily_dao_withdraw
        average_deposit_time mining_reward
        treasury_amount estimated_apc live_cells_count dead_cells_count avg_hash_rate
        avg_difficulty uncle_rate address_balance_distribution
        total_tx_fee occupied_capacity daily_dao_deposit total_supply block_time_distribution
        epoch_time_distribution epoch_length_distribution locked_capacity
      }

      established_order + others
    end

    def to_be_counted_date
      @to_be_counted_date ||= (datetime.presence || Time.current.yesterday).beginning_of_day
    end

    def started_at
      @started_at ||= CkbUtils.time_in_milliseconds(to_be_counted_date.beginning_of_day)
    end

    def ended_at
      @ended_at ||= CkbUtils.time_in_milliseconds(to_be_counted_date.end_of_day) - 1
    end

    def transactions_in_current_period
      @transactions_in_current_period ||= CkbTransaction.tx_committed.created_between(started_at, ended_at)
    end
  end
end
