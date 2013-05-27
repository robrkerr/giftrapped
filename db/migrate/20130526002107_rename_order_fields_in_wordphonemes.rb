class RenameOrderFieldsInWordphonemes < ActiveRecord::Migration
  def up
  	rename_column :word_phonemes, :order, :position
  	rename_column :word_phonemes, :r_order, :r_position
  end

  def down
  	rename_column :word_phonemes, :position, :order
  	rename_column :word_phonemes, :r_position, :r_order
  end
end
