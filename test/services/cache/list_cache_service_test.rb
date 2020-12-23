require "test_helper"

module Cache
	class ListCacheServiceTest < ActiveSupport::TestCase
		setup do
			redis_cache_store = ActiveSupport::Cache.lookup_store(:redis_cache_store)
			Rails.stubs(:cache).returns(redis_cache_store)
			Rails.cache.extend(CacheRealizer)
		end

		test "fetch function should return the corresponding result when the key is exist" do
			block = create(:block, :with_block_hash)
			addr = create(:address)
			20.times.each do |i|
				create(:ckb_transaction, :with_single_output, block: block, contained_address_ids: [addr.id], block_timestamp: Time.current.to_i + i)
			end
			txs = addr.custom_ckb_transactions.select(:id, :tx_hash, :block_id, :block_number, :block_timestamp, :is_cellbase, :updated_at).recent
			tx_jsons = []
			score_member_pairs = txs.map do |tx|
				tx_jsons << tx.to_json
				[tx.id, tx.to_json]
			end
			$redis.zadd(addr.tx_list_cache_key, score_member_pairs)
			s = Cache::ListCacheService.new
			rs = s.fetch(addr.tx_list_cache_key, 1, 20, CkbTransaction)
			expected_rs = tx_jsons.map do |json|
				CkbTransaction.new.from_json(json)
			end
			assert_equal expected_rs, rs
		end

		test "fetch function should return the corresponding result when block is given" do
			block = create(:block, :with_block_hash)
			addr = create(:address)
			20.times.each do |i|
				create(:ckb_transaction, :with_single_output, block: block, contained_address_ids: [addr.id], block_timestamp: Time.current.to_i + i)
			end
			$redis.flushdb
			s = Cache::ListCacheService.new
			tx_jsons = []
			rs = s.fetch(addr.tx_list_cache_key, 1, 20, CkbTransaction) do
				txs = addr.custom_ckb_transactions.select(:id, :tx_hash, :block_id, :block_number, :block_timestamp, :is_cellbase, :updated_at).recent
				txs.map do |tx|
					tx_jsons << tx.to_json
					[tx.id, tx.to_json]
				end
				txs
			end
			expected_rs = tx_jsons.map do |json|
				CkbTransaction.new.from_json(json)
			end
			assert_equal expected_rs, rs
		end

		test "write function should add records to cache" do
			block = create(:block, :with_block_hash)
			addr = create(:address)
			20.times.each do |i|
				create(:ckb_transaction, :with_single_output, block: block, contained_address_ids: [addr.id], block_timestamp: Time.current.to_i + i)
			end
			txs = addr.custom_ckb_transactions.select(:id, :tx_hash, :block_id, :block_number, :block_timestamp, :is_cellbase, :updated_at).recent
			tx_jsons = []
			score_member_pairs = txs.map do |tx|
				tx_jsons << tx.to_json
				[tx.id, tx.to_json]
			end
			s = Cache::ListCacheService.new
			s.write(addr.tx_list_cache_key, score_member_pairs)
			rs = s.fetch(addr.tx_list_cache_key, 1, 20, CkbTransaction)
			expected_rs = tx_jsons.map do |json|
				CkbTransaction.new.from_json(json)
			end
			assert_equal expected_rs, rs
		end
	end
end
