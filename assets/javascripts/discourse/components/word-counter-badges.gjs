import Component from "@glimmer/component";
import UserBadge from "discourse/components/user-badge";

const BADGE_TYPE_CLASSES = [
  "badge-type-gold",
  "badge-type-silver",
  "badge-type-bronze",
];

export default class WordCounterBadges extends Component {
  get badges() {
    return (this.args.badges || []).map((badge) => {
      const badgeTypeId = badge.badge_type?.id || badge.badge_type_id;

      return {
        ...badge,
        badgeTypeClassName: BADGE_TYPE_CLASSES[badgeTypeId - 1],
        image: badge.image_url || badge.image,
        icon: badge.icon?.replace(/^fa-/, ""),
        url: `/badges/${badge.id}/${badge.slug}`,
      };
    });
  }

  <template>
    {{#each this.badges key="id" as |badge|}}
      <span
        class="poster-icon contribution-badge contribution-badge-{{badge.slug}}"
      >
        <UserBadge @badge={{badge}} @user={{@user}} @showName={{true}} />
      </span>
    {{/each}}
  </template>
}
