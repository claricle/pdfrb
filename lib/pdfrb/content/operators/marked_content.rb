# frozen_string_literal: true

module Pdfrb
  module Content
    module Operator
      # Marked-content operators (s14.6) — used for tagged PDF /
      # structure trees. The Processor maintains a marked-content
      # stack; EMC pops.

      class BeginMarkedContent < Base
        def self.name; "BMC"; end
        def self.invoke(processor, tag)
          processor.begin_marked_content(tag)
        end
        register
      end

      class BeginMarkedContentWithProperties < Base
        def self.name; "BDC"; end
        def self.invoke(processor, tag, properties)
          processor.begin_marked_content(tag, properties)
        end
        register
      end

      class EndMarkedContent < NoArg
        def self.name; "EMC"; end
        def self.invoke(processor, *)
          processor.end_marked_content
        end
        register
      end

      class MarkedContentPoint < Base
        def self.name; "MP"; end
        def self.invoke(processor, tag)
          processor.marked_content_point(tag)
        end
        register
      end

      class MarkedContentPointWithProperties < Base
        def self.name; "DP"; end
        def self.invoke(processor, tag, properties)
          processor.marked_content_point(tag, properties)
        end
        register
      end
    end
  end
end
