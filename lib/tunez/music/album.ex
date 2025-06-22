defmodule Tunez.Music.Album do
  use Ash.Resource,
    otp_app: :tunez,
    domain: Tunez.Music,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshJsonApi.Resource]

  json_api do
    type "album"
  end

  postgres do
    table "albums"
    repo Tunez.Repo

    references do
      reference :artist, index?: true, on_delete: :delete
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:name, :year_released, :cover_image_url, :artist_id]
    end

    update :update do
      accept [:name, :year_released, :cover_image_url]
    end
  end

  validations do
    validate numericality(:year_released, greater_than_or_equal_to: 1950),
      where: [present(:year_released)],
      message: "must be a valid year after 1950"

    validate match(:cover_image_url, ~r"(^https://|/images/).+\.(jpg|jpeg|png|gif)$"),
      where: [present(:cover_image_url)],
      message:
        "must be a valid image URL starting with 'https://' or '/images/' and ending with .jpg, .jpeg, .png, or .gif"
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :year_released, :integer do
      allow_nil? false
      public? true
    end

    attribute :cover_image_url, :string do
      public? true
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :artist, Tunez.Music.Artist do
      allow_nil? false
    end
  end

  calculations do
    calculate :years_ago, :integer, expr(2025 - year_released)
    calculate :string_years_ago, :string, expr("wow, this was released #{years_ago} years ago!")
  end

  identities do
    identity :unique_album_name_per_artist, [:name, :artist_id],
      message: "An album with this name already exists for this artist"
  end
end
