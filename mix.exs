defmodule Giraffe.MixProject do
  use Mix.Project

  def project do
    [
      app: :giraffe,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.cobertura": :test
      ]
    ]
  end

  def package do
    [
      files: ["test", "lib", "mix.exs", "README.md", "LICENSE*"],
      maintainers: ["Dunya Kirkali"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/dunyakirkali/giraffe.ex"}
    ]
  end

  def description do
    """
    Giraffe is a graph library for Elixir.
    """
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
      {:excoveralls, "~> 0.18", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
