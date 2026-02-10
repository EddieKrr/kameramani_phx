defmodule KameramaniPhxWeb.Cldr do
  use Cldr,
    locales: ["en-KE", "en"],
    gettext: KameramaniPhxWeb.Gettext,
    data_dir: "./priv/cldr",
    otp_app: :kameramani_phx,
    precompile_number_formats: ["¤¤#,##0.##"],
    precompile_transilterations: [{:latn, :arab}, {:thai, :latn}],
    providers: [
      Cldr.Number,
      Cldr.Calendar,
      Cldr.DateTime,
      Cldr.List,
      Cldr.Unit,
      Cldr.Territory,
      Cldr.Language
    ]
end
