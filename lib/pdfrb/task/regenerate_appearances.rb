# frozen_string_literal: true

module Pdfrb
  module Task
    # Walks every widget annotation in the document and regenerates
    # the /AP /N appearance stream via Appearance::Generator. Use
    # after mutating field values directly (e.g. via Form#set_value)
    # or to repair documents with /NeedAppearances set so viewers
    # don't have to synthesise appearances on the fly.
    #
    # Per ISO 32000-2 §12.5.5, an annotation's /AP /N is the normal
    # appearance; PDF/A requires it for every widget. This task
    # also clears /NeedAppearances on /AcroForm since by definition
    # all fields now have a computed appearance.
    module RegenerateAppearances
      module_function

      # @param document [Pdfrb::Document]
      # @param only: [Array<Symbol>, nil] limit to the given FT values
      #   (e.g. [:Tx, :Btn]). Default: all field types.
      # @return [Integer] count of appearances regenerated.
      def call(document, only: nil)
        generator = Pdfrb::Appearance::Generator.new(document)
        widgets = each_widget(document).to_a
        count = 0
        widgets.each do |widget|
          next unless matching?(widget, only)

          regenerated = regenerate(generator, widget)
          count += 1 if regenerated
        end
        clear_need_appearances(document)
        count
      end

      def each_widget(document)
        return enum_for(:each_widget, document) unless block_given?

        document.each_indirect_object do |obj|
          next unless obj.value.is_a?(::Hash)

          subtype = obj.value[:Subtype]
          yield obj if subtype == :Widget
        end
      end

      def matching?(widget, only)
        return true if only.nil?

        ft = widget.value[:FT]
        ft && only.include?(ft.to_sym)
      end

      def regenerate(generator, widget)
        ft = widget.value[:FT]&.to_sym
        value = widget.value[:V]
        case ft
        when :Tx
          generator.text_field(widget, value: value.to_s)
          true
        when :Btn
          if value.is_a?(::Hash)
            # Multi-state radio; regenerate each state's appearance.
            value.each_key do |state|
              generator.checkbox(widget, checked: state != :Off)
            end
          else
            generator.checkbox(widget, checked: [:Yes, true].include?(value))
          end
          true
        when :Ch
          generator.combo(widget, value: value.to_s)
          true
        else
          false
        end
      rescue StandardError
        # Appearance generation is best-effort; if a single field
        # raises, skip it rather than aborting the whole sweep.
        false
      end

      def clear_need_appearances(document)
        catalog = document.catalog
        return unless catalog

        acroform = catalog.value[:AcroForm]
        return unless acroform

        if acroform.is_a?(Pdfrb::Model::Cos::Dictionary)
          acroform.value.delete(:NeedAppearances)
        elsif acroform.is_a?(::Hash)
          acroform.delete(:NeedAppearances)
        end
      end
    end
  end
end
