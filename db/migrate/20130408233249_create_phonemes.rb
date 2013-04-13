class CreatePhonemes < ActiveRecord::Migration
  def change
    create_table :phonemes do |t|
      t.string :name
      t.integer :stress
      t.string :ptype

      t.timestamps
    end
  end
end
