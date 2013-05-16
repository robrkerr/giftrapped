Feature: Viewing more words
  In order to view more words
  As a user
  I want them to seed properly and to see them on the page
  
  Background: We have more words
    Given I load more words
    And I am on the homepage

  Scenario: More words
    When I search for "pie"
    Then I should see "potpie" within "#wr_0_"
    And I should see "eye" within "#wr_1_"

  Scenario: Using filters
    When I type in "taboo"
    And I select "l" from "query[first_phoneme]"
    And I press "Rap"
    Then I should see "loo" within "#wr_0_"
    And I should not see "canoe" within "#word_table"
    When I select "" from "query[first_phoneme]"
    And I select "2" from "query[num_syllables]"
    And I press "Rap"
    Then I should see "canoe" within "#wr_0_"
    And I should not see "loo" within "#word_table"

  Scenario: Searching for a word with multiple pronunciations
    When I search for "buffet"
    Then I should see "Please select a pronouncation."
    And I should see that field "query[text]" does contain "buffet"
    And I should see "buffet" within "#wr_0_"
    And I should see "b" within "#wr_0_ td.phonemes"
    And I should see "ah1" within "#wr_0_ td.phonemes"
    And I should see "f" within "#wr_0_ td.phonemes"
    And I should see "ah0" within "#wr_0_ td.phonemes"
    And I should see "t" within "#wr_0_ td.phonemes"
    And I should see "buffet" within "#wr_1_"
    And I should see "b" within "#wr_1_ td.phonemes"
    And I should see "ah0" within "#wr_1_ td.phonemes"
    And I should see "f" within "#wr_1_ td.phonemes"
    And I should see "ey1" within "#wr_1_ td.phonemes"
    When I follow "buffet" within "#wr_0_"
    Then I should see "buffet" within "#title_table td.title_word h2"
    And I should see "buffet" within "#wr_heading_row"
    And I should see "b" within "#wr_heading_row td.phonemes"
    And I should see "ah1" within "#wr_heading_row td.phonemes"
    And I should see "f" within "#wr_heading_row td.phonemes"
    And I should see "ah0" within "#wr_heading_row td.phonemes"
    And I should see "t" within "#wr_heading_row td.phonemes"
