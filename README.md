# Monad

Simple way of working with `Maybe` and `Either` monads in Elixir. Both monads are setup in a way that allows for easy plug in into an already existing Elixir system since they don't rely on custom structures. Rather they rely on the already established ways of handling data in Elixir.

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
|> Either.fold(&Monad.id/1)
4
```

## Maybe
The `Maybe` monad is a union between two general notions: `Just` and `Nothing` (_the naming is inherited from Haskell and it depicts the idea: "Maybe I have a value, maybe I don't."_).
This means that a `Maybe` monad can either be a `Just` or it can be a `Nothing` (_think of it as a simple `union` between two types_).
A `Just` is represented by the well known success type tuple `{:ok, value} when value: any()`,
where as a `Nothing` is represented by `nil`, since it's the closest Elixir gets to representing "nothing".

`Maybe` exports a set of function for ease of chaining functions (_transformations_):
  - `Monad.Maybe.fmap/2` - Used for applying a function over the value of a `Maybe` monad;
  - `Monad.Maybe.bind/2` - Used for applying a function over a value inside a `Maybe` monad that returns a brand new `Maybe` monad;
  - `Monad.Maybe.fold/3` - Used for either returning a default value or applying a function over the value inside the `Maybe` monad;


```elixir
iex> Monad.Maybe.fmap({:ok, 1}, fn v -> v + 1 end)
{:ok, 2}
iex> Monad.Maybe.fmap(nil, fn v -> v + 1 end)
nil
iex> Monad.Maybe.bind({:ok, 1}, fn v -> {:ok, v + 1} end)
{:ok, 2}
iex> Monad.Maybe.bind(nil, fn v -> {:ok, v + 1} end)
nil
iex> Monad.Maybe.bind({:ok, 1}, fn v -> nil end)
nil
iex> Monad.Maybe.fold({:ok, 1}, &Monad.id/1)
1
iex> Monad.Maybe.fold(nil, &Monad.id/1)
nil
iex> Monad.Maybe.fold(nil, :empty, &Monad.id/1)
:empty
```

This set of function are setup in a way to allow for easy pipelining.

### Example
```elixir
iex> {:ok, "hello"}
...> |> Monad.Maybe.fmap(fn v -> v <> " world" end)
...> |> Monad.Maybe.fmap(&String.length/1)
...> |> Monad.Maybe.bind(fn
...>    v when v <= 20 -> {:ok, v}
...>    _ -> nil
...>  end)
...> |> Monad.Maybe.fold(&Monad.id/1)
11
```
`Maybe` exports a set of operators for handling the chaining functions:
  - `~>` represents `Monad.Maybe.fmap/2`
  - `~>>` represents `Monad.Maybe.bind/2`
  - `<~>` represents `Monad.Maybe.fold/3`

```elixir
iex> import Monad.Maybe, only: [~>: 2, ~>>: 2, <~>: 2]
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
...> <~> {0, &Monad.id/1}
29
```

## Either
The `Either` monad is a union between two general notions: `Left` and `Right` (_the naming is inherited from Haskell and it depicts the idea: "Either I have this or I have that."_).
This means that an `Either` monad can either be a `Left` or it can be a `Right` (_think of it as a simple `union` between two types_).
A `Right` is represented by the well known success type tuple `{:ok, value} when value: any()`,
where as a `Left` is represented by the well known error type tuple `{:error, reason} when reason: any()`.
Generally a `Right` `Either` represents a successful transformation/operation where as a `Left` `Either` represents an unsuccessful one.

`Either` exports a set of function for ease of chaining functions (_transformations_):
  - `Monad.Either.fmap/2` - Used for applying a function over the value of a `Either` monad;
  - `Monad.Either.bind/2` - Used for applying a function over a value inside a `Either` monad that returns a brand new `Either` monad;
  - `Monad.Either.fold/3` - Used for either returning a default value or applying a function over the value inside the `Either` monad;

```elixir
iex> Monad.Either.fmap({:ok, 1}, fn v -> v + 1 end)
{:ok, 2}
iex> Monad.Either.fmap({:error, :not_found}, fn v -> v + 1 end)
{:error, :not_found}
iex> Monad.Either.bind({:ok, 1}, fn v -> {:ok, v + 1} end)
{:ok, 2}
iex> Monad.Either.bind({:error, :not_found}, fn v -> {:ok, v + 1} end)
{:error, :not_found}
iex> Monad.Either.bind({:ok, 1}, fn v -> {:error, :not_found} end)
{:error, :not_found}
iex> Monad.Either.fold({:ok, 1}, &Monad.id/1)
1
iex> Monad.Either.fold({:error, :not_found}, &Monad.id/1)
nil
iex> Monad.Either.fold({:error, :not_found}, :empty, &Monad.id/1)
:empty
```

This set of function are setup in a way to allow for easy pipelining.

```elixir
iex> {:ok, "hello"}
...> |> Monad.Either.fmap(fn v -> v <> " world" end)
...> |> Monad.Either.fmap(&String.length/1)
...> |> Monad.Either.bind(fn
...>    v when v <= 20 -> {:ok, v}
...>    _ -> {:error, :too_big}
...>  end)
...> |> Monad.Either.fold(&Monad.id/1)
11
```

`Either` exports a set of operators for handling the chaining functions:
  - `~>` represents `Monad.Either.fmap/2`
  - `~>>` represents `Monad.Either.bind/2`
  - `<~>` represents `Monad.Either.fold/3`

```elixir
iex> import Monad.Either, only: [~>: 2, ~>>: 2, <~>: 2]
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
...> <~> {0, &Monad.id/1}
29
```