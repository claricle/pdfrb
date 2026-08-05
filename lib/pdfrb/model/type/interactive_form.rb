# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # AcroForm interactive form root (s12.7.2). Catalog /AcroForm.
      class InteractiveForm < Pdfrb::Model::Cos::Dictionary
        arlington_object "InteractiveForm"
        register_type :AcroForm

        def fields; self[:Fields]; end
        def need_appearances; self[:NeedAppearances]; end
        def sig_flags; self[:SigFlags]; end
        def co; self[:CO]; end
        def dr; self[:DR]; end
        def da; self[:DA]; end
        def q; self[:Q]; end

        def need_appearances?
          !!need_appearances
        end

        def field_count
          return 0 unless fields
          arr = fields.is_a?(Pdfrb::Model::PdfArray) ? fields.to_a : fields
          arr.is_a?(Array) ? arr.size : 0
        end

        def append_only_signatures?
          sig_flags && (sig_flags & 1) != 0
        end

        def contains_signature_dr_usage?
          sig_flags && (sig_flags & 2) != 0
        end

        def text_alignment
          case q
          when 0 then :left
          when 1 then :center
          when 2 then :right
          else nil
          end
        end
      end
    end
  end
end
