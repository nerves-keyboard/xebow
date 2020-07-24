defmodule Xebow.HIDGadget do
  @moduledoc """
  Set up the gadget devices with usb_gadget.

  This sets up a composite USB device with ethernet (ecm + rndis) and HID.
  """

  if Mix.target() == :host,
    do: @compile({:no_warn_undefined, USBGadget})

  use GenServer, restart: :temporary

  require Logger

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    # Mount configfs if it's not already mounted
    # :os.cmd('mount -t configfs none /sys/kernel/config')

    # Set up gadget devices using configfs
    with :ok <- create_rndis_ecm_hid("hidg"),
         :ok <- USBGadget.disable_device("hidg"),
         :ok <- USBGadget.enable_device("hidg"),
         :ok <- setup_bond0() do
      {:ok, :ok}
    else
      error ->
        Logger.warn("Error setting up USB gadgets: #{inspect(error)}")
        {:ok, error}
    end
  end

  # def handle_call(:status, _from, state) do
  #   {:reply, state, state}
  # end

  # def status do
  #   GenServer.call(__MODULE__, :status)
  # end

  defp create_rndis_ecm_hid(name) do
    device_settings = %{
      "bcdUSB" => "0x0200",
      "bDeviceClass" => "0xEF",
      "bDeviceSubClass" => "0x02",
      "bDeviceProtocol" => "0x01",
      "idVendor" => "0x1209",
      "idProduct" => "0x0071",
      "bcdDevice" => "0x0100",
      "os_desc" => %{
        "use" => "1",
        "b_vendor_code" => "0xcd",
        "qw_sign" => "MSFT100"
      },
      "strings" => %{
        "0x409" => %{
          "manufacturer" => "Nerves Project",
          "product" => "Ethernet + HID Gadget",
          "serialnumber" => ""
        }
      }
    }

    rndis_settings = %{
      "os_desc" => %{
        "interface.rndis" => %{
          "compatible_id" => "RNDIS",
          "sub_compatible_id" => "5162001"
        }
      }
    }

    # 6-key-rollover descriptor:
    # 05 01 09 06 A1 01 05 07 19 E0 29 E7 15 00 25 01
    # 75 01 95 08 81 02 81 01 19 00 29 FF 15 00 25 FF
    # 75 08 95 06 81 00 05 08 19 01 29 05 15 00 25 01
    # 75 01 95 05 91 02 95 03 91 01 C0

    # n-key-rollover descriptor:
    # 05 01 09 06 A1 01 75 01 95 08 15 00 25 01 05 07
    # 19 E0 29 E7 81 02 75 01 95 05 05 08 19 01 29 05
    # 91 02 75 03 95 01 91 03 75 01 95 F8 15 00 25 01
    # 05 07 19 00 29 F7 81 02 C0

    hid_settings = %{
      "protocol" => "1",
      "report_length" => "8",
      "subclass" => "1",
      "report_desc" =>
        <<0x05, 0x01, 0x09, 0x06, 0xA1, 0x01, 0x05, 0x07, 0x19, 0xE0, 0x29, 0xE7, 0x15, 0x00,
          0x25, 0x01, 0x75, 0x01, 0x95, 0x08, 0x81, 0x02, 0x81, 0x01, 0x19, 0x00, 0x29, 0xFF,
          0x15, 0x00, 0x25, 0xFF, 0x75, 0x08, 0x95, 0x06, 0x81, 0x00, 0x05, 0x08, 0x19, 0x01,
          0x29, 0x05, 0x15, 0x00, 0x25, 0x01, 0x75, 0x01, 0x95, 0x05, 0x91, 0x02, 0x95, 0x03,
          0x91, 0x01, 0xC0>>
    }

    config1_settings = %{
      "bmAttributes" => "0xC0",
      "MaxPower" => "500",
      "strings" => %{
        "0x409" => %{
          "configuration" => "RNDIS and ECM Ethernet with HID Keyboard"
        }
      }
    }

    function_list = ["rndis.usb0", "ncm.usb1", "hid.usb2"]

    with {:create_device, :ok} <-
           {:create_device, USBGadget.create_device(name, device_settings)},
         {:create_rndis, :ok} <-
           {:create_rndis, USBGadget.create_function(name, "rndis.usb0", rndis_settings)},
         {:create_ncm, :ok} <-
           {:create_ncm, USBGadget.create_function(name, "ncm.usb1", %{})},
         {:create_hid, :ok} <-
           {:create_hid, USBGadget.create_function(name, "hid.usb2", hid_settings)},
         {:create_config, :ok} <-
           {:create_config, USBGadget.create_config(name, "c.1", config1_settings)},
         {:link_functions, :ok} <-
           {:link_functions, USBGadget.link_functions(name, "c.1", function_list)},
         {:link_os_desc, :ok} <-
           {:link_os_desc, USBGadget.link_os_desc(name, "c.1")} do
      :ok
    else
      {failed_step, {:error, reason}} -> {:error, {failed_step, reason}}
    end
  end

  defp setup_bond0 do
    # Set up the bond0 interface across usb0 and usb1.
    # In the rndis_ecm_acm pre-defined device being used here, usb0 is the
    # RNDIS (Windows-compatible) device and usb1 is the ECM
    # (non-Windows-compatible) device.
    # Since Linux supports both with ECM being more reliable, we set usb1 (ECM)
    # as the primary, meaning that it will be used if both are available.
    bond0_sys_directory = "/sys/class/net/bond0/bonding"
    exit_success = 0

    with {_, ^exit_success} = set_bond0_link_state(:down),
         :ok <- write_file(bond0_sys_directory, "mode", "active-backup"),
         :ok <- write_file(bond0_sys_directory, "miimon", "100"),
         :ok <- write_file(bond0_sys_directory, "slaves", "+usb0"),
         :ok <- write_file(bond0_sys_directory, "slaves", "+usb1"),
         :ok <- write_file(bond0_sys_directory, "primary", "usb0"),
         {_, ^exit_success} = set_bond0_link_state(:up) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp set_bond0_link_state(state) when state in [:up, :down] do
    state = to_string(state)

    try do
      System.cmd("ip", ["link", "set", "bond0", state])
    rescue
      reason -> {:error, reason}
    end
  end

  defp write_file(base_directory, filename, data) do
    base_directory
    |> Path.join(filename)
    |> File.write(data)
  end
end
