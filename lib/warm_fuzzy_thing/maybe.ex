defmodule WarmFuzzyThing.Maybe do
  @moduledoc """
  The `Maybe` monad is a union between two general notions: `Just` and `Nothing` (_the naming is inherited from Haskell and it depicts the idea: "Maybe I have a value, maybe I don't."_).
  This means that a `Maybe` monad can either be a `Just` or it can be a `Nothing` (_think of it as a simple `union` between two types_).
  A `Just` is represented by the well known success type tuple `{:ok, value} when value: any()`,
  where as a `Nothing` is represented by `nil`, since it's the closest Elixir gets to representing "nothing".

  `Maybe` exports a set of function for ease of chaining functions (_transformations_):
    - `WarmFuzzyThing.Maybe.fmap/2` - Used for applying a function over the value of a `Maybe` monad;
    - `WarmFuzzyThing.Maybe.bind/2` - Used for applying a function over a value inside a `Maybe` monad that returns a brand new `Maybe` monad;
    - `WarmFuzzyThing.Maybe.fold/3` - Used for either returning a default value or applying a function over the value inside the `Maybe` monad;

  ## Example
      iex> WarmFuzzyThing.Maybe.fmap({:ok, 1}, fn v -> v + 1 end)
      {:ok, 2}
      iex> WarmFuzzyThing.Maybe.fmap(nil, fn v -> v + 1 end)
      nil
      iex> WarmFuzzyThing.Maybe.bind({:ok, 1}, fn v -> {:ok, v + 1} end)
      {:ok, 2}
      iex> WarmFuzzyThing.Maybe.bind(nil, fn v -> {:ok, v + 1} end)
      nil
      iex> WarmFuzzyThing.Maybe.bind({:ok, 1}, fn v -> nil end)
      nil
      iex> WarmFuzzyThing.Maybe.fold({:ok, 1}, &WarmFuzzyThing.id/1)
      1
      iex> WarmFuzzyThing.Maybe.fold(nil, &WarmFuzzyThing.id/1)
      nil
      iex> WarmFuzzyThing.Maybe.fold(nil, :empty, &WarmFuzzyThing.id/1)
      :empty

  This set of function are setup in a way to allow for easy pipelining.

  ## Example
      iex> {:ok, "hello"}
      ...> |> WarmFuzzyThing.Maybe.fmap(fn v -> v <> " world" end)
      ...> |> WarmFuzzyThing.Maybe.fmap(&String.length/1)
      ...> |> WarmFuzzyThing.Maybe.bind(fn
      ...>    v when v <= 20 -> {:ok, v}
      ...>    _ -> nil
      ...>  end)
      ...> |> WarmFuzzyThing.Maybe.fold(&WarmFuzzyThing.id/1)
      11

  `Maybe` exports a set of operators for handling the chaining functions:
    - `~>` represents `WarmFuzzyThing.Maybe.fmap/2`
    - `~>>` represents `WarmFuzzyThing.Maybe.bind/2`
    - `<~>` represents `WarmFuzzyThing.Maybe.fold/3`

  ## Example
      iex> import WarmFuzzyThing.Maybe, only: [~>: 2, ~>>: 2, <~>: 2]
      iex> {:ok, "elixir"} ~> &String.length/1
      {:ok, 6}
      iex> nil ~> &String.length/1
      nil
      iex> {:ok, "elixir"} ~>> &({:ok, String.length(&1)})
      {:ok, 6}
      iex> {:ok, ""} ~>> fn "" -> nil; v -> {:ok, String.length(v)} end
      nil
      iex> {:ok, "elixir"} <~> &String.length/1
      6
      iex> nil ~>> fn v -> {:ok, v + 1} end
      nil
      iex> nil <~> fn v -> v + 1 end
      nil
      iex> nil <~> {:not_found, fn v -> v + 1 end}
      :not_found
      iex> {:ok, "elixir"}
      ...> ~> fn v -> v <> " with monads" end
      ...> ~> fn v -> v <> " is awesome" end
      ...> ~>> fn v when v < 20 -> nil; v -> {:ok, String.length(v)} end
      ...> <~> {0, &WarmFuzzyThing.id/1}
      29
  """

  @behaviour WarmFuzzyThing

  alias WarmFuzzyThing.Maybe

  @type t(value) :: nil | {:ok, value}

  @doc """
  Checks whether a `Maybe` monad is `Nothing` (_essentially empty_)

  ## Example
    iex> import WarmFuzzyThing.Maybe
    iex> nothing?(nil)
    true
    iex> nothing?({:ok, 1})
    false
  """
  defmacro nothing?(nil), do: quote(do: true)
  defmacro nothing?(_), do: quote(do: false)

  @doc """
  Checks whether a `Maybe` monad is a `Just`

  ## Example
    iex> import WarmFuzzyThing.Maybe
    iex> just?({:ok, 1})
    true
    iex> just?(nil)
    false
  """
  defmacro just?({:ok, _value}), do: quote(do: true)
  defmacro just?(_), do: quote(do: false)

  @impl true
  @spec pure(nil | value) :: Maybe.t(value) when value: any()
  def pure(nil), do: nil
  def pure(value), do: {:ok, value}

  @doc """
  Apply a function over the `Just` portion of a `Maybe` monad.
  The result of the function will be the `new` `Just` portion of the `Maybe` WarmFuzzyThing.

  If a `Maybe` monad with a `Nothing` value is passed, the function is not invoked,
  `WarmFuzzyThing.Maybe.fmap/2` return a `nil`.

  ## Example
      iex> WarmFuzzyThing.Maybe.fmap({:ok, 1}, fn v -> v + 1 end)
      {:ok, 2}
      iex> WarmFuzzyThing.Maybe.fmap({:ok, "hello"}, fn _v -> "world" end)
      {:ok, "world"}
      iex> WarmFuzzyThing.Maybe.fmap({:ok, "hello"}, &String.length/1)
      {:ok, 5}
      iex> WarmFuzzyThing.Maybe.fmap(nil, fn v -> v + 1 end)
      nil
  """
  @impl true
  @spec fmap(Maybe.t(value), function) :: Maybe.t(new_value)
        when value: any(),
             function: (value -> new_value),
             new_value: any()
  def fmap(nil, _f), do: nil
  def fmap({:ok, value}, f) when is_function(f), do: {:ok, f.(value)}

  @doc """
  Apply a function over the `Just` portion of a `Maybe` monad.
  The result of the function will be a brand new `Maybe` monad.
  This means that the value inside the monad can change from `Just` to `Nothing` and vice versa.

  If a `Maybe` monad with a `Nothing` value is passed, the function is not invoked,
  `WarmFuzzyThing.Maybe.bind/2` return a `nil`.

  ## Example
      iex> WarmFuzzyThing.Maybe.bind({:ok, 1}, fn v -> {:ok, v + 1} end)
      {:ok, 2}
      iex> WarmFuzzyThing.Maybe.bind({:ok, "hello"}, fn _v -> {:ok, "world"} end)
      {:ok, "world"}
      iex> WarmFuzzyThing.Maybe.bind({:ok, "hello"}, &({:ok, String.length(&1)}))
      {:ok, 5}
      iex> WarmFuzzyThing.Maybe.bind({:ok, "hello"}, fn _v -> nil end)
      nil
      iex> WarmFuzzyThing.Maybe.bind(nil, fn v -> v + 1 end)
      nil
  """
  @impl true
  @spec bind(Maybe.t(value), function) :: new_maybe
        when value: any(),
             function: (value -> new_maybe),
             new_maybe: Maybe.t(new_value),
             new_value: any()
  def bind(nil, _f), do: nil

  def bind({:ok, value}, f) when is_function(f) do
    case f.(value) do
      nil -> nil
      {:ok, value} -> {:ok, value}
    end
  end

  @doc """
  Depending of the value inside the `Maybe` monad, fold will either (no pun intended):
    - Apply the given function over the `Just` value and return the value itself;
    - Return the `'default'` value given to the function. If no `'default'` value is provided, `nil` is returned;

  ## Example
      iex> WarmFuzzyThing.Maybe.fold({:ok, 1}, fn v -> v + 1 end)
      2
      iex> WarmFuzzyThing.Maybe.fold({:ok, "hello"}, fn _v -> "world" end)
      "world"
      iex> WarmFuzzyThing.Maybe.fold({:ok, "hello"}, &String.length/1)
      5
      iex> WarmFuzzyThing.Maybe.fold(nil, fn v -> v + 1 end)
      nil
      iex> WarmFuzzyThing.Maybe.fold(nil, :not_found, fn v -> v + 1 end)
      :not_found
      iex> WarmFuzzyThing.Maybe.sequence([])
      {:ok, []}
  """
  @impl true
  @spec fold(Maybe.t(value), default :: new_value, function) :: new_value
        when value: any(),
             function: (value -> new_value),
             new_value: any()
  def fold(input, default \\ nil, function)

  def fold(nil, default, _f), do: default
  def fold({:ok, value}, _default, f) when is_function(f), do: f.(value)

  @doc """
  Cycles through a sequence of `Maybe`s, if it finds an empty `Maybe` it short circuits
  and returns an "empty" `Maybe`.

  Otherwise returns a `Maybe` with a list of all values.

  ## Example
      iex> WarmFuzzyThing.Maybe.sequence([{:ok, 1}, {:ok, 2}])
      {:ok, [1, 2]}
      iex> WarmFuzzyThing.Maybe.sequence([])
      {:ok, []}
      iex> WarmFuzzyThing.Maybe.sequence([{:ok, 1}, nil, {:ok, 2}])
      nil
      iex> WarmFuzzyThing.Maybe.sequence([nil])
      nil
  """
  @impl true
  @spec sequence([Maybe.t(value)]) :: Maybe.t([value]) when value: any()
  def sequence([]), do: {:ok, []}

  def sequence(maybes) do
    maybes
    |> Enum.reduce_while([], fn
      nil, _acc -> {:halt, nil}
      {:ok, value}, acc -> {:cont, [value | acc]}
    end)
    |> case do
      nil -> nil
      acc -> Enum.reverse(acc)
    end
    |> Maybe.pure()
  end

  @doc """
  Call a 'void' type of function if the `Maybe` monad is a `Nothing`.
  `WarmFuzzyThing.Maybe.on_nothing/2` returns the `Maybe` as is. No changes are applied.

  _If the `Maybe` has a `'right'` value inside, the function is not invoked._

  ## Example
      iex> WarmFuzzyThing.Maybe.on_nothing({:ok, 1}, &IO.inspect/1)
      {:ok, 1}
      iex> WarmFuzzyThing.Maybe.on_nothing(nil, fn -> IO.inspect("Empty maybe monad") end)
      "Empty maybe monad"
      nil
  """
  @spec on_nothing(Maybe.t(value), function) :: Maybe.t(value)
        when value: any(),
             function: (() -> :ok)

  def on_nothing(maybe, function)

  def on_nothing({:ok, value}, _f), do: {:ok, value}

  def on_nothing(nil, f) when is_function(f) do
    f.()
    nil
  end

  @doc """
  Call a 'void' type of function if the `Maybe` monad is a `Just`.
  `WarmFuzzyThing.Maybe.on_just/2` returns the `Maybe` as is. No changes are applied.

  _If the `Maybe` has a `Nothing` value inside, the function is not invoked._

  ## Example
      iex> WarmFuzzyThing.Maybe.on_just({:ok, 1}, &IO.inspect/1)
      1
      {:ok, 1}
      iex> WarmFuzzyThing.Maybe.on_just(nil, &IO.inspect/1)
      nil
  """
  @spec on_just(Maybe.t(value), function) :: Maybe.t(value)
        when value: any(),
             function: (value -> :ok)

  def on_just(nil, _f), do: nil

  def on_just({:ok, value}, f) do
    f.(value)
    {:ok, value}
  end

  @doc """
  Operator for handling `WarmFuzzyThing.Maybe.fmap/2`.

  ## Example
      iex> import WarmFuzzyThing.Maybe, only: [~>: 2]
      iex> {:ok, 1} ~> fn v -> v + 1 end
      {:ok, 2}
      iex> {:ok, "hello"} ~> fn _v -> "world" end
      {:ok, "world"}
      iex> {:ok, "hello"} ~> &String.length/1
      {:ok, 5}
      iex> nil ~> fn v -> v + 1 end
      nil
  """
  @spec Maybe.t(value) ~> function :: Maybe.t(new_value)
        when value: any(),
             function: (value -> new_value),
             new_value: any()
  def nil ~> _f, do: nil
  def {:ok, value} ~> f when is_function(f), do: {:ok, f.(value)}

  @doc """
  Operator for handling `WarmFuzzyThing.Maybe.bind/2`.

  ## Example
      iex> import WarmFuzzyThing.Maybe, only: [~>>: 2]
      iex> {:ok, 1} ~>> fn v -> {:ok, v + 1} end
      {:ok, 2}
      iex> {:ok, "hello"} ~>> fn _v -> {:ok, "world"} end
      {:ok, "world"}
      iex> {:ok, "hello"} ~>> &({:ok, String.length(&1)})
      {:ok, 5}
      iex> {:ok, "hello"} ~>> fn _v -> nil end
      nil
      iex> nil ~>> fn v -> {:ok, v + 1} end
      nil
  """
  @spec Maybe.t(value) ~>> function :: new_maybe
        when value: any(),
             function: (value -> new_maybe),
             new_maybe: Maybe.t(new_value),
             new_value: any()
  def nil ~>> _f, do: nil

  def {:ok, value} ~>> f when is_function(f) do
    case f.(value) do
      nil -> nil
      {:ok, value} -> {:ok, value}
    end
  end

  @doc """
  Operator for handling `WarmFuzzyThing.Maybe.fold/3`.

  ## Example
      iex> import WarmFuzzyThing.Maybe, only: [<~>: 2]
      iex> {:ok, 1} <~> fn v -> v + 1 end
      2
      iex> {:ok, "hello"} <~> fn _v -> "world" end
      "world"
      iex> {:ok, "hello"} <~> &String.length/1
      5
      iex> nil <~> fn v -> v + 1 end
      nil
      iex> nil <~> {:not_found, fn v -> v + 1 end}
      :not_found
  """
  @spec Maybe.t(value) <~> ({default :: new_value, function} | function) :: new_value
        when value: any(),
             function: (value -> new_value),
             new_value: any()
  def nil <~> {default, _f}, do: default
  def nil <~> f when is_function(f), do: nil
  def {:ok, value} <~> {_default, f} when is_function(f), do: f.(value)
  def {:ok, value} <~> f when is_function(f), do: f.(value)
end
