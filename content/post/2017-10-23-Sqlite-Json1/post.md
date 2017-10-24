+++
date = "2017-10-23T22:24:54-08:00"
draft = false
title = "Modeling one-to-many in SQlite using the JSON1 extension"
slug = "sqlite-one-to-many-json1-extension"
disqus_url = "http://blog.benjamin-encz.de/post/sqlite-one-to-many-json1-extension/"
+++

I'm currently reading a great book on [designing data intensive applications](http://dataintensive.net/). In the earlier chapters of the book the author (one of the main contributors to Apache Kafka) discusses the history of database models and tradeoffs between document, relational and graph databases. 

He touches on interesting trend: Some of the most popular database systems such as PostgreSQL and SQlite now offer APIs to store and query JSON documents, making them multi-paradigm and bringing a lot of the benefits of document based database systems to traditionally relational ones.

Coincidentally I'm currently working on a feature that requires me to model a one-to-many relationship in SQlite, which lead me to try it's JSON support.

<!--more-->

----

## Trees, relations, joins & data locality

In software development (specifically in object oriented programming) developers often face an [impedance mismatch](https://en.wikipedia.org/wiki/Object-relational_impedance_mismatch) between the way data is modelled in code and how it is persisted on disk. Many applications map an object graph into a relational database model using some form of [Object-relational mapping](https://en.wikipedia.org/wiki/Object-relational_mapping) system.

More recently, document-oriented database systems have been on the rise. The tree shaped structure of documents is often more suitable to represent serialized objects.

Throughout this post I want to show the tradeoffs between a traditional relational data model that relies on joins and one that combines relations and document-oriented storage to improve data locality.

Let's jump right into the practical example I am facing to demonstrate these tradeoffs. 

## From one assignee to multiple assignees

In my current project I'm working extending the PlanGrid app to support multiple assignees on issues. As of today the assignee is a single field that stores a UUID which references the assigned user. 

In a relational database one would typically add multiple assignees by introducing a join table:

![](JoinTable.png)

The advantage of this approach is that the data is entirely *normalized*. No information about users or issues is duplicated. Additionally we can work with `UNIQUE` constraints to ensure the database doesn't allow the same assignee to be added to an issue multiple times. For these reason we chose to use a join table on our backend Postgres database.

### Modelling relationships in the iOS app

All of our mobile apps use SQlite as a local database. On iOS we're not using an existing ORM system, instead we have a small library for mapping Swift structs to tables. That system doesn't support modeling relationships. Creating a simple, intuitive API for modeling DB relationships is hard ([you might have struggled to understand Core Data faults in the past](https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/CoreData/FaultingandUniquing.html)). Further, the query pattern of our iOS app tends to be such that we only fetch one type of record per query, which makes modeling relationships unnecessary. 

I briefly prototyped an implementation of relationships that joined the underlying tables to fetch multiple records at a time ([probably a great use case for the new `KeyPath` API)](https://gist.github.com/Ben-G/8c9b7800d86d4dd8f92d8cf100d8f630), but I quickly realized that this approach would add a lot of complexity to our DB layer.

The real additional complexity lies in building a query that servers our typical query pattern: fetching an entire record by its UUID. In the past it was sufficient to select all columns (`SELECT *`), now we need to join with the `issue_assignee` table to get a full representation of an issue into memory. The relational approach reduces *data locality* (not all information about an issue is located in one place anymore) which adds complexity to our application.

Here's the query to fetch an individual issue by its UUID:

{{< highlight sql >}}
SELECT * from issues JOIN issueassignees 
ON issueassignees.issue_uuid = issues.uuid where issues.uuid = "4"
{{< /highlight >}}

 Not too bad. But the result of this query is a lot harder to consume than in the past:

![](RelationIndividualQuery.png)

Even though we queried an invididual issue, we now receive *two* result rows. That happens because of our `JOIN` statement, which leads the query to return the entire issue for each issue assignee found in the `issue_assignee` table. ORM systems do a fair amount of work under the covers to deduplicate these results and map them into a single object.

### SQlite JSON support to the rescue!

As mentioned in the intro of the article, SQlite has built-in support to query columns that contain JSON documents (support was added in SQlite 3.9) through the [JSON1 extension](https://sqlite.org/json1.html).

This means we can model the assignees of an issue as an array of JSON objects, instead of using a join table:

![](AssigneeArray.png)

This approach has significantly better *data locality* for the query patterns used in the iOS app. To fetch an issue and all of its assignees we can simply use a `SELECT *` query:

{{< highlight sql >}}
SELECT * from issues where uuid = "4";
{{< /highlight >}}


Thanks to the JSON1 extension we can also build queries for fetching all issues assigned to specific user, without fetching all issues into memory. To fetch all issues assigned to the user with the UUID "7" we can use the following query:

{{< highlight sql >}}
SELECT Issues.* from Issues, json_each(Issues.assignees) 
WHERE json_extract(value, '$.uuid') = "7"
{{< /highlight >}}

When working with the JSON1 API for the first time, it took me a while to understand its components, so let's look at this query in detail.


`json_each` is a [table-valued function](https://sqlite.org/vtab.html#tabfunc2) that takes a column which contains a JSON array (in this case `issues_table.assignees`) and returns each entry of that array as a row with the [following columns](https://sqlite.org/json1.html#jeach):

> The schema for the table returned by json_each() and json_tree() is as follows:
>
> > ```
> > CREATE TABLE json_tree(
> >     key ANY,             -- key for current element relative to its parent
> >     value ANY,           -- value for the current element
> >     type TEXT,           -- 'object','array','string','integer', etc.
> >     atom ANY,            -- value for primitive types, null for array & object
> >     id INTEGER           -- integer ID for this element
> >     parent INTEGER,      -- integer ID for the parent of this element
> >     fullkey TEXT,        -- full path describing the current element
> >     path TEXT,           -- path to the container of the current row
> >     json JSON HIDDEN,    -- 1st input parameter: the raw JSON
> >     root TEXT HIDDEN     -- 2nd input parameter: the PATH at which to start
> > );
> > ```

For this simple case, we only care about the `value` column, which contains the JSON object we are trying to query on (the assignee).

`json_extract` is a function that allows to select a specific property of a JSON object by defining a path (in this case a path that selects the `uuid` property).

By defining `SELECT Issues.*` we are dropping all of the columns of the virtual table generated by `json_each` from the result set, and only selectin the columns from the `Issues` table.

To make it easier to understand the underlying mechanism of this query; here's the output when selecting an issue with all of its assignees, using the `json_each` function:

![](JsonQuerySqlite.png)

Similar to the join shown earlier, each assignee in the JSON aray is broken into a separate result row. However, since the assignees are now store in a JSON array, each row contains the full representation of an issue (columns in the black box), which makes deserialization a lot simpler.

### The downsides

The biggest downside of using JSON1 is the lack of support of indexes on JSON based columns. In general SQlite doesn't support indexing on virtual tables. 

There are some workarounds for this; we could use an update trigger and maintain a materialized table which is filled with the content from the query above, then we could apply an index on top of that table. In our case the data sets stored locally in the iOS app are small enough that we get good performance even without an index on the `assignees` column. 

When using JSON in a relational database you also loose some of the other goodies you might be used to, such as foreign key constraints, unique constraints, etc. A lot of these tradeoffs are more acceptable in a derived data store (a mobile cache) than in a primary one (our backend database). 

## Conclusion

As always in programming it pays off to learn about and leverage the unique features of different paradigms (whether it's DBs, programming languages or 3rd-party frameworks). A lot of datbases are starting to support multiple paradigms. That is great since even data models that mostly map neatly into a relational model can sometimes benefit from storing a part of the data in a document-oriented fashion.

If support for JSON wasn't part of SQlite I would have ended up with a data model that would have been more complex than necessary for our use case. 

P.S: If you want to experiment with the JSON1 API yourself, you can install [DB Browser for SQlite](http://sqlitebrowser.org/), in recent releases it comes with the JSON1 extension compiled into its version of SQlite.

---

*Personal addendum: It's been a little quite here. I've been a little busy with [great personal news](https://twitter.com/benjaminencz/status/904705141110013952). I've also been refreshing my skills in other programming languages and technology stacks and therefore spent less time writing.*
