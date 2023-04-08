defmodule Monad.Maybe do
  @moduledoc """
  Monad that either holds a `value` or `nil` (_it doesn't_).
  The value is wrapped in the well known pattern of _`{:ok, any()}`_.
  Otherwise `Maybe` holds onto a `nil` value (for the situations where there isn't a value).

  ## Example
      iex> Monad.Maybe.map({:ok, 1}, fn v -> v + 1 end)
      {:ok, 2}
      iex> Monad.Maybe.map(nil, fn v -> v + 1 end)
      nil
      iex> Monad.Maybe.bind({:ok, 1}, fn v -> {:ok, v + 1} end)
      {:ok, 2}
      iex> Monad.Maybe.bind(nil, fn v -> {:ok, v + 1} end)
      nil
      iex> Monad.Maybe.bind({:ok, 1}, fn v -> nil end)
      nil
  """

  alias Monad.Maybe

  @type t(value) :: nil | {:ok, value}

  @doc """
  Apply a function over the `'just'` portion of a `Maybe` monad.
  The result of the function will be the `new` `'just'` portion of the `Maybe` Monad.

  If a `Maybe` monad with a `'nothing'` value is passed, the function is not invoked,
  `Monad.Maybe.map/2` return a `nil`.

  ## Example
      iex> Monad.Maybe.map({:ok, 1}, fn v -> v + 1 end)
      {:ok, 2}
      iex> Monad.Maybe.map({:ok, "hello"}, fn _v -> "world" end)
      {:ok, "world"}
      iex> Monad.Maybe.map({:ok, "hello"}, &String.length/1)
      {:ok, 5}
      iex> Monad.Maybe.map(nil, fn v -> v + 1 end)
      nil
  """
  @spec map(Maybe.t(value), function) :: Maybe.t(new_value)
        when value: any(),
             function: (value -> new_value),
             new_value: any()
  def map(nil, _f), do: nil
  def map({:ok, value}, f) when is_function(f), do: {:ok, f.(value)}

  @doc """
  Apply a function over the `'just'` portion of a `Maybe` monad.
  The result of the function will be a brand new `Maybe` monad.
  This means that the value inside the monad can change from `'just'` to `'nothing'` and vice versa.

  If a `Maybe` monad with a `'nothing'` value is passed, the function is not invoked,
  `Monad.Maybe.bind/2` return a `nil`.

  ## Example
      iex> Monad.Maybe.bind({:ok, 1}, fn v -> {:ok, v + 1} end)
      {:ok, 2}
      iex> Monad.Maybe.bind({:ok, "hello"}, fn _v -> {:ok, "world"} end)
      {:ok, "world"}
      iex> Monad.Maybe.bind({:ok, "hello"}, &({:ok, String.length(&1)}))
      {:ok, 5}
      iex> Monad.Maybe.bind({:ok, "hello"}, fn _v -> nil end)
      nil
      iex> Monad.Maybe.bind(nil, fn v -> v + 1 end)
      nil
  """
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
      other -> raise(bind_exception(other))
    end
  end

  @doc """
  Depending of the value inside the `Maybe` monad, fold will either (no pun intended):
    - Apply the given function over the `'just'` value and return the value itself;
    - Return the `'default'` value given to the function. If no `'default'` value is provided, `nil` is returned;

  ## Example
      iex> Monad.Maybe.fold({:ok, 1}, fn v -> v + 1 end)
      2
      iex> Monad.Maybe.fold({:ok, "hello"}, fn _v -> "world" end)
      "world"
      iex> Monad.Maybe.fold({:ok, "hello"}, &String.length/1)
      5
      iex> Monad.Maybe.fold(nil, fn v -> v + 1 end)
      nil
      iex> Monad.Maybe.fold(nil, :not_found, fn v -> v + 1 end)
      :not_found
  """
  @spec fold(Maybe.t(value), default :: new_value, function) :: new_value
        when value: any(),
             function: (value -> new_value),
             new_value: any()
  def fold(input, default \\ nil, function)

  def fold(nil, default, _f), do: default
  def fold({:ok, value}, _default, f) when is_function(f), do: f.(value)

  @doc """
  Call a 'void' type of function if the `Maybe` monad is a `'nothing'`.
  `Monad.Maybe.on_nothing/2` returns the `Maybe` as is. No changes are applied.

  _If the `Maybe` has a `'right'` value inside, the function is not invoked._

  ## Example
      iex> Monad.Maybe.on_nothing({:ok, 1}, &IO.inspect/1)
      {:ok, 1}
      iex> Monad.Maybe.on_nothing(nil, fn -> IO.inspect("Empty maybe monad") end)
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
  Call a 'void' type of function if the `Maybe` monad is a `'just'`.
  `Monad.Maybe.on_just/2` returns the `Maybe` as is. No changes are applied.

  _If the `Maybe` has a `'nothing'` value inside, the function is not invoked._

  ## Example
      iex> Monad.Maybe.on_just({:ok, 1}, &IO.inspect/1)
      1
      {:ok, 1}
      iex> Monad.Maybe.on_just(nil, &IO.inspect/1)
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
  Operator for handling `Monad.Maybe.map/2`.

  ## Example
      iex> import Monad.Maybe, only: [~>: 2]
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
  Operator for handling `Monad.Maybe.bind/2`.

  ## Example
      iex> import Monad.Maybe, only: [~>>: 2]
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
      other -> raise(bind_exception(other))
    end
  end

  @doc """
  Operator for handling `Monad.Maybe.fold/3`.

  ## Example
      iex> import Monad.Maybe, only: [<~>: 2]
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

  defp bind_exception(other) do
    "Function provided to `Monad.Maybe.bind/2` should return an `Maybe.t(any())` type, got #{inspect(other)}"
  end
end
