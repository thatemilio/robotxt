defmodule Robotxt do
  @moduledoc """
  Robots.txt parser.

  ## Installation

  Add the following to the `deps` portion of your `mix.exs` file.

  ```
  defp deps do
    [
      {:robotxt, "~> 0.1.2"},
    ]
  end
  ```

  """

  defstruct user_agent: nil, disallow: [], allow: [], sitemap: nil

  @type t :: %Robotxt{
    user_agent: nil | binary,
    disallow: list | list(binary),
    allow: list | list(binary),
    sitemap: nil | binary
  }

  @user_agent_regex Regex.compile!("user-agent:\s", "ui")
  @comments_regex Regex.compile!("#.+\n?")
  @split_regex Regex.compile!(":\s")

  @doc """
  Returns a list of `%Robotxt{}`.

  ## Example

      iex> Robotxt.parse("User-agent: *\\nDisallow:\\n")
      [%Robotxt{user_agent: "*", allow: [], disallow: [], sitemap: nil}]

      iex> Robotxt.parse("User-agent: *\\ndisallow:\\n")
      [%Robotxt{user_agent: "*", allow: [], disallow: [], sitemap: nil}]

  """
  @spec parse(binary) :: list(%Robotxt{})
  def parse(body) when is_binary(body) do
    Regex.replace(@comments_regex, body, "")
    |> String.split(@user_agent_regex, trim: true)
    |> Stream.map(&String.split(&1, "\n", trim: true))
    |> Stream.map(&List.pop_at(&1, 0))
    |> Stream.map(&transform/1)
    |> Enum.to_list()
  end

  @doc """
  Returns the `%Robotxt{}` for the given `user_agent` if it exists. Otherwise, `nil` is returned.

  ## Example

      iex> Robotxt.get_by_user_agent([%Robotxt{user_agent: "Twitterbot"}], "Twitterbot")
      %Robotxt{user_agent: "Twitterbot", disallow: [], allow: [], sitemap: nil}

      iex> Robotxt.get_by_user_agent([%Robotxt{user_agent: "Twitterbot"}], "nope")
      nil

  """
  @spec get_by_user_agent(list(%Robotxt{}), binary) :: %Robotxt{} | nil
  def get_by_user_agent(list, user_agent) when is_list(list) and is_binary(user_agent) do
    Enum.filter(list, &(&1.user_agent == user_agent)) |> List.first()
  end

  #
  ## Helper functions
  #

  defp transform({user_agent, values}) do
    user_agent = String.trim(user_agent)
    values =
      values
      |> Stream.map(&String.split(&1, @split_regex))
      |> Enum.map(&downcase/1)
    transform(values, %Robotxt{user_agent: user_agent})
  end

  defp transform([[field, value] | tail], %Robotxt{} = state) do
    new_state = update_state([field, value], state)
    transform(tail, new_state)
  end

  defp transform([[_]], %Robotxt{} = state), do: state
  defp transform([], %Robotxt{} = state), do: state

  defp downcase([field, value]), do: [String.downcase(field), value]
  defp downcase([field]), do: [String.downcase(field)]

  defp update_state([field, value], %Robotxt{disallow: disallow, allow: allow} = state) do
    case field do
      "disallow" ->
        %Robotxt{state | disallow: [value | disallow]}

      "allow" ->
        %Robotxt{state | allow: [value | allow]}

      "sitemap" ->
        %Robotxt{state | sitemap: value}

      _ -> 
        state
    end
  end
end
