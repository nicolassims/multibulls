defmodule Bulls.GameServer do
  use GenServer

  alias Bulls.BackupAgent
  alias Bulls.Game

  # Interface

  def reg(gamename) do
    {:via, Registry, {Bulls.GameReg, gamename}}
  end

  def start(gamename) do
    spec = %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [gamename]},
      restart: :permanent,
      type: :worker
    }
    Bulls.GameSup.start_child(spec)
  end

  def start_link(gamename) do
    game = BackupAgent.get(gamename) || Game.new("game:" <> gamename)
    GenServer.start_link(
      __MODULE__,
      game,
      name: reg(gamename)
    )
  end

  def user_join(gamename, user) do
    GenServer.call(reg(gamename), {:user_join, gamename, user})
  end

  def user_leave(gamename, user) do
    GenServer.call(reg(gamename), {:user_leave, gamename, user})
  end

  def guess(gamename, user, guess) do
    GenServer.call(reg(gamename), {:guess, gamename, user, guess})
  end

  def change_role(gamename, user, role) do
    GenServer.call(reg(gamename), {:change_role, gamename, user, role})
  end

  def view(gamename) do
    GenServer.call(reg(gamename), {:view, gamename})
  end

  # Implementation

  def handle_call({:user_join, gamename, user}, _from, state0) do
    state1 = Game.user_joins(state0, user)
    BackupAgent.put(gamename, state1)
    {:reply, Game.view(state1), state1}
  end

  def handle_call({:user_leave, gamename, user}, _from, state0) do
    state1 = Game.remove_user(state0, user)

    state2 = Game.game_stuck(state1)

    BackupAgent.put(gamename, state2)
    {:reply, Game.view(state2), state2}
  end

  def handle_call({:guess, gamename, user, guess}, _from, state0) do
    state1 = Game.user_guess(state0, user, guess)
    BackupAgent.put(gamename, state1)
    {:reply, Game.view(state1), state1}
  end

  def handle_call({:change_role, gamename, user, role}, _from, state0) do
    if state0.gamephase == "setup" do
      state1 = Game.change_role(state0, user, role)
      state2 = Game.all_ready(state1)

      if state2.gamephase == "playing" do
        Process.send_after(self(), :update_clock, 1_000)
        Process.send_after(self(), :end_round, 30_000)
      end

      BackupAgent.put(gamename, state2)
      {:reply, Game.view(state2), state2}
    else
      {:reply, Game.view(state0), state0}
    end
  end

  def handle_call({:view, gamename}, _from, state0) do
    view = Game.view(state0)
    BackupAgent.put(gamename, state0)
    {:reply, view, state0}
  end

  def handle_info(:end_round, state0) do
    if Game.round_over?(state0) do
      Process.send_after(self(), :end_round, 30_000)
      state1 = Game.end_round(state0)
      BullsWeb.Endpoint.broadcast(state1.gamename, "view", Game.view(state1))
      {:noreply, state1}
    else
      Process.send_after(self(), :end_round, 1_000)
      {:noreply, state0}
    end
  end

  def handle_info(:update_clock, state0) do
    Process.send_after(self(), :update_clock, 1_000)
    state1 = Game.tick(state0)
    BullsWeb.Endpoint.broadcast(state1.gamename, "view", Game.view(state1))
    {:noreply, state1}
  end

  def init(game) do
    {:ok, game}
  end
end
