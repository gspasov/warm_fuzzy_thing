defmodule Monad.Either do
  @moduledoc """
  Monad that either holds a `value` or it holds an `error`.
  The value is wrapped in the well known pattern of _`{:ok, any()}`_.
  Otherwise `Either` holds an `error` value in the well known pattern of _`{:error, any()}`_

  ## Example
      iex> Monad.Either.map({:ok, 1}, fn v -> v + 1 end)
      {:ok, 2}
      iex> Monad.Either.map({:error, :not_a_number}, fn v -> v + 1 end)
      {:error, :not_a_number}
      iex> Monad.Either.bind({:ok, 1}, fn v -> {:ok, v + 1} end)
      {:ok, 2}
      iex> Monad.Either.bind({:error, :not_a_number}, fn v -> {:ok, v + 1} end)
      {:error, :not_a_number}
      iex> Monad.Either.bind({:ok, 1}, fn v -> {:error, :not_a_number} end)
      {:error, :not_a_number}
  """

  alias Monad.Either

  @type t(reason, value) :: {:error, reason} | {:ok, value}

  @doc """
  Apply a function over the `'right'` portion (_the "success" value_) of an `Either` monad.
  The result of the function will be the `new` `'right'` portion of the `Either` monad.

  If an `Either` monad with a `'left'` value is passed, the function is not invoked,
  `Monad.Either.map/2` just return the `'left'` value.

  ## Example
      iex> Monad.Either.map({:ok, 1}, fn v -> v + 1 end)
      {:ok, 2}
      iex> Monad.Either.map({:ok, "hello"}, fn _v -> "world" end)
      {:ok, "world"}
      iex> Monad.Either.map({:ok, "hello"}, &String.length/1)
      {:ok, 5}
      iex> Monad.Either.map({:error, :not_a_number}, fn v -> v + 1 end)
      {:error, :not_a_number}
  """
  @spec map(Either.t(reason, value), function) :: Either.t(reason, new_value)
        when reason: any(),
             value: any(),
             function: (value -> new_value),
             new_value: any()
  def map({:error, reason}, _f), do: {:error, reason}
  def map({:ok, value}, f) when is_function(f), do: {:ok, f.(value)}

  @doc """
  Apply a function over the `'right'` portion (_the "success" value_) of an `Either` monad.
  The result of the function will be a brand new `Either` monad.
  This means that the value inside the monad can change from `'left'` to `'right'` and vice versa.

  If an `Either` monad with a `'left'` value is passed, the function is not invoked,
  `Monad.Either.bind/2` just return the `'left'` value.

  ## Example
      iex> Monad.Either.bind({:ok, 1}, fn v -> {:ok, v + 1} end)
      {:ok, 2}
      iex> Monad.Either.bind({:ok, "hello"}, fn _v -> {:ok, "world"} end)
      {:ok, "world"}
      iex> Monad.Either.bind({:ok, "hello"}, &({:ok, String.length(&1)}))
      {:ok, 5}
      iex> Monad.Either.bind({:ok, "hello"}, fn _v -> {:error, "something went wrong"} end)
      {:error, "something went wrong"}
      iex> Monad.Either.map({:error, :not_a_number}, fn v -> {:ok, v + 1} end)
      {:error, :not_a_number}
  """
  @spec bind(Either.t(reason, value), function) :: new_either
        when reason: any(),
             value: any(),
             function: (value -> new_either),
             new_either: Either.t(new_reason, new_value),
             new_value: any(),
             new_reason: any()
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
      iex> Monad.Either.fold({:ok, 1}, fn v -> v + 1 end)
      2
      iex> Monad.Either.fold({:ok, "hello"}, fn _v -> "world" end)
      "world"
      iex> Monad.Either.fold({:ok, "hello"}, &String.length/1)
      5
      iex> Monad.Either.fold({:error, :not_a_number}, fn v -> v + 1 end)
      nil
      iex> Monad.Either.fold({:error, :not_a_number}, :not_found, fn v -> v + 1 end)
      :not_found
  """
  @spec fold(Either.t(reason, value), default :: new_value, function) :: new_value
        when reason: any(),
             value: any(),
             function: (value -> new_value),
             new_value: any()
  def fold(input, default \\ nil, function)

  def fold({:error, _reason}, default, _f), do: default
  def fold({:ok, value}, _default, f) when is_function(f), do: f.(value)

  @doc """
  Call a 'void' type of function if the `Either` monad is a `'left'`.
  `Monad.Either.on_left/2` returns the `Either` as is. No changes are applied.

  _If the `Either` has a `'right'` value inside, the function is not invoked._

  ## Example
      iex> Monad.Either.on_left({:ok, 1}, &IO.inspect/1)
      {:ok, 1}
      iex> Monad.Either.on_left({:error, :not_a_number}, &IO.inspect/1)
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
  `Monad.Either.on_right/2` returns the `Either` as is. No changes are applied.

  _If the `Either` has a `'left'` value inside, the function is not invoked._

  ## Example
      iex> Monad.Either.on_right({:ok, 1}, &IO.inspect/1)
      1
      {:ok, 1}
      iex> Monad.Either.on_right({:error, :not_a_number}, &IO.inspect/1)
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
  Operator for handling `Monad.Either.map/2`.

  ## Example
      iex> import Monad.Either, only: [~>: 2]
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
  Operator for handling `Monad.Either.bind/2`.

  ## Example
      iex> import Monad.Either, only: [~>>: 2]
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
  Operator for handling `Monad.Either.fold/3`.

  ## Example
      iex> import Monad.Either, only: [<~>: 2]
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
    "Function provided to `Monad.Either.bind/2` should return an `Either.t(any(), any())` type, got #{inspect(other)}"
  end
end
