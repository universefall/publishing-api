PUT /content/:base_path
body:
  content_item_hash (including links)
returns:
  ?
description:
  puts the content item to the LIVE content store, ie. makes it public on the live website.
  also puts the content into the DRAFT content store






PUT /content/:content_id

body:
  content_hash: JSON

returns:
  200 ok, log id?

description:
  store a draft content item
  send the content combined with the latest links to the draft content store






PUT /content/:content_id?publish=true

as above, but also publishes the item





POST /content/:content_id/publish

body:
  empty?

returns:
  ???

description:
  sends the latest draft content item, combined with the latest links to the live content store



PUT /content/:content_id/links

body:
  links_hash: JSON

returns:
  ??

description:
  - stores the provided links as the 'latest' version of the links
  - sends the latest PUBLISHED content item body combined with this set of links to the live content store
  - sends the latest PUBLISHED OR DRAFT content item body combined with this set of links to the draft content store

## Scenario 1

PATCH /links/115e9e1b-2ded-4f39-bcfb-b71d478e930d
{
  organisations: ["a95ab2f2-e5e7-4eb7-a224-3cb2716b422a"]
}

PATCH /links/115e9e1b-2ded-4f39-bcfb-b71d478e930d
{
  organisations: []
}

GET /links/115e9e1b-2ded-4f39-bcfb-b71d478e930d
->
{
}

## Scenario 2

PATCH /links/115e9e1b-2ded-4f39-bcfb-b71d478e930d
{
  organisations: ["a95ab2f2-e5e7-4eb7-a224-3cb2716b422a"]
}

PATCH /links/115e9e1b-2ded-4f39-bcfb-b71d478e930d
{
  topics: ["1c65feee-c988-4ebe-b083-f943264af73b"]
}

GET /links/115e9e1b-2ded-4f39-bcfb-b71d478e930d
->
{
  organisations: ["a95ab2f2-e5e7-4eb7-a224-3cb2716b422a"],
  topics: ["1c65feee-c988-4ebe-b083-f943264af73b"]
}

## Scenario 3

PATCH /links/115e9e1b-2ded-4f39-bcfb-b71d478e930d
{
  organisations: ["a95ab2f2-e5e7-4eb7-a224-3cb2716b422a"]
}

PATCH /links/115e9e1b-2ded-4f39-bcfb-b71d478e930d
{
  topics: ["1c65feee-c988-4ebe-b083-f943264af73b"]
}

PATCH /links/115e9e1b-2ded-4f39-bcfb-b71d478e930d
{
  organisations: []
}

GET /links/115e9e1b-2ded-4f39-bcfb-b71d478e930d
->
{
  topics: ["1c65feee-c988-4ebe-b083-f943264af73b"]
}



## Scenario 4


PUT /content/115e9e1b-2ded-4f39-bcfb-b71d478e930d
{
  format: "case_study",
  details: {
    body: "# stuff"
  }
}

PATCH /links/115e9e1b-2ded-4f39-bcfb-b71d478e930d
{
  organisation: ["3f8fcbc4-782c-4d08-90c0-fc33ee896c7d"]
}
!! send to draft:
{
  format: "case_study",
  details: {
    body: "# stuff"
  },
  links: {
    organisation: ["3f8fcbc4-782c-4d08-90c0-fc33ee896c7d"]
  }
}

POST /publish/115e9e1b-2ded-4f39-bcfb-b71d478e930d
body: nil
!! send to live
{
  format: "case_study",
  details: {
    body: "# stuff"
  },
  links: {
    organisation: ["3f8fcbc4-782c-4d08-90c0-fc33ee896c7d"]
  }
}

PUT /content/115e9e1b-2ded-4f39-bcfb-b71d478e930d
{
  format: "case_study",
  details: {
    body: "# other stuff"
  }
}
!! send to draft
{
  format: "case_study",
  details: {
    body: "# other stuff"
  },
  links: {
    organisation: ["3f8fcbc4-782c-4d08-90c0-fc33ee896c7d"]
  }
}


PATCH /links/115e9e1b-2ded-4f39-bcfb-b71d478e930d
{
  organisation: ["3f8fcbc4-782c-4d08-90c0-fc33ee896c7d", "c8bc7eee-38a0-46e7-babf-1fdb9a75bfd8"]
}
!! send to draft
{
  format: "case_study",
  details: {
    body: "# other stuff"
  },
  links: {
    organisation: ["3f8fcbc4-782c-4d08-90c0-fc33ee896c7d", "c8bc7eee-38a0-46e7-babf-1fdb9a75bfd8"]
  }
}
!! send to live
{
  format: "case_study",
  details: {
    body: "# stuff"
  },
  links: {
    organisation: ["3f8fcbc4-782c-4d08-90c0-fc33ee896c7d", "c8bc7eee-38a0-46e7-babf-1fdb9a75bfd8"]
  }
}


PUT /content/115e9e1b-2ded-4f39-bcfb-b71d478e930d?publish=true
{
  format: "gone"
}
!! send to draft
{
  format: "gone"
}
!! send to live
{
  format: "gone"
}
