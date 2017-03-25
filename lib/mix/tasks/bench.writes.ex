defmodule Mix.Tasks.Bench.Writes do
  @moduledoc """
  Runs simple benchmarks for write operations on a single Set. It compares
  the performance of the stblib Set, Phoenix's Set CRDT and Vial's Set CRDT.

  ## Examples

    $ mix bench.writes
  """

  use Mix.Task
  alias MapSet, as: Set

  @operations 100000

  def run(_opts) do
    operations = @operations

    stdlib_time = time_writes(StdLib, operations)
    vial_time = time_writes(Vial, operations)
    phoenix_time = time_writes(Phoenix, operations)

    log_header("Overall time for #{operations} writes")
    log_data([
      {StdLib, stdlib_time},
      {Vial, vial_time},
      {Phoenix, phoenix_time}
    ], "usec")


    stdlib_ops_sec = ops_sec(operations, stdlib_time)
    stdlib_usecs_op = usecs_op(stdlib_time, operations)

    vial_ops_sec = ops_sec(operations, vial_time)
    vial_usecs_op = usecs_op(vial_time, operations)
    vial_latency_op_usec = latency_usec(vial_usecs_op, stdlib_usecs_op)
    vial_latency_op_percent = latency_percent(vial_latency_op_usec, stdlib_usecs_op)

    phoenix_ops_sec = ops_sec(operations, phoenix_time)
    phoenix_usecs_op = usecs_op(phoenix_time, operations)
    phoenix_latency_op_usec = latency_usec(phoenix_usecs_op, stdlib_usecs_op)
    phoenix_latency_op_percent = latency_percent(phoenix_latency_op_usec, stdlib_usecs_op)

    log_header("Operations / second")
    log_data([
      {StdLib, stdlib_ops_sec},
      {Vial, vial_ops_sec},
      {Phoenix, phoenix_ops_sec}
    ], "ops/sec")

    log_header("Time / operation")
    log_data([
      {StdLib, stdlib_usecs_op},
      {Vial, vial_usecs_op},
      {Phoenix, phoenix_usecs_op}
    ], "usec")

    log_header("Latency / operation")
    log_data([
      {Vial, vial_latency_op_usec},
      {Phoenix, phoenix_latency_op_usec}
    ], "usec")

    log_header("Latency / operation")
    log_data([
      {Vial, vial_latency_op_percent},
      {Phoenix, phoenix_latency_op_percent}
    ], "%")
  end

  defp log_header(header), do: IO.puts ["\n", header, "\n", String.duplicate("=", String.length(header))]
  defp log_data(data, unit) do
    prefix_length =
      data
      |> Enum.map(fn {type, _} -> to_string(type) |> String.length() end)
      |> Enum.max()

    datum_length =
      data
      |> Enum.map(fn {_, x} -> to_string(x) |> String.length() end)
      |> Enum.max()

    for {type, raw_datum} <- data do
      prefix = to_string(type)
      datum = to_string(raw_datum)

      left_padding = (prefix_length + 2) - String.length(prefix)
      right_padding = (datum_length + 2) - String.length(datum)

      IO.puts [
        prefix,
        String.duplicate(" ", left_padding),
        "::",
        String.duplicate(" ", right_padding),
        datum,
        " #{unit}"
      ]
    end
  end

  defp ops_sec(ops, usecs), do: (ops * 1000000) / usecs |> round_float()
  defp usecs_op(usecs, ops), do: usecs / ops |> round_float()
  defp latency_usec(usecs, base_usecs), do: usecs - base_usecs |> round_float()
  defp latency_percent(latency_usecs, base_usecs), do: (latency_usecs * 100) / base_usecs |> round_float()

  defp round_float(float), do: Float.round(float, 2)

  defp time_writes(type, operations) do
    log_header("Timing #{operations} writes for: #{type}")
    set = new_set(type)
    func = write_function(type, operations, set)
    {time, _} = :timer.tc(func)
    time
  end

  defp write_function(type, operations, set) do
    fn ->
      Enum.reduce(1..operations, set, add_function(type))
    end
  end

  defp new_set(Vial),    do: Vial.Set.new(:vial)
  defp new_set(Phoenix), do: Phoenix.Tracker.State.new(:phoenix)
  defp new_set(StdLib),  do: Set.new()

  defp add_function(Vial) do
    fn i, set ->
      Vial.Set.add(set, i, self(), %{})
    end
  end
  defp add_function(Phoenix) do
    fn i, set ->
      Phoenix.Tracker.State.join(set, self(), i, i, %{})
    end
  end
  defp add_function(StdLib) do
    fn i, set ->
      Set.put(set, {self(), i})
    end
  end
end
