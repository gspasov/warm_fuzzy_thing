defmodule WarmFuzzyThing.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/gspasov/warm_fuzzy_thing"
  @authors ["Georgi Spasov"]

  def project do
    [
      app: :warm_fuzzy_thing,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "WarmFuzzyThing",
      description: "A way of using Either and Maybe monads in Elixir",
      source_url: @source_url,
      package: package(),
      docs: docs()
    ]
  end

  defp docs do
    [
      main: "readme",
      authors: @authors,
      formatters: ["html"],
      source_url: @source_url,
      source_ref: "v#{@version}",
      extras: extras()
    ]
  end

  defp extras do
    [
      "README.md": [title: "Overview"],
      LICENSE: [title: "License"]
    ]
  end

  defp package do
    [
      maintainers: @authors,
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url
      }
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},

      # Documentation dependencies
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
    ]
  end
end
