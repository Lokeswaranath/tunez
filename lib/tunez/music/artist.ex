defmodule Tunez.Music.Artist do
  use Ash.Resource,
    otp_app: :tunez,
    domain: Tunez.Music,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshJsonApi.Resource]

  json_api do
    type "artist"
    # includes [:albums]
    derive_filter? false
  end

  resource do
    description "A person or group who creates and releases music."
  end

  postgres do
    table "artists"
    repo Tunez.Repo

    custom_indexes do
      index "name gin_trgm_ops", name: "artists_name_gin_index", using: "GIN"
    end
  end

  actions do
    # defaults [:create, :read, :update, :destroy]
    # default_accept [:name, :biography]
    create :create do
      accept [:name, :biography]
    end

    read :read do
      primary? true
    end

    update :update do
      require_atomic? false
      accept [:name, :biography]

      change Tunez.Music.Changes.UpdatePreviousNames, where: [changing(:name)]
    end

    destroy :destroy do
    end

    read :search do

      description "List artists, optionally filtering by name."

      argument :query, :ci_string do
        description "Return artists with names containing the given value."
        constraints allow_empty?: true
        default ""
      end

      filter expr(contains(name, ^arg(:query)))
      pagination offset?: true, default_limit: 12

      # prepare build(load: [:album_count, :latest_album_year_released, :cover_image_url])
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :biography, :string do
      public? true
    end

    attribute :previous_names, {:array, :string} do
      default []
      public? true
    end

    create_timestamp :inserted_at, public?: true
    update_timestamp :updated_at, public?: true
  end

  relationships do
    has_many :albums, Tunez.Music.Album do
      sort year_released: :desc
      public? true
    end
  end

  calculations do
    # calculate :album_count, :integer, expr(count(albums))
    # calculate :latest_album_year_released, :integer,expr(first(albums, field: :year_released))
    # calculate :cover_image_url, :string, expr(first(albums, field: :cover_image_url))
  end

  aggregates do
    count :album_count, :albums do
      public? true
    end

    first :latest_album_year_released, :albums, :year_released do
      public? true
    end

    first :cover_image_url, :albums, :cover_image_url
  end
end
