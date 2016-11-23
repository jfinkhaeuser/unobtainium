# coding: utf-8
#
# unobtainium
# https://github.com/jfinkhaeuser/unobtainium
#
# Copyright (c) 2016 Jens Finkhaeuser and other unobtainium contributors.
# All rights reserved.
#

def store_ids
  @driver_ids ||= []
  @driver_ids << driver.object_id

  @driver_impl_ids ||= []
  @driver_impl_ids << driver.impl.object_id
end

Given(/^I navigate to the best website in the world$/) do
  driver.navigate.to "http://finkhaeuser.de"
  store_ids
end

When(/^I navigate to the best website in the world again$/) do
  driver.navigate.to "http://finkhaeuser.de"
  store_ids
end

Then(/^I expect the driver in each case to be the same$/) do
  if not @driver_ids[0] == @driver_ids[1]
    raise "Driver instance changed!"
  end
  if not @driver_impl_ids[0] == @driver_impl_ids[1]
    raise "Driver implementation instance changed!"
  end
end
