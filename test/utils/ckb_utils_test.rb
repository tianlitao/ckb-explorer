require "test_helper"

class CkbUtilsTest < ActiveSupport::TestCase
  setup do
    CkbSync::Api.any_instance.stubs(:get_epoch_by_number).returns(
      CKB::Types::Epoch.new(
        compact_target: "0x1000",
        length: "0x3e8",
        number: "0x0",
        start_number: "0x0"
      )
    )
  end

  test ".generate_address should return mainnet address when mode is mainnet" do
    ENV["CKB_NET_MODE"] = "mainnet"
    lock_script = CKB::Types::Script.generate_lock(
      "0x36c329ed630d6ce750712a477543672adab57f4c",
      ENV["CODE_HASH"],
      "data"
    )

    assert CkbUtils.generate_address(lock_script).start_with?("ckb")
    ENV["CKB_NET_MODE"] = "testnet"
  end

  test ".parse_address raise error when address is mainnet address and mode is testnet" do
    assert_raises CKB::AddressParser::InvalidPrefixError do
      CkbUtils.parse_address("haha1qygndsefa43s6m882pcj53m4gdnj4k440axqsm2hnz")
    end
  end

  test ".parse_address should not raise error when address is mainnet address and mode is mainnet" do
    ENV["CKB_NET_MODE"] = "mainnet"
    assert_nothing_raised  do
      CkbUtils.parse_address("ckb1qyqpr9t74uzvr6wrlenw44lfjzcne8ksl64s279w4l")
    end

    ENV["CKB_NET_MODE"] = "testnet"
  end

  test ".generate_address should return full payload address when use correct sig code match" do
    short_payload_blake160_address = "ckt1q2tnhkeh8ja36aftftqqdc4mt0wtvdp3a54kuw2tyfepezgx52khydkr98kkxrtvuag8z2j8w4pkw2k6k4l5cwfw473"
    lock_script = CKB::Types::Script.generate_lock(
      "0x36c329ed630d6ce750712a477543672adab57f4c",
      ENV["CODE_HASH"],
      "data"
    )

    assert_equal short_payload_blake160_address, CkbUtils.generate_address(lock_script)
  end

  test ".generate_address should return short payload blake160 address when use correct sig type match" do
    short_payload_blake160_address = "ckt1qyqrdsefa43s6m882pcj53m4gdnj4k440axqswmu83"
    lock_script = CKB::Types::Script.generate_lock(
      "0x36c329ed630d6ce750712a477543672adab57f4c",
      ENV["SECP_CELL_TYPE_HASH"]
    )

    assert_equal short_payload_blake160_address, CkbUtils.generate_address(lock_script)
  end

  test ".generate_address should return full payload address when use correct multisig code match" do
    short_payload_blake160_address = "ckt1qtqlkzhxj9wn6nk76dyc4m04ltwa330khkyjrc8ch74at67t7fvmcdkr98kkxrtvuag8z2j8w4pkw2k6k4l5ce7s8yp"
    lock_script = CKB::Types::Script.generate_lock(
      "0x36c329ed630d6ce750712a477543672adab57f4c",
      ENV["SECP_MULTISIG_CELL_CODE_HASH"],
      "data"
    )

    assert_equal short_payload_blake160_address, CkbUtils.generate_address(lock_script)
  end

  test ".generate_address should return short payload multisig address when use correct multisig type match" do
    short_payload_blake160_address = "ckt1qyqndsefa43s6m882pcj53m4gdnj4k440axqyz2gg9"
    lock_script = CKB::Types::Script.generate_lock(
      "0x36c329ed630d6ce750712a477543672adab57f4c",
      ENV["SECP_MULTISIG_CELL_TYPE_HASH"]
    )

    assert_equal short_payload_blake160_address, CkbUtils.generate_address(lock_script)
  end

  test ".generate_address should return full payload data address when do not use default lock script and hash type is data" do
    full_payload_address = "ckt1qgvf96jqmq4483ncl7yrzfzshwchu9jd0glq4yy5r2jcsw04d7xlydkr98kkxrtvuag8z2j8w4pkw2k6k4l5csspk07"
    lock_script = CKB::Types::Script.generate_lock(
      "0x36c329ed630d6ce750712a477543672adab57f4c",
      "0x1892ea40d82b53c678ff88312450bbb17e164d7a3e0a90941aa58839f56f8df2",
      "data"
    )

    assert_equal full_payload_address, CkbUtils.generate_address(lock_script)
  end

  test ".generate_address should return full payload data address when do not use default lock script and hash type is type" do
    full_payload_address = "ckt1qjn9dutjk669cfznq7httfar0gtk7qp0du3wjfvzck9l0w3k9eqhvdkr98kkxrtvuag8z2j8w4pkw2k6k4l5ca2tat0"
    lock_script = CKB::Types::Script.generate_lock(
      "0x36c329ed630d6ce750712a477543672adab57f4c",
      "0xa656f172b6b45c245307aeb5a7a37a176f002f6f22e92582c58bf7ba362e4176",
    )

    assert_equal full_payload_address, CkbUtils.generate_address(lock_script)
  end

  test ".generate_address should return nil when do not use default lock script and args is empty" do
    full_payload_address = "ckt1qjn9dutjk669cfznq7httfar0gtk7qp0du3wjfvzck9l0w3k9eqhv77zeg7"
    lock_script = CKB::Types::Script.generate_lock(
      "0x",
      "0xa656f172b6b45c245307aeb5a7a37a176f002f6f22e92582c58bf7ba362e4176",
      )

    assert_equal full_payload_address, CkbUtils.generate_address(lock_script)
  end

  test ".parse_address should return block160 when target is short payload blake160 address" do
    blake160 = "0x36c329ed630d6ce750712a477543672adab57f4c"
    short_payload_blake160_address = "ckt1qyqrdsefa43s6m882pcj53m4gdnj4k440axqswmu83"

    assert_equal blake160, CkbUtils.parse_address(short_payload_blake160_address).script.args
  end

  test ".parse_address should return an hash that contains format type, code hash and args when target is full payload address" do
    full_payload_address = "ckt1q2n9dutjk669cfznq7httfar0gtk7qp0du3wjfvzck9l0w3k9eqhv9pkcv576ccddnn4quf2ga65xee2m26h7nq2rtnac"
    parsed_result = CkbUtils.parse_address(full_payload_address)

    assert_equal "0xa656f172b6b45c245307aeb5a7a37a176f002f6f22e92582c58bf7ba362e4176", parsed_result.script.code_hash
    assert_equal "0x1436c329ed630d6ce750712a477543672adab57f4c", parsed_result.script.args
    assert_equal "data", parsed_result.script.hash_type
    assert_equal "FULL", parsed_result.address_type
  end

  test ".base_reward should return 0 for genesis block" do
    VCR.use_cassette("genesis_block", record: :new_episodes) do
      node_block = CkbSync::Api.instance.get_block_by_number(0)

      local_block = CkbSync::NodeDataProcessor.new.process_block(node_block)

      assert_equal 0, local_block.reward
    end
  end

  test ".calculate_cell_min_capacity should return output's min capacity" do
    VCR.use_cassette("blocks/#{DEFAULT_NODE_BLOCK_NUMBER}") do
      node_block = CkbSync::Api.instance.get_block_by_number(DEFAULT_NODE_BLOCK_NUMBER)

      node_data_processor.process_block(node_block)
      output = node_block.transactions.first.outputs.first
      output_data = node_block.transactions.first.outputs_data.first

      expected_cell_min_capacity = output.calculate_min_capacity(output_data)

      assert_equal expected_cell_min_capacity, CkbUtils.calculate_cell_min_capacity(output, output_data)
    end
  end

  test ".block_cell_consumed generated block's cell_consumed should equal to the sum of transactions output occupied capacity" do
    VCR.use_cassette("blocks/#{DEFAULT_NODE_BLOCK_NUMBER}") do
      node_block = CkbSync::Api.instance.get_block_by_number(DEFAULT_NODE_BLOCK_NUMBER)

      node_data_processor.process_block(node_block)
      outputs_data = node_block.transactions.flat_map(&:outputs_data).flatten
      expected_total_cell_consumed =
        node_block.transactions.flat_map(&:outputs).flatten.each_with_index.reduce(0) do |memo, (output, index)|
          memo + output.calculate_min_capacity(outputs_data[index])
        end

      assert_equal expected_total_cell_consumed, CkbUtils.block_cell_consumed(node_block.transactions)
    end
  end

  test ".address_cell_consumed should return right cell consumed by the address" do
    prepare_node_data(12)
    VCR.use_cassette("blocks/12") do
      node_block = CkbSync::Api.instance.get_block_by_number(13)
      cellbase = node_block.transactions.first
      lock_script = CkbUtils.generate_lock_script_from_cellbase(cellbase)
      miner_address = Address.find_or_create_address(lock_script)
      unspent_cells = miner_address.cell_outputs.live
      expected_address_cell_consumed = unspent_cells.reduce(0) { |memo, cell| memo + cell.node_output.calculate_min_capacity(cell.data) }

      assert_equal expected_address_cell_consumed, CkbUtils.address_cell_consumed(miner_address.address_hash)
    end
  end

  test ".ckb_transaction_fee should return right tx_fee when tx is not dao withdraw tx" do
    node_block = fake_node_block("0x3307186493c5da8b91917924253a5ffd35231151649d0c7e2941aa8801815063")
    VCR.use_cassette("blocks/#{DEFAULT_NODE_BLOCK_NUMBER}") do
      block = create(:block, :with_block_hash)
      ckb_transaction1 = create(:ckb_transaction, tx_hash: "0x498315db9c7ba144cca74d2e9122ac9b3a3da1641b2975ae321d91ec34f1c0e3", block: block)
      ckb_transaction2 = create(:ckb_transaction, tx_hash: "0x598315db9c7ba144cca74d2e9122ac9b3a3da1641b2975ae321d91ec34f1c0e3", block: block)
      create(:cell_output, ckb_transaction: ckb_transaction1, cell_index: 1, tx_hash: "0x498315db9c7ba144cca74d2e9122ac9b3a3da1641b2975ae321d91ec34f1c0e3", generated_by: ckb_transaction2, block: block)
      create(:cell_output, ckb_transaction: ckb_transaction2, cell_index: 2, tx_hash: "0x598315db9c7ba144cca74d2e9122ac9b3a3da1641b2975ae321d91ec34f1c0e3", generated_by: ckb_transaction1, block: block)
      node_data_processor.process_block(node_block)
      node_tx = node_block.transactions.last
      ckb_transaction = CkbTransaction.find_by(tx_hash: node_tx.hash)
      input_capacities = { ckb_transaction.id => [800000000] }
      output_capacities = { ckb_transaction.id => [500000000] }

      assert_equal 10**8 * 3, CkbUtils.ckb_transaction_fee(ckb_transaction, input_capacities[ckb_transaction.id].sum, output_capacities[ckb_transaction.id].sum)
    end
  end

  test ".ckb_transaction_fee should return right tx_fee when tx is dao withdraw tx" do
    CkbSync::Api.any_instance.stubs(:calculate_dao_maximum_withdraw).returns("0x177825f000")
    node_block = fake_node_block("0x3307186493c5da8b91917924253a5ffd35231151649d0c7e2941aa8801815063")
    VCR.use_cassette("blocks/#{DEFAULT_NODE_BLOCK_NUMBER}") do
      block = create(:block, :with_block_hash)
      ckb_transaction1 = create(:ckb_transaction, tx_hash: "0x498315db9c7ba144cca74d2e9122ac9b3a3da1641b2975ae321d91ec34f1c0e3", block: block)
      ckb_transaction2 = create(:ckb_transaction, tx_hash: "0x598315db9c7ba144cca74d2e9122ac9b3a3da1641b2975ae321d91ec34f1c0e3", block: block)
      create(:cell_output, ckb_transaction: ckb_transaction1, cell_index: 1, tx_hash: "0x498315db9c7ba144cca74d2e9122ac9b3a3da1641b2975ae321d91ec34f1c0e3", generated_by: ckb_transaction2, block: block, cell_type: "nervos_dao_withdrawing")
      create(:cell_output, ckb_transaction: ckb_transaction2, cell_index: 1, tx_hash: "0x398315db9c7ba144cca74d2e9122ac9b3a3da1641b2975ae321d91ec34f1c0e2", generated_by: ckb_transaction1, block: block, consumed_by: ckb_transaction2, cell_type: "nervos_dao_deposit", capacity: 10**8 * 1000, data: CKB::Utils.bin_to_hex("\x00" * 8))
      create(:cell_output, ckb_transaction: ckb_transaction2, cell_index: 2, tx_hash: "0x598315db9c7ba144cca74d2e9122ac9b3a3da1641b2975ae321d91ec34f1c0e3", generated_by: ckb_transaction1, block: block)
      tx = node_block.transactions.last
      tx.header_deps = ["0x0b3e980e4e5e59b7d478287e21cd89ffdc3ff5916ee26cf2aa87910c6a504d61"]
      tx.witnesses = %w(0x8ae8061ec879d66c0f3996ab60d7c2a21094b8739817beddaea1e28d3620a70a21497a692581ca352631a67f3f6659a7c47d9a0c6c2def79d3e39440918a66fef00 0x4e52933358ae2f26863b8c1c71bf20f17489328820f8f2cd84a070069f10ceef784bc3693c3c51b93475a7b5dbf652ba6532d0580ecc1faf909f9fd53c5f6405000000000000000000)

      node_data_processor.process_block(node_block)

      node_tx = node_block.transactions.last
      ckb_transaction = CkbTransaction.find_by(tx_hash: node_tx.hash)
      input_capacities = { ckb_transaction.id => [800000000] }
      output_capacities = { ckb_transaction.id => [500000000] }

      assert_equal 10**8 * 3 + 10**8 * 8, CkbUtils.ckb_transaction_fee(ckb_transaction, input_capacities[ckb_transaction.id].sum, output_capacities[ckb_transaction.id].sum)
    end
  end

  test ".ckb_transaction_fee should return right tx_fee when tx is dao withdraw tx and have multiple dao cell" do
    CkbSync::Api.any_instance.stubs(:calculate_dao_maximum_withdraw).returns("0x177825f000")
    node_block = fake_node_block("0x3307186493c5da8b91917924253a5ffd35231151649d0c7e2941aa8801815063")
    VCR.use_cassette("blocks/#{DEFAULT_NODE_BLOCK_NUMBER}") do
      block = create(:block, :with_block_hash)
      ckb_transaction1 = create(:ckb_transaction, tx_hash: "0x498315db9c7ba144cca74d2e9122ac9b3a3da1641b2975ae321d91ec34f1c0e3", block: block)
      ckb_transaction2 = create(:ckb_transaction, tx_hash: "0x598315db9c7ba144cca74d2e9122ac9b3a3da1641b2975ae321d91ec34f1c0e3", block: block)
      create(:cell_output, ckb_transaction: ckb_transaction1, cell_index: 0, tx_hash: "0x498315db9c7ba144cca74d2e9122ac9b3a3da1641b2975ae321d91ec34f1c0e3", generated_by: ckb_transaction1, block: block)
      create(:cell_output, ckb_transaction: ckb_transaction1, cell_index: 1, tx_hash: "0x498315db9c7ba144cca74d2e9122ac9b3a3da1641b2975ae321d91ec34f1c0e3", generated_by: ckb_transaction2, block: block, cell_type: "nervos_dao_withdrawing")
      create(:cell_output, ckb_transaction: ckb_transaction2, cell_index: 1, tx_hash: "0x398315db9c7ba144cca74d2e9122ac9b3a3da1641b2975ae321d91ec34f1c0e2", generated_by: ckb_transaction1, block: block, consumed_by: ckb_transaction2, cell_type: "nervos_dao_deposit", capacity: 10**8 * 1000, data: CKB::Utils.bin_to_hex("\x00" * 8))
      create(:cell_output, ckb_transaction: ckb_transaction2, cell_index: 2, tx_hash: "0x598315db9c7ba144cca74d2e9122ac9b3a3da1641b2975ae321d91ec34f1c0e3", generated_by: ckb_transaction1, block: block)
      tx = node_block.transactions.last
      input = CKB::Types::Input.new(previous_output: CKB::Types::OutPoint.new(tx_hash: "0x498315db9c7ba144cca74d2e9122ac9b3a3da1641b2975ae321d91ec34f1c0e3", index: "0x0"))
      tx.inputs.unshift(input)
      tx.header_deps = ["0x0b3e980e4e5e59b7d478287e21cd89ffdc3ff5916ee26cf2aa87910c6a504d61"]
      tx.witnesses = %w(0x8ae8061ec879d66c0f3996ab60d7c2a21094b8739817beddaea1e28d3620a70a21497a692581ca352631a67f3f6659a7c47d9a0c6c2def79d3e39440918a66fef00 0x4e52933358ae2f26863b8c1c71bf20f17489328820f8f2cd84a070069f10ceef784bc3693c3c51b93475a7b5dbf652ba6532d0580ecc1faf909f9fd53c5f6405000000000000000000)

      node_data_processor.process_block(node_block)

      node_tx = node_block.transactions.last
      ckb_transaction = CkbTransaction.find_by(tx_hash: node_tx.hash)
      input_capacities = { ckb_transaction.id => [800000000] }
      output_capacities = { ckb_transaction.id => [500000000] }
      expected_tx_fee = 10**8 * 16 + 10**8 * 8 - 10**8 * 5

      assert_equal expected_tx_fee, CkbUtils.ckb_transaction_fee(ckb_transaction, input_capacities, output_capacities)
    end
  end

  test ".parse_epoch_info should return epoch 0 info if epoch is equal to 0" do
    header = OpenStruct.new(epoch: 0, number: 0)

    assert_equal CkbUtils.get_epoch_info(0), CkbUtils.parse_epoch_info(header)
  end

  test ".parse_epoch_info should return correct epoch info" do
    VCR.use_cassette("blocks/#{DEFAULT_NODE_BLOCK_NUMBER}") do
      node_block = CkbSync::Api.instance.get_block_by_number(DEFAULT_NODE_BLOCK_NUMBER)
      header = node_block.header
      epoch_info = CkbUtils.parse_epoch_info(header)
      expected_epoch_info = CkbUtils.get_epoch_info(epoch_info.number)

      assert_equal expected_epoch_info.number, epoch_info.number
      assert_equal expected_epoch_info.start_number, epoch_info.start_number
      assert_equal expected_epoch_info.length, epoch_info.length
    end
  end

  private

  def node_data_processor
    CkbSync::NodeDataProcessor.new
  end
end
