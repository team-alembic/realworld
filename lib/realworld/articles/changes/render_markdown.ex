defmodule Realworld.Articles.Changes.RenderMarkdown do
  use Ash.Resource.Change

  alias Ash.Changeset

  @impl true
  @spec change(Changeset.t(), keyword, Change.context()) :: Changeset.t()
  def change(changeset, _options, _context) do
    Changeset.before_action(changeset, &render_markdown/1)
  end

  defp render_markdown(changeset) do
    body = changeset |> Changeset.get_attribute(:body_raw) |> Earmark.as_html!()
    Changeset.change_attribute(changeset, :body, body)
  end
end
