# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Shared behaviour for name-keyed maps (Resources
      # sub-dictionaries, role/class maps, VRI entries): lookup
      # accepts Symbol or String, +add+ normalises the key to a
      # Symbol, +names+ lists the keys.
      module NameMap
        def [](name)
          key = name.to_sym
          value.key?(key) ? value[key] : value[name.to_s]
        end

        def add(name, entry)
          value[name.to_sym] = entry
          name.to_sym
        end

        def names
          value.keys
        end

        def each_entry(&)
          return enum_for(:each_entry) unless block_given?

          value.each(&)
        end
      end
    end
  end
end
