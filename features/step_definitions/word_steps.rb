require "#{Rails.root}/db/seed_helper.rb"

Given(/^there is a word "([^"]*)"$/) do |name|
  @word = FactoryGirl.create(:word, name: name)
end

Given(/^that word has phonemes:$/) do |table|
  n = table.hashes.length
  table.hashes.each_with_index do |attributes,i|
    phoneme = Phoneme.find(:all, :conditions => attributes).first
    @word.word_phonemes.create!({:phoneme_id => phoneme.id, :order => n-1-i})
  end
end

When(/^there are (\d+) other words$/) do |number|
  number.to_i.times { FactoryGirl.create!(:word) }
end

Then(/^I should not see all words$/) do
  should_not satisfy { |page| Word.all.map { |word| page.has_content?(word.name) }.all? }
end

Then(/^I should see some words$/) do
  should satisfy { |page| Word.all.map { |word| page.has_content?(word.name) }.any? }
end

When(/^I type in "([^"]*)"$/) do |input|
  steps(%Q{When I fill in "name" with "#{input}"})
end

When(/^I search for "([^"]*)"$/) do |input|
  steps(%Q{
    When I fill in "name" with "#{input}"
    And I press "Rap"
    })
end

When(/^I load more words$/) do
  seed_words("#{Rails.root}/data/cmudict.0.7a.partial",false)
end

Then(/^I should see "([^"]*)" as a result$/) do |word|
  steps(%Q{
    And there should be an object "#wr_#{word}_"
    And I should see "#{word}" within "#wr_#{word}_"
  })
end

Then(/^I should not see "([^"]*)" as a result$/) do |word|
  steps(%Q{
    And there should not be an object "#wr_#{word}_"
  })
end
