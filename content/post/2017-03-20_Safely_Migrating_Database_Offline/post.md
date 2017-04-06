+++
date = "2017-03-20T22:24:54-08:00"
draft = false
title = "Safely migrating millions of database records across thousands of devices"
slug = "safely-migrating-millions-of-database-records-across-thousands-of-devices"
disqus_url = "http://blog.benjamin-encz.de/post/safely-migrating-millions-of-database-records-across-thousands-of-devices/"
+++

*This is a cross post of a piece that original appeared on [the PlanGrid R&D blog](https://medium.com/plangrid-technology/safely-migrating-millions-of-database-records-across-thousands-of-devices-f9ea98f941dc)*

<!--more-->

----

At PlanGrid we recently shipped a major release for our iOS app that required a data migration of our core record types: annotations and issues. Most app developers avoid complex migrations by re-downloading all user data. If you are a developer on a PlanGrid mobile app, you unfortunately do not have that luxury. All PlanGrid apps (iOS, Android, Windows) work entirely offline — an experience that is essential to field workers that use our app under very spotty network conditions. The amount of data stored on a device can be huge; we have users with well over 500,000 records in their local database. This means re-downloading a user’s data isn’t a viable option.

Here’s a quick overview of the issues we faced in this release:

- We updated to new immutable Swift data models from old Objective-C models. These two model types were fundamentally incompatible. Feature flagging the code to support both types would have been a huge overhead (they are used widely throughout the app), so we decided to only support the new types after users updated to version 5.0.0 of the app.
- Since a user could launch their updated app for the first time without a network connection, we had to make sure that we could generate new models from the old models offline. This was the only way to ensure that users would not be blocked when updating to 5.0.0.
- We did not only update our models, but also the underlying database schema. In the old schema a large portion of the models was stored as a shapeless JSON blob. In the new schema every property of a model cleanly maps to a database column. When going to a stricter schema, there is always a risk of facing old data that doesn’t match the new schema.

There are a bunch of additional challenges outside of the scope of the data migration that we’ll discuss in a future blog post.

## Mitigating Risk

Especially on the iOS platform, risk mitigation is an essential part of every major release. Unlike web or backend teams, we cannot simply roll back changes that cause production issues. Unfortunately, Apple also doesn’t support a gradual rollout of a new app version (as Android does). We needed to ensure that the data migration would work reliably for all our users before we shipped the 5.0.0 release.

After discussing various approaches we decided to roll out a “dry run” data migration in a pre-5.0.0 release. This migration would use the actual migration code, but the migrated records would not be used in the app. The migration would also not be visible to the user. Instead we would run the migration to collect various metrics:

- How many records does the user have in the local database?
- How long did the migration take?
- How many records were migrated successfully? How many failed? Why did some records fail to be migrated?
- Did the app crash during the migration?

While we tested the migration extensively in-house, we knew that the sheer number of production users and the diversity of their projects, would cause issues that we wouldn’t find through our QA process.

So we combined the rollout with a feature flag, that allowed us to quickly turn the dry-run migration off in case of issues on production projects.

## Shipping the Dry Run Migration

In total, we only shipped two versions of our dry run migration.

As (almost) expected, the first version caused a measurable amount of crashes that we hadn’t seen internally. We quickly turned off the feature flag and used the information from our analytics data and our crash reporter to fix the underlying issues. We also found four varieties of records that were in an invalid schema. For those four varieties, we came up with a migration path that provided sensible default values for missing or incorrect fields.

We then rolled out a second version and verified our fixes. The data from the second roll out assured us that all of our users would be able to migrate without any crashes, data losses or corruptions — with the exception of exactly one customer (that had a local SQLite DB of a whopping 3.7 GB!).

## Product-ifying the Migration

Now that we had verified our migration code, it was time to finalize the migration and ship it as part of the 5.0.0 release. We used the exact code that we tested throughout the dry run migrations, except this time we would use the migrated records in production.

Our new code was only compatible with the new schema and new models. This meant we needed to block the user from interacting with records until the migration was complete.

![](migration_screenshot.png)

*The data migration with one of our test accounts that has 100,000 annotations and issues in its local DB.*

We informed the user about a one-time performance update (the new models enabled significant performance gains) and showed them how many of their records had been migrated. Based on the metrics we collected from our dry-run migration, we knew that the 90th percentile of our users would complete the migration in under one minute.

## Conclusion

We’ve released PlanGrid 5.0.0 about three weeks ago and well over 50% of our users have updated to 5.0.0 or higher. We’ve been monitoring the rollout closely and are extremely happy to see that the insights from our dry run migrations have held up in production. Only a single customer (you might remember, the one with the 3.7 GB SQLite database) ran into issues during the migration and they were very grateful when we immediately reached out to them.

Feature flags and testing new code in the background in a production app can go a long way to mitigate risk. When rolling out changes like these, I’m extremely envious of backend engineers that can use awesome tools like [GitHub’s scientist](https://github.com/github/scientist). With a little bit of creativity we can bring some of these ideas to mobile and ensure that large migrations aren’t preceded & followed by sleepless nights.