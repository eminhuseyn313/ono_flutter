# [TECH] Expert Domain: Technical Architecture

## Purpose
Define technical standards for ONO's Flutter/Dart mobile application, Supabase backend, AI integrations (Claude API), and supporting infrastructure. Ensure performance, privacy, scalability, and maintainability across all features. Every technical decision must prioritize user privacy and data minimization.

## Scope Within ONO
- **Mobile App**: Flutter/Dart architecture, state management, offline-first capabilities
- **Backend**: Supabase (PostgreSQL, Auth, Storage, Edge Functions, Realtime)
- **AI Integration**: Claude API for personalization, content generation, and coaching
- **Image Classification**: Workout verification, progress photos (with strict privacy controls)
- **Real-Time Features**: Accountability check-ins, live challenges, notification delivery
- **Performance**: App startup time, animation smoothness, battery/data efficiency

## Quality Standards
1. Flutter app must maintain 60fps on mid-range Android devices (Snapdragon 600-series baseline)
2. Offline-first: Core features must work without network for up to 24 hours
3. All user data encrypted at rest (Supabase) and in transit (TLS 1.3)
4. AI API calls must never send raw personal data — anonymize/tokenize before transmission
5. Image classification must process locally where possible; server-side only with explicit consent
6. Cold start time under 3 seconds on target devices
7. APK size under 50MB (excluding on-demand asset downloads)

## Review Checklist
- [ ] Does the state management approach (Riverpod/Bloc) handle offline/online transitions gracefully?
- [ ] Are Supabase Row Level Security policies defined for every table?
- [ ] Do AI prompts strip PII before sending to Claude API?
- [ ] Is image data processed with user consent flows and retention limits?
- [ ] Are real-time subscriptions properly cleaned up on widget disposal?
- [ ] Does the app gracefully degrade when API rate limits are hit?
- [ ] Are database migrations versioned and reversible?
- [ ] Is the CI/CD pipeline running lint, tests, and security scans?

## Content Guidelines
### Flutter/Dart Best Practices
- **State Management**: Riverpod (preferred) or Bloc — consistent across the app, never mixed
- **Architecture**: Feature-first folder structure with clean separation (data/domain/presentation)
- **Navigation**: GoRouter with typed routes, deep link support
- **Testing**: Unit tests for business logic, widget tests for UI, integration tests for critical flows
- **Code Style**: Effective Dart guidelines, strict analysis options, zero lint warnings policy

### Supabase Patterns
- **Auth**: Supabase Auth with email/password + social providers, JWT refresh handling
- **Database**: Normalized schema, RLS on every table, no direct client-side SQL for mutations
- **Edge Functions**: Deno-based, for server-side validation, AI API proxying, and webhook handling
- **Storage**: User uploads (progress photos) in private buckets with signed URLs, auto-expiry
- **Realtime**: Presence for accountability features, broadcast for group challenges
- **Migrations**: Sequential, timestamped, tested in staging before production

### AI Integration (Claude API)
- **Proxy Pattern**: All Claude API calls routed through Supabase Edge Functions (never direct from client)
- **Context Management**: User profile summary (anonymized) + current lane progress + recent activity
- **Rate Limiting**: Per-user daily limits on AI interactions, graceful fallback to pre-written content
- **Prompt Safety**: System prompts enforce ONO's tone guidelines, prevent off-topic responses
- **Cost Control**: Cache common responses, batch similar requests, use appropriate model tiers
- **Disclaimer**: AI-generated content always labeled as such in the UI

### Image Classification
- **Workout Verification**: On-device TFLite model for basic exercise recognition
- **Privacy**: Images processed locally, only classification results (not images) sent to server
- **Consent**: Explicit opt-in for any server-side image processing, with clear data retention policy
- **Fallback**: Manual check-in always available as alternative to photo verification

### Real-Time Features
- **Accountability Check-ins**: Supabase Realtime presence channels per accountability pair
- **Group Challenges**: Broadcast channels with server-side aggregation
- **Notifications**: FCM (Android) + APNs (iOS), with Supabase Edge Function orchestration
- **Connection Handling**: Exponential backoff on reconnection, local queue for offline actions

### Performance Optimization
- **Lazy Loading**: Screens and heavy assets loaded on demand
- **Image Caching**: Cached network images with appropriate cache duration
- **Database Queries**: Indexed columns for frequent queries, pagination for lists
- **Animation**: Use RepaintBoundary for complex animations, avoid rebuilding widget trees
- **Battery**: Background sync intervals respect battery level, reduce frequency on low battery

### Privacy-First Architecture
- **Data Minimization**: Collect only what each feature requires, document the purpose
- **Retention Policies**: Progress photos auto-deleted after 90 days, analytics anonymized after 30
- **Export**: User data export (GDPR Art. 20) via Edge Function generating JSON/CSV
- **Deletion**: Hard delete on account deletion, cascading across all tables and storage
- **Audit Log**: Track data access for compliance, stored separately from user data

## Red Flags to Avoid
- **Direct API keys in client code**: All secret keys must live server-side
- **Unbounded queries**: Every database query must have limits and pagination
- **Silent failures**: Every error must be caught, logged, and surfaced appropriately to the user
- **Over-collection**: Requesting permissions (camera, location, contacts) without immediate need
- **Vendor lock-in without abstraction**: Wrap third-party services in repository interfaces
- **Premature optimization**: Profile before optimizing, measure after

## Consultant Brief Template

### Project: ONO Personal Transformation App
**Domain**: Mobile Architecture, Backend, AI Integration
**Stack**: Flutter/Dart, Supabase, Claude API, TFLite

#### What We Need From You
1. **Audit scope**: _(architecture review, performance audit, security assessment, or specific feature)_
2. **Key questions**: _(list 3-5 specific technical questions)_
3. **Deliverable format**: Technical report with code-level recommendations
4. **Timeline**: _(target date)_

#### Context to Review Before Session
- Repository access (read-only) to mobile app and Edge Functions
- Architecture decision records (ADRs)
- Current performance benchmarks
- Supabase schema and RLS policies

#### Specific Concerns
- _(list any performance bottlenecks or architectural debt)_
- _(note any security concerns from internal review)_

#### Success Criteria
- Architecture recommendations with migration path from current state
- Performance improvements quantified with before/after benchmarks
- Security findings rated by severity with remediation steps
- Code examples for recommended patterns

#### Consultant Fills In
- **Assessment date**: ___
- **Codebase areas reviewed**: ___
- **Architecture findings**: ___
- **Performance findings**: ___
- **Security findings**: ___
- **Priority recommendations**: ___
- **Estimated implementation effort**: ___
- **Signed**: ___
