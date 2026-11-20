import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import WordCounterBadgesConnector from "discourse/plugins/discourse-word-counter/discourse/connectors/post-meta-data-poster-name__after/word-counter-badges";

module("Integration | Connector | WordCounterBadges", function (hooks) {
  setupRenderingTest(hooks);

  test("only shows badges when the plugin is enabled", async function (assert) {
    this.outletArgs = {
      post: {
        word_counter_badges: [
          { id: 42, slug: "contributor", name: "Contributor", icon: "heart" },
        ],
      },
      user: { username_lower: "alice" },
    };

    this.siteSettings.discourse_word_counter_enabled = false;
    await render(
      <template><WordCounterBadgesConnector @outletArgs={{this.outletArgs}} /></template>
    );
    assert.dom(".contribution-badge").doesNotExist();

    this.siteSettings.discourse_word_counter_enabled = true;
    await render(
      <template><WordCounterBadgesConnector @outletArgs={{this.outletArgs}} /></template>
    );
    assert.dom(".contribution-badge").exists();
  });
});
