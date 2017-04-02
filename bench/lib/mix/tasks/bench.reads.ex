defmodule Mix.Tasks.Bench.Reads do
  @moduledoc """
  Runs simple benchmarks for read operations on a single Set. It compares
  the performance of the stblib Set, Phoenix's Set CRDT and Vial's Set CRDT.

  ## Examples

    $ mix bench.reads
  """

  use Mix.Task

  alias Bench.{
    Benchmark,
    Generator,
    Timer
  }

  @set_size   10_000
  @block_size 1_000
  @start      10_000
  @step       2_000
  @finish     100_000

  def run(_opts) do
    for module <- [StdLib, Vial, Phoenix] do
      {:ok, _} = Agent.start_link(fn -> set_with_elements(module, 10000) end, name: module)
    end

    Benchmark.run("reads", &time_reads/2, @start, @step, @finish)
  end

  defp time_reads(module, operations) do
    Task.async(fn ->
      set = Agent.get(module, &(&1))
      keys = div(@set_size, @block_size)
      function = Generator.read_function(module, operations, keys, set, @block_size)
      Timer.time(:read, module, operations, function)
    end)
    |> Task.await(:infinity)
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
