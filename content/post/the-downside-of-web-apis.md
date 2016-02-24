+++
date = "2014-08-10T22:24:54-08:00"
draft = false
title = "The downside of Web APIs"
+++

Web APIs have done a lot for the world of technology. Services that have formerly been isolated islands can now be connected through a few simple HTTP Requests. Posting to Facebook on every GitHub commit? Printing a Postcard as soon as a new Photo is uploaded to a Dropbox folder? Basically anything is possible through Web Services.

<!--more-->

Another great aspect of Web Services is that all the implementation details of these powerful platforms are hidden behind a well documented HTTP Interface allowing Developers to build products that integrate with multiple services in the matter of hours - without establishing old-school SQL Connections and writing complicated Database Queries.

## Now what are the downsides then?

Simple is good. But simple also means less flexibility and less power. Accessing information through Web APIs can often be very inefficient. Many Web APIs embrace patterns that can lead to poor performance of a Web Application.

## Example Query: Count Commits per Contributor on GitHub Repository##

Let's assume we want to build an Application that allows users to log in with their GitHub account. Once the user is logged in, the application shall count all commits of that user from all of the repositories he/she owns.

### Database Request Solution (Old Fashioned)

This part of the Blog post is entirely fictional. It only serves the purpose of showing what a DB request could look like. Assuming GitHub would run on a Relational Database and would allow developers to access the DB directly, a request could look somewhat like that:

	SELECT COUNT(*) FROM COMMITS WHERE AUTHOR=$USERNAME AND REPO_OWNER=$USERNAME

Despite the fact that an actual request on GitHubs DB definitely would not look like the one above, the key takeaways are:

- We can retrieve the information with one query. Admittedly the request above assumes a *strongly* denormalized DB model. But even if that wasn't the case we could retrieve the information we need in one query by joining tables
- We can define which information we are interested in. In this case we just want the *count* of commits and don't want to select any additional information.

### Web API Solution
*Note: The GitHub Web API provides a Statistics API that makes it easier to access the commit count per contributor. However it only provides information for the past year. For our application we want the information over the entire lifetime.*

Now let's take a look at a solution using the GitHub Web API. Like most queries our problem cannot be solved with a single request. First we need to retrieve a list of repositories using this GET Request:

	GET /users/:username/repos

Now we need to perform another request **for each** repository to get the repository details (Can you already feel the pain?):

	GET /repos/:owner/:repo/commits

Finally we need to iterate over all returned commits for each repository and check the author field and count all commits authored by the current user.

You can see the downsides? If the User has 20 Repositories we need to run 21 `HTTP GET` requests. For each repository we will get all commits, even though we only want the ones authored by the current user. Then we have to manually filter the list in order to retrieve the actual commit count.

This is inefficient in multiple ways:

- The overhead of 21 HTTP Requests is significant
- The server will trigger a DB Query for each HTTP Request (let's ignore potential caches for simplicity). Because the Server treats every request isolated it cannot optimize the DB Query
- The server will return too much data. If only 70% of the commits on the repositories we are checking are by the original author then we are downloading 30% of the JSON data for nothing. Additionally we cannot specify which fields we are interested in. For each Commit the GitHub API returns 11 fields of which we only need the email of the author
- After all the requests have completed we need to filter the response manually. This is more of an inefficiency from a development standpoint. The performance impact of this step will usually be very low

The largest of the above problems is that we need to create an individual request for each repository. That problem is called the ["N+1 problem"](http://www.infoq.com/articles/N-Plus-1). 1 Request is needed to retrieve a list of items. Than we need another request for each entry (N) in that list.

### Alternatives?

Obviously, for Security reasons, no Platform will allow API clients to write entirely custom DB queries. The viable alternative is exposing a little bit more of the DB layer to the Web API; Resulting in more complexity but also more power. Examples:

- [Batch Requests](https://parse.com/docs/rest#objects-batch) as used e.g. by Parse. Though these in most cases only avoid multiple HTTP Requests but not multiple DB Queries
- [Resource Expansion](https://stormpath.com/blog/linking-and-resource-expansion-rest-api-tips/) as provided by some REST APIs. If GitHub would provide this option, an example query could look like this:

       	GET /users/:username/repos?expand=commits

	This would tell the GitHub API that we want to select the commits of each repository along with the repository details in one response. Resource Expansion can solve the N+1 problem.

The Microsoft initiated OData goes one step further and allows Web API clients to append [*expand* **and** *select*](http://blogs.msdn.com/b/webdev/archive/2013/07/05/introducing-select-and-expand-support-in-web-api-odata.aspx) parameters to their queries providing an Interface that is almost as powerful as direct DB queries.

The N+1 problem should be kept in mind when consuming or designing Web APIs. I'm sure we will see more sophisticated query interfaces in Web APIs in future.


*Resources linked in this post:*

- https://stormpath.com/blog/linking-and-resource-expansion-rest-api-tips/

- http://www.asp.net/web-api/overview/odata-support-in-aspnet-web-api/using-$select,-$expand,-and-$value

- http://blogs.msdn.com/b/webdev/archive/2013/07/05/introducing-select-and-expand-support-in-web-api-odata.aspx

*Other related Resources:*

- http://redotheweb.com/2012/08/09/how-to-design-rest-apis-for-mobile.html
