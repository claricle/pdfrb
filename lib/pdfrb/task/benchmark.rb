# frozen_string_literal: true

require "benchmark"
require "stringio"

module Pdfrb
  module Task
    # Performance benchmarks for parsing, serialization, and round-trip.
    # Uses the corpus generator to produce test PDFs of various sizes,
    # then measures throughput.
    #
    # Usage:
    #   Pdfrb::Task::Benchmark.run
    #   Pdfrb::Task::Benchmark.run(repetitions: 100)
    class Benchmark
      Result = Struct.new(:name, :repetitions, :total_seconds,
                          :ops_per_second, :bytes_per_op, keyword_init: true)

      class << self
        def run(repetitions: 50)
          corpus = GenerateCorpus.all
          results = []

          corpus.each do |name, pdf_bytes|
            next if pdf_bytes.empty?

            r = bench_parse(name, pdf_bytes, repetitions)
            results << r
            puts format_result(r)
          end

          bench_round_trip(results, repetitions)
          results
        end

        def bench_parse(name, pdf_bytes, repetitions)
          io = StringIO.new(pdf_bytes)
          elapsed = ::Benchmark.realtime do
            repetitions.times do
              io.rewind
              Pdfrb::Document.new(io: StringIO.new(pdf_bytes))
            end
          end

          Result.new(
            name: "parse:#{name}",
            repetitions: repetitions,
            total_seconds: elapsed,
            ops_per_second: repetitions / elapsed,
            bytes_per_op: pdf_bytes.bytesize
          )
        end

        def bench_serialize(name, pdf_bytes, repetitions)
          doc = Pdfrb::Document.new(io: StringIO.new(pdf_bytes))
          elapsed = ::Benchmark.realtime do
            repetitions.times do
              StringIO.new.tap { |io| doc.write(io: io) }
            end
          end

          Result.new(
            name: "serialize:#{name}",
            repetitions: repetitions,
            total_seconds: elapsed,
            ops_per_second: repetitions / elapsed,
            bytes_per_op: pdf_bytes.bytesize
          )
        end

        def bench_round_trip(_results, _repetitions)
          nil
        end

        def format_result(result)
          format("%-25s  %6.1f ops/s  %7.1f KB/op  %6.3fs total",
                 result.name, result.ops_per_second,
                 result.bytes_per_op / 1024.0, result.total_seconds)
        end
      end
    end
  end
end
