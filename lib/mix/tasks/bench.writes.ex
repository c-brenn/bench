defmodule Mix.Tasks.Bench.Writes do
  @moduledoc """
  Runs simple benchmarks for write operations on a single Set. It compares
  the performance of the stblib Set, Phoenix's Set CRDT and Vial's Set CRDT.

  ## Examples

    $ mix bench.writes
  """

  use Mix.Task
  alias Bench.Logger, as: Logger

  alias Bench.{
    Generator,
    Metrics,
    Timer
  }
  @operations 100000

  def run(_opts) do
    operations = @operations

    stdlib_time = time_writes(StdLib, operations)
    vial_time = time_writes(Vial, operations)
    phoenix_time = time_writes(Phoenix, operations)

    Logger.log_header("Overall time for #{operations} writes")
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

  defp time_writes(module, operations) do
    set = Generator.new_set(module)
    function = Generator.write_function(module, operations, set)
    Timer.time(:write, module, operations, function)
  end
end
