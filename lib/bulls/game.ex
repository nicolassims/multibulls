defmodule Bulls.Game do
  # This module doesn't do stuff,
  # it computes stuff.

  def new do
    %{
      secret: random_secret(),
      guesses: MapSet.new(),
    }
  end

  def calculateAB(num, secret, index, places, numbers) do
    cond do
      index == 4
        -> [places, numbers]#if the list is on its last character, return
      binary_part(secret, index, 1) == binary_part(num, index, 1)
        -> calculateAB(num, secret, index + 1, places + 1, numbers)
      secret =~ binary_part(num, index, 1)
        -> calculateAB(num, secret, index + 1, places, numbers + 1)
      true
        -> calculateAB(num, secret, index + 1, places, numbers)
    end
  end

  def guess(st, guess) do
    if (is_binary(guess)#if the guess is binary...
      && String.length(guess) == 4#and if the guess is four characters long...
      && !(inspect(st.guesses) =~ guess)#and if the guess is not in the guess list...
      && !String.match?(guess, ~r/^0|(?:([0-9])(.*\1))|\D/)) do#and if the guess has only unique digits, and doesn't begin with 0...

      [matchedplaces, matchednumbers] = calculateAB(guess, st.secret, 0, 0, 0)

      fullGuess = inspect(guess) <> " -- A" <> inspect(matchedplaces) <> "B" <> inspect(matchednumbers)

      %{ st | guesses: MapSet.put(st.guesses, fullGuess) }
    else
      st
    end
  end

  def view(st) do
    %{
      guesses: MapSet.to_list(st.guesses),
    }
  end

  def assign_random(num) do
    numbers = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
    if (Enum.count(num) == 0) do
      num ++ [Enum.random(numbers -- ["0"])]
    else
      num ++ [Enum.random(numbers -- num)]
    end
  end

  def random_secret() do
    []#there's definitely a way to do this that isn't calling the same function four times...
    |> assign_random()#but this doesn't seem overly offensive, so it stays.
    |> assign_random()
    |> assign_random()
    |> assign_random()
    |> to_string()
  end
end
