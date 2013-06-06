class AddSourceToWords < ActiveRecord::Migration
  def change
  	add_column :words, :source, :integer
  end
end
