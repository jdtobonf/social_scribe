defmodule SocialScribeWeb.MeetingLive.HubSpotModalComponent do
  use SocialScribeWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id="modal"
      class={"fixed inset-0 z-50 overflow-y-auto #{if @show_modal, do: "block", else: "hidden"}"}
      phx-hook="Modal"
    >
      <div class="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        <div class="fixed inset-0 transition-opacity" aria-hidden="true">
          <div class="absolute inset-0 bg-gray-500 opacity-75"></div>
        </div>

        <span class="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">
          &#8203;
        </span>

        <div class="inline-block bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8">
          <div class="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
            <div class="sm:flex sm:items-start">
              <div class="mt-3 text-center sm:mt-0 sm:text-left w-full">
                <.header class="mb-4">
                  Update in HubSpot
                  <:subtitle>
                    Here are suggested updates to sync with your integrations based on this meeting
                  </:subtitle>
                </.header>

                <.form for={@form} id="modal-form" phx-target={@myself} phx-submit="submit_form">
                  <.input
                    type="select"
                    name="contact"
                    label="Select contact"
                    value=""
                    placeholder="Select a contact from the list"
                    phx-change="contact_selected"
                    phx-target={@myself}
                    options={
                      [{"Select a contact from the list", ""}] ++
                        Enum.map(@contacts, fn contact ->
                          {"#{contact.firstname} #{contact.lastname}" |> String.trim(), contact.id}
                        end)
                    }
                  />

                  <%= if @selected_first_name != "" or @selected_last_name != "" or @selected_email != "" do %>
                    <div class="bg-slate-100 rounded p-4 mt-4">
                      <div class="flex justify-between align-center mb-4">
                        <label>
                          <input
                            type="checkbox"
                            name="update_client_first_name"
                            value="true"
                            class="rounded border-zinc-300 focus:ring-0 inline-block align-middle"
                            checked="checked"
                          />
                          <span class="inline-block align-middle font-medium text-sm">
                            Client First Name
                          </span>
                        </label>
                        <div class="">
                          <span class="px-2 py-1 text-xs font-medium rounded-full bg-slate-200">
                            1 update selected
                          </span>
                          <span class="text-xs">Hide details</span>
                        </div>
                      </div>

                      <div class="pl-2">
                        <div class="font-medium text-sm mb-2">Client First Name</div>
                        <div class="flex justify-between items-center text-sm mt-2">
                          <input
                            type="checkbox"
                            name="confirm_client_first_name"
                            value="true"
                            class="rounded border-zinc-300 focus:ring-0"
                            checked="checked"
                          />
                          <input
                            type="text"
                            name="old_client_first_name"
                            class="rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6 border-zinc-300 focus:border-zinc-400 line-through"
                            value={@selected_first_name}
                            disabled="disabled"
                          />

                          <svg
                            xmlns="http://www.w3.org/2000/svg"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke-width="1.5"
                            stroke="currentColor"
                            class="size-6"
                          >
                            <path
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              d="M17.25 8.25 21 12m0 0-3.75 3.75M21 12H3"
                            />
                          </svg>

                          <input
                            type="text"
                            name="client_first_name"
                            class="rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6 border-zinc-300 focus:border-zinc-400"
                            value={@selected_first_name}
                          />
                        </div>
                      </div>

                      <div class="text-sm text-blue-500">
                        Update mapping
                      </div>
                    </div>

                    <div class="bg-slate-100 rounded p-4 mt-2">
                      <div class="flex justify-between align-center mb-4">
                        <label>
                          <input
                            type="checkbox"
                            name="update_client_last_name"
                            value="true"
                            class="rounded border-zinc-300 focus:ring-0 inline-block align-middle"
                            checked="checked"
                          />
                          <span class="inline-block align-middle font-medium text-sm">
                            Client Last Name
                          </span>
                        </label>
                        <div class="">
                          <span class="px-2 py-1 text-xs font-medium rounded-full bg-slate-200">
                            1 update selected
                          </span>
                          <span class="text-xs">Hide details</span>
                        </div>
                      </div>

                      <div class="pl-2">
                        <div class="font-medium text-sm mb-2">Client Last Name</div>
                        <div class="flex justify-between items-center text-sm mt-2">
                          <input
                            type="checkbox"
                            name="confirm_client_last_name"
                            value="true"
                            class="rounded border-zinc-300 focus:ring-0"
                            checked="checked"
                          />
                          <input
                            type="text"
                            name="old_client_last_name"
                            class="rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6 border-zinc-300 focus:border-zinc-400 line-through"
                            value={@selected_last_name}
                            disabled="disabled"
                          />

                          <svg
                            xmlns="http://www.w3.org/2000/svg"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke-width="1.5"
                            stroke="currentColor"
                            class="size-6"
                          >
                            <path
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              d="M17.25 8.25 21 12m0 0-3.75 3.75M21 12H3"
                            />
                          </svg>

                          <input
                            type="text"
                            name="client_last_name"
                            class="rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6 border-zinc-300 focus:border-zinc-400"
                            value={@selected_last_name}
                          />
                        </div>
                      </div>

                      <div class="text-sm text-blue-500">
                        Update mapping
                      </div>
                    </div>

                    <div class="bg-slate-100 rounded p-4 mt-2">
                      <div class="flex justify-between align-center mb-4">
                        <label>
                          <input
                            type="checkbox"
                            name="update_client_email"
                            value="true"
                            class="rounded border-zinc-300 focus:ring-0 inline-block align-middle"
                            checked="checked"
                          />
                          <span class="inline-block align-middle font-medium text-sm">
                            Client Email
                          </span>
                        </label>
                        <div class="">
                          <span class="px-2 py-1 text-xs font-medium rounded-full bg-slate-200">
                            1 update selected
                          </span>
                          <span class="text-xs">Hide details</span>
                        </div>
                      </div>

                      <div class="pl-2">
                        <div class="font-medium text-sm mb-2">Client Email</div>
                        <div class="flex justify-between items-center text-sm mt-2">
                          <input
                            type="checkbox"
                            name="confirm_client_email"
                            value="true"
                            class="rounded border-zinc-300 focus:ring-0"
                            checked="checked"
                          />
                          <input
                            type="text"
                            name="old_client_email"
                            class="rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6 border-zinc-300 focus:border-zinc-400 line-through"
                            value={@selected_email}
                            disabled="disabled"
                          />

                          <svg
                            xmlns="http://www.w3.org/2000/svg"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke-width="1.5"
                            stroke="currentColor"
                            class="size-6"
                          >
                            <path
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              d="M17.25 8.25 21 12m0 0-3.75 3.75M21 12H3"
                            />
                          </svg>

                          <input
                            type="text"
                            name="client_email"
                            class="rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6 border-zinc-300 focus:border-zinc-400"
                            value={@selected_email}
                          />
                        </div>
                      </div>

                      <div class="text-sm text-blue-500">
                        Update mapping
                      </div>
                    </div>
                  <% end %>
                </.form>
              </div>
            </div>
          </div>
          <div class="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse border-t">
            <.button
              type="submit"
              form="modal-form"
              class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-indigo-600 text-base font-medium text-white hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:ml-3 sm:w-auto sm:text-sm"
            >
              Update HubSpot
            </.button>
            <button
              type="button"
              phx-click="close_modal"
              class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm"
            >
              Cancel
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(%{"name" => "", "email" => "", "message" => ""})
     end)
     |> assign_new(:selected_first_name, fn -> "" end)
     |> assign_new(:selected_last_name, fn -> "" end)
     |> assign_new(:selected_email, fn -> "" end)}
  end

  @impl true
  def handle_event("contact_selected", %{"contact" => contact_id}, socket) do
    if contact_id == "" do
      # Clear fields when placeholder is selected
      {:noreply,
       socket
       |> assign(:selected_first_name, "")
       |> assign(:selected_last_name, "")
       |> assign(:selected_email, "")}
    else
      selected_contact =
        Enum.find(socket.assigns.contacts, fn contact -> contact.id == contact_id end)

      if selected_contact do
        {:noreply,
         socket
         |> assign(:selected_first_name, selected_contact.firstname)
         |> assign(:selected_last_name, selected_contact.lastname)
         |> assign(:selected_email, selected_contact.email)}
      else
        {:noreply, socket}
      end
    end
  end

  @impl true
  def handle_event("submit_form", params, socket) do
    # Handle form submission - for now just log the data
    IO.inspect(params, label: "HubSpot form submitted")

    # Check if we have a credential and selected contact
    credential = socket.assigns.credential
    contact_id = params["contact"]

    if credential && contact_id && contact_id != "" do
      # Build properties to update based on checked checkboxes
      properties = %{}

      properties =
        if params["update_client_first_name"] == "true" do
          Map.put(properties, "firstname", params["client_first_name"])
        else
          properties
        end

      properties =
        if params["update_client_last_name"] == "true" do
          Map.put(properties, "lastname", params["client_last_name"])
        else
          properties
        end

      properties =
        if params["update_client_email"] == "true" do
          Map.put(properties, "email", params["client_email"])
        else
          properties
        end

      # Update contact if any properties to update
      if map_size(properties) > 0 do
        case SocialScribe.HubSpot.update_contact(credential, contact_id, properties) do
          {:ok, _response} ->
            IO.inspect("Successfully updated HubSpot contact #{contact_id}",
              label: "HubSpot Update Success"
            )

            # Notify parent to refresh contacts
            send(self(), {__MODULE__, :refresh_contacts})
            {:noreply, socket}

          {:error, reason} ->
            IO.inspect("Failed to update HubSpot contact: #{reason}",
              label: "HubSpot Update Error"
            )

            {:noreply, socket}
        end
      else
        {:noreply, socket}
      end
    end

    # Notify parent to close modal
    send(self(), {__MODULE__, :close_modal})

    {:noreply, socket}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    send(self(), {__MODULE__, :close_modal})
    {:noreply, socket}
  end
end
