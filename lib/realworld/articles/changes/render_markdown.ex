defmodule Realworld.Articles.Changes.RenderMarkdown do
  @moduledoc """
  Renders the user-supplied `:body_raw` markdown into sanitized HTML and
  writes it to `:body` in a `before_action` hook.

  The article page injects `:body` with `raw/1`, so this change is the XSS
  boundary: MDEx parses with `unsafe: true` (inline HTML allowed through the
  parser) and then **sanitizes** the output (scripts and event handlers are
  stripped). `:body` is never accepted by any action — this change is the
  only writer, via `force_change_attribute/3`.
  """
  use Ash.Resource.Change

  alias Ash.Changeset

  @impl true
  @spec change(Changeset.t(), keyword, Change.context()) :: Changeset.t()
  def change(changeset, _options, _context) do
    Changeset.before_action(changeset, &render_markdown/1)
  end

  defp render_markdown(changeset) do
    body =
      changeset
      |> Changeset.get_attribute(:body_raw)
      |> MDEx.to_html!(
        extension: [table: true, strikethrough: true, autolink: true, tasklist: true],
        render: [unsafe: true],
        sanitize: MDEx.Document.default_sanitize_options()
      )

    Changeset.force_change_attribute(changeset, :body, body)
  end
end
