
module CKB
  module Utils
    # script 结构更新之后使用新版方法
    def self.calculate_cell_min_capacity(output)
      capacity = 8 + output["data"].bytesize + CKB::Utils.hex_to_bin(output["lock"]).bytesize
      if type = output["type"]
        capacity += 1
        capacity += (type["args"] || []).map { |arg| arg.bytesize }.reduce(0, &:+)
        if type["reference"]
          capacity += CKB::Utils.hex_to_bin(type["reference"]).bytesize
        end
        if type["binary"]
          capacity += type["binary"].bytesize
        end
        capacity += (type["signed_args"] || []).map { |arg| arg.bytesize }.reduce(0, &:+)
      end
      capacity
    end

    def self.block_cell_consumed(commit_transactions)
      commit_transactions.inject(0) do |memo, commit_transaction|
        memo + commit_transaction["outputs"].reduce(0) { |inside_memo, output| inside_memo + CKB::Utils.calculate_cell_min_capacity(output) }
      end
    end

    def self.total_cell_capacity(commit_transactions)
      commit_transactions.inject(0) do |memo, commit_transaction|
        memo + commit_transaction["outputs"].reduce(0) { |inside_memo, output| inside_memo + output["capacity"] }
      end
    end

    def self.miner_hash(cellbase)
      cellbase["outputs"].first["lock"] #TODO script 结构更新之后更改计算方式
    end

    def self.miner_reward(cellbase)
      cellbase["outputs"].first["capacity"]
    end

    def self.transaction_fee(transaction)
      output_capacity = transaction["outputs"].map { |output| output["capacity"] }.reduce(0, &:+)
      input_capacity = transaction["inputs"].map { |input| CKB::Utils.cell_input_capacity(input) }.reduce(0, &:+)
      output_capacity - input_capacity
    end

    def self.total_transaction_fee(transactions)
      transactions.inject(0) { |memo, transaction| memo + CKB::Utils.transaction_fee(transaction) }
    end

    def self.get_unspent_cells(lock_hash)
      to = CkbSync::Api.get_tip_block_number
      results = []
      current_from = 1
      while current_from <= to
        current_to = [current_from + 100, to].min
        cells = CkbSync::Api.get_cells_by_lock_hash(lock_hash, current_from, current_to)
        results.concat(cells)
        current_from = current_to + 1
      end
      results
    end

    #TODO 可以改成通过本地的 cell 来计算。
    def self.get_balance(lock_hash)
      CKB::Utils.get_unspent_cells(lock_hash).map { |cell| cell[:capacity].reduce(0, &:+) }
    end

    #TODO 可以改成通过本地的 cell 来计算。
    def self.account_cell_consumed(lock_hash)
      outputs = CKB::Utils.get_unspent_cells(lock_hash).map do |cell|
        out_point = cell[:out_point]
        previous_transaction_hash = out_point[:hash]
        previous_output_index = out_point[:index]
        if CellOutput::BASE_HASH != previous_transaction_hash
          previous_transacton = CkbTransaction.find_by(tx_hash: previous_transaction_hash)
          previous_output = previous_transacton.cell_outputs.order(:id)[previous_output_index]
          previous_output
        end
      end

      outputs.compact.reduce(0) { |memo, output| memo + CKB::Utils.calculate_cell_min_capacity(output) }
    end

    def self.cell_input_capacity(cell_input)
      outpoint = cell_input["previous_output"]
      previous_transaction_hash = outpoint["hash"]
      previous_output_index = outpoint["index"]
      if CellOutput::BASE_HASH == previous_transaction_hash
        0
      else
        previous_transacton = CkbTransaction.find_by(tx_hash: previous_transaction_hash)
        previous_output = previous_transacton.cell_outputs.order(:id)[previous_output_index]
        previous_output.capacity
      end
    end
  end
end
