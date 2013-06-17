Feature: Rhyming more words
  In order to find more words that rhyme
  As a user
  I want them to seed the word database properly and to view results on the page
  
  Background: We have more words
    Given I load more words
    And I am on the homepage

  Scenario: Ignoring identity rhymes
    When I search for "pie"
    Then I should see "pie" within "#title_banner div.title_word h2"
    And I should see that field "query_text" does contain "pie"
    And I should not see "potpie" within "#wr_0_"
    And I should see "eye" within "#wr_0_"
    # When I search for "eye"
    When I follow "eye" within "div.result_simple"  
    Then I should see "eye" within "#title_banner div.title_word h2"
    And I should see that field "query_text" does contain "eye"
    And I should see "pie" within "#wr_0_"
    And I should see "potpie" within "#wr_1_"
    # When I search for "potpie"
    When I follow "potpie" within "#wr_1_"  
    Then I should not see "pie" within "#wr_0_"
    And I should see "eye" within "#wr_0_"

  Scenario: Using filters
    When I type in "taboo"
    And I select "l" from "query[first_phoneme]"
    And I press "Rap"
    Then I should see "loo" within "#wr_0_"
    And I should not see "canoe" within "div.result_simple"
    When I select "" from "query[first_phoneme]"
    And I select "2" from "query[num_syllables]"
    And I press "Rap"
    Then I should see "canoe" within "#wr_0_"
    And I should not see "loo" within "div.result_simple"

  # Scenario: Searching for a word with multiple pronunciations
    # When I search for "buffet"
    # Then I should see "Please select a pronouncation."
    # And I should see that field "query[text]" does contain "buffet"
    # And I should see "buffet" within "#wr_0_"
    # And I should see "b" within "#wr_0_ div.phonemes"
    # And I should see "ah1" within "#wr_0_ div.phonemes"
    # And I should see "f" within "#wr_0_ div.phonemes"
    # And I should see "ah0" within "#wr_0_ div.phonemes"
    # And I should see "t" within "#wr_0_ div.phonemes"
    # And I should see "buffet" within "#wr_1_"
    # And I should see "b" within "#wr_1_ div.phonemes"
    # And I should see "ah0" within "#wr_1_ div.phonemes"
    # And I should see "f" within "#wr_1_ div.phonemes"
    # And I should see "ey1" within "#wr_1_ div.phonemes"
    # When I follow "buffet" within "#wr_0_"
    # Then I should see "buffet" within "#title_table div.title_word h2"
    # And I should see "buffet" within "#wr_heading_row"
    # And I should see "b" within "#wr_heading_row div.phonemes"
    # And I should see "ah1" within "#wr_heading_row div.phonemes"
    # And I should see "f" within "#wr_heading_row div.phonemes"
    # And I should see "ah0" within "#wr_heading_row div.phonemes"
    # And I should see "t" within "#wr_heading_row div.phonemes"
