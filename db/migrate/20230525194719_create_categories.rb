class CreateCategories < ActiveRecord::Migration[6.1]
  def change
    create_table :categories do |t|
      t.string :name
      t.string :emoji
      t.string :color
      t.decimal :budget

      t.timestamps
    end
  end
end
