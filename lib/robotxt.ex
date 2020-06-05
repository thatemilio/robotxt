defmodule Robotxt do
  @moduledoc """
  Robots.txt parser.

  ## Installation

  Add the following to the `deps` portion of your `mix.exs` file.

  ```
  defp deps do
    [
      {:robotxt, "~> 0.1.0"},
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
  @valid_fields ~w(Disallow: Allow: Sitemap:)

  @doc """
  Returns a list of `%Robotxt{}`.

  ## Example

      iex> Robotxt.parse("User-agent: *\\nDisallow:\\n")
      [%Robotxt{user_agent: "*", allow: [], disallow: [], sitemap: nil}]

  """
  @spec parse(binary) :: list(%Robotxt{})
  def parse(body) when is_binary(body) do
    Regex.replace(@comments_regex, body, "")
    |> String.split(@user_agent_regex, trim: true)
    |> Stream.map(&String.split/1)
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

  defp transform(tuple) when is_tuple(tuple) do
    key = elem(tuple, 0)
    values = elem(tuple, 1)
    transform(values, %Robotxt{user_agent: key})
  end

  defp transform([field, value | tail], %Robotxt{} = state) when field in @valid_fields do
    new_state = update_state(field, value, state)
    transform(tail, new_state)
  end

  defp transform([_], %Robotxt{} = state), do: state
  defp transform([], %Robotxt{} = state), do: state

  defp update_state(field, value, %Robotxt{disallow: disallow, allow: allow} = state) do
    case field do
      "Disallow:" ->
        %Robotxt{state | disallow: [value | disallow]}

      "Allow:" ->
        %Robotxt{state | allow: [value | allow]}

      "Sitemap:" ->
        %Robotxt{state | sitemap: value}
    end
  end
end
