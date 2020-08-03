defmodule Robotxt.MixProject do
  use Mix.Project

  @version "0.1.3"

  def project do
    [
      app: :robotxt,
      version: @version,
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      name: "Robotxt",
      source_url: "https://github.com/thatemilio/robotxt"
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
      {:ex_doc, "~> 0.22.1", only: :dev, runtime: false},
    ]
  end

  defp description do
    "Robots.txt parser."
  end


  defp package do
    [
      files: ~w(lib README.md mix.exs .formatter.exs),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/thatemilio/robotxt"}
    ]
  end
end
