defmodule ChatWeb.PageController do
  use ChatWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def ping(conn, params) do
    Ping.render_pixel(conn, params)
  end
end
