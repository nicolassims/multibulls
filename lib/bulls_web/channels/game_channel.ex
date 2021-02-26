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
    user = socket.assigns[:user]
    game = socket.assigns[:name]

    GameServer.guess(game, user, ll)

    view = GameServer.view(game)
    broadcast(socket, "view", view)
    {:reply, {:ok, view}, socket}
  end

  # User wants to reset to login page
  @impl true
  def handle_in("reset", _payload, socket) do
    user = socket.assigns[:user]
    game = socket.assigns[:name]
    view = GameServer.user_leave(game, user)
    broadcast(socket, "view", view)
    {:reply, {:ok, view}, socket}
  end

  @impl true
  def handle_in("change role", %{"role" => role}, socket) do
    user = socket.assigns[:user]
    game = socket.assigns[:name]

    changed = GameServer.change_role(game, user, role)
    view = GameServer.view(game)
    broadcast(socket, "view", view)

    if changed do
      {:reply, {:ok, view}, socket}
    else
      {:reply, {:error, "Change Denied"}, socket}
    end
  end
end
