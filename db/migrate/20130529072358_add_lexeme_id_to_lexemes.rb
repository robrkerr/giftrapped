class AddLexemeIdToLexemes < ActiveRecord::Migration
  def change
  	add_column :lexemes, :lexeme_id, :integer
  	add_index :lexemes, :lexeme_id
  end
end
