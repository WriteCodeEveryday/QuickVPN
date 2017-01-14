class CreateCredentials < ActiveRecord::Migration[5.0]
  def change
    create_table :credentials do |t|
      t.string :username
      t.string :password
      t.integer :account_id
      t.string :secret

      t.timestamps
    end
  end
end
