Feature: Viewing some words
  In order to view some words
  As a user
  I want to see them on the page
  
  Background: We have some words
    Given there is a word "dog"
    And that word has phonemes:
      | name    | stress  |
      | d       | 0       |
      | ao      | 1       |
      | g       | 0       |
    And there is a word "cat"
    And that word has phonemes:
      | name    | stress  |
      | k       | 0       |
      | ae      | 1       |
      | t       | 0       |
    And there is a word "hat"
    And that word has phonemes:
      | name    | stress  |
      | hh      | 0       |
      | ae      | 1       |
      | t       | 0       |
    And there is a word "apple"
    And that word has phonemes:
      | name    | stress  |
      | ae      | 1       |
      | p       | 0       |
      | ah      | 0       |
      | l       | 0       |
    And I am on the homepage

  Scenario: Entering a word
    When I type in "hat"
    And I press "Rap"
    Then I should see "hat" within "#title_table td.title_word h2"
    And I should see that field "query[text]" does contain "hat"
    And I should see "hat" within "#wr_heading_row"
    And I should see "hh" within "#wr_heading_row td.phonemes"
    And I should see "ae1" within "#wr_heading_row td.phonemes"
    And I should see "t" within "#wr_heading_row td.phonemes"
    And I should see "cat" within "#word_table"
    And I should see "cat" within "#wr_0_"
    And I should see "k" within "#wr_0_ td.phonemes"
    And I should see "ae1" within "#wr_0_ td.phonemes"
    And I should see "t" within "#wr_0_ td.phonemes"
    And I should not see "dog" within "#word_table"

  Scenario: Clicking on word
    When I search for "hat"
    And I follow "cat" within "#word_table"
    Then I should see "cat" within "#title_table td.title_word h2"
    And I should not see "hat" within "#title_table td.title_word h2"
    
  Scenario: Entering a invalid word
    When I search for "gggggg"
    Then I should see "The word you entered doesn't match any we know of."
    And I should see that field "query[text]" does not contain "gggggg"

