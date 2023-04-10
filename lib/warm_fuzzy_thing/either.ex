defmodule WarmFuzzyThing.Either do
  @moduledoc """
  The `Either` monad is a union between two general notions: `Left` and `Right` (_the naming is inherited from Haskell and it depicts the idea: "Either I have this or I have that."_).
  This means that an `Either` monad can either be a `Left` or it can be a `Right` (_think of it as a simple `union` between two types_).
  A `Right` is represented by the well known success type tuple `{:ok, value} when value: any()`,
  where as a `Left` is represented by the well known error type tuple `{:error, reason} when reason: any()`.
  Generally a `Right` `Either` represents a successful transformation/operation where as a `Left` `Either` represents an unsuccessful one.

  `Either` exports a set of function for ease of chaining functions (_transformations_):
    - `WarmFuzzyThing.Either.fmap/2` - Used for applying a function over the value of a `Either` monad;
    - `WarmFuzzyThing.Either.bind/2` - Used for applying a function over a value inside a `Either` monad that returns a brand new `Either` monad;
    - `WarmFuzzyThing.Either.fold/3` - Used for either returning a default value or applying a function over the value inside the `Either` monad;

  ## Example
      iex> WarmFuzzyThing.Either.fmap({:ok, 1}, fn v -> v + 1 end)
      {:ok, 2}
      iex> WarmFuzzyThing.Either.fmap({:error, :not_found}, fn v -> v + 1 end)
      {:error, :not_found}
      iex> WarmFuzzyThing.Either.bind({:ok, 1}, fn v -> {:ok, v + 1} end)
      {:ok, 2}
      iex> WarmFuzzyThing.Either.bind({:error, :not_found}, fn v -> {:ok, v + 1} end)
      {:error, :not_found}
      iex> WarmFuzzyThing.Either.bind({:ok, 1}, fn v -> {:error, :not_found} end)
      {:error, :not_found}
      iex> WarmFuzzyThing.Either.fold({:ok, 1}, &WarmFuzzyThing.id/1)
      1
      iex> WarmFuzzyThing.Either.fold({:error, :not_found}, &WarmFuzzyThing.id/1)
      nil
      iex> WarmFuzzyThing.Either.fold({:error, :not_found}, :empty, &WarmFuzzyThing.id/1)
      :empty

  This set of function are setup in a way to allow for easy pipelining.

  ## Example
      iex> {:ok, "elixir"}
      ...> |> WarmFuzzyThing.Either.fmap(fn v -> v <> " with monads" end)
      ...> |> WarmFuzzyThing.Either.fmap(&String.length/1)
      ...> |> WarmFuzzyThing.Either.bind(fn
      ...>    v when v <= 20 -> {:ok, v}
      ...>    _ -> {:error, :too_big}
      ...>  end)
      ...> |> WarmFuzzyThing.Either.fold(&WarmFuzzyThing.id/1)
      18

  `Either` exports a set of operators for handling the chaining functions:
    - `~>` represents `WarmFuzzyThing.Either.fmap/2`
    - `~>>` represents `WarmFuzzyThing.Either.bind/2`
    - `<~>` represents `WarmFuzzyThing.Either.fold/3`

  ## Example
      iex> import WarmFuzzyThing.Either, only: [~>: 2, ~>>: 2, <~>: 2]
      iex> {:ok, "elixir"} ~> &String.length/1
      {:ok, 6}
      iex> {:error, :not_found} ~> &String.length/1
      {:error, :not_found}
      iex> {:ok, "elixir"} ~>> &({:ok, String.length(&1)})
      {:ok, 6}
      iex> {:ok, ""} ~>> fn "" -> {:error, :empty}; v -> {:ok, String.length(v)} end
      {:error, :empty}
      iex> {:ok, "elixir"} <~> &String.length/1
      6
      iex> {:error, :not_a_number} ~>> fn v -> {:ok, v + 1} end
      {:error, :not_a_number}
      iex> {:error, :empty} <~> fn v -> v + 1 end
      nil
      iex> {:error, :empty} <~> {:not_found, fn v -> v + 1 end}
      :not_found
      iex> {:ok, "elixir"}
      ...> ~> fn v -> v <> " with monads" end
      ...> ~> fn v -> v <> " is awesome" end
      ...> ~>> fn v when v < 20 -> {:error, :too_short}; v -> {:ok, String.length(v)} end
      ...> <~> {0, &WarmFuzzyThing.id/1}
      29
  """

  @behaviour WarmFuzzyThing

  alias WarmFuzzyThing.Either

  @type t(reason, value) :: {:error, reason} | {:ok, value}

  @doc """
  Checks whether a `Either` monad is `'left'`

  ## Example
    iex> import WarmFuzzyThing.Either
    iex> left?({:error, :empty})
    true
    iex> left?({:ok, 1})
    false
  """
  defmacro left?({:error, _reason}), do: true
  defmacro left?(_), do: false

  @doc """
  Checks whether a `Either` monad is `'right'`

  ## Example
    iex> import WarmFuzzyThing.Either
    iex> right?({:ok, 1})
    true
    iex> right?({:error, :empty})
    false
  """
  defmacro right?({:ok, _value}), do: true
  defmacro right?(_), do: false

  @impl true
  @spec pure({:error, reason} | value) :: Either.t(reason, value) when reason: any(), value: any()
  def pure({:error, reason}), do: {:error, reason}
  def pure(value), do: {:ok, value}

  @doc """
  Apply a function over the `'right'` portion (_the "success" value_) of an `Either` monad.
  The result of the function will be the `new` `'right'` portion of the `Either` monad.

  If an `Either` monad with a `'left'` value is passed, the function is not invoked,
  `WarmFuzzyThing.Either.map/2` just return the `'left'` value.

  ## Example
      iex> WarmFuzzyThing.Either.fmap({:ok, 1}, fn v -> v + 1 end)
      {:ok, 2}
      iex> WarmFuzzyThing.Either.fmap({:ok, "hello"}, fn _v -> "world" end)
      {:ok, "world"}
      iex> WarmFuzzyThing.Either.fmap({:ok, "hello"}, &String.length/1)
      {:ok, 5}
      iex> WarmFuzzyThing.Either.fmap({:error, :not_a_number}, fn v -> v + 1 end)
      {:error, :not_a_number}
  """
  @impl true
  @spec fmap(Either.t(reason, value), function) :: Either.t(reason, new_value)
        when reason: any(),
             value: any(),
             function: (value -> new_value),
             new_value: any()
  def fmap(either, function)

  def fmap({:error, reason}, _f), do: {:error, reason}
  def fmap({:ok, value}, f) when is_function(f), do: {:ok, f.(value)}

  @doc """
  Apply a function over the `'right'` portion (_the "success" value_) of an `Either` monad.
  The result of the function will be a brand new `Either` monad.
  This means that the value inside the monad can change from `'left'` to `'right'` and vice versa.

  If an `Either` monad with a `'left'` value is passed, the function is not invoked,
  `WarmFuzzyThing.Either.bind/2` just return the `'left'` value.

  ## Example
      iex> WarmFuzzyThing.Either.bind({:ok, 1}, fn v -> {:ok, v + 1} end)
      {:ok, 2}
      iex> WarmFuzzyThing.Either.bind({:ok, "hello"}, fn _v -> {:ok, "world"} end)
      {:ok, "world"}
      iex> WarmFuzzyThing.Either.bind({:ok, "hello"}, &({:ok, String.length(&1)}))
      {:ok, 5}
      iex> WarmFuzzyThing.Either.bind({:ok, "hello"}, fn _v -> {:error, "something went wrong"} end)
      {:error, "something went wrong"}
      iex> WarmFuzzyThing.Either.fmap({:error, :not_a_number}, fn v -> {:ok, v + 1} end)
      {:error, :not_a_number}
  """
  @impl true
  @spec bind(Either.t(reason, value), function) :: new_either
        when reason: any(),
             value: any(),
             function: (value -> new_either),
             new_either: Either.t(new_reason, new_value),
             new_value: any(),
             new_reason: any()
  def bind(either, function)

  def bind({:error, reason}, _f), do: {:error, reason}

  def bind({:ok, value}, f) when is_function(f) do
    case f.(value) do
      {:ok, value} -> {:ok, value}
      {:error, reason} -> {:error, reason}
      other -> raise(bind_exception(other))
    end
  end

  @doc """
  Depending of the value inside the `Either` monad, fold will either (no pun intended):
    - Apply the given function over the `'right'` value and return the value itself;
    - Return the `'default'` value given to the function. If no `'default'` value is provided, `nil` is returned;

  ## Example
      iex> WarmFuzzyThing.Either.fold({:ok, 1}, fn v -> v + 1 end)
      2
      iex> WarmFuzzyThing.Either.fold({:ok, "hello"}, fn _v -> "world" end)
      "world"
      iex> WarmFuzzyThing.Either.fold({:ok, "hello"}, &String.length/1)
      5
      iex> WarmFuzzyThing.Either.fold({:error, :not_a_number}, fn v -> v + 1 end)
      nil
      iex> WarmFuzzyThing.Either.fold({:error, :not_a_number}, :not_found, fn v -> v + 1 end)
      :not_found
  """
  @impl true
  @spec fold(Either.t(reason, value), default :: new_value, function) :: new_value
        when reason: any(),
             value: any(),
             function: (value -> new_value),
             new_value: any()
  def fold(input, default \\ nil, function)

  def fold({:error, _reason}, default, _f), do: default
  def fold({:ok, value}, _default, f) when is_function(f), do: f.(value)

  @doc """
  Cycles through a sequence of `EIther`s, if it reaches a `'left'` `Either` it short circuits and returns it.

  Otherwise returns a `Either` with a list of all values.

  ## Example
      iex> WarmFuzzyThing.Either.sequence([{:ok, 1}, {:ok, 2}])
      {:ok, [1, 2]}
      iex> WarmFuzzyThing.Either.sequence([])
      {:ok, []}
      iex> WarmFuzzyThing.Either.sequence([{:ok, 1}, {:error, :not_found}, {:ok, 2}])
      {:error, :not_found}
      iex> WarmFuzzyThing.Either.sequence([{:error, :not_found}, {:error, :empty}])
      {:error, :not_found}
  """
  @impl true
  @spec sequence([Either.t(reason, value)]) :: Either.t(reason, [value])
        when reason: any(), value: any()
  def sequence(eithers)

  def sequence([]), do: {:ok, []}

  def sequence(eithers) when is_list(eithers) do
    eithers
    |> Enum.reduce_while([], fn
      {:error, reason}, _acc -> {:halt, {:error, reason}}
      {:ok, value}, acc -> {:cont, [value | acc]}
    end)
    |> case do
      {:error, reason} -> {:error, reason}
      acc -> Enum.reverse(acc)
    end
    |> Either.pure()
  end

  @doc """
  Call a 'void' type of function if the `Either` monad is a `'left'`.
  `WarmFuzzyThing.Either.on_left/2` returns the `Either` as is. No changes are applied.

  _If the `Either` has a `'right'` value inside, the function is not invoked._

  ## Example
      iex> WarmFuzzyThing.Either.on_left({:ok, 1}, &IO.inspect/1)
      {:ok, 1}
      iex> WarmFuzzyThing.Either.on_left({:error, :not_a_number}, &IO.inspect/1)
      :not_a_number
      {:error, :not_a_number}
  """
  @spec on_left(Either.t(reason, value), function) :: Either.t(reason, value)
        when reason: any(),
             value: any(),
             function: (reason -> :ok)
  def on_left(either, function)

  def on_left({:ok, value}, _f), do: {:ok, value}

  def on_left({:error, reason}, f) when is_function(f) do
    f.(reason)
    {:error, reason}
  end

  @doc """
  Call a 'void' type of function if the `Either` monad is a `'right'`.
  `WarmFuzzyThing.Either.on_right/2` returns the `Either` as is. No changes are applied.

  _If the `Either` has a `'left'` value inside, the function is not invoked._

  ## Example
      iex> WarmFuzzyThing.Either.on_right({:ok, 1}, &IO.inspect/1)
      1
      {:ok, 1}
      iex> WarmFuzzyThing.Either.on_right({:error, :not_a_number}, &IO.inspect/1)
      {:error, :not_a_number}
  """
  @spec on_right(Either.t(reason, value), function) :: Either.t(reason, value)
        when reason: any(),
             value: any(),
             function: (value -> :ok)
  def on_right(either, function)

  def on_right({:error, reason}, _f), do: {:error, reason}

  def on_right({:ok, value}, f) when is_function(f) do
    f.(value)
    {:ok, value}
  end

  @doc """
  Similar to how `Either.fmap/2` works, but it maps over the `Left` value of the `Either` monad.

  Useful when you want to change the structure of the reason.

  ## Example
      iex> WarmFuzzyThing.Either.map_left({:ok, 1}, fn reason -> {:operation, reason} end)
      {:ok, 1}
      iex> WarmFuzzyThing.Either.map_left({:error, :not_found}, fn reason -> {:user, reason} end)
      {:error, {:user, :not_found}}
  """
  @spec map_left(Either.t(reason, value), (reason -> new_reason)) :: Either.t(new_reason, value)
        when reason: any(),
             value: any(),
             new_reason: any()
  def map_left(either, function)

  def map_left({:ok, value}, _f), do: {:ok, value}

  def map_left({:error, reason}, f) when is_function(f) do
    {:error, f.(reason)}
  end

  @doc """
  Operator for handling `WarmFuzzyThing.Either.map/2`.

  ## Example
      iex> import WarmFuzzyThing.Either, only: [~>: 2]
      iex> {:ok, 1} ~> fn v -> v + 1 end
      {:ok, 2}
      iex> {:ok, "hello"} ~> fn _v -> "world" end
      {:ok, "world"}
      iex> {:ok, "hello"} ~> &String.length/1
      {:ok, 5}
      iex> {:error, :not_a_number} ~> fn v -> v + 1 end
      {:error, :not_a_number}
  """
  @spec Either.t(reason, value) ~> function :: Either.t(reason, new_value)
        when reason: any(),
             value: any(),
             function: (value -> new_value),
             new_value: any()
  def {:error, reason} ~> _, do: {:error, reason}
  def {:ok, value} ~> f when is_function(f), do: {:ok, f.(value)}

  @doc """
  Operator for handling `WarmFuzzyThing.Either.bind/2`.

  ## Example
      iex> import WarmFuzzyThing.Either, only: [~>>: 2]
      iex> {:ok, 1} ~>> fn v -> {:ok, v + 1} end
      {:ok, 2}
      iex> {:ok, "hello"} ~>> fn _v -> {:ok, "world"} end
      {:ok, "world"}
      iex> {:ok, "hello"} ~>> &({:ok, String.length(&1)})
      {:ok, 5}
      iex> {:ok, "hello"} ~>> fn _v -> {:error, "something went wrong"} end
      {:error, "something went wrong"}
      iex> {:error, :not_a_number} ~>> fn v -> {:ok, v + 1} end
      {:error, :not_a_number}
  """
  @spec Either.t(reason, value) ~>> function :: Either.t(new_reason, new_value)
        when reason: any(),
             value: any(),
             function: (value -> new_either),
             new_either: Either.t(new_reason, new_value),
             new_value: any(),
             new_reason: any()
  def {:error, reason} ~>> _, do: {:error, reason}

  def {:ok, value} ~>> f when is_function(f) do
    case f.(value) do
      {:ok, value} -> {:ok, value}
      {:error, reason} -> {:error, reason}
      other -> raise(bind_exception(other))
    end
  end

  @doc """
  Operator for handling `WarmFuzzyThing.Either.fold/3`.

  ## Example
      iex> import WarmFuzzyThing.Either, only: [<~>: 2]
      iex> {:ok, 1} <~> fn v -> v + 1 end
      2
      iex> {:ok, "hello"} <~> fn _v -> "world" end
      "world"
      iex> {:ok, "hello"} <~> &String.length/1
      5
      iex> {:error, :not_a_number} <~> fn v -> v + 1 end
      nil
      iex> {:error, :not_a_number} <~> {:not_found, fn v -> v + 1 end}
      :not_found
  """
  @spec Either.t(reason, value) <~> ({default :: new_value, function} | function) ::
          new_value
        when reason: any(),
             value: any(),
             function: (value -> new_value),
             new_value: any()
  def {:error, _} <~> {default, _f}, do: default
  def {:error, _} <~> f when is_function(f), do: nil
  def {:ok, value} <~> {_default, f} when is_function(f), do: f.(value)
  def {:ok, value} <~> f when is_function(f), do: f.(value)

  defp bind_exception(other) do
    "Function provided to `WarmFuzzyThing.Either.bind/2` should return an `Either.t(any(), any())` type, got #{inspect(other)}"
  end
end
