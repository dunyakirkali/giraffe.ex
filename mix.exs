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
      package: package()
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
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
