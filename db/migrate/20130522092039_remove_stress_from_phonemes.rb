class RemoveStressFromPhonemes < ActiveRecord::Migration
  def up
  	remove_column :phonemes, :stress
  end

  def down
  	add_column :phonemes, :stress, :integer
  end
end
