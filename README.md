# Monad

A way of writing `Monad` in Elixir

## Using
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