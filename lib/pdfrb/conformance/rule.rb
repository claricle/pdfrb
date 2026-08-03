# frozen_string_literal: true

module Pdfrb
  module Conformance
    # A single validation check. Each rule is self-contained: given a
    # document, it returns zero or more Violations. Rules are
    # registered into a RuleSet; adding a new check = defining a new
    # Rule + registering it (no switch to edit — OCP).
    Rule = Struct.new(:id, :description, :severity, :spec_clause, :check, keyword_init: true) do
      def evaluate(document)
        result = check.call(document)
        return [] unless result

        result.is_a?(::Array) ? result : [result]
      end
    end

    # A rule violation found during validation.
    Violation = Struct.new(:rule_id, :message, :object, :severity, :spec_clause,
                           keyword_init: true) do
      def error? = severity == :error
      def warning? = severity == :warning
    end

    # Aggregated validation output. Knows whether the document
    # passes (no errors) and can filter by severity.
    ValidationResult = Struct.new(:profile, :violations, keyword_init: true) do
      def passed? = errors.empty?

      def errors = violations.select(&:error?)

      def warnings = violations.select(&:warning?)

      def infos = violations.reject { |v| v.error? || v.warning? }

      def violation_count = violations.length
    end

    # A named collection of rules. Rules are added via #register
    # and evaluated via #validate. Open for extension (new rules =
    # register, no code edits), closed for modification.
    class RuleSet
      attr_reader :name, :rules

      def initialize(name)
        @name = name
        @rules = []
      end

      def register(rule)
        @rules << rule
        self
      end

      def validate(document)
        violations = @rules.flat_map do |rule|
          rule.evaluate(document).map do |v|
            ensure_violation(v, rule)
          end
        end
        ValidationResult.new(profile: @name, violations: violations)
      end

      private

      def ensure_violation(value, rule)
        return value if value.is_a?(Violation)

        Violation.new(
          rule_id: rule.id,
          message: value.to_s,
          severity: rule.severity,
          spec_clause: rule.spec_clause
        )
      end
    end
  end
end
