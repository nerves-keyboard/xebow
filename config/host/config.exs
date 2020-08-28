import Config

config :xebow,
  layout: [
    leds: [
      %{id: :l001, x: 0, y: 0},
      %{id: :l002, x: 1, y: 0},
      %{id: :l003, x: 2, y: 0},
      %{id: :l004, x: 0, y: 1},
      %{id: :l005, x: 1, y: 1},
      %{id: :l006, x: 2, y: 1},
      %{id: :l007, x: 0, y: 2},
      %{id: :l008, x: 1, y: 2},
      %{id: :l009, x: 2, y: 2},
      %{id: :l010, x: 0, y: 3},
      %{id: :l011, x: 1, y: 3},
      %{id: :l012, x: 2, y: 3}
    ],
    keys: [
      %{id: :k001, x: 0, y: 0, opts: [led: :l001]},
      %{id: :k002, x: 1, y: 0, opts: [led: :l002]},
      %{id: :k003, x: 2, y: 0, opts: [led: :l003]},
      %{id: :k004, x: 0, y: 1, opts: [led: :l004]},
      %{id: :k005, x: 1, y: 1, opts: [led: :l005]},
      %{id: :k006, x: 2, y: 1, opts: [led: :l006]},
      %{id: :k007, x: 0, y: 2, opts: [led: :l007]},
      %{id: :k008, x: 1, y: 2, opts: [led: :l008]},
      %{id: :k009, x: 2, y: 2, opts: [led: :l009]},
      %{id: :k010, x: 0, y: 3, opts: [led: :l010]},
      %{id: :k011, x: 1, y: 3, opts: [led: :l011]},
      %{id: :k012, x: 2, y: 3, opts: [led: :l012]}
    ]
  ]

import_config "#{Mix.env()}.exs"
