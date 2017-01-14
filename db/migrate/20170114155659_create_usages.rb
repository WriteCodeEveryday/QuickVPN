class CreateUsages < ActiveRecord::Migration[5.0]
  def change
    create_table :usages do |t|
      t.datetime :start_time
      t.datetime :stop_time
      t.integer :amount
      t.integer :account_id
      t.integer :credential_id

      t.timestamps
    end
  end
end
