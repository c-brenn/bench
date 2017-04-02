defmodule Mix.Tasks.Bench.Writes do
  @moduledoc """
  Runs simple benchmarks for write operations on a single Set. It compares
  the performance of the stblib Set, Phoenix's Set CRDT and Vial's Set CRDT.

  ## Examples

    $ mix bench.writes
  """

  use Mix.Task

  alias Bench.{
    Benchmark,
    Generator,
    Timer
  }
  @start  10_000
  @step   2_000
  @finish 100_000

  def run(_opts) do
    Benchmark.run("writes", &time_writes/2, @start, @step, @finish)
  end

  defp time_writes(module, operations) do
    Task.async(fn ->
      set = Generator.new_set(module)
      function = Generator.write_function(module, operations, set)
      t =Timer.time(:write, module, operations, function)
      Generator.cleanup(module, set)
      t
    end)
    |> Task.await
  end
end
