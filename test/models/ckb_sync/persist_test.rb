require "test_helper"
require "minitest/autorun"

module CkbSync
  class PersistTest < ActiveSupport::TestCase
    setup do
      Faker::Number.unique.clear
      create_list(:sync_info, 15, name: "inauthentic_tip_block_number")
    end

    test ".call should invoke save_block method " do
      VCR.use_cassette("blocks/10") do
        CkbSync::Persist.expects(:save_block)
        CkbSync::Persist.call(DEFAULT_NODE_BLOCK_HASH, "inauthentic")
      end
    end

    test ".save_block should create one block" do
      assert_difference "Block.count", 1 do
        VCR.use_cassette("blocks/10") do
          SyncInfo.local_inauthentic_tip_block_number
          node_block = CkbSync::Api.instance.get_block(DEFAULT_NODE_BLOCK_HASH)
          set_default_lock_params(node_block: node_block)

          CkbSync::Persist.save_block(node_block, "inauthentic")
        end
      end
    end

    test ".save_block should generate miner's address when cellbase has witnesses" do
      CkbSync::Api.any_instance.stubs(:get_epoch_by_number).returns(
        CKB::Types::Epoch.new(
          epoch_reward: "250000000000",
          difficulty: "0x1000",
          length: "2000",
          number: "0",
          start_number: "0"
        )
      )
      assert_difference "Address.count", 2 do
        VCR.use_cassette("blocks/11") do
          SyncInfo.local_inauthentic_tip_block_number
          node_block = CkbSync::Api.instance.get_block("0xd895e3fd670fd499567ce219cf8a8e6da27a91e1679ed01088fdcd1b072d3c4c")
          set_default_lock_params(node_block: node_block)

          CkbSync::Persist.save_block(node_block, "inauthentic")
        end
      end
    end

    test ".save_block should generate miner's lock when cellbase has witnesses" do
      CkbSync::Api.any_instance.stubs(:get_epoch_by_number).returns(
        CKB::Types::Epoch.new(
          epoch_reward: "250000000000",
          difficulty: "0x1000",
          length: "2000",
          number: "0",
          start_number: "0"
        )
      )
      assert_difference "LockScript.count", 2 do
        VCR.use_cassette("blocks/11") do
          SyncInfo.local_inauthentic_tip_block_number
          node_block = CkbSync::Api.instance.get_block("0xd895e3fd670fd499567ce219cf8a8e6da27a91e1679ed01088fdcd1b072d3c4c")
          set_default_lock_params(node_block: node_block)

          CkbSync::Persist.save_block(node_block, "inauthentic")
        end
      end
    end

    test ".save_block should set cellbase's transaction_fee_status to calculated" do
      CkbSync::Api.any_instance.stubs(:get_epoch_by_number).returns(
        CKB::Types::Epoch.new(
          epoch_reward: "250000000000",
          difficulty: "0x1000",
          length: "2000",
          number: "0",
          start_number: "0"
        )
      )
      VCR.use_cassette("blocks/11") do
        SyncInfo.local_inauthentic_tip_block_number
        node_block = CkbSync::Api.instance.get_block("0xd895e3fd670fd499567ce219cf8a8e6da27a91e1679ed01088fdcd1b072d3c4c")
        set_default_lock_params(node_block: node_block)

        local_block = CkbSync::Persist.save_block(node_block, "inauthentic")
        assert_equal "calculated", local_block.cellbase.transaction_fee_status
      end
    end

    test "after .save_block generated block's ckb_transactions_count should equal to transactions count" do
      VCR.use_cassette("blocks/10") do
        SyncInfo.local_inauthentic_tip_block_number
        node_block = CkbSync::Api.instance.get_block(DEFAULT_NODE_BLOCK_HASH)
        set_default_lock_params(node_block: node_block)

        local_block = CkbSync::Persist.save_block(node_block, "inauthentic")

        assert_equal node_block.transactions.size, local_block.ckb_transactions_count
      end
    end

    test ".save_block should create uncle_blocks" do
      VCR.use_cassette("blocks/10") do
        SyncInfo.local_inauthentic_tip_block_number
        node_block = CkbSync::Api.instance.get_block(DEFAULT_NODE_BLOCK_HASH)
        set_default_lock_params(node_block: node_block)
        node_block_uncle_blocks = node_block.uncles

        assert_difference "UncleBlock.count", node_block_uncle_blocks.size do
          CkbSync::Persist.save_block(node_block, "inauthentic")
        end
      end
    end

    test ".save_block should create ckb_transactions" do
      VCR.use_cassette("blocks/10") do
        SyncInfo.local_inauthentic_tip_block_number
        node_block = CkbSync::Api.instance.get_block(DEFAULT_NODE_BLOCK_HASH)
        set_default_lock_params(node_block: node_block)
        node_block_transactions = node_block.transactions

        assert_difference "CkbTransaction.count", node_block_transactions.count do
          CkbSync::Persist.save_block(node_block, "inauthentic")
        end
      end
    end

    test ".save_block should create cell_inputs" do
      VCR.use_cassette("blocks/10") do
        SyncInfo.local_inauthentic_tip_block_number
        node_block = CkbSync::Api.instance.get_block(DEFAULT_NODE_BLOCK_HASH)
        set_default_lock_params(node_block: node_block)
        node_block_transactions = node_block.transactions
        node_cell_inputs_count = node_block_transactions.reduce(0) { |memo, commit_transaction| memo + commit_transaction.inputs.size }

        assert_difference "CellInput.count", node_cell_inputs_count do
          CkbSync::Persist.save_block(node_block, "inauthentic")
        end
      end
    end

    test ".save_block should create cell_outputs" do
      VCR.use_cassette("blocks/10") do
        SyncInfo.local_inauthentic_tip_block_number
        node_block = CkbSync::Api.instance.get_block(DEFAULT_NODE_BLOCK_HASH)
        set_default_lock_params(node_block: node_block)
        node_block_transactions = node_block.transactions
        node_cell_outputs_count = node_block_transactions.reduce(0) { |memo, commit_transaction| memo + commit_transaction.outputs.size }

        assert_difference "CellOutput.count", node_cell_outputs_count do
          CkbSync::Persist.save_block(node_block, "inauthentic")
        end
      end
    end

    test ".save_block should create addresses" do
      VCR.use_cassette("blocks/10") do
        SyncInfo.local_inauthentic_tip_block_number
        node_block = CkbSync::Api.instance.get_block(DEFAULT_NODE_BLOCK_HASH)
        set_default_lock_params(node_block: node_block)
        node_block_transactions = node_block.transactions
        node_cell_outputs = node_block_transactions.map { |commit_transaction| commit_transaction.outputs }.flatten
        node_lock_scripts = node_cell_outputs.map { |cell_output| cell_output.lock }.uniq

        cellbase = node_block.transactions.first
        miner_lock = CkbUtils.generate_lock_script_from_cellbase(cellbase)
        if miner_lock.in?(node_lock_scripts)
          expected_difference = node_cell_outputs.size
        else
          expected_difference = node_cell_outputs.size + 1
        end

        assert_difference "Address.count", expected_difference do
          CkbSync::Persist.save_block(node_block, "inauthentic")
        end
      end
    end

    test ".save_block should create lock_scripts" do
      VCR.use_cassette("blocks/10") do
        SyncInfo.local_inauthentic_tip_block_number
        node_block = CkbSync::Api.instance.get_block(DEFAULT_NODE_BLOCK_HASH)
        set_default_lock_params(node_block: node_block)
        node_block_transactions = node_block.transactions
        node_cell_outputs = node_block_transactions.map { |commit_transaction| commit_transaction.outputs }.flatten
        cellbase = node_block.transactions.first
        miner_lock = CkbUtils.generate_lock_script_from_cellbase(cellbase)
        cell_output_locks = node_cell_outputs.map(&:lock)
        if miner_lock.in?(cell_output_locks)
          expected_difference = node_cell_outputs.size
        else
          expected_difference = node_cell_outputs.size + 1
        end

        assert_difference "LockScript.count", expected_difference do
          CkbSync::Persist.save_block(node_block, "inauthentic")
        end
      end
    end

    test ".save_block should create type_scripts" do
      VCR.use_cassette("blocks/10") do
        SyncInfo.local_inauthentic_tip_block_number
        node_block = CkbSync::Api.instance.get_block(DEFAULT_NODE_BLOCK_HASH)
        set_default_lock_params(node_block: node_block)
        node_block_transactions = node_block.transactions
        node_cell_outputs = node_block_transactions.map { |commit_transaction| commit_transaction.outputs }.flatten
        node_cell_outputs_with_type_script = node_cell_outputs.select { |cell_output| cell_output.type.present? }

        assert_difference "TypeScript.count", node_cell_outputs_with_type_script.size do
          CkbSync::Persist.save_block(node_block, "inauthentic")
        end
      end
    end

    test ".save_block created block's attribute value should equal with the node block's attribute value" do
      VCR.use_cassette("blocks/10") do
        SyncInfo.local_inauthentic_tip_block_number
        node_block = CkbSync::Api.instance.get_block(DEFAULT_NODE_BLOCK_HASH)
        set_default_lock_params(node_block: node_block)

        local_block = CkbSync::Persist.save_block(node_block, "inauthentic")

        node_block = node_block.to_h.deep_stringify_keys
        formatted_node_block = format_node_block(node_block)
        formatted_node_block["witnesses_root"] = formatted_node_block.delete("witnesses_root")

        local_block_hash = local_block.attributes.select { |attribute| attribute.in?(%w(difficulty block_hash number parent_hash seal timestamp transactions_root proposals_hash uncles_count uncles_hash version witnesses_root proposals epoch dao)) }
        local_block_hash["hash"] = local_block_hash.delete("block_hash")
        local_block_hash["number"] = local_block_hash["number"].to_s
        local_block_hash["version"] = local_block_hash["version"].to_s
        local_block_hash["uncles_count"] = local_block_hash["uncles_count"].to_s
        local_block_hash["epoch"] = local_block_hash["epoch"].to_s
        local_block_hash["timestamp"] = local_block_hash["timestamp"].to_s

        assert_equal formatted_node_block.sort, local_block_hash.sort
      end
    end

    test ".save_block created block's proposals_count should equal with the node block's proposals size" do
      VCR.use_cassette("blocks/10") do
        SyncInfo.local_inauthentic_tip_block_number
        node_block = CkbSync::Api.instance.get_block(DEFAULT_NODE_BLOCK_HASH)
        set_default_lock_params(node_block: node_block)

        local_block = CkbSync::Persist.save_block(node_block, "inauthentic")

        assert_equal node_block.proposals.size, local_block.proposals_count
      end
    end

    test ".save_block created uncle_block's attribute value should equal with the node uncle_block's attribute value" do
      VCR.use_cassette("blocks/10") do
        SyncInfo.local_inauthentic_tip_block_number
        node_block = CkbSync::Api.instance.get_block(DEFAULT_NODE_BLOCK_HASH)
        set_default_lock_params(node_block: node_block)
        node_uncle_blocks = node_block.uncles.map { |uncle| uncle.to_h.deep_stringify_keys }
        formatted_node_uncle_blocks = node_uncle_blocks.map { |uncle_block| format_node_block(uncle_block).sort }

        local_block = CkbSync::Persist.save_block(node_block, "inauthentic")
        local_uncle_blocks =
          local_block.uncle_blocks.map do |uncle_block|
            uncle_block =
              uncle_block.attributes.select do |attribute|
                attribute.in?(%w(difficulty block_hash number parent_hash seal timestamp transactions_root proposals_hash uncles_count uncles_hash version witnesses_root proposals epoch dao))
              end
            uncle_block["hash"] = uncle_block.delete("block_hash")
            uncle_block["epoch"] = uncle_block["epoch"].to_s
            uncle_block["number"] = uncle_block["number"].to_s
            uncle_block["timestamp"] = uncle_block["timestamp"].to_s
            uncle_block["version"] = uncle_block["version"].to_s
            uncle_block["uncles_count"] = uncle_block["uncles_count"].to_s
            uncle_block.sort
          end

        assert_equal formatted_node_uncle_blocks.sort, local_uncle_blocks.sort
      end
    end

    test ".save_block created unlce_block's proposals_count should equal with the node uncle_block's proposals size" do
      VCR.use_cassette("blocks/10") do
        SyncInfo.local_inauthentic_tip_block_number
        node_block = CkbSync::Api.instance.get_block(DEFAULT_NODE_BLOCK_HASH)
        set_default_lock_params(node_block: node_block)
        node_uncle_blocks = node_block.uncles
        node_uncle_blocks_count = node_uncle_blocks.reduce(0) { |memo, uncle_block| memo + uncle_block.proposals.size }

        local_block = CkbSync::Persist.save_block(node_block, "inauthentic")
        local_uncle_blocks = local_block.uncle_blocks
        local_uncle_blocks_count = local_uncle_blocks.reduce(0) { |memo, uncle_block| memo + uncle_block.proposals_count }

        assert_equal node_uncle_blocks_count, local_uncle_blocks_count
      end
    end

    test ".save_block created ckb_transaction's attribute value should equal with the node commit_transaction's attribute value" do
      VCR.use_cassette("blocks/10") do
        SyncInfo.local_inauthentic_tip_block_number
        node_block = CkbSync::Api.instance.get_block(DEFAULT_NODE_BLOCK_HASH)
        set_default_lock_params(node_block: node_block)
        node_block_transactions = node_block.transactions
        formatted_node_block_transactions = node_block_transactions.map { |commit_transaction| format_node_block_commit_transaction(commit_transaction).sort }

        local_block = CkbSync::Persist.save_block(node_block, "inauthentic")
        local_ckb_transactions =
          local_block.ckb_transactions.map do |ckb_transaction|
            ckb_transaction = ckb_transaction.attributes.select { |attribute| attribute.in?(%w(tx_hash deps version witnesses)) }
            ckb_transaction["hash"] = ckb_transaction.delete("tx_hash")
            ckb_transaction["version"] = ckb_transaction["version"].to_s
            ckb_transaction.sort
          end

        assert_equal formatted_node_block_transactions, local_ckb_transactions
      end
    end

    test ".save_block created cell_inputs's attribute value should equal with the node cell_inputs's attribute value" do
      VCR.use_cassette("blocks/10") do
        SyncInfo.local_inauthentic_tip_block_number
        node_block = CkbSync::Api.instance.get_block(DEFAULT_NODE_BLOCK_HASH)
        set_default_lock_params(node_block: node_block)
        node_transactions = node_block.transactions.map(&:to_h).map(&:deep_stringify_keys)
        node_block_cell_inputs = node_transactions.map { |commit_transaction| commit_transaction["inputs"].map(&:sort) }.flatten

        local_block = CkbSync::Persist.save_block(node_block, "inauthentic")
        local_block_transactions = local_block.ckb_transactions
        local_block_cell_inputs = local_block_transactions.map { |commit_transaction| commit_transaction.cell_inputs.map { |cell_input| cell_input.attributes.select { |attribute| attribute.in?(%(previous_output since)) }.sort } }.flatten

        assert_equal node_block_cell_inputs, local_block_cell_inputs
      end
    end

    test ".save_block created cell_outputs's attribute value should equal with the node cell_outputs's attribute value" do
      VCR.use_cassette("blocks/10") do
        SyncInfo.local_inauthentic_tip_block_number
        node_block = CkbSync::Api.instance.get_block(DEFAULT_NODE_BLOCK_HASH)
        set_default_lock_params(node_block: node_block)
        node_block_transactions = node_block.transactions
        node_block_cell_outputs = node_block_transactions.map { |commit_transaction| commit_transaction.to_h.deep_stringify_keys["outputs"].map { |output| format_node_block_cell_output(output).sort } }.flatten

        local_block = CkbSync::Persist.save_block(node_block, "inauthentic")
        local_block_transactions = local_block.ckb_transactions
        local_block_cell_outputs = local_block_transactions.map { |commit_transaction|
          commit_transaction.cell_outputs.map do |cell_output|
            attributes = cell_output.attributes
            attributes["capacity"] = attributes["capacity"].to_i.to_s
            attributes.select { |attribute| attribute.in?(%w(capacity data)) }.sort
          end
        }.flatten

        assert_equal node_block_cell_outputs, local_block_cell_outputs
      end
    end

    test ".save_block created lock_script's attribute value should equal with the node lock_script's attribute value" do
      VCR.use_cassette("blocks/10") do
        SyncInfo.local_inauthentic_tip_block_number
        node_block = CkbSync::Api.instance.get_block(DEFAULT_NODE_BLOCK_HASH)
        set_default_lock_params(node_block: node_block)
        node_block_transactions = node_block.transactions
        node_block_lock_scripts = node_block_transactions.map { |commit_transaction| commit_transaction.to_h.deep_stringify_keys["outputs"].map { |output| output["lock"] }.sort }.flatten

        local_block = CkbSync::Persist.save_block(node_block, "inauthentic")
        local_block_transactions = local_block.ckb_transactions
        local_block_lock_scripts = local_block_transactions.map { |commit_transaction| commit_transaction.cell_outputs.map { |cell_output| cell_output.lock_script.attributes.select { |attribute| attribute.in?(%w(args code_hash hash_type)) } }.sort }.flatten

        assert_equal node_block_lock_scripts, local_block_lock_scripts
      end
    end

    test ".save_block created type_script's attribute value should equal with the node type_script's attribute value" do
      VCR.use_cassette("blocks/10") do
        SyncInfo.local_inauthentic_tip_block_number
        node_block = CkbSync::Api.instance.get_block(DEFAULT_NODE_BLOCK_HASH)
        set_default_lock_params(node_block: node_block)
        fake_node_block_with_type_script(node_block)
        node_block_transactions = node_block.transactions
        node_block_type_scripts = node_block_transactions.map { |commit_transaction| commit_transaction.to_h.deep_stringify_keys["outputs"].map { |output| output["type"] }.sort }.flatten

        local_block = CkbSync::Persist.save_block(node_block, "inauthentic")
        local_block_transactions = local_block.ckb_transactions
        local_block_type_scripts = local_block_transactions.map { |commit_transaction| commit_transaction.cell_outputs.map { |cell_output| cell_output.type_script.attributes.select { |attribute| attribute.in?(%w(args code_hash hash_type)) } }.sort }.flatten

        assert_equal node_block_type_scripts, local_block_type_scripts
      end
    end

    test ".save_block generated transactions should be nil" do
      VCR.use_cassette("blocks/10") do
        SyncInfo.local_inauthentic_tip_block_number
        node_block = CkbSync::Api.instance.get_block(DEFAULT_NODE_BLOCK_HASH)
        set_default_lock_params(node_block: node_block)

        local_block = CkbSync::Persist.save_block(node_block, "inauthentic")
        local_ckb_transactions = local_block.ckb_transactions
        local_block_cell_inputs = local_ckb_transactions.map(&:display_inputs).flatten
        cellbase = Cellbase.new(local_block)
        expected_display_inputs = [{ id: nil, from_cellbase: true, capacity: nil, address_hash: nil, target_block_number: cellbase.target_block_number }]

        assert_equal expected_display_inputs, local_block_cell_inputs
      end
    end

    test ".save_block generated transactions should has correct display output" do
      VCR.use_cassette("blocks/10") do
        SyncInfo.local_inauthentic_tip_block_number
        node_block = CkbSync::Api.instance.get_block(DEFAULT_NODE_BLOCK_HASH)
        set_default_lock_params(node_block: node_block)

        local_block = CkbSync::Persist.save_block(node_block, "inauthentic")

        local_ckb_transactions = local_block.ckb_transactions
        local_block_cell_outputs = local_ckb_transactions.map(&:display_outputs).flatten
        output = local_ckb_transactions.first.outputs.order(:id).first
        cellbase = Cellbase.new(local_block)
        expected_display_outputs = [{ id: output.id, capacity: output.capacity, address_hash: output.address_hash, target_block_number: cellbase.target_block_number, block_reward: cellbase.block_reward, commit_reward: cellbase.commit_reward, proposal_reward: cellbase.proposal_reward }]

        assert_equal expected_display_outputs, local_block_cell_outputs
      end
    end

    test ".save_block generated block should has correct total transaction fee" do
      VCR.use_cassette("blocks/10") do
        SyncInfo.local_inauthentic_tip_block_number
        node_block = CkbSync::Api.instance.get_block(DEFAULT_NODE_BLOCK_HASH)
        set_default_lock_params(node_block: node_block)

        local_block = CkbSync::Persist.save_block(node_block, "inauthentic")

        assert_equal local_block.ckb_transactions.sum(:transaction_fee), local_block.total_transaction_fee
      end
    end

    test ".save_block generated block should has correct total capacity" do
      VCR.use_cassette("blocks/10") do
        SyncInfo.local_inauthentic_tip_block_number
        node_block = CkbSync::Api.instance.get_block(DEFAULT_NODE_BLOCK_HASH)
        set_default_lock_params(node_block: node_block)

        local_block = CkbSync::Persist.save_block(node_block, "inauthentic")

        assert_equal CkbUtils.total_cell_capacity(node_block.transactions), local_block.total_cell_capacity
      end
    end

    test ".save_block generated block should has correct miner hash when miner use default lock script " do
      VCR.use_cassette("blocks/10") do
        SyncInfo.local_inauthentic_tip_block_number
        node_block = CkbSync::Api.instance.get_block(DEFAULT_NODE_BLOCK_HASH)
        set_default_lock_params(node_block: node_block, code_hash: ENV["CODE_HASH"])

        local_block = CkbSync::Persist.save_block(node_block, "inauthentic")

        assert_equal CkbUtils.miner_hash(node_block.transactions.first), local_block.miner_hash
      end
    end

    test ".save_block generated block should has correct miner lock hash when miner use default lock script " do
      VCR.use_cassette("blocks/10") do
        SyncInfo.local_inauthentic_tip_block_number
        node_block = CkbSync::Api.instance.get_block(DEFAULT_NODE_BLOCK_HASH)
        set_default_lock_params(node_block: node_block, code_hash: ENV["CODE_HASH"])

        local_block = CkbSync::Persist.save_block(node_block, "inauthentic")

        assert_equal CkbUtils.miner_lock_hash(node_block.transactions.first), local_block.miner_lock_hash
      end
    end

    test ".save_block generated block should has correct reward" do
      CkbSync::Api.any_instance.stubs(:get_epoch_by_number).returns(
        CKB::Types::Epoch.new(
          epoch_reward: "250000000000",
          difficulty: "0x1000",
          length: "2000",
          number: "0",
          start_number: "0"
        )
      )
      VCR.use_cassette("blocks/10") do
        SyncInfo.local_inauthentic_tip_block_number
        node_block = CkbSync::Api.instance.get_block(DEFAULT_NODE_BLOCK_HASH)
        set_default_lock_params(node_block: node_block)

        local_block = CkbSync::Persist.save_block(node_block, "inauthentic")

        assert_equal CkbUtils.base_reward(node_block.header.number, node_block.header.epoch).to_i, local_block.reward
      end
    end

    test ".save_block generated block should has correct cell consumed" do
      VCR.use_cassette("blocks/10") do
        SyncInfo.local_inauthentic_tip_block_number
        node_block = CkbSync::Api.instance.get_block(DEFAULT_NODE_BLOCK_HASH)
        set_default_lock_params(node_block: node_block)

        local_block = CkbSync::Persist.save_block(node_block, "inauthentic")

        assert_equal CkbUtils.block_cell_consumed(node_block.transactions), local_block.cell_consumed
      end
    end

    test "should generate the correct number of ckb transactions" do
      SyncInfo.local_inauthentic_tip_block_number
      node_block = fake_node_block
      VCR.use_cassette("blocks/10") do
        assert_difference "CkbTransaction.count", 2 do
          CkbSync::Persist.save_block(node_block, "inauthentic")
        end
      end
    end

    test ".save_block generated transactions's display inputs should be nil when previous_transaction_hash is not exist" do
      SyncInfo.local_inauthentic_tip_block_number
      node_block = fake_node_block
      VCR.use_cassette("blocks/10") do
        local_block = CkbSync::Persist.save_block(node_block, "inauthentic")
        local_ckb_transactions = local_block.ckb_transactions
        local_block_cell_inputs = local_ckb_transactions.map(&:display_inputs).flatten

        assert local_block_cell_inputs.any?(&:nil?)
        assert_equal 0, local_ckb_transactions.map(&:transaction_fee).reduce(&:+)
      end
    end

    test ".save_block generated transactions's display inputs status should be ungenerated when previous_transaction_hash is not exist" do
      SyncInfo.local_inauthentic_tip_block_number
      node_block = fake_node_block
      VCR.use_cassette("blocks/10") do
        local_block = CkbSync::Persist.save_block(node_block, "inauthentic")
        local_ckb_transactions = local_block.ckb_transactions

        assert_equal "ungenerated", local_ckb_transactions.map(&:display_inputs_status).uniq.first
      end
    end

    test ".save_block generated transactions's transaction fee status should be uncalculated when previous_transaction_hash is not exist" do
      SyncInfo.local_inauthentic_tip_block_number
      node_block = fake_node_block
      VCR.use_cassette("blocks/10") do
        local_block = CkbSync::Persist.save_block(node_block, "inauthentic")
        local_ckb_transactions = local_block.ckb_transactions

        assert_equal "uncalculated", local_ckb_transactions.where(is_cellbase: false).pluck(:transaction_fee_status).uniq.first
      end
    end

    test ".save_block should update current block's miner address pending reward blocks count" do
      prepare_inauthentic_node_data(11)
      SyncInfo.local_inauthentic_tip_block_number
      node_block = fake_node_block("0x4f1d958f0601d04d1bd88634fac4bcd65ffc8a42e8b0c50d065e70ba5e922840", 12)
      VCR.use_cassette("blocks/12") do
        cellbase = node_block.transactions.first
        lock_script = CkbUtils.generate_lock_script_from_cellbase(cellbase)
        miner_address = Address.find_or_create_address(lock_script)

        assert_difference -> { miner_address.reload.pending_reward_blocks_count }, 1 do
          CkbSync::Persist.save_block(node_block, "inauthentic")
        end
      end
    end

    test "cellbase's display inputs should contain target block number" do
      prepare_inauthentic_node_data(11)
      CkbSync::Api.any_instance.stubs(:get_epoch_by_number).returns(
        CKB::Types::Epoch.new(
          epoch_reward: "250000000000",
          difficulty: "0x1000",
          length: "2000",
          number: "0",
          start_number: "0"
        )
      )
      VCR.use_cassette("blocks/12") do
        assert_difference "Block.count", 1 do
          CkbSync::Persist.call("0x4f1d958f0601d04d1bd88634fac4bcd65ffc8a42e8b0c50d065e70ba5e922840", "inauthentic")
          block = Block.last
          cellbase = Cellbase.new(block)
          expected_cellbase_display_inputs = [{ id: nil, from_cellbase: true, capacity: nil, address_hash: nil, target_block_number: cellbase.target_block_number }]

          assert_equal expected_cellbase_display_inputs, block.cellbase.display_inputs
        end
      end
    end

    test "genesis block's cellbase display outputs should have multiple cells" do
      CkbSync::Api.any_instance.stubs(:get_epoch_by_number).returns(
        CKB::Types::Epoch.new(
          epoch_reward: "250000000000",
          difficulty: "0x1000",
          length: "2000",
          number: "0",
          start_number: "0"
        )
      )
      VCR.use_cassette("genesis_block") do
        create(:sync_info, name: "inauthentic_tip_block_number", value: 0)
        CkbSync::Persist.sync(0)
        block = Block.last
        cellbase = Cellbase.new(block)
        expected_cellbase_display_outputs = block.cellbase.cell_outputs.map { |cell_output| { id: cell_output.id, capacity: cell_output.capacity, address_hash: cell_output.address_hash, target_block_number: cellbase.target_block_number, block_reward: cellbase.block_reward, commit_reward: cellbase.commit_reward, proposal_reward: cellbase.proposal_reward } }

        assert_equal expected_cellbase_display_outputs, block.cellbase.display_outputs
      end
    end

    test "cellbase's display outputs should contain block reward commit reward and proposal reward" do
      prepare_inauthentic_node_data(11)
      CkbSync::Api.any_instance.stubs(:get_epoch_by_number).returns(
        CKB::Types::Epoch.new(
          epoch_reward: "250000000000",
          difficulty: "0x1000",
          length: "2000",
          number: "0",
          start_number: "0"
        )
      )
      VCR.use_cassette("blocks/12") do
        assert_difference "Block.count", 1 do
          CkbSync::Persist.call("0x4f1d958f0601d04d1bd88634fac4bcd65ffc8a42e8b0c50d065e70ba5e922840", "inauthentic")
          block = Block.last
          cellbase = Cellbase.new(block)
          cell_output = block.cellbase.cell_outputs.first
          expected_cellbase_display_outputs = [{ id: cell_output.id, capacity: cell_output.capacity, address_hash: cell_output.address_hash, target_block_number: cellbase.target_block_number, block_reward: cellbase.block_reward, commit_reward: cellbase.commit_reward, proposal_reward: cellbase.proposal_reward }]

          assert_equal expected_cellbase_display_outputs, block.cellbase.display_outputs
        end
      end
    end

    test ".calculate_tx_fee should update transaction fee status" do
      SyncInfo.local_inauthentic_tip_block_number
      node_block = fake_node_block

      VCR.use_cassette("blocks/10") do
        CkbSync::Persist.expects(:calculate_tx_fee)
        CkbSync::Persist.save_block(node_block, "inauthentic")
      end
    end

    test ".calculate_tx_fee should not update transaction fee if previous cell output is not synced" do
      SyncInfo.local_inauthentic_tip_block_number
      node_block = fake_node_block("0x3307186493c5da8b91917924253a5ffd35231151649d0c7e2941aa8801815063")
      VCR.use_cassette("blocks/10") do
        local_block = CkbSync::Persist.save_block(node_block, "inauthentic")

        create(:ckb_transaction, :with_cell_output_and_lock_script, tx_hash: "0x598315db9c7ba144cca74d2e9122ac9b3a3da1641b2975ae321d91ec34f1c0e3", block: local_block)

        local_ckb_transaction = local_block.ckb_transactions.first
        CkbSync::Persist.update_tx_fee_related_data(local_block)

        assert_no_difference -> { local_ckb_transaction.reload.transaction_fee } do
          CkbSync::Persist.calculate_tx_fee(local_block)
        end
      end
    end

    test ".calculate_tx_fee should update transaction fee" do
      SyncInfo.local_inauthentic_tip_block_number
      node_block = fake_node_block("0x3307186493c5da8b91917924253a5ffd35231151649d0c7e2941aa8801815063")
      VCR.use_cassette("blocks/10") do
        local_block = CkbSync::Persist.save_block(node_block, "inauthentic")
        block = create(:block, :with_block_hash)
        ckb_transaction1 = create(:ckb_transaction, tx_hash: "0x498315db9c7ba144cca74d2e9122ac9b3a3da1641b2975ae321d91ec34f1c0e3", block: block)
        ckb_transaction2 = create(:ckb_transaction, tx_hash: "0x598315db9c7ba144cca74d2e9122ac9b3a3da1641b2975ae321d91ec34f1c0e3", block: block)
        create(:cell_output, ckb_transaction: ckb_transaction1, cell_index: 1, tx_hash: "0x498315db9c7ba144cca74d2e9122ac9b3a3da1641b2975ae321d91ec34f1c0e3", generated_by: ckb_transaction2, block: block)
        create(:cell_output, ckb_transaction: ckb_transaction2, cell_index: 0, tx_hash: "0x598315db9c7ba144cca74d2e9122ac9b3a3da1641b2975ae321d91ec34f1c0e3", generated_by: ckb_transaction1, block: block)
        CkbSync::Persist.update_tx_fee_related_data(local_block)
        CkbSync::Persist.calculate_tx_fee(local_block)

        assert_equal 10**8 * 3, local_block.reload.total_transaction_fee
      end
    end

    test ".update_block_reward_info should change block reward status from pending to issued before proposal window" do
      prepare_inauthentic_node_data(12)
      CkbSync::Api.any_instance.stubs(:get_epoch_by_number).returns(
        CKB::Types::Epoch.new(
          epoch_reward: "250000000000",
          difficulty: "0x1000",
          length: "2000",
          number: "0",
          start_number: "0"
        )
      )
      target_block = Block.find_by(number: 1)
      current_block = Block.find_by(number: 12)
      assert_changes -> { target_block.reload.reward_status }, from: "pending", to: "issued" do
        CkbSync::Persist.update_block_reward_info(current_block)
      end
    end

    test ".update_block_reward_info should change block received tx fee status from calculating to calculated before proposal window" do
      prepare_inauthentic_node_data(12)
      CkbSync::Api.any_instance.stubs(:get_epoch_by_number).returns(
        CKB::Types::Epoch.new(
          epoch_reward: "250000000000",
          difficulty: "0x1000",
          length: "2000",
          number: "0",
          start_number: "0"
        )
      )
      target_block = Block.find_by(number: 1)
      current_block = Block.find_by(number: 12)
      assert_changes -> { target_block.reload.received_tx_fee_status }, from: "calculating", to: "calculated" do
        CkbSync::Persist.update_block_reward_info(current_block)
      end
    end

    test ".update_block_reward_info should update block received tx fee before proposal window" do
      prepare_inauthentic_node_data(12)
      CkbSync::Api.any_instance.stubs(:get_epoch_by_number).returns(
        CKB::Types::Epoch.new(
          epoch_reward: "250000000000",
          difficulty: "0x1000",
          length: "2000",
          number: "0",
          start_number: "0"
        )
      )
      target_block = Block.find_by(number: 1)
      current_block = Block.find_by(number: 12)

      expected_received_tx_fee = current_block.cellbase.cell_outputs.first.capacity - target_block.reward - target_block.total_transaction_fee * 0.6 + target_block.total_transaction_fee * 0.4
      assert_changes -> { target_block.reload.received_tx_fee }, from: 0, to: expected_received_tx_fee do
        CkbSync::Persist.update_block_reward_info(current_block)
      end
    end

    test ".update_block_reward_info should update miner's address pending reward blocks count before the proposal window" do
      prepare_inauthentic_node_data(12)
      target_block = Block.find_by(number: 1)
      current_block = Block.find_by(number: 12)
      miner_address = target_block.miner_address
      VCR.use_cassette("blocks/12") do
        assert_difference -> { miner_address.reload.pending_reward_blocks_count }, -1 do
          CkbSync::Persist.update_block_reward_info(current_block)
        end
      end
    end
  end
end
