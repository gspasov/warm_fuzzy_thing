defmodule Monad do
  @moduledoc """
  Provides a way of working with already known Elixir constructs through monads.

  `Monad.Maybe` represents the Union `nil | {:ok, value} when value: any()`.

  `Monad.Either` represents the Union `{:error, reason} | {:ok, value} when reason: any(), value: any()`.

  _To understand more about their general idea and implementation details, head over to their respective documentation._
  """

  alias Monad.Either
  alias Monad.Maybe

  @type t(a) :: Either.t(any(), a) | Maybe.t(a)

  @callback pure(a) :: Monad.t(a) when a: any()
  @callback fmap(Monad.t(a), (a -> b)) :: Monad.t(b) when a: any(), b: any()
  @callback bind(Monad.t(a), (a -> Monad.t(b))) :: Monad.t(b) when a: any(), b: any()
  @callback fold(Monad.t(a), default :: b, (a -> b)) :: b when a: any(), b: any()
  @callback sequence([Monad.t(a)]) :: Monad.t([a]) when a: any()

  @doc """
  Functions that return the value itself.

  ## Example
      iex> Monad.id(10)
      10
      iex> Monad.id({:ok, 10})
      {:ok, 10}
      iex> Monad.id({:error, :not_found})
      {:error, :not_found}
      iex> Monad.id(nil)
      nil
  """
  @spec id(value) :: value when value: any()
  def id(value), do: value

  @doc """
  Converts a `Monad.Maybe` to `Monad.Either`

  ## Example
      iex> Monad.maybe_to_either({:ok, 1}, :not_found)
      {:ok, 1}
      iex> Monad.maybe_to_either(nil, :not_found)
      {:error, :not_found}
  """
  @spec maybe_to_either(Maybe.t(value), reason) :: Either.t(reason, value)
        when value: any(),
             reason: any()
  def maybe_to_either(maybe, reason)

  def maybe_to_either(nil, reason), do: {:error, reason}
  def maybe_to_either({:ok, value}, _), do: {:ok, value}

  @doc """
  Converts a `Monad.Either` to `Monad.Maybe`

  ## Example
      iex> Monad.either_to_maybe({:ok, 1})
      {:ok, 1}
      iex> Monad.either_to_maybe({:error, :not_found})
      nil
  """
  @spec either_to_maybe(Either.t(reason, value)) :: Maybe.t(value)
        when value: any(),
             reason: any()
  def either_to_maybe(either)
  def either_to_maybe({:error, _reason}), do: nil
  def either_to_maybe({:ok, value}), do: {:ok, value}
end
