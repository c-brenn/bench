defmodule Mix.Tasks.Bench.Merges do
  @moduledoc """
  Runs simple benchmarks for read operations on a single Set. It compares
  the performance of the stblib Set, Phoenix's Set CRDT and Vial's Set CRDT.

  ## Examples

    $ mix bench.merges
  """

  use Mix.Task

  alias Bench.{
    Benchmark,
    Generator,
    Timer
  }

  @max_ops    50000
  @step        5000
  @start      10000
  @set_size   10

  def run(_opts) do
    Benchmark.run("merges", &time_merges/2, @start, @step, @max_ops)
  end

  defp time_merges(StdLib, _), do: {:error, :not_implemented}
  defp time_merges(module, operations) do
    Task.async(fn ->
      {set, delta} = make_them(module, @set_size, operations)
      function = Generator.merge_function(module, set, delta)
      Timer.time(:merge, module, operations, function)
    end)
    |> Task.await(:infinity)
  end

  defp make_them(module, set_size, delta_size) do
    key_space = 1..10000

    set = Enum.reduce(1..(div(set_size, 2)), Generator.new_set(module, :merge_into), fn(_, set) ->
      key = Enum.random(key_space)
      pid = make_ref()
      add(module, set, key, pid)
    end)

    {additions, delta} =
      Enum.reduce(1..set_size, {[], Generator.new_set(module, :delta)}, fn(_, {adds, set}) ->
        key = Enum.random(key_space)
        pid = make_ref()
        set = add(module, set, key, pid)
        {[{key, pid}|adds], set}
      end)

    set = Generator.merge_function(module, set, Generator.delta(module, delta)).()

    delta = Generator.clear_delta(module, delta)

    {_, delta} = Enum.reduce(1..delta_size, {additions, delta}, fn(i,{adds, delta}) ->
      if rem(i, 10) == 0 do
        [{key, pid}|tail] = adds
        {tail, remove(module, delta, key, pid)}
      else
        key = Enum.random(key_space)
        pid = make_ref()
        {adds ++ [{key, pid}], add(module, delta, key, pid)}
      end
    end)

    {set, Generator.delta(module, delta)}
  end

  defp add(Vial, set, key, pid) do
    Vial.Set.add(set, key, pid, %{})
  end
  defp add(Phoenix, set, key, pid) do
    Phoenix.Tracker.State.join(set, pid, key, key, %{})
  end

  defp remove(Vial, set, key, pid) do
    Vial.Set.remove(set, key, pid)
  end
  defp remove(Phoenix, set, key, pid) do
    Phoenix.Tracker.State.leave(set, pid, key, key)
  end
end
