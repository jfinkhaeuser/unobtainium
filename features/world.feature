Feature: World

  Scenario: Driver and configuration loading
    Given I navigate to the best website in the world

  Scenario: Driver re-use
    Given I navigate to the best website in the world
    When I navigate to the best website in the world again
    Then I expect the driver in each case to be the same
