defmodule JustChatWeb.Router do
  use JustChatWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {JustChatWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", JustChatWeb do
    pipe_through :browser

    live "/", ChatLive, :index
    live "/channel/:id", ChatLive, :show
  end
end
