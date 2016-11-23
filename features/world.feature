Feature: World

  Background:
    Given I have no driver IDs stored

  Scenario: Driver and configuration loading
    Given I navigate to the best website in the world

  Scenario: Driver re-use
    Given I navigate to the best website in the world
    When I navigate to the best website in the world again
    Then I expect the driver in each case to be the same

  Scenario: Multiple drivers
    Given I navigate to the best website in the world
    When I navigate to the best website in the world with another driver instance
    Then I expect to have two driver instances
