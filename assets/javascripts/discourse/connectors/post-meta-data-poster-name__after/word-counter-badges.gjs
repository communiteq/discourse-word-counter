import Component from "@glimmer/component";
import { service } from "@ember/service";
import WordCounterBadges from "../../components/word-counter-badges";

export default class WordCounterBadgesConnector extends Component {
  @service siteSettings;

  <template>
    {{#if this.siteSettings.discourse_word_counter_enabled}}
      <WordCounterBadges
        @badges={{@outletArgs.post.word_counter_badges}}
        @user={{@outletArgs.user}}
      />
    {{/if}}
  </template>
}
