class RemoveWordFieldFromLexemes < ActiveRecord::Migration
  def up
  	remove_column :lexemes, :word
  end

  def down
  	add_column :lexemes, :word, :string
  end
end
