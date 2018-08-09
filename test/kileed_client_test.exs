defmodule KileedClientTest do
  use ExUnit.Case
  doctest KileedClient

  test "greets the world" do
    assert KileedClient.hello() == :world
  end
end
