defmodule JustChat.Rooms do
  @moduledoc """
  Handles chat rooms
  """

  @doc """
  Validates a chat room name

  ## Examples
      iex> Rooms.validate_room_name("tech-talk")
      :ok

      iex> Rooms.validate_room_name("")
      :empty

      iex> Rooms.validate_room_name("very-long-name-that-is-more-than-30-chars-long")
      :too_long

      iex> Rooms.validate_room_name("name with spaces")
      :invalid_characters
  """
  def validate_room_name(""), do: :empty

  def validate_room_name(name) when byte_size(name) > 30, do: :too_long

  def validate_room_name(name) do
    if Regex.match?(~r/^[a-zA-Z0-9_-]+$/, name) do
      :ok
    else
      :invalid_characters
    end
  end
end
