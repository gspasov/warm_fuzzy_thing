defmodule Monad do
  alias Monad.Either
  alias Monad.Maybe

  @spec maybe_to_either(Maybe.t(value), reason) :: Either.t(reason, value)
        when value: any(),
             reason: any()
  def maybe_to_either(maybe, reason)

  def maybe_to_either(nil, reason), do: {:error, reason}
  def maybe_to_either({:ok, value}, _), do: {:ok, value}

  @spec either_to_maybe(Either.t(reason, value)) :: Maybe.t(value)
        when value: any(),
             reason: any()
  def either_to_maybe(either)
  def either_to_maybe({:error, _reason}), do: nil
  def either_to_maybe({:ok, value}), do: {:ok, value}
end
