class CreateTransactions < ActiveRecord::Migration[6.1]
  def change
    create_table :transactions do |t|
      t.string :name, null: false
      t.boolean :reviewed, null: false, default: false
      t.decimal :amount, precision: 22, scale: 3, null: false, default: 0.0
      t.date :date, null: false
      t.references :category, null: false, foreign_key: true
      t.references :merchant, null: false, foreign_key: true

      t.timestamps
    end
  end
end
