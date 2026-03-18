defmodule KameramaniPhxWeb.NotificationsLive do
  use KameramaniPhxWeb, :live_view

  alias KameramaniPhx.Accounts
  alias KameramaniPhx.Notifications

  @impl true
  def mount(_params, %{"current_user_id" => current_user_id}, socket) do
    current_user = Accounts.get_user!(current_user_id)
    timezone = notification_timezone(socket)

    if connected?(socket) do
      Notifications.subscribe(current_user.id)
    end

    {:ok,
     socket
     |> assign(:timezone, timezone)
     |> assign_notifications(current_user)}
  end

  @impl true
  def handle_event("toggle_dropdown", _, socket) do
    {:noreply, assign(socket, dropdown_open: !socket.assigns.dropdown_open)}
  end

  @impl true
  def handle_event("close_dropdown", _, socket) do
    {:noreply, assign(socket, dropdown_open: false)}
  end

  @impl true
  def handle_event("mark_all_read", _, socket) do
    :ok = Notifications.mark_all_as_read(socket.assigns.current_user)
    {:noreply, assign_notifications(socket, socket.assigns.current_user)}
  end

  @impl true
  def handle_event("clear_notifications", _, socket) do
    :ok = Notifications.clear_notifications(socket.assigns.current_user)
    {:noreply, assign_notifications(socket, socket.assigns.current_user)}
  end

  @impl true
  def handle_event("open_notification", %{"id" => notification_id}, socket) do
    :ok = Notifications.mark_as_read(socket.assigns.current_user, notification_id)

    notification =
      Enum.find(socket.assigns.notifications, fn item -> item.id == notification_id end)

    {:noreply,
     socket
     |> assign_notifications(socket.assigns.current_user)
     |> assign(dropdown_open: false)
     |> push_navigate(to: notification_path(notification))}
  end

  @impl true
  def handle_info(:notifications_updated, socket) do
    previous_notification_id = socket.assigns.last_notification_id
    latest_notifications = Notifications.list_notifications(socket.assigns.current_user, limit: 12)
    latest_unread_count = Notifications.unread_count(socket.assigns.current_user)
    latest_notification = List.first(latest_notifications) #new notification huko juu

    socket =
      socket
      |> assign(:notifications, latest_notifications)
      |> assign(:unread_count, latest_unread_count)
      |> assign(:last_notification_id, latest_notification && latest_notification.id)

    socket =
      if new_notification?(previous_notification_id, latest_notification) do
        put_flash(socket, :info, notification_text(latest_notification))
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.flash
      id="notification-live-flash"
      kind={:info}
      flash={@flash}
      class="pointer-events-auto fixed right-4 top-20 z-[70]"
    />

    <div
      id="navbar-notifications-root"
      class="relative"
      phx-click-away="close_dropdown"
    >
      <button
        id="navbar-notifications-toggle"
        type="button"
        phx-click="toggle_dropdown"
        class={[
          "group relative inline-flex h-11 w-11 items-center justify-center rounded-2xl border transition-all duration-300",
          @dropdown_open &&
            "border-[#39d0ff]/60 bg-linear-to-br from-[#10253a] to-[#111827] text-white shadow-[0_14px_38px_rgba(10,30,52,0.45)]",
          !@dropdown_open &&
            "border-white/10 bg-linear-to-br from-[#161a23] to-[#0f1117] text-[#e8edf5] hover:border-[#39d0ff]/40 hover:text-white hover:shadow-[0_10px_30px_rgba(14,30,48,0.35)]"
        ]}
      >
        <div class="absolute inset-0 bg-linear-to-br from-[#39d0ff]/0 via-[#39d0ff]/0 to-[#ff6a88]/0 opacity-0 transition-opacity duration-300 group-hover:opacity-100 group-hover:from-[#39d0ff]/10 group-hover:to-[#ff6a88]/10" />
        <.icon name="hero-bell" class="relative h-5 w-5 transition-transform duration-300 group-hover:-translate-y-0.5" />

        <span
          :if={@unread_count > 0}
          id="navbar-notifications-count"
          class="absolute -right-1 -top-1 inline-flex h-5 min-w-[20px] items-center justify-center rounded-full bg-red-500 px-1.5 text-[10px] font-bold text-white ring-2 ring-[#10131b]"
        >
          {min(@unread_count, 9)}
          <span :if={@unread_count > 9}>+</span>
        </span>
      </button>

      <div
        :if={@dropdown_open}
        id="navbar-notifications-panel"
        class="absolute bg-slate-700 right-0 z-50 mt-3 w-[24rem] overflow-hidden rounded-[28px] border border-white/10 shadow-2xl">
        <div class="relative overflow-hidden border-b border-white/8 bg-slate-800 px-5 py-4">
          <div class="absolute -right-10 -top-10 h-24 w-24 rounded-full bg-[#39d0ff]/10 blur-2xl" />
          <div class="absolute -left-6 bottom-0 h-16 w-16 rounded-full bg-[#ff6a88]/10 blur-2xl" />
          <div class="relative flex items-start justify-between gap-4">
            <div>
              <p class="text-sm font-semibold uppercase tracking-[0.18em] text-[#7ddfff]">
                Notifications
              </p>
              <p class="mt-1 text-sm text-[#e7edf7]">
                You have
                <span class="font-bold text-white">{@unread_count}</span>
                unread update<%= if @unread_count != 1, do: "s" %>.
              </p>
            </div>
            <div class="rounded-full border border-white/10 bg-white/5 px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.18em] text-[#a5b4c7]">
              Live feed
            </div>
          </div>
          <div class="mt-3 flex flex-wrap gap-3">
            <button
              :if={@unread_count > 0}
              id="navbar-notifications-mark-all"
              type="button"
              phx-click="mark_all_read"
              class="relative inline-flex items-center rounded-full border border-[#39d0ff]/20 bg-[#39d0ff]/10 px-3 py-1.5 text-[11px] font-semibold uppercase tracking-[0.14em] text-[#7ddfff] transition hover:border-[#39d0ff]/40 hover:bg-[#39d0ff]/15 hover:text-white"
            >
              Mark all read
            </button>

            <button
              :if={@notifications != []}
              id="navbar-notifications-clear-all"
              type="button"
              phx-click="clear_notifications"
              class="relative inline-flex items-center rounded-full border border-[#ff6d99]/20 bg-[#ff6d99]/10 px-3 py-1.5 text-[11px] font-semibold uppercase tracking-[0.14em] text-[#ff9ac6] transition hover:border-[#ff6d99]/40 hover:bg-[#ff6d99]/15 hover:text-white"
            >
              Clear all
            </button>
          </div>
        </div>

        <div
          id="navbar-notifications-list"
          class="max-h-[30rem] overflow-y-auto overscroll-contain px-2 py-2 scrollbar-thin scrollbar-thumb-[#2a3242] scrollbar-track-transparent"
        >
          <div
            :if={@notifications == []}
            id="navbar-notifications-empty"
            class="flex flex-col items-center gap-3 px-6 py-10 text-center"
          >
            <div class="flex h-14 w-14 items-center justify-center rounded-2xl border border-white/10 bg-[#141924] text-[#7ddfff] shadow-[0_10px_30px_rgba(16,23,36,0.35)]">
              <.icon name="hero-bell-alert" class="h-6 w-6" />
            </div>
            <div>
              <p class="text-sm font-semibold text-[#eef4ff]">Nothing new yet</p>
              <p class="mt-1 text-xs leading-relaxed text-[#94a3b8]">
                When people follow you, subscribe, or go live, those updates will show up here.
              </p>
            </div>
          </div>

          <button
            :for={notification <- @notifications}
            id={"notification-#{notification.id}"}
            type="button"
            phx-click="open_notification"
            phx-value-id={notification.id}
            class={[
              "group mb-2 flex w-full items-start gap-3 rounded-[22px] border px-4 py-3.5 text-left transition-all duration-200",
              is_nil(notification.read_at) &&
                "border-[#39d0ff]/18 bg-linear-to-r from-[#121a27] to-[#12131a] shadow-[0_8px_24px_rgba(18,26,39,0.28)] hover:border-[#39d0ff]/30",
              !is_nil(notification.read_at) &&
                "border-transparent bg-[#12151d] hover:border-white/8 hover:bg-[#171b24]"
            ]}
          >
            <div class={[
              "mt-0.5 flex h-10 w-10 shrink-0 items-center justify-center rounded-2xl border text-white shadow-inner",
              notification_icon_container(notification.type)
            ]}>
              <.icon name={notification_icon(notification.type)} class="h-4 w-4" />
            </div>

            <div class="min-w-0 flex-1">
              <div class="flex items-center justify-between gap-3">
                <span class="truncate text-xs font-semibold uppercase tracking-[0.16em] text-[#7b8ca7]">
                  {notification_label(notification.type)}
                </span>
                <span class="shrink-0 text-[11px] text-[#73839b]">
                  {format_timestamp(notification.inserted_at, @timezone)}
                </span>
              </div>
              <p class="mt-1 text-sm leading-snug text-[#eef4ff]">
                {notification_text(notification)}
              </p>
              <p class="mt-2 text-xs text-[#95a3b8]">
                {notification_subtext(notification)}
              </p>
            </div>

            <span
              :if={is_nil(notification.read_at)}
              class="mt-1.5 h-2.5 w-2.5 shrink-0 rounded-full bg-[#39d0ff] shadow-[0_0_18px_rgba(57,208,255,0.8)]"
            />
          </button>
        </div>
      </div>
    </div>
    """
  end

  defp assign_notifications(socket, current_user) do
    notifications = Notifications.list_notifications(current_user, limit: 12)

    socket
    |> assign(:current_user, current_user)
    |> assign(:dropdown_open, socket.assigns[:dropdown_open] || false)
    |> assign(:notifications, notifications)
    |> assign(:unread_count, Notifications.unread_count(current_user))
    |> assign(:last_notification_id, List.first(notifications) && List.first(notifications).id)
  end

  defp notification_path(%{type: :stream_went_live, metadata: %{"actor_username" => username}}),
    do: ~p"/watch/#{username}"

  defp notification_path(%{type: type, metadata: %{"actor_username" => username}})
       when type in [:new_follower, :new_subscription, :verification_approved, :verification_rejected],
    do: ~p"/users/profile/#{username}"

  defp notification_path(_), do: ~p"/"

  defp notification_text(%{type: :stream_went_live, metadata: metadata}) do
    username = Map.get(metadata, "actor_username", "A streamer you follow")
    title = Map.get(metadata, "stream_title", "just went live")
    "#{username} is live now: #{title}"
  end

  defp notification_text(%{type: :new_follower, metadata: metadata}) do
    username = Map.get(metadata, "actor_username", "Someone")
    "#{username} followed you."
  end

  defp notification_text(%{type: :new_subscription, metadata: metadata}) do
    username = Map.get(metadata, "actor_username", "Someone")
    tier = Map.get(metadata, "tier", 1)
    "#{username} subscribed at tier #{tier}."
  end

  defp notification_text(%{type: :verification_submitted, metadata: metadata}) do
    username = Map.get(metadata, "actor_username", "Someone")
    "#{username} submitted a verification request."
  end

  defp notification_text(%{type: :verification_approved, metadata: metadata}) do
    Map.get(metadata, "message", "Your verification request has been approved!")
  end

  defp notification_text(%{type: :verification_rejected, metadata: metadata}) do
    Map.get(metadata, "message", "Your verification request has been rejected.")
  end
  defp notification_icon(:stream_went_live), do: "hero-signal"
  defp notification_icon(:new_follower), do: "hero-heart"
  defp notification_icon(:new_subscription), do: "hero-star"
  defp notification_icon(:verification_submitted), do: "hero-document-text"
  defp notification_icon(:verification_approved), do: "hero-check-circle"
  defp notification_icon(:verification_rejected), do: "hero-x-circle"

  defp notification_label(:stream_went_live), do: "Live now"
  defp notification_label(:new_follower), do: "New follower"
  defp notification_label(:new_subscription), do: "New sub"
  defp notification_label(:verification_submitted), do: "Verification request"
  defp notification_label(:verification_approved), do: "Verification approved"
  defp notification_label(:verification_rejected), do: "Verification rejected"

  defp notification_subtext(%{type: :stream_went_live}), do: "Jump in and join the stream."
  defp notification_subtext(%{type: :new_follower}), do: "They are now part of your audience."
  defp notification_subtext(%{type: :new_subscription}), do: "Support landed on your channel."
  defp notification_subtext(%{type: :verification_submitted}), do: "Review and approve the request."
  defp notification_subtext(%{type: :verification_approved}), do: "Your account is now verified!"
  defp notification_subtext(%{type: :verification_rejected}), do: "Check the requirements and try again."

  defp notification_icon_container(:stream_went_live),
    do: "border-[#ff6a88]/20 bg-linear-to-br from-[#52273d] to-[#25131d] text-[#ff9eb4]"

  defp notification_icon_container(:new_follower),
    do: "border-[#39d0ff]/20 bg-linear-to-br from-[#173248] to-[#121a27] text-[#7ddfff]"

  defp notification_icon_container(:new_subscription),
    do: "border-[#f8c35d]/20 bg-linear-to-br from-[#47361b] to-[#1f1911] text-[#ffd47e]"

  defp notification_icon_container(:verification_submitted),
    do: "border-[#8b5cf6]/20 bg-linear-to-br from-[#4c1d95] to-[#2e1065] text-[#a78bfa]"

  defp notification_icon_container(:verification_approved),
    do: "border-[#10b981]/20 bg-linear-to-br from-[#064e3b] to-[#022c22] text-[#34d399]"

  defp notification_icon_container(:verification_rejected),
    do: "border-[#ef4444]/20 bg-linear-to-br from-[#7f1d1d] to-[#450a0a] text-[#f87171]"

  defp format_timestamp(%DateTime{} = timestamp, timezone) when is_binary(timezone) do
    case DateTime.shift_zone(timestamp, timezone) do
      {:ok, localized_timestamp} ->
        Calendar.strftime(localized_timestamp, "%b %d, %I:%M %p")

      _ ->
        Calendar.strftime(timestamp, "%b %d, %I:%M %p UTC")
    end
  end

  defp notification_timezone(socket) do
    case connected?(socket) && get_connect_params(socket) do
      %{"timezone" => timezone} when is_binary(timezone) and timezone != "" -> timezone
      _ -> "Etc/UTC"
    end
  end

  defp new_notification?(previous_id, %{id: latest_id}) when previous_id != latest_id, do: true
  defp new_notification?(_, _), do: false
end
