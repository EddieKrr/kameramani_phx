defmodule KameramaniPhx.SocialsTest do
  use KameramaniPhx.DataCase

  alias KameramaniPhx.Socials

  describe "social_accounts" do
    alias KameramaniPhx.Socials.SocialAccount

    import KameramaniPhx.SocialsFixtures

    @invalid_attrs %{url: nil, username: nil, platform: nil}

    test "list_social_accounts/0 returns all social_accounts" do
      social_account = social_account_fixture()
      assert Socials.list_social_accounts() == [social_account]
    end

    test "get_social_account!/1 returns the social_account with given id" do
      social_account = social_account_fixture()
      assert Socials.get_social_account!(social_account.id) == social_account
    end

    test "create_social_account/1 with valid data creates a social_account" do
      valid_attrs = %{url: "some url", username: "some username", platform: "some platform"}

      assert {:ok, %SocialAccount{} = social_account} = Socials.create_social_account(valid_attrs)
      assert social_account.url == "some url"
      assert social_account.username == "some username"
      assert social_account.platform == "some platform"
    end

    test "create_social_account/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Socials.create_social_account(@invalid_attrs)
    end

    test "update_social_account/2 with valid data updates the social_account" do
      social_account = social_account_fixture()

      update_attrs = %{
        url: "some updated url",
        username: "some updated username",
        platform: "some updated platform"
      }

      assert {:ok, %SocialAccount{} = social_account} =
               Socials.update_social_account(social_account, update_attrs)

      assert social_account.url == "some updated url"
      assert social_account.username == "some updated username"
      assert social_account.platform == "some updated platform"
    end

    test "update_social_account/2 with invalid data returns error changeset" do
      social_account = social_account_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Socials.update_social_account(social_account, @invalid_attrs)

      assert social_account == Socials.get_social_account!(social_account.id)
    end

    test "delete_social_account/1 deletes the social_account" do
      social_account = social_account_fixture()
      assert {:ok, %SocialAccount{}} = Socials.delete_social_account(social_account)
      assert_raise Ecto.NoResultsError, fn -> Socials.get_social_account!(social_account.id) end
    end

    test "change_social_account/1 returns a social_account changeset" do
      social_account = social_account_fixture()
      assert %Ecto.Changeset{} = Socials.change_social_account(social_account)
    end
  end
end
