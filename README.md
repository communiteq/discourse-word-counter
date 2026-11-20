# Discourse Word Counter

This plugin counts words in regular-topic posts and displays badges from the
`Contribution` badge group next to authors' names. Quoted content is excluded.

The `discourse word counter enabled` site setting controls counting and the
display of contribution badges. It defaults to enabled for existing installations.
Posts created or edited while the plugin is disabled may need a recount after it
is re-enabled. The setting does not remove existing counts or badges, or disable
automatic badge queries.

## Contribution badges

The `wordcounter:create_badges` task creates or updates these badges:

| Badge | Words | Period |
| --- | --- | --- |
| Contributor | 251–1,000 | Total |
| Patron | 1,001–2,500 | Total |
| Sr. Member | 2,501–10,000 | Total |
| Influencer | 10,000–9,999,999,999 | Total |
| Legend | 10,000–9,999,999,999 | Last year |

Users with at least 10,000 words in the last year are excluded from the total
badges. The Sr. Member and Influencer ranges overlap at exactly 10,000 words.

## Updating badges on production

Deploy the updated plugin first. For a standard Docker installation, enter the
Discourse container from `/var/discourse` on the host, then run the task:

```sh
./launcher enter app
cd /var/www/discourse
RAILS_ENV=production bundle exec rake wordcounter:create_badges
```

The task updates badges by name, preserves existing badge images, and restores
their configured type, grouping, query, trigger, and automatic revocation settings.
It also queues backfills for **all enabled badges** when badges are enabled.
Sidekiq processes those jobs asynchronously; grants and automatic revocations
may therefore take some time. The task does not recount existing posts. To
rebuild counts separately, run `RAILS_ENV=production bundle exec rake
wordcounter:count_post_words`; this removes the existing counts before rebuilding
them and can take a while on a large site.
