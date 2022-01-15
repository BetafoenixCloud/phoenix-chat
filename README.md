# Phoenix Chat Example

A Step-by-Step Tutorial for building, testing and deploying a Chat app in Phoenix!

## Why?

Chat apps are the "Hello World" of "real time" examples.

## What?

A simple step-by-step tutorial showing you

This example is meant to be as beginner friendly as possible.

## How?

These instructions show you how to _create_ the Chat app
_from scratch_.

If you prefer to _run_ the existing/sample app,
scroll down to the "Run On Localhost" section instead.

### 0. Pre-requisites

+ Install Elixir & Erlang on your local machine.
see: https://github.com/dwyl/learn-elixir#installation
e.g:
```sh
brew install elixir
```
+ Basic Elixir Syntax knowledge will help,
see: https://elixir-lang.org/getting-started/introduction.html
+ Phoenix installed.
see: https://hexdocs.pm/phoenix/installation.html
e.g:
```sh
mix archive.install https://github.com/phoenixframework/archives/raw/master/phx_new.ez
```
+ PostgreSQL installed.
https://github.com/dwyl/learn-postgresql#installation

#### Check You Have Everything _Before_ Starting

Check you have the latest version of Elixir:
```sh
elixir -v
```

You should see something like:
```sh
Erlang/OTP 20 [erts-9.2] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Elixir 1.5.3
```

Check you have the latest version Phoenix:
```sh
mix phx.new -v
```
You should see:
```sh
Phoenix v1.3.0
```


### 1. Create App

In your terminal on localhost,
type the following command to create the app.

```sh
mix phx.new chat
```
That will create the directory structure and files. <br />

When asked to "Fetch and install dependencies? [Yn]",<br />
Type "y" in your terminal,
followed by the `[Enter]` / `[Return]` key.

You should see:
![fetch-and-install-dependencies](https://user-images.githubusercontent.com/194400/34833220-d219221c-f6e6-11e7-88d6-87aa4c3054e4.png)



### 2. Create/Configure Database

Follow the steps/instructions given in your terminal:

Change into the project directory if you haven't already.

```sh
cd chat
```
> Note: if you cloned this project from GitHub instead creating it from scratch,
> run: `cd phoenix-chat-example` instead. The rest is the same.

```sh
mix ecto.create
```
You should see:
```sh
The database for Chat.Repo has been created
```

### 3. Create the "Channel"

Generate the (WebSocket) channel to be used in the chat app:

```sh
mix phx.gen.channel chat_room
```

This will create a couple of files:<br />
```sh
* creating lib/chat_web/channels/chat_room_channel.ex
* creating test/chat_web/channels/chat_room_channel_test.exs
```

And inform you that you need to copy-paste a piece of code into your app: <br />
```sh
Add the channel to your `/lib/chat_web/channels/user_socket.ex` handler, for example:

    channel "chat_room:lobby", ChatWeb.ChatRoomChannel
```
Copy that line,
Open the file called `/lib/chat_web/channels/user_socket.ex`
and paste it it


### 4. Update Template File

Open the file:
`/lib/chat_web/templates/layout/app.html.eex`
and add the following code:



### 5. Import Scocket in App.js

Open:
`/assets/js/app.js`
and uncomment the line:
```js
import socket from "./socket"
```
with the line _uncommented_ our app will import the `socket.js` file
which will give us WebSocket functionality.


### 6. Generate Database Schema to Store Chat History

Run the following command in your terminal:
```sh
mix phx.gen.schema Message messages name:string message:string
```
You should see the following output:
```sh
* creating lib/chat/message.ex
* creating priv/repo/migrations/20180107074333_create_messages.exs

Remember to update your repository by running migrations:

    $ mix ecto.migrate
```

Let's break down that command for clarity:
+ `mix phx.gen.schema` - the mix command to create a new schema (database table)
+ `Message` - the singular name for record in our messages "collection"
+ `messages` - the name of the collection (_or database table_)
+ `name:string` - the name of the person sending a message, stored as a `string`.
+ `message:string` - the message sent by the person, also stored as a `string`.

The `creating lib/chat/message.ex` file is the "schema"
for our Message database table.

And the `creating priv/repo/migrations/20180107074333_create_messages.exs` file
is the "_migration_" that _creates_ the database table in our chose database.

#### 6.1 Run the Ecto Migration

In your terminal run the following command to create the Message

```sh
mix ecto.migrate
```
You should see the following in your terminal:
```sh
Compiling 1 file (.ex)
Generated chat app
[info] == Running Chat.Repo.Migrations.CreateMessages.change/0 forward
[info] create table messages
[info] == Migrated in 0.0s
```

#### 6.2 Review the Messages Table Schema

If you open your PostgreSQL GUI (_we use `Postico`_)
you will see that the messages table has been created:

![messages-table-schema-postico](https://user-images.githubusercontent.com/194400/34839040-2c6fcd0e-f6f8-11e7-807f-eb5e81b4192b.png)


### 7. Save Messages to Database

Open the `lib/chat_web/channels/chat_room_channel.ex` file
and inside the function `def handle_in("shout", payload, socket) do`
add the following line:
```elixir
Chat.Message.changeset(%Chat.Message{}, payload) |> Chat.Repo.insert  
```

So that your function ends up looking like this:
```elixir
def handle_in("shout", payload, socket) do
  Chat.Message.changeset(%Chat.Message{}, payload) |> Chat.Repo.insert  
  broadcast socket, "shout", payload
  {:noreply, socket}
end
```

### 8. Load Existing Messages

Open the `lib/chat/message.ex` file and add a new function to it:
```elixir
def get_messages(limit \\ 20) do
  Chat.Repo.all(Message, limit: limit)
end
```
This function accepts a single parameter `limit` to only return a fixed/maximum
number of records.
It uses Ecto's `all` function to fetch all records from the database.
`Message` is the name of the schema/table we want to get records for,
and limit is the maximum number of records to fetch.


### 9. Send Existing Messages to the Client when they Join

In the `/lib/chat_web/channels/chat_room_channel.ex` file create a new function:
```elixir
def handle_info(:after_join, socket) do
  Chat.Message.get_messages()
  |> Enum.each(fn msg -> push(socket, "shout", %{
      name: msg.name,
      message: msg.message,
    }) end)
  {:noreply, socket} # :noreply
end
```

and at the top of the file in the `join` function,

```elixir
def join("chat_room:lobby", payload, socket) do
  if authorized?(payload) do
    send(self(), :after_join)
    {:ok, socket}
  else
    {:error, %{reason: "unauthorized"}}
  end
end
```

### X. Start Server

```sh
mix phx.server
```


To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  * Install Node.js dependencies with `cd assets && npm install`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](http://www.phoenixframework.org/docs/deployment).




## Inspiration

This repo is inspired by @chrismccord's Simple Chat Example:
https://github.com/chrismccord/phoenix_chat_example

At the time of writing Chris' example is still
[Phoenix 1.2](https://github.com/chrismccord/phoenix_chat_example/blob/31f0c5f80a04af0a05fdec89d5b428880c4ea814/mix.exs#L25)
see: https://github.com/chrismccord/phoenix_chat_example/issues/40
therefore we decided to write a quick version for Phoenix 1.3 :-)


## Learn more

* Official website: http://www.phoenixframework.org/
* Guides: http://phoenixframework.org/docs/overview
* Docs: https://hexdocs.pm/phoenix
* Mailing list: http://groups.google.com/group/phoenix-talk
* Source: https://github.com/phoenixframework/phoenix
