defmodule Productive.Mixfile do
  use Mix.Project

  def project do
    [app: :productive,
     version: "0.3.0",
     build_path: "./_build",
     config_path: "./config/config.exs",
     deps_path: "./deps",
     lockfile: "./mix.lock",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description(),
     package: package(),
     deps: deps()]
  end

  defp description, do: "A workflow library allowing a process to be defined as steps.  Think of a more generic implementation of Plug."

  defp package do
    [
        name: :productive,
        files: [
          "lib",
          "mix.exs",
          "README*",
          "LICENSE*"
        ],
        maintainers: ["C. Jason Harrelson"],
        licenses: ["MIT"],
        links: %{
          "GitHub" => "https://github.com/midas/productive",
          "Docs" => "https://hexdocs.pm/productive/0.3.0"
        }
      ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # To depend on another app inside the umbrella:
  #
  #   {:myapp, in_umbrella: true}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end
end
