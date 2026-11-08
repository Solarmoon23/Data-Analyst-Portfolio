
# Pine & Paw Memories — Digital Guestbook & Guest Data Management

An interactive, database-driven digital guestbook developed for Pine & Paw Lodge, a vacation rental near Deep Creek Lake, Maryland.

**Live guestbook:** https://pine-paw-memories.dclcmanage.workers.dev/

**Public showcase:** https://pine-paw-memories.dclcmanage.workers.dev/showcase

## Goal

Replace the traditional paper guestbook with an interactive digital experience that allows guests to share memories and photographs while giving property owners control over what is published.

The system also establishes a structured foundation for future guest engagement analytics.

## Features

### Live

- Digital guest memory submission form
- Optional guest names and stay dates
- Guest stories and photo uploads
- Private links for adding additional memories
- Owner dashboard for reviewing submissions
- Approve and reject workflow
- Public showcase displaying approved guest memories
- Interactive guestbook with clickable story titles
- QR-code access for guests

### Planned

- Guest participation and engagement dashboard
- Monthly submission trend analysis
- Approval-rate reporting
- Aggregated guestbook activity metrics

## Data Architecture

- **Cloudflare Workers:** Server-side application logic
- **Cloudflare D1 (SQLite):** Relational database for guest submissions and related records
- **SQL:** Data retrieval, filtering, and record management
- **HTML, CSS, JavaScript:** Responsive user interface

## Skills Demonstrated

- Relational database management
- SQL queries and data filtering
- Data collection and validation
- Data quality and record management
- Workflow automation
- Privacy-conscious data publishing
- Business process improvement
- Web application development

## Business Value

The digital guestbook allows Pine & Paw Lodge to preserve guest memories, streamline the owner's review process, and showcase approved experiences to prospective guests.

The structured data can also support future analysis of guest participation and engagement.

## Privacy

Guest information is not included in this repository. Publicly displayed memories are subject to owner approval and applicable photo-sharing permissions.

## Project Status

Live application. Analytics dashboard planned.
