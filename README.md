# WarmFuzzyThing

Simple way of working with `Maybe` and `Either` monads in Elixir. Both monads are setup in a way that allows for easy plug in into an already existing Elixir system since they don't rely on custom structures. Rather they rely on the already established ways of handling data in Elixir.

## Why Warm fuzzy thing?
It's just [a sweeter way](https://www.urbandictionary.com/define.php?term=Warm%20Fuzzy%20Thing) of saying Monad.

## Using
Both `Maybe` and `Either` monads have been setup to use already imposed structures by Elixir/Erlang standards.

The difference is that the `Either` monad is setup for holding errors while the `Maybe` monad only cares if there is a value or not.

In Elixir usually to chain transformations and make sure that each step is correct we might use `with`

```elixir
with {:ok, value1} <- transform_1(input),
     {:ok, value2} <- transform_2(value1),
     {:ok, value3} <- transform_3(value2) do
  # Handle success case
else 
  {:error, reason} -> # Handle error case
end
```

Using `WarmFuzzyThing.Either` this could look something like this
```elixir
input
|> Either.pure()
|> Either.bind(&transform_1/1)
|> Either.bind(&transform_2/1)
|> Either.bind(&transform_3/1)
|> case do
  {:ok, value3} -> # Handle success case
  {:error, reason} -> # Handle error case
end
```

```elixir
iex> alias WarmFuzzyThing.Either
WarmFuzzyThing.Either
iex> {:ok, 1}
|> Either.map(fn v -> v + 1 end)
|> Either.map(fn v -> v + 1 end)
|> Either.map(fn v -> v + 1 end)
|> Either.fold(&WarmFuzzyThing.id/1)
4
```

## Maybe
The `Maybe` monad is a union between two general notions: `Just` and `Nothing` (_the naming is inherited from Haskell and it depicts the idea: "Maybe I have a value, maybe I don't."_).
This means that a `Maybe` monad can either be a `Just` or it can be a `Nothing` (_think of it as a simple `union` between two types_).
A `Just` is represented by the well known success type tuple `{:ok, value} when value: any()`,
where as a `Nothing` is represented by `nil`, since it's the closest Elixir gets to representing "nothing".

`Maybe` exports a set of function for ease of chaining functions (_transformations_):
  - `WarmFuzzyThing.Maybe.fmap/2` - Used for applying a function over the value of a `Maybe` monad;
  - `WarmFuzzyThing.Maybe.bind/2` - Used for applying a function over a value inside a `Maybe` monad that returns a brand new `Maybe` monad;
  - `WarmFuzzyThing.Maybe.fold/3` - Used for either returning a default value or applying a function over the value inside the `Maybe` monad;


```elixir
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
```

This set of function are setup in a way to allow for easy pipelining.

### Example
```elixir
iex> {:ok, "hello"}
...> |> WarmFuzzyThing.Maybe.fmap(fn v -> v <> " world" end)
...> |> WarmFuzzyThing.Maybe.fmap(&String.length/1)
...> |> WarmFuzzyThing.Maybe.bind(fn
...>    v when v <= 20 -> {:ok, v}
...>    _ -> nil
...>  end)
...> |> WarmFuzzyThing.Maybe.fold(&WarmFuzzyThing.id/1)
11
```
`Maybe` exports a set of operators for handling the chaining functions:
  - `~>` represents `WarmFuzzyThing.Maybe.fmap/2`
  - `~>>` represents `WarmFuzzyThing.Maybe.bind/2`
  - `<~>` represents `WarmFuzzyThing.Maybe.fold/3`

```elixir
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
```

## Either
The `Either` monad is a union between two general notions: `Left` and `Right` (_the naming is inherited from Haskell and it depicts the idea: "Either I have this or I have that."_).
This means that an `Either` monad can either be a `Left` or it can be a `Right` (_think of it as a simple `union` between two types_).
A `Right` is represented by the well known success type tuple `{:ok, value} when value: any()`,
where as a `Left` is represented by the well known error type tuple `{:error, reason} when reason: any()`.
Generally a `Right` `Either` represents a successful transformation/operation where as a `Left` `Either` represents an unsuccessful one.

`Either` exports a set of function for ease of chaining functions (_transformations_):
  - `WarmFuzzyThing.Either.fmap/2` - Used for applying a function over the value of a `Either` monad;
  - `WarmFuzzyThing.Either.bind/2` - Used for applying a function over a value inside a `Either` monad that returns a brand new `Either` monad;
  - `WarmFuzzyThing.Either.fold/3` - Used for either returning a default value or applying a function over the value inside the `Either` monad;

```elixir
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
```

This set of function are setup in a way to allow for easy pipelining.

```elixir
iex> {:ok, "hello"}
...> |> WarmFuzzyThing.Either.fmap(fn v -> v <> " world" end)
...> |> WarmFuzzyThing.Either.fmap(&String.length/1)
...> |> WarmFuzzyThing.Either.bind(fn
...>    v when v <= 20 -> {:ok, v}
...>    _ -> {:error, :too_big}
...>  end)
...> |> WarmFuzzyThing.Either.fold(&WarmFuzzyThing.id/1)
11
```

`Either` exports a set of operators for handling the chaining functions:
  - `~>` represents `WarmFuzzyThing.Either.fmap/2`
  - `~>>` represents `WarmFuzzyThing.Either.bind/2`
  - `<~>` represents `WarmFuzzyThing.Either.fold/3`

```elixir
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
```