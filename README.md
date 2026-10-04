# MyBookClub

A free iOS app for finding and running in-person book clubs. Live on the App Store with real users and active clubs across several regions.

[App Store](https://apps.apple.com/app/id6762190250) · [Privacy & Terms](https://samaralimads.github.io/mybookclub-legal)


## What it does

- **Discover:** map and list of nearby clubs, filtered by genre and distance
- **Clubs:** public clubs and private clubs with organiser approval
- **Voting:** members suggest books and vote, the organiser picks the winner
- **Meetings:** scheduling with chapter ranges, RSVPs, calendar export, reminders
- **Board:** organiser announcements with comments, likes, pinning and spoiler tags
- **Reading:** chapter checklist per meeting, book history and group ratings

## Built with

SwiftUI with `@Observable` · Supabase (Postgres, PostGIS, RLS, Storage, Edge Functions) · Sign in with Apple and Google Sign-In · MapKit and CoreLocation · EventKit · APNs · Google Books and Open Library APIs

## Project structure

```
MyBookClub/
  App/            App entry, root view, tab bar
  Config/         Secrets loading
  Models/         Codable models mapped to Supabase columns
  Services/       SupabaseService, book search, location, calendar, notifications
  View Models/    Business logic per feature
  Views/          Auth, Discover, Club, Meetings, Profile
  Shared/         Design system, buttons, layouts, reusable components
```

## Engineering decisions

- **MVVM:** SwiftUI views, `@Observable` ViewModels, and a single service layer for backend access.
- **Security in the database:** access control is enforced with Row Level Security, not UI checks, since client-side gates can be bypassed.
- **Privacy by design:** location is city-level and rounded before storage. Users can export their data and delete their account in-app.
- **Resilient book search:** two APIs queried in parallel, merged, deduplicated and ranked, so one failing source does not break search.
- **Geospatial queries:** nearby clubs are found with PostGIS distance queries.

## Status

Shipped and maintained as a solo project, from design to App Store release.

Source is shown for portfolio purposes. All rights reserved.
