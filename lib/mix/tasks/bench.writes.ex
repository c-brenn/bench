defmodule Mix.Tasks.Bench.Writes do
  @moduledoc """
  Runs simple benchmarks for write operations on a single Set. It compares
  the performance of the stblib Set, Phoenix's Set CRDT and Vial's Set CRDT.

  ## Examples

    $ mix bench.writes
  """

  use Mix.Task

  alias Bench.{
    Datum,
    Generator,
    LogFile,
    Metrics,
    Timer
  }
  @operations 100000
  @min_ops     10000
  @step        10000

  def run(_opts) do
    max_ops = @operations
    start = @min_ops
    step = @step

    {:ok, log} = LogFile.new("writes")

    indices = 0..((max_ops - start) |> div(step))

    IO.puts(log, "[")

    indices
    |> Enum.map(fn index ->
      operations = start + (index * step)

      datum = Datum.new(operations)

      stdlib_time = time_writes(StdLib, operations)
      vial_time = time_writes(Vial, operations)
      phoenix_time = time_writes(Phoenix, operations)

      datum =
        datum
        |> Datum.record([:stdlib, :time], stdlib_time)
        |> Datum.record([:vial, :time], vial_time)
        |> Datum.record([:phoenix, :time], phoenix_time)

      stdlib_ops_per_sec = Metrics.ops_per_sec(operations, stdlib_time)
      stdlib_time_per_op_usec = Metrics.time_per_op_usec(stdlib_time, operations)

      datum =
        datum
        |> Datum.record([:stdlib, :ops_per_sec], stdlib_ops_per_sec)
        |> Datum.record([:stdlib, :time_per_op_usec], stdlib_time_per_op_usec)

      vial_ops_per_sec = Metrics.ops_per_sec(operations, vial_time)
      vial_time_per_op_usec = Metrics.time_per_op_usec(vial_time, operations)
      vial_latency_op_usec = Metrics.latency_per_op_usec(vial_time_per_op_usec, stdlib_time_per_op_usec)
      vial_latency_op_percent = Metrics.latency_per_op_percent(vial_latency_op_usec, stdlib_time_per_op_usec)

      datum =
        datum
        |> Datum.record([:vial, :ops_per_sec], vial_ops_per_sec)
        |> Datum.record([:vial, :time_per_op_usec], vial_time_per_op_usec)
        |> Datum.record([:vial, :latency_per_op_usec], vial_latency_op_usec)
        |> Datum.record([:vial, :latency_per_op_percent], vial_latency_op_percent)

      phoenix_ops_per_sec = Metrics.ops_per_sec(operations, phoenix_time)
      phoenix_time_per_op_usec = Metrics.time_per_op_usec(phoenix_time, operations)
      phoenix_latency_op_usec = Metrics.latency_per_op_usec(phoenix_time_per_op_usec, stdlib_time_per_op_usec)
      phoenix_latency_op_percent = Metrics.latency_per_op_percent(phoenix_latency_op_usec, stdlib_time_per_op_usec)

      datum =
        datum
        |> Datum.record([:phoenix, :ops_per_sec], phoenix_ops_per_sec)
        |> Datum.record([:phoenix, :time_per_op_usec], phoenix_time_per_op_usec)
        |> Datum.record([:phoenix, :latency_per_op_usec], phoenix_latency_op_usec)
        |> Datum.record([:phoenix, :latency_per_op_percent], phoenix_latency_op_percent)

      encoded = Poison.encode_to_iodata!(datum, pretty: true)
      IO.puts(log, [encoded, ","])
    end)

    IO.puts(log, "]")
    LogFile.close(log)
  end

  defp time_writes(module, operations) do
    set = Generator.new_set(module)
    function = Generator.write_function(module, operations, set)
    Timer.time(:write, module, operations, function)
  end
end
