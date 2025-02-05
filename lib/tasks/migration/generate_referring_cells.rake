namespace :migration do
  desc "Usage: RAILS_ENV=production bundle exec rake migration:generate_referring_cells"
  task generate_referring_cells: :environment do
    live_cells = CellOutput.live.left_joins(:referring_cell).where(referring_cells: { id: nil })
    progress_bar = ProgressBar.create({ total: live_cells.count, format: "%e %B %p%% %c/%C" })

    live_cells.find_in_batches do |outputs|
      outputs.each do |output|
        progress_bar.increment

        contracts = [output.lock_script.contract, output.type_script&.contract].compact

        next if contracts.empty?

        contracts.each do |contract|
          ReferringCell.create_or_find_by(
            cell_output_id: output.id,
            ckb_transaction_id: output.ckb_transaction_id,
            contract_id: contract.id
          )
        end
      end
    end

    puts "done"
  end

  desc "Usage: RAILS_ENV=production bundle exec rake migration:generate_missed_type_script_contract_referring_cells"
  task generate_missed_type_script_contract_referring_cells: :environment do
    contract_hashes = Contract.where(role: "type_script").pluck(:code_hash)
    binary_hashes = CkbUtils.hexes_to_bins(contract_hashes)
    contract_type_ids = TypeScript.where(code_hash: binary_hashes).pluck(:id)
    contract_type_ids.each do |type_id|
      puts "============#{type_id}"
      live_cells = CellOutput.live.where(type_script_id: type_id)

      live_cells.find_in_batches do |outputs|
        outputs.each do |output|
          contract = output.type_script&.contract

            ReferringCell.create_or_find_by(
              cell_output_id: output.id,
              ckb_transaction_id: output.ckb_transaction_id,
              contract_id: contract.id
            )
        end
      end
    end

    puts "done"
  end
end
