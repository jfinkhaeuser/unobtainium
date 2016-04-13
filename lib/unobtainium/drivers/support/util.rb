# coding: utf-8
#
# unobtainium
# https://github.com/jfinkhaeuser/unobtainium
#
# Copyright (c) 2016 Jens Finkhaeuser and other unobtainium contributors.
# All rights reserved.
#
module Unobtainium
  module Drivers
    ##
    # Utility code shared by driver implementations
    module Utility
      ##
      # For a recognized label alias, returns a normalized label. Requires
      # the enclosing class to provide a LABELS connstant that is a hash
      # where keys are the normalized label, and the value is an array of
      # aliases:
      #
      #   LABELS = {
      #     foo: [:alias1, :alias2],
      #     bar: [],
      #   }.freeze
      #
      # Empty aliases means that there are no aliases for this label.
      def normalize_label(label)
        self::LABELS.each do |normalized, aliases|
          if label == normalized or aliases.include?(label)
            return normalized
          end
        end
        return nil
      end
    end # module Utility
  end # module Drivers
end # module Unobtainium
