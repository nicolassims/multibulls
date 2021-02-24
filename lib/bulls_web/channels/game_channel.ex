defmodule BullsWeb.GameChannel do
  use BullsWeb, :channel

  alias Bulls.Game
  alias Bulls.BackupAgent

  #TODO add calls to a GameServer module

  @impl true
  def join("game:" <> name, payload, socket) do
    game = BackupAgent.get(name) || Game.new
    game = Game.user_joins(game, payload)
    socket = socket
    |> assign(:name, name)
    |> assign(:game, game)
    BackupAgent.put(name, game)
    view = Game.view(game)
    {:ok, view, socket}
  end

  @impl true
  def handle_in("guess", %{"num" => ll}, socket0) do
    game0 = BackupAgent.get(socket0.assigns[:name]) || socket0.assigns[:game]
    game1 = Game.guess(game0, ll)
    socket1 = assign(socket0, :game, game1)
    BackupAgent.put(socket0.assigns[:name], game1)
    view = Game.view(game1)
    broadcast(socket1, "view", view)
    {:reply, {:ok, view}, socket1}
  end

  @impl true
  def handle_in("reset", username, socket) do
    game0 = BackupAgent.get(socket.assigns[:name]) || socket.assigns[:game]
    socket = assign(socket, :game, game0)
    view = Game.remove_user(game0, username)
    view = Game.view(view)
    broadcast(socket, "view", view)
    {:reply, {:ok, view}, socket}
  end

  @impl true
  def handle_in("change role", %{"user" => user, "role" => role}, socket0) do
    game0 = BackupAgent.get(socket0.assigns[:name]) || socket0.assigns[:game]
    if game0.gamephase == "setup" do
      game1 = Game.change_role(game0, user, role)
      game1 = Game.all_ready(game1)

      socket1 = assign(socket0, :game, game1)
      BackupAgent.put(socket1.assigns[:name], game1)
      view = Game.view(game1)
      broadcast(socket1, "view", view)
      {:reply, {:ok, view}, socket1}
    end
  end
end
