defmodule Mix.Tasks.Bench.Reads do
  @moduledoc """
  Runs simple benchmarks for read operations on a single Set. It compares
  the performance of the stblib Set, Phoenix's Set CRDT and Vial's Set CRDT.

  ## Examples

    $ mix bench.reads
  """

  use Mix.Task
  alias Bench.Logger, as: Logger

  alias Bench.{
    Generator,
    Metrics,
    Timer
  }

  @operations 10000
  @set_size   10000
  @block_size 1000

  def run(_opts) do
    operations = @operations

    stdlib_time = time_reads(StdLib, operations)
    vial_time = time_reads(Vial, operations)
    phoenix_time = time_reads(Phoenix, operations)

    Logger.log_header("Overall time for #{operations} reads")
    Logger.log_data([
      {StdLib, stdlib_time},
      {Vial, vial_time},
      {Phoenix, phoenix_time}
    ], "usec")


    stdlib_ops_per_sec = Metrics.ops_per_sec(operations, stdlib_time)
    stdlib_time_per_op_usec = Metrics.time_per_op_usec(stdlib_time, operations)

    vial_ops_per_sec = Metrics.ops_per_sec(operations, vial_time)
    vial_time_per_op_usec = Metrics.time_per_op_usec(vial_time, operations)
    vial_latency_op_usec = Metrics.latency_per_op_usec(vial_time_per_op_usec, stdlib_time_per_op_usec)
    vial_latency_op_percent = Metrics.latency_per_op_percent(vial_latency_op_usec, stdlib_time_per_op_usec)

    phoenix_ops_per_sec = Metrics.ops_per_sec(operations, phoenix_time)
    phoenix_time_per_op_usec = Metrics.time_per_op_usec(phoenix_time, operations)
    phoenix_latency_op_usec = Metrics.latency_per_op_usec(phoenix_time_per_op_usec, stdlib_time_per_op_usec)
    phoenix_latency_op_percent = Metrics.latency_per_op_percent(phoenix_latency_op_usec, stdlib_time_per_op_usec)

    Logger.log_header("Operations / second")
    Logger.log_data([
      {StdLib, stdlib_ops_per_sec},
      {Vial, vial_ops_per_sec},
      {Phoenix, phoenix_ops_per_sec}
    ], "ops/sec")

    Logger.log_header("Time / operation")
    Logger.log_data([
      {StdLib, stdlib_time_per_op_usec},
      {Vial, vial_time_per_op_usec},
      {Phoenix, phoenix_time_per_op_usec}
    ], "usec")

    Logger.log_header("Latency / operation")
    Logger.log_data([
      {Vial, vial_latency_op_usec},
      {Phoenix, phoenix_latency_op_usec}
    ], "usec")

    Logger.log_header("Latency / operation")
    Logger.log_data([
      {Vial, vial_latency_op_percent},
      {Phoenix, phoenix_latency_op_percent}
    ], "%")
  end

  defp time_reads(module, operations) do
    Logger.log_header("Creating #{@set_size} element set for: #{to_string(module)}")
    set = set_with_elements(module, @set_size)
    function = Generator.read_function(module, operations, @block_size, set)
    Timer.time(:read, module, operations, function)
  end

  def set_with_elements(module, elements) do
    empty_set = Generator.new_set(module)
    # create an N element set, with M values per key
    keys = div(elements, @block_size)

    Enum.reduce(1..@block_size, empty_set, fn (_, set) ->
      filler_function = Generator.write_function(module, keys, set)
      filler_function.()
    end)
  end
end
