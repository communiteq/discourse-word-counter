import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import WordCounterBadges from "discourse/plugins/discourse-word-counter/discourse/components/word-counter-badges";

module("Integration | Component | WordCounterBadges", function (hooks) {
  setupRenderingTest(hooks);

  test("renders contribution badges for the post author", async function (assert) {
    this.user = { username_lower: "alice" };
    this.badges = [
      {
        id: 42,
        name: "Contributor",
        slug: "contributor",
        description: "Contributed to the community",
        icon: "fa-heart",
        badge_type: { id: 1 },
      },
    ];

    await render(
      <template>
        <WordCounterBadges @badges={{this.badges}} @user={{this.user}} />
      </template>
    );

    assert
      .dom(".poster-icon.contribution-badge.contribution-badge-contributor")
      .exists();
    assert.dom(".user-badge.badge-type-gold").hasText("Contributor");
    assert.dom(".d-icon-heart").exists();
    assert
      .dom("a.user-card-badge-link")
      .hasAttribute("href", "/badges/42/contributor?username=alice");
  });

  test("renders nothing when the user has no contribution badges", async function (assert) {
    await render(
      <template>
        <WordCounterBadges @badges={{undefined}} @user={{undefined}} />
      </template>
    );

    assert.dom(".contribution-badge").doesNotExist();
  });
});
