defmodule Robotxt do
  @moduledoc """
  Robots.txt parser.

  ## Installation

  Add the following to the `deps` portion of your `mix.exs` file.

  ```
  defp deps do
    [
      {:robotxt, "~> 0.1.3"},
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

  @doc """
  Returns a list of `%Robotxt{}`.

  ## Example

      iex> Robotxt.parse("User-agent: *\\nDisallow:\\n")
      [%Robotxt{user_agent: "*", allow: [], disallow: [""], sitemap: nil}]

      iex> Robotxt.parse("user-agent: *\\ndisallow:\\n")
      [%Robotxt{user_agent: "*", allow: [], disallow: [""], sitemap: nil}]

  """
  @spec parse(binary) :: list(%Robotxt{})
  def parse(body) when is_binary(body) do
    String.split(body, "\n", trim: true)
    |> Stream.reject(&String.starts_with?(&1, "#"))
    |> Stream.map(&String.split(&1, ":", parts: 2))
    |> Stream.map(fn [k, v] -> [String.downcase(k), String.trim(v)] end)
    |> Enum.to_list()
    |> transform()
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

  defp transform(data) when is_list(data), do: transform(data, %Robotxt{}, [])
  defp transform([], %Robotxt{} = txt, state) when is_list(state), do: [txt | state]
  defp transform([[k, v] | tail], %Robotxt{} = txt, state) when is_list(state) do
    cond do
      k == "user-agent" and txt.user_agent == nil ->
        new_txt =
          update_robotxt(k, v, txt)
        transform(tail, new_txt, state)
      k == "user-agent" and txt.user_agent != nil ->
        new_txt =
          update_robotxt(k, v, %Robotxt{})
        transform(tail, new_txt, [txt | state])
      true ->
        new_txt =
          update_robotxt(k, v, txt)
        transform(tail, new_txt, state)
    end
  end

  defp update_robotxt(key, value, %Robotxt{disallow: disallow, allow: allow} = txt) do
    case key do
      "user-agent" ->
        %Robotxt{txt | user_agent: value}

      "disallow" ->
        %Robotxt{txt | disallow: [value | disallow]}

      "allow" ->
        %Robotxt{txt | allow: [value | allow]}

      "sitemap" ->
        %Robotxt{txt | sitemap: value}

      _ -> 
        txt
    end
  end
end
