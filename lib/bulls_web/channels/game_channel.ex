defmodule BullsWeb.GameChannel do
  use BullsWeb, :channel

  alias Bulls.GameServer

  #TODO add calls to a GameServer module

  @impl true
  def join("game:" <> name, payload, socket) do
    GameServer.start(name)
    GameServer.user_join(name, payload)
    view = GameServer.view(name)

    socket = socket
    |> assign(:name, name)
    |> assign(:user, payload)

    {:ok, view, socket}
  end

  @impl true
  def handle_in("guess", %{"num" => ll}, socket) do
    user = socket.assigns(:user)
    game = socket.assigns(:name)

    GameServer.guess(game, user, ll)

    view = GameServer.view(game)
    {:reply, {:ok, view}, socket}
  end

  # User wants to reset to login page
  @impl true
  def handle_in("reset", _payload, socket) do
    IO.puts("Starting channel handler")
    user = socket.assigns(:user)
    game = socket.assigns(:name)
    IO.puts("About to remove user")
    view = GameServer.user_leave(game, user)

    {:reply, {:ok, view}, socket}
    #{:stop, {:shutdown, :left}, socket}

    #game = Game.new
    #socket = assign(socket, :game, game)
    #view = Game.view(game)
    #{:reply, {:ok, view}, socket}
  end

  @impl true
  def handle_in("change role", %{"role" => role}, socket) do
    user = socket.assigns(:user)
    game = socket.assigns(:name)

    changed = GameServer.change_role(game, user, role)
    view = GameServer.view(game)

    if changed do
      {:reply, {:ok, view}, socket}
    else
      {:reply, {:error, "Change Denied"}, socket}
    end

    #game0 = BackupAgent.get(socket0.assigns[:name]) || socket0.assigns[:game]
    #if game0.gamephase == "setup" do
    #  game1 = Game.change_role(game0, user, role)
    #  game1 = Game.all_ready(game1)

    #  socket1 = assign(socket0, :game, game1)
    #  BackupAgent.put(socket1.assigns[:name], game1)
    #  view = Game.view(game1)
    #  {:reply, {:ok, view}, socket1}
    #end
  end
end
