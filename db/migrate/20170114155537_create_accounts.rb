class CreateAccounts < ActiveRecord::Migration[5.0]
  def change
    create_table :accounts do |t|
      t.string :public_address
      t.integer :wallet_balance
      t.integer :spent_balance

      t.timestamps
    end
  end
end
