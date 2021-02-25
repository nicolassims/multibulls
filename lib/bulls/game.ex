defmodule Bulls.Game do
  # This module doesn't do stuff,
  # it computes stuff.

  def new do
    %{
      secret: random_secret(),
      guesses: Map.new(),
      tempguesses: MapSet.new(),
      gamephase: "setup",
      userstatus: Map.new(),
      roundtime: 30,
      lastwinners: [],
      userstats: MapSet.new()
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

  def user_guess(st, user, guess) do
    if (is_binary(guess)#if the guess is binary...
      && String.length(guess) == 4#and if the guess is four characters long...
      && !(inspect(st.guesses) =~ guess)#and if the guess is not in the guess list...
      && !String.match?(guess, ~r/^0|(?:([0-9])(.*\1))|\D/)) do#and if the guess has only unique digits, and doesn't begin with 0...

      [matchedplaces, matchednumbers] = calculateAB(guess, st.secret, 0, 0, 0)

      fullGuess = inspect(guess) <> " -- A" <> inspect(matchedplaces) <> "B" <> inspect(matchednumbers)

      case Map.fetch(st.guesses, user) do
        {:ok, guesslist} -> %{ st | guesses: Map.put(st.guesses, user, [ fullGuess | guesslist]) }
        :error -> %{ st | guesses: Map.put(st.guesses, user, [ fullGuess ]) }
      end
    else
      st
    end
  end

  def view(st) do
    if st.gamephase == "setup" do
      %{
        gamephase: st.gamephase,
        lastwinners: st.lastwinners,
        userstats: MapSet.to_list(st.userstats)
      }
    else
      %{
        gamephase: st.gamephase,
        guesses: inspect(Map.to_list(st.guesses)),
        roundtime: st.roundtime
      }
    end
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

  # changes a users role into a chosen observer, readying, or ready player
  # assumes this is during setup phase
  def change_role(st, user, role) do
    fetch = Map.fetch(st.userstatus, user)
    if ((role == "readyingplayer" && {:ok, "observer"} == fetch)
      || (role == "readyplayer" && {:ok, "readyingplayer"} == fetch)
      || (role == "observer")) do
      %{ st | userstatus: Map.put(st.userstatus, user, role) }
    else
      st
    end
  end

  def all_ready(st) do
    if(Enum.any?(st.userstatus, fn {_k, v} ->#if any of your players...
        v == "readyplayer"#are ready...
      end) && !Enum.any?(st.userstatus, fn {_k, v} ->
        v == "readyingplayer"
      end)) do
      %{ st | gamephase: "playing" }#then the game can begin to play
    else#otherwise...
      %{ st | gamephase: "setup" }#you're still in the setup phase
    end
  end

  # if there are no active players in 'playing' phase
  def game_stuck(st) do
    if st.gamephase == "playing"
    && !Enum.any?(st.userstatus, fn {_k, v} -> v == "readyplayer" end) do
      reset(st)
    else
      st
    end
  end

  # updates user win/loss stats
  @spec record_wins(any) :: any
  def record_wins(st) do
    #TODO implement
    st
  end

  #reset to setup phase
  def reset(st) do
    %{ st | gamephase: "setup",
              secret: random_secret(),
              guesses: Map.new()}
  end

  def user_joins(st, name) do
    IO.inspect(st.userstatus)
    %{ st | userstatus: Map.put(st.userstatus, name, "observer") }
  end

  def remove_user(st, name) do
    %{ st | userstatus: elem(Map.pop!(st.userstatus, name), 1) }
  end
end
