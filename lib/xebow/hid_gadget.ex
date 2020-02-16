defmodule Xebow.HIDGadget do
  @moduledoc """
  Set up the HID gadget device with usb_gadget
  """

  use GenServer, restart: :temporary

  require Logger

  # An unclaimed vendor/product ID. Consider claiming one: http://pid.codes/
  @vendor_id "0x1209"
  @product_id "0x0072"

  @product_name "Xebow"

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    case create_hid_device("hidg") do
      :ok ->
        {:ok, :ok}

      error ->
        Logger.warn("Error setting up USB gadgets: #{inspect(error)}")
        {:ok, error}
    end
  end

  defp create_hid_device(name) do
    device_settings = %{
      "bcdUSB" => "0x0200",
      "bDeviceClass" => "0x00",
      "bDeviceSubClass" => "0x00",
      "bDeviceProtocol" => "0x00",
      "idVendor" => @vendor_id,
      "idProduct" => @product_id,
      "bcdDevice" => "0x0100",
      "bMaxPacketSize0" => "0x08",
      "os_desc" => %{
        "use" => "1",
        "b_vendor_code" => "0xcd",
        "qw_sign" => "MSFT100"
      },
      "strings" => %{
        "0x409" => %{
          "manufacturer" => "Nerves Project",
          "product" => @product_name,
          "serialnumber" => ""
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
          "configuration" => @product_name
        }
      }
    }

    function_list = ["hid.usb0"]

    with {:create_device, :ok} <-
           {:create_device, USBGadget.create_device(name, device_settings)},
         {:create_hid, :ok} <-
           {:create_hid, USBGadget.create_function(name, "hid.usb0", hid_settings)},
         {:create_config, :ok} <-
           {:create_config, USBGadget.create_config(name, "c.1", config1_settings)},
         {:link_functions, :ok} <-
           {:link_functions, USBGadget.link_functions(name, "c.1", function_list)},
         {:link_os_desc, :ok} <- {:link_os_desc, USBGadget.link_os_desc(name, "c.1")},
         {:enable_device, :ok} <- {:enable_device, USBGadget.enable_device("hidg")} do
      :ok
    else
      {failed_step, {:error, reason}} -> {:error, {failed_step, reason}}
    end
  end
end
