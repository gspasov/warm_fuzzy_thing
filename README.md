# Monad

Simple way of working with `Maybe` and `Either` monads in Elixir.

## Maybe
`Maybe` corresponds to `nil | {:ok, any()}`

## Either
`Either` corresponds to `{:error, any()} | {:ok, any()}`

## Using
Both `Maybe` and `Either` monads have been setup to use already imposed structures by Elixir/Erlang standards.

The difference is that the `Either` monad is setup for holding errors while the `Maybe` monad only cares if there is a value or not.

```elixir

iex> alias Monad.Either
Monad.Either
iex> {:ok, 1}
|> Either.map(fn v -> v + 1 end)
|> Either.map(fn v -> v + 1 end)
|> Either.map(fn v -> v + 1 end)
|> Either.fold(0)
4
```