defmodule Bulls.Game do
  # This module doesn't do stuff,
  # it computes stuff.

  def new(gamename) do
    %{
      gamename: gamename,
      secret: random_secret(),
      guesses: Map.new(),
      tempguesses: Map.new(),
      gamephase: "setup",
      userstatus: Map.new(),
      roundtime: 30,
      lastwinners: [],
      userstats: Map.new()
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
    if (guess == "pass") do
      st
    end
    if (st.gamephase == "playing" # if game is in playing phase
      && Map.fetch!(st.userstatus, user) == "readyplayer" # user is playing
      && is_binary(guess)#if the guess is binary...
      && String.length(guess) == 4#and if the guess is four characters long...
      && !(inspect(st.guesses) =~ guess)#and if the guess is not in the guess list...
      && !String.match?(guess, ~r/^0|(?:([0-9])(.*\1))|\D/)) do#and if the guess has only unique digits, and doesn't begin with 0...

      [matchedplaces, matchednumbers] = calculateAB(guess, st.secret, 0, 0, 0)

      fullGuess = inspect(guess) <> " -- A" <> inspect(matchedplaces) <> "B" <> inspect(matchednumbers)

      stWithNewGuess = case Map.fetch(st.tempguesses, user) do
        {:ok, _guesslist} -> st
        :error -> %{ st | tempguesses: Map.put(st.tempguesses, user, fullGuess) }
      end

      check_win(stWithNewGuess)
    else
      st
    end
  end

  def view(st) do
    if st.gamephase == "setup" do
      %{
        gamephase: st.gamephase,
        lastwinners: st.lastwinners,
        userstats: st.userstats
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

  def all_guessed?(st) do
    !Enum.any?(st.userstatus,
      fn {k, v}
        -> v == "readyplayer"
          && case Map.fetch(st.tempguesses, k) do
                {:ok, _guess} -> false
                :error -> true
          end
      end)
  end

  def secret_guessed?(st) do
    Enum.any?(Map.values(st.guesses),
          fn [lastguess | _rest] -> String.contains?(lastguess, "A4") end)
  end

  # TODO switch to tempguess, add check that all players have guessed
  # or round time is over
  def check_win(st) do
    cond do
      st.gamephase == "playing"
      && all_guessed?(st)
      && secret_guessed?(st)
        -> reset(record_wins(st))# record the win and reset to setup
      all_guessed?(st)
        -> end_round(st)
      true
        -> st
    end
  end

  # updates user win/loss stats and lastwinners
  def record_wins(st) do
    #will become lastwinners
    winnerlist = Enum.reduce(st.guesses, [], fn {k, v}, acc ->
      if (Enum.any?(v, fn x -> String.contains?(x, "A4") end)) do
        [k | acc]
      else
        acc
      end
    end)

    #will become userstats
    newuserstats = Enum.reduce(st.userstats, Map.new(), fn {k, v}, acc ->
      if (Enum.member?(winnerlist, k)) do
        Map.put(acc, k, [Enum.fetch!(v, 0) + 1, Enum.fetch!(v, 1)  + 1])
      else
        Map.put(acc, k, [Enum.fetch!(v, 0), Enum.fetch!(v, 1) + 1])
      end
    end)

    st = %{ st | lastwinners: winnerlist }
    %{ st | userstats: newuserstats }
  end

  #reset to setup phase
  def reset(st) do
    %{ st | gamephase: "setup",
            secret: random_secret(),
            guesses: Map.new(),
            tempguesses: Map.new(),
            roundtime: 30}
  end

  def user_joins(st, name) do
    st = %{ st | userstats: Map.put(st.userstats, name, [0, 0]) }
    %{ st | userstatus: Map.put(st.userstatus, name, "observer") }
  end

  def remove_user(st, name) do
    %{ st | userstatus: elem(Map.pop!(st.userstatus, name), 1) }
  end

  def tick(st) do
    %{ st | roundtime: max(0, st.roundtime - 1)}
  end

  def round_over?(st) do
    st.roundtime == 0
  end

  def end_round(st) do
    st = if (all_guessed?(st)) do
            IO.puts("All players guessed.")
            st
          else
            IO.puts("Not all players guessed.")
            st
            #auto_pass(st)
          end
    if secret_guessed?(st) do
      check_win(st)
    else
      %{ st | roundtime: 30,
        tempguesses: Map.new(),
        guesses: Enum.reduce(st.tempguesses,
          st.guesses,
          fn {k, v}, acc ->
            Map.put(acc, k, [v | Map.get(acc, k)]) end)
        }
    end
  end

  def auto_pass(st) do
    players = Enum.filter(st.userstatus,
      fn {_k, v} -> v == "readyplayer" end)
    newTempguesses = Enum.reduce(players,
      st.tempguesses,
      fn {k, _v}, acc
        -> case Map.fetch(acc, k) do
          {:ok, _guess} -> acc
          :error -> Map.put(acc, k, "pass")
        end
      end)
    %{ st | tempguesses: newTempguesses}
  end
end
