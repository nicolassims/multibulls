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
    game = BackupAgent.get(gamename) || Game.new
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
    BackupAgent.put(gamename, state1)
    {:reply, Game.view(state1), state1}
  end

  def handle_call({:guess, gamename, user, guess}, _from, state0) do
    state1 = Game.user_guess(state0, user, guess)
    BackupAgent.put(gamename, state1)
    {:reply, Game.view(state1), state1}
  end

  def handle_call({:change_role, gamename, user, role}, _from, state0) do
    state1 = Game.change_role(state0, user, role)
    state2 = Game.all_ready(state1)
    BackupAgent.put(gamename, state2)
    {:reply, Game.view(state2), state2}
  end

  def handle_call({:view, gamename}, _from, state0) do
    view = Game.view(state0)
    BackupAgent.put(gamename, state0)
    {:reply, view, state0}
  end

  def init(game) do
    {:ok, game}
  end
end
