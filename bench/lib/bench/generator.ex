defmodule Bench.Generator do
  def write_function(module, operations, set) do
    fn ->
      Enum.reduce(1..operations, set, add_function(module))
    end
  end

  def read_function(module, operations, keys, set, _size) do
    fn ->
      Stream.cycle(1..keys)
      |> Stream.take(operations)
      |> Enum.each(fn key ->
        get_function(module).(key, set)
      end)
    end
  end

  def merge_function(Vial, set, delta) do
    fn ->
      Vial.Set.merge(set, delta)
    end
  end

  def merge_function(Phoenix, set, delta) do
    fn ->
      {s, _, _} = Phoenix.Tracker.State.merge(set, delta)
      s
    end
  end

  def delta(Vial, set) do
    set.delta
  end
  def delta(Phoenix, set) do
    Phoenix.Tracker.State.extract(set)
  end

  def clear_delta(Vial, set) do
    clock = Vial.Vector.clock(set.vector, set.actor) - 1
    delta = Vial.Delta.new(set.actor, clock)
    %{set|delta: delta}
  end
  def clear_delta(Phoenix, set) do
    Phoenix.Tracker.State.reset_delta(set)
  end

  def new_set(module, name \\ :set)
  def new_set(Vial, name),    do: Vial.Set.new(name)
  def new_set(Phoenix, name), do: Phoenix.Tracker.State.new(name)
  def new_set(StdLib, _),  do: :ets.new(:foo, [:bag, :protected])

  def cleanup(StdLib, set), do: :ets.delete(set)
  def cleanup(Vial, set), do: :ets.delete(set.table)
  def cleanup(Phoenix, set) do
    :ets.delete(set.pids)
    :ets.delete(set.values)
  end

  def add_function(Vial) do
    fn key, set ->
      Vial.Set.add(set, key, make_ref(), %{})
    end
  end
  def add_function(Phoenix) do
    fn key, set ->
      Phoenix.Tracker.State.join(set, make_ref(), key, key, %{})
    end
  end
  def add_function(StdLib) do
    fn key, set ->
      :ets.insert(set, {key, make_ref()})
      set
    end
  end

  defp get_function(Vial) do
    fn key, set -> Vial.Set.list(set, key)
    end
  end
  defp get_function(Phoenix) do
    fn key, set ->
      Phoenix.Tracker.State.get_by_topic(set, key)
    end
  end
  defp get_function(StdLib) do
    fn key, set ->
      :ets.lookup(set, key)
    end
  end
end
