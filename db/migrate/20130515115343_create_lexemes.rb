class CreateLexemes < ActiveRecord::Migration
  def change
    create_table :lexemes do |t|
      t.string :word
      t.string :word_class
      t.text :gloss

      t.timestamps
    end
  end
end
