# Read Me

Put your documentation here! Your text is rendered with [GitHub Flavored Markdown](https://help.github.com/articles/github-flavored-markdown).

Click the "Edit Source" button above to make changes.

---
# Overview of SUMO dashboards
---

This document provides background to the Explores and Views used to create these SUMO dashboards:

  * [Community Support](https://mozilla.cloud.looker.com/dashboards-next/160)
  * [Community Support Performance](https://mozilla.cloud.looker.com/dashboards-next/130)
  * [Contributor History](https://mozilla.cloud.looker.com/dashboards-next/159)


## **Explores**

The /sumo/explores folder contain files which define one or more explores appearing in Explore menu under the group label **SUMO**:

|  file  | description  |
| -------------------------|-----------|
|[sumo_q_and_a.explore](../sumo/explores/sumo_q_and_a.explore.lkml)  | contains multiple explores used for ``community support`` and ``knowledge base`` portions of the SUMO dashboards |
|[contributor_health_user_totals_by_period.explore](../sumo/explores/contributor_health_user_totals_by_period.explore.lkml) | supports ``contributor health`` portion of the SUMO dashboards |

At the top of each explore file are multiple *include* statements necessary to reference all the views needed in the explores and joins. For example:

```
include: "/sumo/views/kitsune_questions.view"
include: "/sumo/views/kitsune_answers.view"
```


### ***Community Support: All Metrics***
The **Community Support** explore (labeled **Community Support: All Metrics** in Explore menu)  is the primary explore containing all relevant metrics. This explore joins the *Community_Support* view to four different views on ```question_id```. This explore also has two inner joins on a specific month. The reason for having the monthly roll up is to satisfy the reporting requirement to have a monthly filter. In order to bring in community support metrics and knowledge base metrics all together in the same explore, monthly rolled up derived tables were created from parent views.

**Community Support** explore is created from the view *Community_Support* which extends the *kitsune_questions* view as the primary table. This view is then joined to *kitsune_answers* view to get all answers per question in order to compute ```answer rate and answer count```. Both views are used to create derived tables *first_answer_timestamp* and *avg_first_response* to compute metrics such as ```Avg. First Response, Response < 24 hours``` and so on. For knowledge base metrics, the source tables are monthly aggregated derived tables - *helpfulness_of_kb_articles* and *kitsune_questions_ga_self_service* - which are joined by month to the base *Community Support* view.

```
explore: community_support {
  group_label: "SUMO"
  label: "Community Support: All Metrics"

  join: kitsune_frt {
    type: left_outer
    sql_on: ${community_support.question_id} = ${kitsune_frt.question_id} ;;
    relationship: one_to_one
  }
  join: kitsune_answers {
    type: left_outer
    sql_on: ${community_support.question_id} = ${kitsune_answers.question_id} ;;
    relationship: one_to_many
  }
  join: first_answer_timestamp {
    type:  left_outer
    sql_on: ${community_support.question_id} = ${first_answer_timestamp.kitsune_answers_question_id} ;;
    relationship: one_to_one
  }
  join: avg_first_response {
    type: left_outer
    sql_on: ${community_support.question_id} = ${avg_first_response.community_support_question_id} ;;
    relationship: one_to_one
  }
  join: helpfulness_of_kb_articles {
    type: inner
    sql_on: ${community_support.month} = ${helpfulness_of_kb_articles.month} ;;
    relationship: one_to_one
  }
  join: kitsune_questions_ga_self_service {
    type: inner
    sql_on: ${community_support.month} = ${kitsune_questions_ga_self_service.month} ;;
    relationship: one_to_one
  }
}
```


### ***Community Support: Monthly Aggregated View***
The monthly aggregated explore **Monthly Agg Community Support** (labeled **Community Support: Monthly Aggregated View** in Explore menu) is a clean rollup of the above **Community Support** explore pulling in only the relevant metrics needed for the dashboard. Another reason for creating a separate monthly rolled up explore is to be able to pull in previous month's data for comparison easily, without having to do complex period over period joins. In the below explore join, *monthly_agg_community_support* view is joined to itself on ```current month``` = ```current month - 1 month``` (which gives us the previous month metrics) to compute percentage change vs. previous month.

```
explore: monthly_agg_community_support {
  group_label: "SUMO"
  label: "Community Support: Monthly Aggregated View"
  join: previous_month {
    from: monthly_agg_community_support
    type: inner
    sql_on: ${monthly_agg_community_support.previous_month}=${previous_month.current_month};;
    relationship: one_to_one
  }
  join: percent_calculations {
    sql:   ;;
  relationship: one_to_one
}
}
```

Apart from the pre-created community support dashboards, if you would like to explore the metrics on your own, please use [Monthly version](https://mozilla.cloud.looker.com/explore/sumo/monthly_agg_community_support) explore first to see if the data you need is available there. In such cases where the monthly explore does not contain what you are looking for, you can use the [detailed explore](https://mozilla.cloud.looker.com/explore/sumo/community_support) to explore the data on your own.

### ***Hidden and Single View Explores***
There are three separate explores for three tables: *kitsune_answers*, *kitsune_questions* and *kitsune_wiki_helpfulvote*. All have specific labels which describe these tables. If some of these explores/views do not need to be queried, you can hide them from the menu yet still reference in other explores. For example, the explore **kitsune_wiki_helpfulvote** is a hidden explore used for the native-derived table *helpfulness_of_kb_articles* joined in the larger **Community Support** explore.


### ***Community Support: Contributor Health - User Totals by Period***
The **Contributor Health User Totals by Period** explore (labeled **Community Support: Contributor Health - User Totals by Period** in Explore menu) joins the _contributor health user totals by period_ view with _kitsune users profile_ view to allow for drilling to user attributes. The _shared parameters_ view contains ```Target Month``` parameters and related dimensions that do not refer to a specific database table and can be shared/reused in multiple Explores through a special **bare join**.

This explore also requires the user to provide a Target Month. The underlying view calculates user contribution totals for a series of rolling three-month periods as well as year-to-date through the target month. With total contributions for a rolling 3-month period, we can classify a contributor as ```New, Regular or Core```

```explore: contributor_health_user_totals_by_period {
  group_label: "SUMO"
  label: "Community Support: Contributor Health - User Totals by Period"

  always_filter: {filters:[shared_parameters.target_month: "2021-08-01"]}

  join: kitsune_users_profile {
    relationship: many_to_one
    type: left_outer
    sql_on: ${contributor_health_user_totals_by_period.id} = ${kitsune_users_profile.user_id};;
  }
  ## bare join to add Target Month parameters to this explore
  join: shared_parameters  {
    relationship: one_to_one
    sql:  ;;
  }
}
```

## **Views**
All the views leveraged for the SUMO explores and dashboards are in the folder **/sumo/views**. Many of these are one-to-one mapping with underlying database table while others are Native-derived tables like [Monthly Agg Community Support](../sumo/views/monthly_agg_community_support.view.lkml) or SQL-derived tables like [Contributor Health User Totals by Period](https://mozilla.cloud.looker.com/projects/sumo/files/sumo/views/contributor_health_user_totals_by_period.view.lkml). Refer to each view for more details on the dimensions and measures defined for reporting.

See [Derived Tables in Looker](https://docs.looker.com/data-modeling/learning-lookml/derived-tables) for more information on native- and sql-derived tables.
